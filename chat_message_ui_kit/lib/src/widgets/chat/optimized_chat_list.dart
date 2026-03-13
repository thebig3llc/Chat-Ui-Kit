import 'dart:async';

import 'package:chat_message_ui_kit/src/models/message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../enums/bubble_rtl_alignment.dart';
import '../../utils/message_cache_manager.dart';
import '../../inherited/inherited_chat_theme.dart';
import '../../inherited/inherited_user.dart';
import '../typing_indicator.dart';

/// Performance-optimized chat list that uses ListView.builder for better memory usage
/// and moves diff calculations to isolate for large message lists.
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
    this.enableIsolateForDiff = true,
    this.diffThreshold = 100,
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

  /// Whether to use isolate for diff calculation on large lists
  final bool enableIsolateForDiff;

  /// Minimum number of items to trigger isolate diff calculation
  final int diffThreshold;

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

  /// Message cache manager for performance optimization
  late final MessageCacheManager _cacheManager;

  /// P-4: pending animation-cleanup timers stored so they can be cancelled in dispose.
  final List<Timer> _pendingTimers = [];

  /// P-7: last-seen model per message ID — used to detect stale cached widgets.
  final Map<String, MessageModel> _lastSeenMessages = {};

  @override
  void initState() {
    super.initState();
    _cacheManager = MessageCacheManager(maxCacheSize: 50);
  }

  @override
  void didUpdateWidget(covariant OptimizedChatList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.items.length != oldWidget.items.length ||
        !MessageUtils.listsEqual(widget.items, oldWidget.items)) {
      _handleListUpdate(oldWidget.items);
    }
  }

  /// Efficiently handle list updates with optimized diff calculation
  void _handleListUpdate(List<Object> oldItems) async {
    if (widget.items.length > widget.diffThreshold &&
        widget.enableIsolateForDiff) {
      // P-6: use compute() for large lists (warm-isolate reuse, no spawn overhead)
      await _calculateDiffsInIsolate(oldItems);
    } else {
      _calculateDiffsSync(oldItems);
    }

    _scrollToBottomIfNeeded(oldItems);
  }

  /// Synchronous diff calculation for smaller lists
  void _calculateDiffsSync(List<Object> oldItems) {
    final newIds = MessageUtils.extractMessageIds(widget.items);
    final oldIds = MessageUtils.extractMessageIds(oldItems);

    final newMessages = newIds.difference(oldIds);

    for (final messageId in newMessages) {
      _cacheManager.setAnimating(messageId, true);
    }

    // P-4: store the timer reference so it can be cancelled if widget disposes.
    if (newMessages.isNotEmpty) {
      _pendingTimers.add(
        Timer(const Duration(milliseconds: 300), () {
          if (mounted) _cacheManager.clearAnimationState(newMessages);
        }),
      );
    }
  }

  /// Asynchronous diff calculation using compute() for large lists.
  /// P-6: replaces Isolate.spawn + ReceivePort with compute() which reuses a
  /// warm background isolate and avoids the ~20–50 ms per-spawn overhead.
  /// P-5: adds a 5-second timeout so a hung compute never freezes the UI.
  Future<void> _calculateDiffsInIsolate(List<Object> oldItems) async {
    try {
      final result = await compute(
        _computeDiffFunction,
        _DiffComputeData(oldItems: oldItems, newItems: widget.items),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => DiffResult(newMessageIds: {}, removedMessageIds: {}),
      );

      if (result.newMessageIds.isNotEmpty) {
        for (final messageId in result.newMessageIds) {
          _cacheManager.setAnimating(messageId, true);
        }
        // P-4: store timer reference.
        _pendingTimers.add(
          Timer(const Duration(milliseconds: 300), () {
            if (mounted) {
              _cacheManager.clearAnimationState(result.newMessageIds);
            }
          }),
        );
      }
    } catch (e) {
      // Fallback to sync calculation if compute fails
      _calculateDiffsSync(oldItems);
    }
  }

  /// Auto-scroll to bottom for new user messages
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
        // Ignore errors in scroll calculation
      }
    }
  }

  /// Build widget with caching for better performance.
  /// P-7: evicts the cached widget when the message model has changed
  /// (e.g. status transitions sending → sent → delivered).
  Widget _buildCachedItem(Object item, int index) {
    final message = MessageUtils.extractMessage(item);
    if (message != null) {
      // P-7: if we have a stale cached widget, evict it before the lookup.
      final lastSeen = _lastSeenMessages[message.id];
      if (lastSeen != null && lastSeen != message) {
        _cacheManager.removeCachedWidget(message.id);
      }

      final cachedWidget = _cacheManager.getCachedWidget(message.id);
      if (cachedWidget != null) {
        _lastSeenMessages[message.id] = message;
        if (_cacheManager.isAnimating(message.id)) {
          return _wrapWithAnimation(cachedWidget);
        }
        return cachedWidget;
      }

      // Build new widget and cache it
      final newWidget = widget.itemBuilder(item, index);
      _cacheManager.cacheWidget(message.id, newWidget);
      _lastSeenMessages[message.id] = message;

      if (_cacheManager.isAnimating(message.id)) {
        return _wrapWithAnimation(newWidget);
      }
      return newWidget;
    }

    return widget.itemBuilder(item, index);
  }

  /// Wrap widget with slide-in animation
  Widget _wrapWithAnimation(Widget child) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutQuad,
      child: child,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
    );
  }

  @override
  void dispose() {
    // P-4: cancel all pending animation-cleanup timers.
    for (final t in _pendingTimers) {
      t.cancel();
    }
    _pendingTimers.clear();
    _lastSeenMessages.clear();
    _controller.dispose();
    _cacheManager.clearCache();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        // P-3: guard setState so it only fires when the value actually changes.
        // Use <= 10.0 (not == 0.0) so the indicator resets even on slow scrolls.
        if (notification.metrics.pixels > 10.0 && !_indicatorOnScrollStatus) {
          setState(() {
            _indicatorOnScrollStatus = true;
          });
        } else if (notification.metrics.pixels <= 10.0 &&
            _indicatorOnScrollStatus) {
          setState(() {
            _indicatorOnScrollStatus = false;
          });
        }

        // Handle pagination
        if (widget.onEndReached != null &&
            widget.isLastPage != true &&
            !_isNextPageLoading &&
            widget.items.isNotEmpty) {
          final threshold = widget.onEndReachedThreshold ?? 0.75;
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent * threshold) {
            _controller.duration = Duration.zero;
            _controller.forward();

            setState(() {
              _isNextPageLoading = true;
            });

            widget.onEndReached!().whenComplete(() {
              if (mounted) {
                _controller.duration = const Duration(milliseconds: 300);
                _controller.reverse();
                setState(() {
                  _isNextPageLoading = false;
                });
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
          // Bottom widget
          if (widget.bottomWidget != null)
            SliverToBoxAdapter(child: widget.bottomWidget),

          // Typing indicator
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 4),
            sliver: SliverToBoxAdapter(child: _buildTypingIndicator()),
          ),

          // Optimized message list
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 4),
            sliver: SliverList.builder(
              itemCount: widget.items.length,
              itemBuilder: (context, index) {
                return _buildCachedItem(widget.items[index], index);
              },
            ),
          ),

          // Loading indicator
          SliverPadding(
            padding: EdgeInsets.only(
              top:
                  16 +
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
                    child:
                        _isNextPageLoading
                            ? SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                backgroundColor: Colors.transparent,
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  InheritedChatTheme.of(
                                    context,
                                  ).theme.primaryColor,
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

// ---------------------------------------------------------------------------
// compute() infrastructure (P-6)
// ---------------------------------------------------------------------------

/// Private data class passed to [_computeDiffFunction] via compute().
class _DiffComputeData {
  _DiffComputeData({required this.oldItems, required this.newItems});

  final List<Object> oldItems;
  final List<Object> newItems;
}

/// Top-level function executed by compute() in a background isolate.
/// Returns a [DiffResult] directly rather than communicating via SendPort.
DiffResult _computeDiffFunction(_DiffComputeData data) {
  try {
    final oldIds = _extractMessageIdsIsolate(data.oldItems);
    final newIds = _extractMessageIdsIsolate(data.newItems);
    return DiffResult(
      newMessageIds: newIds.difference(oldIds),
      removedMessageIds: oldIds.difference(newIds),
    );
  } catch (e) {
    return DiffResult(newMessageIds: {}, removedMessageIds: {});
  }
}

/// Extract message IDs from an items list (runs in background isolate).
Set<String> _extractMessageIdsIsolate(List<Object> items) {
  return items.whereType<Map<String, Object>>().map((item) {
    final message = item['message'] as MessageModel;
    return message.id;
  }).toSet();
}

// ---------------------------------------------------------------------------
// Public data classes (kept for API stability)
// ---------------------------------------------------------------------------

/// Result class for diff calculation
class DiffResult {
  DiffResult({required this.newMessageIds, required this.removedMessageIds});

  final Set<String> newMessageIds;
  final Set<String> removedMessageIds;
}
