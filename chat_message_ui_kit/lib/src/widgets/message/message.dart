import 'package:chat_message_ui_kit/src/models/message.dart';
import 'package:chat_message_ui_kit/src/models/audio_message.dart';
import 'package:chat_message_ui_kit/src/models/image_message.dart';
import 'package:chat_message_ui_kit/src/models/text_message.dart';
import 'package:chat_message_ui_kit/src/models/video_message.dart';
import 'package:chat_message_ui_kit/src/models/preview_data.dart';
import 'package:chat_message_ui_kit/src/models/chat_user.dart';
import 'package:chat_message_ui_kit/src/enums/message_type.dart';
import 'package:chat_message_ui_kit/src/widgets/message/image_message.dart';
import 'package:chat_message_ui_kit/src/widgets/message/text_message.dart';
import 'package:flutter/material.dart';

import 'package:visibility_detector/visibility_detector.dart';

import '../../utils/conditional.dart';
import '../../enums/bubble_rtl_alignment.dart';
import '../../enums/emoji_enlargement_behavior.dart';
import '../../utils/functions.dart';
import '../../inherited/inherited_chat_theme.dart';
import '../../inherited/inherited_user.dart';
import 'message_status.dart';
import 'user_avatar.dart';

/// Base widget for all message types in the chat. Renders bubbles around
/// messages and status. Sets maximum width for a message for
/// a nice look on larger screens.
class Message extends StatelessWidget {
  /// Creates a particular message from any message type.
  const Message({
    super.key,
    this.audioMessageBuilder,
    this.avatarBuilder,
    this.bubbleBuilder,
    this.bubbleRtlAlignment,
    required this.emojiEnlargementBehavior,
    required this.hideBackgroundOnEmojiMessages,
    this.imageHeaders,
    this.imageMessageBuilder,
    this.imageProviderBuilder,
    required this.message,
    required this.messageWidth,
    this.nameBuilder,
    this.onAvatarTap,
    this.onMessageDoubleTap,
    this.onMessageLongPress,
    this.onMessageStatusLongPress,
    this.onMessageStatusTap,
    this.onMessageTap,
    this.onMessageVisibilityChanged,
    this.onPreviewDataFetched,
    required this.roundBorder,
    required this.showAvatar,
    required this.showName,
    required this.showStatus,
    required this.isLeftStatus,
    required this.showUserAvatars,
    this.textMessageBuilder,
    required this.textMessageOptions,
    required this.usePreviewData,
    this.userAgent,
    this.videoMessageBuilder,
  });

  /// Build an audio message inside predefined bubble.
  final Widget Function(AudioMessageModel, {required int messageWidth})?
  audioMessageBuilder;

  /// This is to allow custom user avatar builder
  /// By using this we can fetch newest user info based on id.
  final Widget Function(ChatUser author)? avatarBuilder;

  /// Customize the default bubble using this function. `child` is a content
  /// you should render inside your bubble, `message` is a current message
  /// (contains `author` inside) and `nextMessageInGroup` allows you to see
  /// if the message is a part of a group (messages are grouped when written
  /// in quick succession by the same author).
  final Widget Function(
    Widget child, {
    required MessageModel message,
    required bool nextMessageInGroup,
  })?
  bubbleBuilder;

  /// Determine the alignment of the bubble for RTL languages. Has no effect
  /// for the LTR languages.
  final BubbleRtlAlignment? bubbleRtlAlignment;

  /// Controls the enlargement behavior of the emojis in the
  /// [types.TextMessage].
  /// Defaults to [EmojiEnlargementBehavior.multi].
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// Hide background for messages containing only emojis.
  final bool hideBackgroundOnEmojiMessages;

  /// See [Chat.imageHeaders].
  final Map<String, String>? imageHeaders;

  /// Build an image message inside predefined bubble.
  final Widget Function(ImageMessageModel, {required int messageWidth})?
  imageMessageBuilder;

  /// See [Chat.imageProviderBuilder].
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })?
  imageProviderBuilder;

  /// Any message type.
  final MessageModel message;

  /// Maximum message width.
  final int messageWidth;

  /// See [TextMessage.nameBuilder].
  final Widget Function(ChatUser)? nameBuilder;

  /// See [UserAvatar.onAvatarTap].
  final void Function(ChatUser)? onAvatarTap;

  /// Called when user double taps on any message.
  final void Function(BuildContext context, MessageModel)? onMessageDoubleTap;

  /// Called when user makes a long press on any message.
  final void Function(BuildContext context, MessageModel)? onMessageLongPress;

  /// Called when user makes a long press on status icon in any message.
  final void Function(BuildContext context, MessageModel)?
  onMessageStatusLongPress;

  /// Called when user taps on status icon in any message.
  final void Function(BuildContext context, MessageModel)? onMessageStatusTap;

  /// Called when user taps on any message.
  final void Function(BuildContext context, MessageModel)? onMessageTap;

  /// Called when the message's visibility changes.
  final void Function(MessageModel, bool visible)? onMessageVisibilityChanged;

  /// See [TextMessage.onPreviewDataFetched].
  final void Function(TextMessageModel, PreviewData)? onPreviewDataFetched;

  /// Rounds border of the message to visually group messages together.
  final bool roundBorder;

  /// Show user avatar for the received message. Useful for a group chat.
  final bool showAvatar;

  /// See [TextMessage.showName].
  final bool showName;

  /// Show message's status.
  final bool showStatus;

  /// This is used to determine if the status icon should be on the left or
  /// right side of the message.
  /// This is only used when [showStatus] is true.
  /// Defaults to false.
  final bool isLeftStatus;

  /// Show user avatars for received messages. Useful for a group chat.
  final bool showUserAvatars;

  /// Build a text message inside predefined bubble.
  final Widget Function(
    TextMessageModel, {
    required int messageWidth,
    required bool showName,
  })?
  textMessageBuilder;

  /// See [TextMessage.options].
  final TextMessageOptions textMessageOptions;

  /// See [TextMessage.usePreviewData].
  final bool usePreviewData;

  /// See [TextMessage.userAgent].
  final String? userAgent;

  /// Build an audio message inside predefined bubble.
  final Widget Function(VideoMessageModel, {required int messageWidth})?
  videoMessageBuilder;

  Widget _avatarBuilder() {
    return showAvatar
        ? avatarBuilder?.call(message.author) ??
            UserAvatar(
              author: message.author,
              bubbleRtlAlignment: bubbleRtlAlignment,
              imageHeaders: imageHeaders,
              onAvatarTap: onAvatarTap,
            )
        : const SizedBox(width: 40);
  }

  Widget _repliedMessageWidget(
    BuildContext context,
    MessageModel replied,
    bool currentUserIsAuthor,
  ) {
    final theme = InheritedChatTheme.of(context).theme;

    String previewText;
    if (replied is TextMessageModel) {
      previewText = replied.text;
    } else if (replied is ImageMessageModel) {
      previewText = '📷 Photo';
    } else if (replied is AudioMessageModel) {
      previewText = '🎵 Audio message';
    } else {
      previewText = '🎥 Video message';
    }

    final accentColor =
        currentUserIsAuthor
            ? Colors.white.withValues(alpha: 0.6)
            : theme.primaryColor;

    return Container(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accentColor, width: 3)),
        color:
            currentUserIsAuthor
                ? Colors.black.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.05),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            getUserName(replied.author),
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            previewText,
            style: (currentUserIsAuthor
                    ? theme.sentMessageBodyTextStyle
                    : theme.receivedMessageBodyTextStyle)
                .copyWith(fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _bubbleBuilder(
    BuildContext context,
    BorderRadius borderRadius,
    bool currentUserIsAuthor,
    bool enlargeEmojis,
  ) {
    final bubbleContent =
        message.repliedMessage != null
            ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _repliedMessageWidget(
                  context,
                  message.repliedMessage!,
                  currentUserIsAuthor,
                ),
                _messageBuilder(context),
              ],
            )
            : _messageBuilder(context);

    final defaultMessage =
        (enlargeEmojis && hideBackgroundOnEmojiMessages)
            ? bubbleContent
            : Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                color:
                    !currentUserIsAuthor || message.type == MessageType.image
                        ? InheritedChatTheme.of(context).theme.secondaryColor
                        : InheritedChatTheme.of(context).theme.primaryColor,
              ),
              child: ClipRRect(
                borderRadius: borderRadius,
                child: bubbleContent,
              ),
            );
    return bubbleBuilder != null
        ? bubbleBuilder!(
          _messageBuilder(context),
          message: message,
          nextMessageInGroup: roundBorder,
        )
        : defaultMessage;
  }

  Widget _messageBuilder(BuildContext context) {
    switch (message.type) {
      case MessageType.audio:
        final audioMessage = message as AudioMessageModel;
        return audioMessageBuilder != null
            ? audioMessageBuilder!(audioMessage, messageWidth: messageWidth)
            : _unsupportedMessagePlaceholder(
              context,
              Icons.audiotrack_rounded,
              'Audio message',
            );
      case MessageType.image:
        final imageMessage = message as ImageMessageModel;
        return imageMessageBuilder != null
            ? imageMessageBuilder!(imageMessage, messageWidth: messageWidth)
            : ImageMessage(
              imageHeaders: imageHeaders,
              imageProviderBuilder: imageProviderBuilder,
              message: imageMessage,
              messageWidth: messageWidth,
            );
      case MessageType.text:
        final textMessage = message as TextMessageModel;
        return textMessageBuilder != null
            ? textMessageBuilder!(
              textMessage,
              messageWidth: messageWidth,
              showName: showName,
            )
            : TextMessage(
              emojiEnlargementBehavior: emojiEnlargementBehavior,
              hideBackgroundOnEmojiMessages: hideBackgroundOnEmojiMessages,
              message: textMessage,
              nameBuilder: nameBuilder,
              onPreviewDataFetched: onPreviewDataFetched,
              options: textMessageOptions,
              showName: showName,
              usePreviewData: usePreviewData,
              userAgent: userAgent,
            );
      case MessageType.video:
        final videoMessage = message as VideoMessageModel;
        return videoMessageBuilder != null
            ? videoMessageBuilder!(videoMessage, messageWidth: messageWidth)
            : _unsupportedMessagePlaceholder(
              context,
              Icons.videocam_rounded,
              'Video message',
            );
    }
  }

  /// Minimal labeled placeholder shown when no custom builder is provided for
  /// audio or video messages. Avoids invisible const SizedBox() (L-1).
  Widget _unsupportedMessagePlaceholder(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    final theme = InheritedChatTheme.of(context).theme;
    final user = InheritedUser.of(context).user;
    final isSent = user.id == message.author.id;
    final textStyle =
        isSent
            ? theme.sentMessageBodyTextStyle
            : theme.receivedMessageBodyTextStyle;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.messageInsetsHorizontal,
        vertical: theme.messageInsetsVertical,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: textStyle.color),
          const SizedBox(width: 8),
          Text(label, style: textStyle),
        ],
      ),
    );
  }

  Widget _statusIcon(BuildContext context) {
    if (!showStatus) return const SizedBox.shrink();

    return Padding(
      padding: InheritedChatTheme.of(context).theme.statusIconPadding,
      child: GestureDetector(
        onLongPress: () => onMessageStatusLongPress?.call(context, message),
        onTap: () => onMessageStatusTap?.call(context, message),
        child: MessageStatus(status: message.status),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = MediaQuery.of(context);
    final user = InheritedUser.of(context).user;
    final currentUserIsAuthor = user.id == message.author.id;
    final enlargeEmojis =
        emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
        message is TextMessage &&
        consistsOfEmojis(emojiEnlargementBehavior, message as TextMessageModel);
    final messageBorderRadius =
        InheritedChatTheme.of(context).theme.messageBorderRadius;
    final borderRadius =
        bubbleRtlAlignment == BubbleRtlAlignment.left
            ? BorderRadiusDirectional.only(
              bottomEnd: Radius.circular(
                !currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
              ),
              bottomStart: Radius.circular(
                currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
              ),
              topEnd: Radius.circular(messageBorderRadius),
              topStart: Radius.circular(messageBorderRadius),
            )
            : BorderRadius.only(
              bottomLeft: Radius.circular(
                currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
              ),
              bottomRight: Radius.circular(
                !currentUserIsAuthor || roundBorder ? messageBorderRadius : 0,
              ),
              topLeft: Radius.circular(messageBorderRadius),
              topRight: Radius.circular(messageBorderRadius),
            );

    return Container(
      alignment:
          bubbleRtlAlignment == BubbleRtlAlignment.left
              ? currentUserIsAuthor
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart
              : currentUserIsAuthor
              ? Alignment.centerRight
              : Alignment.centerLeft,
      margin:
          bubbleRtlAlignment == BubbleRtlAlignment.left
              ? EdgeInsetsDirectional.only(
                bottom: 4,
                end: isMobile ? query.padding.right : 0,
                start: 20 + (isMobile ? query.padding.left : 0),
              )
              : EdgeInsets.only(
                bottom: 4,
                left: 20 + (isMobile ? query.padding.left : 0),
                right: isMobile ? query.padding.right : 0,
              ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        textDirection:
            bubbleRtlAlignment == BubbleRtlAlignment.left
                ? null
                : TextDirection.ltr,
        children: [
          if (!currentUserIsAuthor && showUserAvatars) _avatarBuilder(),
          if (currentUserIsAuthor && isLeftStatus) _statusIcon(context),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: messageWidth.toDouble()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                GestureDetector(
                  onDoubleTap: () => onMessageDoubleTap?.call(context, message),
                  onLongPress: () => onMessageLongPress?.call(context, message),
                  onTap: () => onMessageTap?.call(context, message),
                  child:
                      onMessageVisibilityChanged != null
                          ? VisibilityDetector(
                            key: Key(message.id),
                            onVisibilityChanged:
                                (visibilityInfo) => onMessageVisibilityChanged!(
                                  message,
                                  visibilityInfo.visibleFraction > 0.1,
                                ),
                            child: _bubbleBuilder(
                              context,
                              borderRadius.resolve(Directionality.of(context)),
                              currentUserIsAuthor,
                              enlargeEmojis,
                            ),
                          )
                          : _bubbleBuilder(
                            context,
                            borderRadius.resolve(Directionality.of(context)),
                            currentUserIsAuthor,
                            enlargeEmojis,
                          ),
                ),
              ],
            ),
          ),
          if (currentUserIsAuthor && !isLeftStatus) _statusIcon(context),
        ],
      ),
    );
  }
}
