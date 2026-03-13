import 'package:flutter/material.dart';

import '../../models/message.dart';
import '../../models/image_message.dart';
import '../../enums/bubble_rtl_alignment.dart';
import '../typing_indicator.dart';
import 'optimized_chat_list.dart';
import '../message/lazy_image_message.dart';
import '../message/image_message.dart';

/// Performance-optimized Chat widget that uses the optimized ChatList and lazy loading components.
/// This is a drop-in replacement for the standard Chat widget with better performance for large message lists.
class PerformanceOptimizedChat extends StatefulWidget {
  const PerformanceOptimizedChat({
    super.key,
    required this.messages,
    required this.onSendPressed,
    required this.user,
    this.bubbleRtlAlignment = BubbleRtlAlignment.right,
    this.enableLazyImageLoading = true,
    this.imageCacheWidth,
    this.imageCacheHeight,
    this.onEndReached,
    this.onEndReachedThreshold,
    this.scrollController,
    this.typingIndicatorOptions,
    this.useTopSafeAreaInset = true,
  });

  /// List of messages to display
  final List<MessageModel> messages;

  /// Function called when user sends a message
  final void Function(dynamic) onSendPressed;

  /// Current user
  final dynamic user;

  /// RTL alignment for bubbles
  final BubbleRtlAlignment bubbleRtlAlignment;

  /// Whether to enable lazy loading for images (default: true)
  final bool enableLazyImageLoading;

  /// Cache width for images (for memory optimization)
  final int? imageCacheWidth;

  /// Cache height for images (for memory optimization)
  final int? imageCacheHeight;

  /// Called when scrolled to end for pagination
  final Future<void> Function()? onEndReached;

  /// Threshold for triggering pagination (0.0 to 1.0)
  final double? onEndReachedThreshold;

  /// Custom scroll controller
  final ScrollController? scrollController;

  /// Typing indicator configuration
  final TypingIndicatorOptions? typingIndicatorOptions;

  /// Whether to use top safe area inset
  final bool useTopSafeAreaInset;

  @override
  State<PerformanceOptimizedChat> createState() =>
      _PerformanceOptimizedChatState();
}

class _PerformanceOptimizedChatState extends State<PerformanceOptimizedChat> {
  late ScrollController _scrollController;

  /// P-10: cached item list — recomputed only when widget.messages changes.
  late List<Object> _cachedItems;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _cachedItems = _convertMessagesToItems();
  }

  @override
  void didUpdateWidget(covariant PerformanceOptimizedChat oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recompute only when the messages list reference (or length) changes.
    if (!identical(widget.messages, oldWidget.messages)) {
      _cachedItems = _convertMessagesToItems();
    }
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  /// Convert messages to the format expected by OptimizedChatList
  List<Object> _convertMessagesToItems() {
    final items = <Object>[];

    // Add spacer at the beginning (index 0)
    items.add('spacer');

    // Add messages
    for (final message in widget.messages) {
      items.add({'message': message});
    }

    return items;
  }

  /// Build message widget based on type
  Widget _buildMessageWidget(Object item, int? index) {
    if (item == 'spacer') {
      return const SizedBox(height: 8);
    }

    if (item is Map<String, Object>) {
      final message = item['message'] as MessageModel;

      // Use lazy image loading for image messages if enabled
      if (message is ImageMessageModel && widget.enableLazyImageLoading) {
        return LazyImageMessage(
          message: message,
          messageWidth: 300,
          lazyLoadingEnabled: true,
          cacheWidth: widget.imageCacheWidth,
          cacheHeight: widget.imageCacheHeight,
        );
      }

      // Fall back to regular image widget
      if (message is ImageMessageModel) {
        return ImageMessage(message: message, messageWidth: 300);
      }

      // For other message types, return a basic implementation
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Message: ${message.id}',
          style: const TextStyle(color: Colors.white),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final items = _cachedItems;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: OptimizedChatList(
              items: items,
              scrollController: _scrollController,
              bubbleRtlAlignment: widget.bubbleRtlAlignment,
              useTopSafeAreaInset: widget.useTopSafeAreaInset,
              onEndReached: widget.onEndReached,
              onEndReachedThreshold: widget.onEndReachedThreshold,
              typingIndicatorOptions: widget.typingIndicatorOptions,
              itemBuilder: _buildMessageWidget,
            ),
          ),
          // You would add your input widget here
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FloatingActionButton.small(
                  onPressed: () {
                    widget.onSendPressed('Test message');
                  },
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Configuration class for performance optimization settings
class ChatPerformanceConfig {
  const ChatPerformanceConfig({
    this.enableLazyImageLoading = true,
    this.imageCacheSize = 50,
    this.imageCacheWidth,
    this.imageCacheHeight,
  });

  /// Whether to enable lazy loading for images
  final bool enableLazyImageLoading;

  /// Maximum number of image widgets to cache
  final int imageCacheSize;

  /// Cache width for images (memory optimization)
  final int? imageCacheWidth;

  /// Cache height for images (memory optimization)
  final int? imageCacheHeight;

  /// Default high-performance configuration
  static const ChatPerformanceConfig highPerformance = ChatPerformanceConfig(
    enableLazyImageLoading: true,
    imageCacheSize: 30,
    imageCacheWidth: 300,
    imageCacheHeight: 300,
  );

  /// Default memory-optimized configuration
  static const ChatPerformanceConfig memoryOptimized = ChatPerformanceConfig(
    enableLazyImageLoading: true,
    imageCacheSize: 20,
    imageCacheWidth: 200,
    imageCacheHeight: 200,
  );
}
