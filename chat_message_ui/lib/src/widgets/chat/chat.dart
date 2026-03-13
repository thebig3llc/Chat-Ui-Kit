import 'dart:math';

import 'package:chat_message_core/src/models/message.dart';
import 'package:chat_message_core/src/models/audio_message.dart';
import 'package:chat_message_core/src/models/image_message.dart';
import 'package:chat_message_core/src/models/partial_text.dart';
import 'package:chat_message_core/src/models/text_message.dart';
import 'package:chat_message_core/src/models/video_message.dart';
import 'package:chat_message_core/src/models/preview_data.dart';
import 'package:chat_message_core/src/models/chat_user.dart';
import 'package:flutter/foundation.dart' show compute, kIsWeb, listEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../../utils/chat_l10n.dart';
import '../../themes/chat_theme.dart';
import '../../utils/conditional.dart';
import '../../enums/bubble_rtl_alignment.dart';
import '../../models/date_header.dart';
import '../../enums/emoji_enlargement_behavior.dart';
import '../../models/message_spacer.dart';
import '../../models/preview_image.dart';
import '../../models/unread_header_data.dart';
import '../../utils/functions.dart';
import 'chat_list.dart';
import '../image_gallery.dart';
import '../input/input.dart';
import '../message/message.dart';
import '../message/text_message.dart';
import '../../inherited/inherited_chat_theme.dart';
import '../../inherited/inherited_l10n.dart';
import '../../inherited/inherited_user.dart';
import '../typing_indicator.dart';
import '../unread_header.dart';

/// Keep track of all the auto scroll indices by their respective message's id to allow animating to them.
final Map<String, int> _chatMessageAutoScrollIndexById = {};

/// Parameter bundle for [_calculateChatMessagesIsolate]. All fields must be
/// sendable across isolate boundaries — no closures or native objects.
class _CalculateChatMessagesParams {
  const _CalculateChatMessagesParams({
    required this.messages,
    required this.user,
    required this.dateHeaderThreshold,
    this.dateFormat,
    this.dateIsUtc = false,
    this.dateLocale,
    required this.groupMessagesThreshold,
    this.lastReadMessageId,
    required this.showUserNames,
    this.timeFormat,
    this.isWeb = false,
  });

  final List<MessageModel> messages;
  final ChatUser user;
  final int dateHeaderThreshold;
  final DateFormat? dateFormat;
  final bool dateIsUtc;
  final String? dateLocale;
  final int groupMessagesThreshold;
  final String? lastReadMessageId;
  final bool showUserNames;
  final DateFormat? timeFormat;
  final bool isWeb;
}

/// Top-level function required by [compute]. Must not be a closure.
List<Object> _calculateChatMessagesIsolate(_CalculateChatMessagesParams p) =>
    calculateChatMessages(
      p.messages,
      p.user,
      dateFormat: p.dateFormat,
      dateHeaderThreshold: p.dateHeaderThreshold,
      dateIsUtc: p.dateIsUtc,
      dateLocale: p.dateLocale,
      groupMessagesThreshold: p.groupMessagesThreshold,
      isWeb: p.isWeb,
      lastReadMessageId: p.lastReadMessageId,
      showUserNames: p.showUserNames,
      timeFormat: p.timeFormat,
    );

/// Entry widget, represents the complete chat. If you wrap it in [SafeArea] and
/// it should be full screen, set [SafeArea]'s `bottom` to `false`.
class Chat extends StatefulWidget {
  /// Creates a chat widget.
  const Chat({
    super.key,
    this.audioMessageBuilder,
    this.avatarBuilder,
    this.bubbleBuilder,
    this.bubbleRtlAlignment = BubbleRtlAlignment.right,
    this.customBottomWidget,
    this.customDateHeaderText,
    this.dateFormat,
    this.dateHeaderBuilder,
    this.dateHeaderThreshold = 900000,
    this.dateIsUtc = false,
    this.dateLocale,
    this.disableImageGallery,
    this.emojiEnlargementBehavior = EmojiEnlargementBehavior.multi,
    this.emptyState,
    this.groupMessagesThreshold = 60000,
    this.hideBackgroundOnEmojiMessages = true,
    this.imageGalleryOptions = const ImageGalleryOptions(
      maxScale: PhotoViewComputedScale.covered,
      minScale: PhotoViewComputedScale.contained,
    ),
    this.imageHeaders,
    this.imageMessageBuilder,
    this.imageProviderBuilder,
    this.inputOptions = const InputOptions(),
    this.isAttachmentUploading,
    this.isLastPage,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.l10n = const ChatL10nEn(),
    this.listBottomWidget,
    required this.messages,
    this.nameBuilder,
    this.onAttachmentPressed,
    this.onAvatarTap,
    this.onBackgroundTap,
    this.onEndReached,
    this.onEndReachedThreshold,
    this.onMessageDoubleTap,
    this.onMessageLongPress,
    this.onMessageStatusLongPress,
    this.onMessageStatusTap,
    this.onMessageTap,
    this.onMessageVisibilityChanged,
    this.onPreviewDataFetched,
    required this.onSendPressed,
    this.scrollController,
    this.scrollPhysics,
    this.scrollToUnreadOptions = const ScrollToUnreadOptions(),
    this.showUserAvatars = false,
    this.showUserNames = false,
    this.textMessageBuilder,
    this.textMessageOptions = const TextMessageOptions(),
    this.theme = const DefaultChatTheme(),
    this.timeFormat,
    this.typingIndicatorOptions = const TypingIndicatorOptions(),
    this.usePreviewData = true,
    required this.user,
    this.userAgent,
    this.useTopSafeAreaInset,
    this.videoMessageBuilder,
    this.slidableMessageBuilder,
    this.isLeftStatus = false,
    this.messageWidthRatio = 0.72,
    this.inputWidgetHeight = 24.0,
  });

  /// See [Message.audioMessageBuilder].
  final Widget Function(AudioMessageModel, {required int messageWidth})?
  audioMessageBuilder;

  /// See [Message.avatarBuilder].
  final Widget Function(ChatUser author)? avatarBuilder;

  /// See [Message.bubbleBuilder].
  final Widget Function(
    Widget child, {
    required MessageModel message,
    required bool nextMessageInGroup,
  })?
  bubbleBuilder;

  /// See [Message.bubbleRtlAlignment].
  final BubbleRtlAlignment? bubbleRtlAlignment;

  /// Allows you to replace the default Input widget e.g. if you want to create a channel view.
  /// If you're looking for the bottom widget added to the chat list, see [listBottomWidget] instead.
  final Widget? customBottomWidget;

  /// If [dateFormat], [dateLocale] and/or [timeFormat] is not enough to customize date headers in your case,
  /// use this to return an arbitrary string based on a [DateTime] of a particular message. Can be helpful to
  /// return "Today" if [DateTime] is today. IMPORTANT: this will replace all default date headers, so you must
  /// handle all cases yourself, like for example today, yesterday and before. Or you can just return the same date header for any message.
  final String Function(DateTime)? customDateHeaderText;

  /// Allows you to customize the date format. IMPORTANT: only for the date, do not return time here.
  /// See [timeFormat] to customize the time format. [dateLocale] will be ignored if you use this,
  /// so if you want a localized date make sure you initialize your [DateFormat] with a locale.
  /// See [customDateHeaderText] for more customization.
  final DateFormat? dateFormat;

  /// Custom date header builder gives ability to customize date header widget.
  final Widget Function(DateHeader)? dateHeaderBuilder;

  /// Time (in ms) between two messages when we will render a date header.
  /// Default value is 15 minutes, 900000 ms. When time between two messages
  /// is higher than this threshold, date header will be rendered. Also,
  /// not related to this value, date header will be rendered on every new day.
  final int dateHeaderThreshold;

  /// Use utc time to convert message milliseconds to date.
  final bool dateIsUtc;

  /// Locale will be passed to the `Intl` package. Make sure you initialized
  /// date formatting in your app before passing any locale here, otherwise
  /// an error will be thrown. Also see [customDateHeaderText], [dateFormat], [timeFormat].
  final String? dateLocale;

  /// Disable automatic image preview on tap.
  final bool? disableImageGallery;

  /// See [Message.emojiEnlargementBehavior].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// Allows you to change what the user sees when there are no messages.
  /// `emptyChatPlaceholder` and `emptyChatPlaceholderTextStyle` are ignored
  /// in this case.
  final Widget? emptyState;

  /// Time (in ms) between two messages when we will visually group them.
  /// Default value is 1 minute, 60000 ms. When time between two messages
  /// is lower than this threshold, they will be visually grouped.
  final int groupMessagesThreshold;

  /// See [Message.hideBackgroundOnEmojiMessages].
  final bool hideBackgroundOnEmojiMessages;

  /// See [ImageGallery.options].
  final ImageGalleryOptions imageGalleryOptions;

  /// Headers passed to all network images used in the chat.
  final Map<String, String>? imageHeaders;

  /// See [Message.imageMessageBuilder].
  final Widget Function(ImageMessageModel, {required int messageWidth})?
  imageMessageBuilder;

  /// This feature allows you to use a custom image provider.
  /// This is useful if you want to manage image loading yourself, or if you need to cache images.
  /// You can also use the `cached_network_image` feature, but when it comes to caching, you might want to decide on a per-message basis.
  /// Plus, by using this provider, you can choose whether or not to send specific headers based on the URL.
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })?
  imageProviderBuilder;

  /// See [Input.options].
  final InputOptions inputOptions;

  /// See [Input.isAttachmentUploading].
  final bool? isAttachmentUploading;

  /// See [ChatList.isLastPage].
  final bool? isLastPage;

  /// See [ChatList.keyboardDismissBehavior].
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;

  /// Localized copy. Extend [ChatL10n] class to create your own copy or use
  /// existing one, like the default [ChatL10nEn]. You can customize only
  /// certain properties, see more here [ChatL10nEn].
  final ChatL10n l10n;

  /// See [ChatList.bottomWidget]. For a custom chat input
  /// use [customBottomWidget] instead.
  final Widget? listBottomWidget;

  /// List of [types.Message] to render in the chat widget.
  final List<MessageModel> messages;

  /// See [Message.nameBuilder].
  final Widget Function(ChatUser)? nameBuilder;

  /// See [Input.onAttachmentPressed].
  final VoidCallback? onAttachmentPressed;

  /// See [Message.onAvatarTap].
  final void Function(ChatUser)? onAvatarTap;

  /// Called when user taps on background.
  final VoidCallback? onBackgroundTap;

  /// See [ChatList.onEndReached].
  final Future<void> Function()? onEndReached;

  /// See [ChatList.onEndReachedThreshold].
  final double? onEndReachedThreshold;

  /// See [Message.onMessageDoubleTap].
  final void Function(BuildContext context, MessageModel)? onMessageDoubleTap;

  /// See [Message.onMessageLongPress].
  final void Function(BuildContext context, MessageModel)? onMessageLongPress;

  /// See [Message.onMessageStatusLongPress].
  final void Function(BuildContext context, MessageModel)?
  onMessageStatusLongPress;

  /// See [Message.onMessageStatusTap].
  final void Function(BuildContext context, MessageModel)? onMessageStatusTap;

  /// See [Message.onMessageTap].
  final void Function(BuildContext context, MessageModel)? onMessageTap;

  /// See [Message.onMessageVisibilityChanged].
  final void Function(MessageModel, bool visible)? onMessageVisibilityChanged;

  /// See [Message.onPreviewDataFetched].
  final void Function(TextMessageModel, PreviewData)? onPreviewDataFetched;

  /// See [Input.onSendPressed].
  final void Function(PartialTextModel) onSendPressed;

  /// See [ChatList.scrollController].
  /// If provided, you cannot use the scroll to message functionality.
  final AutoScrollController? scrollController;

  /// See [ChatList.scrollPhysics].
  final ScrollPhysics? scrollPhysics;

  /// Controls if and how the chat should scroll to the newest unread message.
  final ScrollToUnreadOptions scrollToUnreadOptions;

  /// See [Message.showUserAvatars].
  final bool showUserAvatars;

  /// Show user names for received messages. Useful for a group chat. Will be
  /// shown only on text messages.
  final bool showUserNames;

  /// See [Message.textMessageBuilder].
  final Widget Function(
    TextMessageModel, {
    required int messageWidth,
    required bool showName,
  })?
  textMessageBuilder;

  /// See [Message.textMessageOptions].
  final TextMessageOptions textMessageOptions;

  /// Chat theme. Extend [ChatTheme] class to create your own theme or use
  /// existing one, like the [DefaultChatTheme]. You can customize only certain
  /// properties, see more here [DefaultChatTheme].
  final ChatTheme theme;

  /// Allows you to customize the time format. IMPORTANT: only for the time, do not return date here.
  /// See [dateFormat] to customize the date format. [dateLocale] will be ignored if you use this, so
  /// if you want a localized time make sure you initialize your [DateFormat] with a locale.
  /// See [customDateHeaderText] for more customization.
  final DateFormat? timeFormat;

  /// Used to show typing users with indicator. See [TypingIndicatorOptions].
  final TypingIndicatorOptions typingIndicatorOptions;

  /// See [Message.usePreviewData].
  final bool usePreviewData;

  /// See [InheritedUser.user].
  final ChatUser user;

  /// See [Message.userAgent].
  final String? userAgent;

  /// See [ChatList.useTopSafeAreaInset].
  final bool? useTopSafeAreaInset;

  /// See [Message.videoMessageBuilder].
  final Widget Function(VideoMessageModel, {required int messageWidth})?
  videoMessageBuilder;

  /// See [Message.slidableMessageBuilder].
  final Widget Function(MessageModel, Widget msgWidget)? slidableMessageBuilder;

  /// See [Message.isLeftStatus].
  /// If true, status will be shown on the left side of the message.
  /// If false, status will be shown on the right side of the message.
  /// Default value is false.
  final bool isLeftStatus;

  /// Width ratio for message bubble.
  final double messageWidthRatio;

  /// Value used to change the height of the input widget. Defaults to 24 unless
  /// specified otherwise.
  final double inputWidgetHeight;

  @override
  State<Chat> createState() => ChatState();
}

/// [Chat] widget state.
class ChatState extends State<Chat> {
  /// Used to get the correct auto scroll index from [chatMessageAutoScrollIndexById].
  static const String _unreadHeaderId = 'unread_header_id';

  List<Object> _chatMessages = [];
  List<PreviewImage> _gallery = [];
  PageController? _galleryPageController;
  bool _hadScrolledToUnreadOnOpen = false;
  bool _isImageViewVisible = false;

  late final AutoScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = widget.scrollController ?? AutoScrollController();

    didUpdateWidget(widget);
  }

  /// Scroll to the unread header.
  void scrollToUnreadHeader() {
    final unreadHeaderIndex = _chatMessageAutoScrollIndexById[_unreadHeaderId];
    if (unreadHeaderIndex != null) {
      _scrollController.scrollToIndex(
        unreadHeaderIndex,
        duration: widget.scrollToUnreadOptions.scrollDuration,
      );
    }
  }

  /// Scroll to the message with the specified [id].
  /// If the message is not in the current visible list (e.g. not yet loaded),
  /// this is a no-op.
  void scrollToMessage(
    String id, {
    Duration? scrollDuration,
    bool withHighlight = false,
    Duration? highlightDuration,
  }) async {
    final index = _chatMessageAutoScrollIndexById[id];
    if (index == null) return;
    await _scrollController.scrollToIndex(
      index,
      duration: scrollDuration ?? scrollAnimationDuration,
      preferPosition: AutoScrollPosition.middle,
    );
    if (withHighlight) {
      await _scrollController.highlight(
        index,
        highlightDuration: highlightDuration ?? const Duration(seconds: 3),
      );
    }
  }

  /// Highlight the message with the specified [id].
  /// If the message is not in the current visible list, returns immediately.
  Future highlightMessage(String id, {Duration? duration}) {
    final index = _chatMessageAutoScrollIndexById[id];
    if (index == null) return Future.value();
    return _scrollController.highlight(
      index,
      highlightDuration: duration ?? const Duration(seconds: 3),
    );
  }

  Widget _emptyStateBuilder() {
    return widget.emptyState ??
        Container(
          alignment: Alignment.center,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            widget.l10n.emptyChatPlaceholder,
            style: widget.theme.emptyChatPlaceholderTextStyle,
            textAlign: TextAlign.center,
          ),
        );
  }

  /// Only scroll to first unread if there are messages and it is the first open.
  void _maybeScrollToFirstUnread() {
    if (widget.scrollToUnreadOptions.scrollOnOpen &&
        _chatMessages.isNotEmpty &&
        !_hadScrolledToUnreadOnOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (mounted) {
          await Future.delayed(widget.scrollToUnreadOptions.scrollDelay);
          scrollToUnreadHeader();
        }
      });
      _hadScrolledToUnreadOnOpen = true;
    }
  }

  /// We need the index for auto scrolling because it will scroll until it reaches an index higher or equal that what
  ///  it is scrolling towards. Index will be null for removed messages. Can just set to -1 for auto scroll.
  Widget _messageBuilder(
    Object object,
    BoxConstraints constraints,
    int? index,
  ) {
    if (object is DateHeader) {
      return widget.dateHeaderBuilder?.call(object) ??
          Container(
            alignment: Alignment.center,
            margin: widget.theme.dateDividerMargin,
            child: Text(object.text, style: widget.theme.dateDividerTextStyle),
          );
    } else if (object is MessageSpacer) {
      return SizedBox(height: object.height);
    } else if (object is UnreadHeaderData) {
      return AutoScrollTag(
        controller: _scrollController,
        index: index ?? -1,
        key: const Key('unread_header'),
        child: UnreadHeader(marginTop: object.marginTop),
      );
    } else {
      final map = object as Map<String, Object>;
      final message = map['message']! as MessageModel;

      final Widget messageWidget;

      final maxWidth = widget.theme.messageMaxWidth;
      final messageWidth =
          widget.showUserAvatars && message.author.id != widget.user.id
              ? min(
                constraints.maxWidth * widget.messageWidthRatio,
                maxWidth,
              ).floor()
              : min(
                constraints.maxWidth * (widget.messageWidthRatio + 0.06),
                maxWidth,
              ).floor();
      final Widget msgWidget = Message(
        audioMessageBuilder: widget.audioMessageBuilder,
        avatarBuilder: widget.avatarBuilder,
        bubbleBuilder: widget.bubbleBuilder,
        bubbleRtlAlignment: widget.bubbleRtlAlignment,
        emojiEnlargementBehavior: widget.emojiEnlargementBehavior,
        hideBackgroundOnEmojiMessages: widget.hideBackgroundOnEmojiMessages,
        imageHeaders: widget.imageHeaders,
        imageMessageBuilder: widget.imageMessageBuilder,
        imageProviderBuilder: widget.imageProviderBuilder,
        message: message,
        messageWidth: messageWidth,
        nameBuilder: widget.nameBuilder,
        onAvatarTap: widget.onAvatarTap,
        onMessageDoubleTap: widget.onMessageDoubleTap,
        onMessageLongPress: widget.onMessageLongPress,
        onMessageStatusLongPress: widget.onMessageStatusLongPress,
        onMessageStatusTap: widget.onMessageStatusTap,
        onMessageTap: (context, tappedMessage) {
          if (tappedMessage is ImageMessageModel &&
              widget.disableImageGallery != true) {
            _onImagePressed(tappedMessage);
          }

          widget.onMessageTap?.call(context, tappedMessage);
        },
        onMessageVisibilityChanged: widget.onMessageVisibilityChanged,
        onPreviewDataFetched: _onPreviewDataFetched,
        roundBorder: map['nextMessageInGroup'] == true,
        showAvatar: map['nextMessageInGroup'] == false,
        showName: map['showName'] == true,
        showStatus: map['showStatus'] == true,
        isLeftStatus: widget.isLeftStatus,
        showUserAvatars: widget.showUserAvatars,
        textMessageBuilder: widget.textMessageBuilder,
        textMessageOptions: widget.textMessageOptions,
        usePreviewData: widget.usePreviewData,
        userAgent: widget.userAgent,
        videoMessageBuilder: widget.videoMessageBuilder,
      );
      messageWidget =
          widget.slidableMessageBuilder == null
              ? msgWidget
              : widget.slidableMessageBuilder!(message, msgWidget);

      return AutoScrollTag(
        controller: _scrollController,
        index: index ?? -1,
        key: Key('scroll-${message.id}'),
        highlightColor: widget.theme.highlightMessageColor,
        child: messageWidget,
      );
    }
  }

  void _onCloseGalleryPressed() {
    setState(() {
      _isImageViewVisible = false;
    });
    _galleryPageController?.dispose();
    _galleryPageController = null;
  }

  void _onImagePressed(ImageMessageModel message) {
    final initialPage = _gallery.indexWhere(
      (element) => element.id == message.id && element.uri == message.uri,
    );
    _galleryPageController = PageController(initialPage: initialPage);
    setState(() {
      _isImageViewVisible = true;
    });
  }

  void _onPreviewDataFetched(
    TextMessageModel message,
    PreviewData previewData,
  ) {
    widget.onPreviewDataFetched?.call(message, previewData);
  }

  /// Updates the [chatMessageAutoScrollIndexById] mapping with the latest messages.
  void _refreshAutoScrollMapping() {
    _chatMessageAutoScrollIndexById.clear();
    var i = 0;
    for (final object in _chatMessages) {
      if (object is UnreadHeaderData) {
        _chatMessageAutoScrollIndexById[_unreadHeaderId] = i;
      } else if (object is Map<String, Object>) {
        final message = object['message']! as MessageModel;
        _chatMessageAutoScrollIndexById[message.id] = i;
      }
      i++;
    }
  }

  /// Runs [calculateChatMessages] in a background isolate when there are
  /// 200+ messages and no un-sendable [Chat.customDateHeaderText] closure.
  /// Falls back to synchronous execution otherwise.
  Future<void> _recalculateChatMessages() async {
    final messages = widget.messages;
    final List<Object> result;

    if (messages.length >= 200 && widget.customDateHeaderText == null) {
      result = await compute(
        _calculateChatMessagesIsolate,
        _CalculateChatMessagesParams(
          messages: messages,
          user: widget.user,
          dateFormat: widget.dateFormat,
          dateHeaderThreshold: widget.dateHeaderThreshold,
          dateIsUtc: widget.dateIsUtc,
          dateLocale: widget.dateLocale,
          groupMessagesThreshold: widget.groupMessagesThreshold,
          isWeb: kIsWeb,
          lastReadMessageId: widget.scrollToUnreadOptions.lastReadMessageId,
          showUserNames: widget.showUserNames,
          timeFormat: widget.timeFormat,
        ),
      );
      if (!mounted) return;
      setState(() {
        _chatMessages = result[0] as List<Object>;
        _gallery = result[1] as List<PreviewImage>;
      });
    } else {
      result = calculateChatMessages(
        messages,
        widget.user,
        customDateHeaderText: widget.customDateHeaderText,
        dateFormat: widget.dateFormat,
        dateHeaderThreshold: widget.dateHeaderThreshold,
        dateIsUtc: widget.dateIsUtc,
        dateLocale: widget.dateLocale,
        groupMessagesThreshold: widget.groupMessagesThreshold,
        isWeb: kIsWeb,
        lastReadMessageId: widget.scrollToUnreadOptions.lastReadMessageId,
        showUserNames: widget.showUserNames,
        timeFormat: widget.timeFormat,
      );
      _chatMessages = result[0] as List<Object>;
      _gallery = result[1] as List<PreviewImage>;
    }

    _refreshAutoScrollMapping();
    _maybeScrollToFirstUnread();
  }

  @override
  void didUpdateWidget(covariant Chat oldWidget) {
    super.didUpdateWidget(oldWidget);

    final messagesChanged = !listEquals(widget.messages, oldWidget.messages);
    final configChanged =
        widget.dateHeaderThreshold != oldWidget.dateHeaderThreshold ||
        widget.groupMessagesThreshold != oldWidget.groupMessagesThreshold ||
        widget.showUserNames != oldWidget.showUserNames ||
        widget.dateLocale != oldWidget.dateLocale ||
        widget.dateIsUtc != oldWidget.dateIsUtc ||
        widget.scrollToUnreadOptions.lastReadMessageId !=
            oldWidget.scrollToUnreadOptions.lastReadMessageId;

    if (widget.messages.isNotEmpty && (messagesChanged || configChanged)) {
      _recalculateChatMessages();
    }
  }

  @override
  void dispose() {
    _galleryPageController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: InheritedUser(
        user: widget.user,
        child: InheritedChatTheme(
          theme: widget.theme,
          child: InheritedL10n(
            l10n: widget.l10n,
            child: Stack(
              children: [
                Container(
                  color: widget.theme.backgroundColor,
                  child: Column(
                    children: [
                      Flexible(
                        child:
                            widget.messages.isEmpty
                                ? SizedBox.expand(child: _emptyStateBuilder())
                                : GestureDetector(
                                  onTap: () {
                                    FocusManager.instance.primaryFocus
                                        ?.unfocus();
                                    widget.onBackgroundTap?.call();
                                  },
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return ChatList(
                                        bottomWidget: widget.listBottomWidget,
                                        bubbleRtlAlignment:
                                            widget.bubbleRtlAlignment!,
                                        isLastPage: widget.isLastPage,
                                        itemBuilder: (item, index) {
                                          return _messageBuilder(
                                            item,
                                            constraints,
                                            index,
                                          );
                                        },
                                        items: _chatMessages,
                                        keyboardDismissBehavior:
                                            widget.keyboardDismissBehavior,
                                        onEndReached: widget.onEndReached,
                                        onEndReachedThreshold:
                                            widget.onEndReachedThreshold,
                                        scrollController: _scrollController,
                                        scrollPhysics: widget.scrollPhysics,
                                        typingIndicatorOptions:
                                            widget.typingIndicatorOptions,
                                        useTopSafeAreaInset:
                                            widget.useTopSafeAreaInset ??
                                            isMobile,
                                      );
                                    },
                                  ),
                                ),
                      ),
                      widget.customBottomWidget ??
                          Input(
                            isAttachmentUploading: widget.isAttachmentUploading,
                            onAttachmentPressed: widget.onAttachmentPressed,
                            onSendPressed: widget.onSendPressed,
                            options: widget.inputOptions,
                            inputWidgetHeight: widget.inputWidgetHeight,
                          ),
                    ],
                  ),
                ),
                if (_isImageViewVisible)
                  ImageGallery(
                    imageHeaders: widget.imageHeaders,
                    imageProviderBuilder: widget.imageProviderBuilder,
                    images: _gallery,
                    pageController: _galleryPageController!,
                    onClosePressed: _onCloseGalleryPressed,
                    options: widget.imageGalleryOptions,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
