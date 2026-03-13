import 'dart:async';

import 'package:chat_message_core/src/models/message.dart';
import 'package:diffutil_dart/diffutil.dart'
    show calculateListDiff, Insert, Remove, Move;
import 'package:flutter/material.dart';

import '../../enums/bubble_rtl_alignment.dart';
import '../../utils/message_cache_manager.dart';
import '../../inherited/inherited_chat_theme.dart';
import '../../inherited/inherited_user.dart';
import '../typing_indicator.dart';

/// Performance-optimized chat list backed by [SliverAnimatedList].
/// Uses [diffutil_dart] (synchronous Myers diff) to compute minimal insert/
/// remove operations — no isolate overhead for a Set.difference() that takes
/// ~0.1 ms on the UI thread.
class OptimizedChatList extends StatefulWidget {
  const OptimizedChatList({
    super.key,
    this.bottomWidget,
    required this.bubbleRtlAlignment,
    this.isLastPage,
    required this.itemBuilder,
    required this.items,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.onEndReached,
    this.onEndReachedThreshold,
    required this.scrollController,
    this.scrollPhysics,
    this.typingIndicatorOptions,
    required this.useTopSafeAreaInset,
  });

  final Widget? bottomWidget;
  final BubbleRtlAlignment bubbleRtlAlignment;
  final bool? isLastPage;
  final Widget Function(Object, int? index) itemBuilder;
  final List<Object> items;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final Future<void> Function()? onEndReached;
  final double? onEndReachedThreshold;
  final ScrollController scrollController;
  final ScrollPhysics? scrollPhysics;
  final TypingIndicatorOptions? typingIndicatorOptions;
  final bool useTopSafeAreaInset;

  @override
  State<OptimizedChatList> createState() => _OptimizedChatListState();
}

class _OptimizedChatListState extends State<OptimizedChatList>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  late final Animation<double> _animation = CurvedAnimation(
    curve: Curves.easeOutQuad,
    parent: _controller,
  );

  bool _indicatorOnScrollStatus = false;
  bool _isNextPageLoading = false;

  final GlobalKey<SliverAnimatedListState> _listKey = GlobalKey();

  /// Internal copy of the displayed items — kept in sync with the animated list.
  List<Object> _items = [];

  late final MessageCacheManager _cacheManager;

  /// Pending animation-cleanup timers stored so they can be cancelled on dispose.
  final List<Timer> _pendingTimers = [];

  @override
  void initState() {
    super.initState();
    _cacheManager = MessageCacheManager(maxCacheSize: 50);
    _items = List<Object>.from(widget.items);
  }

  @override
  void didUpdateWidget(covariant OptimizedChatList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.length != oldWidget.items.length ||
        !MessageUtils.listsEqual(widget.items, oldWidget.items)) {
      _updateItems(widget.items, oldWidget.items);
    }
  }

  void _updateItems(List<Object> newItems, List<Object> oldItems) {
    // Snapshot the current list for remove animation builders.
    final snapshot = List<Object>.from(_items);

    // Update internal state first so itemBuilder sees the correct new items.
    _items = List<Object>.from(newItems);

    // Myers diff — synchronous, ~0.1 ms even for large lists.
    final updates = calculateListDiff<Object>(
      snapshot,
      newItems,
      equalityChecker: (a, b) => a == b,
      detectMoves: false,
    ).getUpdates(batch: true);

    for (final update in updates) {
      if (update is Insert) {
        for (var i = 0; i < update.count; i++) {
          _listKey.currentState?.insertItem(update.position + i);
        }
      } else if (update is Remove) {
        for (var i = 0; i < update.count; i++) {
          final item = snapshot[update.position + i];
          _listKey.currentState?.removeItem(
            update.position,
            (context, animation) => SizeTransition(
              sizeFactor: animation,
              axisAlignment: -1,
              child: widget.itemBuilder(item, null),
            ),
          );
        }
      } else if (update is Move) {
        final item = snapshot[update.from];
        _listKey.currentState?.removeItem(
          update.from,
          (context, animation) => SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1,
            child: widget.itemBuilder(item, null),
          ),
        );
        _listKey.currentState?.insertItem(update.to);
      }
      // Change: widget rebuilds automatically via the hash guard in the cache.
    }

    // Mark newly-arrived messages for slide-in animation.
    final oldIds = MessageUtils.extractMessageIds(oldItems);
    final newIds = MessageUtils.extractMessageIds(newItems);
    final arrivedIds = newIds.difference(oldIds);
    for (final id in arrivedIds) {
      _cacheManager.setAnimating(id, true);
    }
    if (arrivedIds.isNotEmpty) {
      _pendingTimers.add(
        Timer(const Duration(milliseconds: 300), () {
          if (mounted) _cacheManager.clearAnimationState(arrivedIds);
        }),
      );
    }

    _scrollToBottomIfNeeded(oldItems);
  }

  void _scrollToBottomIfNeeded(List<Object> oldItems) {
    if (widget.items.length > 1 && oldItems.length > 1) {
      try {
        final oldItem = oldItems[1];
        final item = widget.items[1];

        if (oldItem is Map<String, Object> && item is Map<String, Object>) {
          final oldMessage = oldItem['message'] as MessageModel;
          final message = item['message'] as MessageModel;

          if (oldMessage.id != message.id &&
              message.author.id == InheritedUser.of(context).user.id) {
            Future.delayed(const Duration(milliseconds: 50), () {
              if (widget.scrollController.hasClients) {
                widget.scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutQuad,
                );
              }
            });
          }
        }
      } catch (e) {
        // Ignore errors in scroll calculation.
      }
    }
  }

  Widget _buildCachedItem(Object item, int index, Animation<double> animation) {
    final message = MessageUtils.extractMessage(item);
    if (message != null) {
      final hash = message.hashCode;
      final cachedWidget = _cacheManager.getCachedWidget(message.id, hash);

      final child = cachedWidget != null
          ? (_cacheManager.isAnimating(message.id)
              ? _wrapWithSlideIn(cachedWidget)
              : cachedWidget)
          : _buildAndCache(item, index, message.id, hash);

      return SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: child,
      );
    }

    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1,
      child: widget.itemBuilder(item, index),
    );
  }

  Widget _buildAndCache(Object item, int index, String messageId, int hash) {
    final newWidget = widget.itemBuilder(item, index);
    _cacheManager.cacheWidget(messageId, newWidget, hash);
    return _cacheManager.isAnimating(messageId)
        ? _wrapWithSlideIn(newWidget)
        : newWidget;
  }

  Widget _wrapWithSlideIn(Widget child) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuad,
      child: child,
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, 20 * (1 - value)),
        child: Opacity(opacity: value, child: child),
      ),
    );
  }

  @override
  void dispose() {
    for (final t in _pendingTimers) {
      t.cancel();
    }
    _pendingTimers.clear();
    _controller.dispose();
    _cacheManager.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification.metrics.pixels > 10.0 && !_indicatorOnScrollStatus) {
          setState(() => _indicatorOnScrollStatus = true);
        } else if (notification.metrics.pixels <= 10.0 &&
            _indicatorOnScrollStatus) {
          setState(() => _indicatorOnScrollStatus = false);
        }

        if (widget.onEndReached != null &&
            widget.isLastPage != true &&
            !_isNextPageLoading &&
            widget.items.isNotEmpty) {
          final threshold = widget.onEndReachedThreshold ?? 0.75;
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent * threshold) {
            _controller.duration = Duration.zero;
            _controller.forward();
            setState(() => _isNextPageLoading = true);

            widget.onEndReached!().whenComplete(() {
              if (mounted) {
                _controller.duration = const Duration(milliseconds: 300);
                _controller.reverse();
                setState(() => _isNextPageLoading = false);
              }
            });
          }
        }

        return false;
      },
      child: CustomScrollView(
        controller: widget.scrollController,
        keyboardDismissBehavior: widget.keyboardDismissBehavior,
        physics: widget.scrollPhysics,
        reverse: true,
        slivers: [
          if (widget.bottomWidget != null)
            SliverToBoxAdapter(child: widget.bottomWidget),

          SliverPadding(
            padding: const EdgeInsets.only(bottom: 4),
            sliver: SliverToBoxAdapter(child: _buildTypingIndicator()),
          ),

          SliverPadding(
            padding: const EdgeInsets.only(bottom: 4),
            sliver: SliverAnimatedList(
              key: _listKey,
              initialItemCount: _items.length,
              itemBuilder: (context, index, animation) =>
                  _buildCachedItem(_items[index], index, animation),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.only(
              top: 16 +
                  (widget.useTopSafeAreaInset
                      ? MediaQuery.of(context).padding.top
                      : 0),
            ),
            sliver: SliverToBoxAdapter(
              child: SizeTransition(
                axisAlignment: 1,
                sizeFactor: _animation,
                child: Center(
                  child: Container(
                    alignment: Alignment.center,
                    height: 32,
                    width: 32,
                    child: _isNextPageLoading
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              backgroundColor: Colors.transparent,
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                InheritedChatTheme.of(context).theme.primaryColor,
                              ),
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    final typingOptions = widget.typingIndicatorOptions;
    if (typingOptions == null ||
        typingOptions.typingUsers.isEmpty ||
        _indicatorOnScrollStatus) {
      return const SizedBox.shrink();
    }

    if (typingOptions.customTypingIndicatorBuilder != null) {
      return typingOptions.customTypingIndicatorBuilder!(
        context: context,
        bubbleAlignment: widget.bubbleRtlAlignment,
        options: typingOptions,
        indicatorOnScrollStatus: _indicatorOnScrollStatus,
      );
    }

    return typingOptions.customTypingIndicator ??
        TypingIndicator(
          bubbleAlignment: widget.bubbleRtlAlignment,
          options: typingOptions,
          showIndicator: true,
        );
  }
}
