import 'package:flutter/material.dart';

import '../../enums/bubble_rtl_alignment.dart';
import '../typing_indicator.dart';
import 'optimized_chat_list.dart';

/// The main scrollable list widget that displays chat messages with animations and pagination.
/// This widget handles the complex logic of animating messages in/out, managing scroll behavior,
/// infinite scrolling for loading more messages, and showing typing indicators.
///
/// **Performance Note**: This widget now uses OptimizedChatList internally for better performance
/// with large message lists while maintaining the same API for backward compatibility.
class ChatList extends StatefulWidget {
  /// Creates a ChatList widget with all necessary configuration.
  /// Most parameters are required to ensure proper chat functionality.
  const ChatList({
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

  /// Optional widget to display at the bottom of the message list.
  /// This appears below all messages and can be used for custom UI elements.
  final Widget? bottomWidget;

  /// Controls the alignment of typing indicator and other RTL-aware elements.
  /// Used to properly position UI elements based on text direction.
  final BubbleRtlAlignment bubbleRtlAlignment;

  /// Flag indicating whether all messages have been loaded (no more pages available).
  /// When true, infinite scroll pagination will not be triggered anymore.
  /// Used together with onEndReached for pagination control.
  final bool? isLastPage;

  /// Function that builds individual list items (messages, headers, spacers, etc.).
  /// Called for each item in the list to create the corresponding widget.
  /// The index parameter can be null for removed items during animation.
  final Widget Function(Object, int? index) itemBuilder;

  /// List of all items to be displayed in the chat list.
  /// Can contain messages, date headers, spacers, and other chat elements.
  final List<Object> items;

  /// Callback function for infinite scroll pagination.
  /// Called when user scrolls near the end of the list to load more messages.
  /// Should return a Future that completes when new messages are loaded.
  final Future<void> Function()? onEndReached;

  /// Controls how the on-screen keyboard should be dismissed when scrolling.
  /// Affects user experience during typing and scrolling interactions.
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Threshold for triggering pagination, ranging from 0.0 to 1.0.
  /// 0.0 = trigger immediately when scrolling starts
  /// 1.0 = trigger only when scrolled to the very end
  /// Default is 0.75 (trigger when 75% of content is scrolled through)
  final double? onEndReachedThreshold;

  /// Controller for managing scroll position and behavior.
  /// Also used by the Chat widget to programmatically scroll to specific messages.
  /// Must be provided for proper scrolling functionality.
  final ScrollController scrollController;

  /// Defines the scrolling physics behavior (bouncing, clamping, etc.).
  /// When null, uses the default platform scrolling physics.
  final ScrollPhysics? scrollPhysics;

  /// Configuration for the typing indicator display and behavior.
  /// Controls when and how to show typing indicators from other users.
  final TypingIndicatorOptions? typingIndicatorOptions;

  /// Whether to add padding for the device's safe area at the top.
  /// Should be true for full-screen chat views to avoid overlap with status bar.
  final bool useTopSafeAreaInset;

  @override
  State<ChatList> createState() => _ChatListState();
}

/// State class for ChatList - now delegates to OptimizedChatList for better performance.
class _ChatListState extends State<ChatList> {
  @override
  Widget build(BuildContext context) {
    // Delegate to OptimizedChatList while maintaining the same API
    return OptimizedChatList(
      bottomWidget: widget.bottomWidget,
      bubbleRtlAlignment: widget.bubbleRtlAlignment,
      isLastPage: widget.isLastPage,
      itemBuilder: widget.itemBuilder,
      items: widget.items,
      keyboardDismissBehavior: widget.keyboardDismissBehavior,
      onEndReached: widget.onEndReached,
      onEndReachedThreshold: widget.onEndReachedThreshold,
      scrollController: widget.scrollController,
      scrollPhysics: widget.scrollPhysics,
      typingIndicatorOptions: widget.typingIndicatorOptions,
      useTopSafeAreaInset: widget.useTopSafeAreaInset,
    );
  }
}
