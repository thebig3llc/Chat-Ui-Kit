import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../widgets/typing_indicator.dart';
import '../widgets/unread_header.dart';

// For internal usage only. Use values from theme itself.

/// See [ChatTheme.userAvatarNameColors].
const colors = [
  Color(0xffff6767),
  Color(0xff66e0da),
  Color(0xfff5a2d9),
  Color(0xfff0c722),
  Color(0xff6a85e5),
  Color(0xfffd9a6f),
  Color(0xff92db6e),
  Color(0xff73b8e5),
  Color(0xfffd7590),
  Color(0xffc78ae5),
];

/// Base chat theme containing all required properties to make a theme.
/// Extend this class if you want to create a custom theme.
@immutable
abstract class ChatTheme {
  /// Creates a new chat theme based on provided colors and text styles.
  const ChatTheme({
    required this.attachmentButtonIcon,
    required this.attachmentButtonMargin,
    required this.backgroundColor,
    required this.dateDividerMargin,
    required this.dateDividerTextStyle,
    required this.deliveredIcon,
    required this.documentIcon,
    required this.emptyChatPlaceholderTextStyle,
    required this.errorColor,
    required this.errorIcon,
    required this.inputBackgroundColor,
    required this.inputSurfaceTintColor,
    required this.inputElevation,
    required this.inputBorderRadius,
    this.inputContainerDecoration,
    required this.inputMargin,
    required this.inputPadding,
    required this.inputTextColor,
    this.inputTextCursorColor,
    required this.inputTextDecoration,
    required this.inputTextStyle,
    required this.messageBorderRadius,
    required this.messageInsetsHorizontal,
    required this.messageInsetsVertical,
    required this.messageMaxWidth,
    required this.primaryColor,
    required this.receivedEmojiMessageTextStyle,
    this.receivedMessageBodyBoldTextStyle,
    this.receivedMessageBodyCodeTextStyle,
    this.receivedMessageBodyLinkTextStyle,
    required this.receivedMessageBodyTextStyle,
    required this.receivedMessageCaptionTextStyle,
    required this.receivedMessageDocumentIconColor,
    required this.receivedMessageLinkDescriptionTextStyle,
    required this.receivedMessageLinkTitleTextStyle,
    required this.secondaryColor,
    required this.seenIcon,
    required this.sendButtonIcon,
    required this.sendButtonMargin,
    required this.sendingIcon,
    required this.sentEmojiMessageTextStyle,
    this.sentMessageBodyBoldTextStyle,
    this.sentMessageBodyCodeTextStyle,
    this.sentMessageBodyLinkTextStyle,
    required this.sentMessageBodyTextStyle,
    required this.sentMessageCaptionTextStyle,
    required this.sentMessageDocumentIconColor,
    required this.sentMessageLinkDescriptionTextStyle,
    required this.sentMessageLinkTitleTextStyle,
    required this.statusIconPadding,
    required this.typingIndicatorTheme,
    required this.unreadHeaderTheme,
    required this.userAvatarImageBackgroundColor,
    required this.userAvatarNameColors,
    required this.userAvatarTextStyle,
    required this.userNameTextStyle,
    this.highlightMessageColor,
  });

  /// Icon for select attachment button.
  final Widget? attachmentButtonIcon;

  /// Margin of attachment button.
  final EdgeInsets? attachmentButtonMargin;

  /// Used as a background color of a chat widget.
  final Color backgroundColor;

  /// Margin around date dividers.
  final EdgeInsets dateDividerMargin;

  /// Text style of the date dividers.
  final TextStyle dateDividerTextStyle;

  /// Icon for message's `delivered` status. For the best look use size of 16.
  final Widget? deliveredIcon;

  /// Icon inside file message.
  final Widget? documentIcon;

  /// Text style of the empty chat placeholder.
  final TextStyle emptyChatPlaceholderTextStyle;

  /// Color to indicate something bad happened (usually - shades of red).
  final Color errorColor;

  /// Icon for message's `error` status. For the best look use size of 16.
  final Widget? errorIcon;

  /// Color of the bottom bar where text field is.
  final Color inputBackgroundColor;

  /// Surface Tint Color of the bottom bar where text field is.
  final Color inputSurfaceTintColor;

  final double inputElevation;

  /// Top border radius of the bottom bar where text field is.
  final BorderRadius inputBorderRadius;

  /// Decoration of the container wrapping the text field.
  final Decoration? inputContainerDecoration;

  /// Outer insets of the bottom bar where text field is.
  final EdgeInsets inputMargin;

  /// Inner insets of the bottom bar where text field is.
  final EdgeInsets inputPadding;

  /// Color of the text field's text and attachment/send buttons.
  final Color inputTextColor;

  /// Color of the text field's cursor.
  final Color? inputTextCursorColor;

  /// Decoration of the input text field.
  final InputDecoration inputTextDecoration;

  /// Text style of the message input. To change the color use [inputTextColor].
  final TextStyle inputTextStyle;

  /// Border radius of message container.
  final double messageBorderRadius;

  /// Horizontal message bubble insets.
  final double messageInsetsHorizontal;

  /// Vertical message bubble insets.
  final double messageInsetsVertical;

  /// Message bubble max width. set to [double.infinity] adaptive screen.
  final double messageMaxWidth;

  /// Primary color of the chat used as a background of sent messages
  /// and statuses.
  final Color primaryColor;

  /// Text style used for displaying emojis on text messages.
  final TextStyle receivedEmojiMessageTextStyle;

  /// Body text style used for displaying bold text on received text messages.
  /// Default to a bold version of [receivedMessageBodyTextStyle].
  final TextStyle? receivedMessageBodyBoldTextStyle;

  /// Body text style used for displaying code text on received text messages.
  /// Defaults to a mono version of [receivedMessageBodyTextStyle].
  final TextStyle? receivedMessageBodyCodeTextStyle;

  /// Text style used for displaying link text on received text messages.
  /// Defaults to [receivedMessageBodyTextStyle].
  final TextStyle? receivedMessageBodyLinkTextStyle;

  /// Body text style used for displaying text on different types
  /// of received messages.
  final TextStyle receivedMessageBodyTextStyle;

  /// Caption text style used for displaying secondary info (e.g. file size) on different types of received messages.
  final TextStyle receivedMessageCaptionTextStyle;

  /// Color of the document icon on received messages. Has no effect when
  /// [documentIcon] is used.
  final Color receivedMessageDocumentIconColor;

  /// Text style used for displaying link description on received messages.
  final TextStyle receivedMessageLinkDescriptionTextStyle;

  /// Text style used for displaying link title on received messages.
  final TextStyle receivedMessageLinkTitleTextStyle;

  /// Secondary color, used as a background of received messages.
  final Color secondaryColor;

  /// Icon for message's `seen` status. For the best look use size of 16.
  final Widget? seenIcon;

  /// Icon for send button.
  final Widget? sendButtonIcon;

  /// Margin of send button.
  final EdgeInsets? sendButtonMargin;

  /// Icon for message's `sending` status. For the best look use size of 10.
  final Widget? sendingIcon;

  /// Text style used for displaying emojis on text messages.
  final TextStyle sentEmojiMessageTextStyle;

  /// Body text style used for displaying bold text on sent text messages.
  /// Defaults to a bold version of [sentMessageBodyTextStyle].
  final TextStyle? sentMessageBodyBoldTextStyle;

  /// Body text style used for displaying code text on sent text messages.
  /// Defaults to a mono version of [sentMessageBodyTextStyle].
  final TextStyle? sentMessageBodyCodeTextStyle;

  /// Text style used for displaying link text on sent text messages.
  /// Defaults to [sentMessageBodyTextStyle].
  final TextStyle? sentMessageBodyLinkTextStyle;

  /// Body text style used for displaying text on different types
  /// of sent messages.
  final TextStyle sentMessageBodyTextStyle;

  /// Caption text style used for displaying secondary info (e.g. file size) on different types of sent messages.
  final TextStyle sentMessageCaptionTextStyle;

  /// Color of the document icon on sent messages. Has no effect when
  /// [documentIcon] is used.
  final Color sentMessageDocumentIconColor;

  /// Text style used for displaying link description on sent messages.
  final TextStyle sentMessageLinkDescriptionTextStyle;

  /// Text style used for displaying link title on sent messages.
  final TextStyle sentMessageLinkTitleTextStyle;

  /// Padding around status icons.
  final EdgeInsets statusIconPadding;

  /// Theme for typing indicator. See [TypingIndicator].
  final TypingIndicatorTheme typingIndicatorTheme;

  /// Theme for the unread header.
  final UnreadHeaderTheme unreadHeaderTheme;

  /// Color used as a background for user avatar if an image is provided.
  /// Visible if the image has some transparent parts.
  final Color userAvatarImageBackgroundColor;

  /// Colors used as backgrounds for user avatars with no image and so,
  /// corresponding user names.
  /// Calculated based on a user ID, so unique across the whole app.
  final List<Color> userAvatarNameColors;

  /// Text style used for displaying initials on user avatar if no
  /// image is provided.
  final TextStyle userAvatarTextStyle;

  /// User names text style. Color will be overwritten with [userAvatarNameColors].
  final TextStyle userNameTextStyle;

  /// Color used as background of message row on highligth.
  final Color? highlightMessageColor;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChatTheme) return false;
    return attachmentButtonIcon == other.attachmentButtonIcon &&
        attachmentButtonMargin == other.attachmentButtonMargin &&
        backgroundColor == other.backgroundColor &&
        dateDividerMargin == other.dateDividerMargin &&
        dateDividerTextStyle == other.dateDividerTextStyle &&
        deliveredIcon == other.deliveredIcon &&
        documentIcon == other.documentIcon &&
        emptyChatPlaceholderTextStyle == other.emptyChatPlaceholderTextStyle &&
        errorColor == other.errorColor &&
        errorIcon == other.errorIcon &&
        inputBackgroundColor == other.inputBackgroundColor &&
        inputSurfaceTintColor == other.inputSurfaceTintColor &&
        inputElevation == other.inputElevation &&
        inputBorderRadius == other.inputBorderRadius &&
        inputContainerDecoration == other.inputContainerDecoration &&
        inputMargin == other.inputMargin &&
        inputPadding == other.inputPadding &&
        inputTextColor == other.inputTextColor &&
        inputTextCursorColor == other.inputTextCursorColor &&
        inputTextDecoration == other.inputTextDecoration &&
        inputTextStyle == other.inputTextStyle &&
        messageBorderRadius == other.messageBorderRadius &&
        messageInsetsHorizontal == other.messageInsetsHorizontal &&
        messageInsetsVertical == other.messageInsetsVertical &&
        messageMaxWidth == other.messageMaxWidth &&
        primaryColor == other.primaryColor &&
        receivedEmojiMessageTextStyle == other.receivedEmojiMessageTextStyle &&
        receivedMessageBodyBoldTextStyle == other.receivedMessageBodyBoldTextStyle &&
        receivedMessageBodyCodeTextStyle == other.receivedMessageBodyCodeTextStyle &&
        receivedMessageBodyLinkTextStyle == other.receivedMessageBodyLinkTextStyle &&
        receivedMessageBodyTextStyle == other.receivedMessageBodyTextStyle &&
        receivedMessageCaptionTextStyle == other.receivedMessageCaptionTextStyle &&
        receivedMessageDocumentIconColor == other.receivedMessageDocumentIconColor &&
        receivedMessageLinkDescriptionTextStyle == other.receivedMessageLinkDescriptionTextStyle &&
        receivedMessageLinkTitleTextStyle == other.receivedMessageLinkTitleTextStyle &&
        secondaryColor == other.secondaryColor &&
        seenIcon == other.seenIcon &&
        sendButtonIcon == other.sendButtonIcon &&
        sendButtonMargin == other.sendButtonMargin &&
        sendingIcon == other.sendingIcon &&
        sentEmojiMessageTextStyle == other.sentEmojiMessageTextStyle &&
        sentMessageBodyBoldTextStyle == other.sentMessageBodyBoldTextStyle &&
        sentMessageBodyCodeTextStyle == other.sentMessageBodyCodeTextStyle &&
        sentMessageBodyLinkTextStyle == other.sentMessageBodyLinkTextStyle &&
        sentMessageBodyTextStyle == other.sentMessageBodyTextStyle &&
        sentMessageCaptionTextStyle == other.sentMessageCaptionTextStyle &&
        sentMessageDocumentIconColor == other.sentMessageDocumentIconColor &&
        sentMessageLinkDescriptionTextStyle == other.sentMessageLinkDescriptionTextStyle &&
        sentMessageLinkTitleTextStyle == other.sentMessageLinkTitleTextStyle &&
        statusIconPadding == other.statusIconPadding &&
        typingIndicatorTheme == other.typingIndicatorTheme &&
        unreadHeaderTheme == other.unreadHeaderTheme &&
        userAvatarImageBackgroundColor == other.userAvatarImageBackgroundColor &&
        listEquals(userAvatarNameColors, other.userAvatarNameColors) &&
        userAvatarTextStyle == other.userAvatarTextStyle &&
        userNameTextStyle == other.userNameTextStyle &&
        highlightMessageColor == other.highlightMessageColor;
  }

  @override
  int get hashCode => Object.hashAll([
    attachmentButtonIcon,
    attachmentButtonMargin,
    backgroundColor,
    dateDividerMargin,
    dateDividerTextStyle,
    deliveredIcon,
    documentIcon,
    emptyChatPlaceholderTextStyle,
    errorColor,
    errorIcon,
    inputBackgroundColor,
    inputSurfaceTintColor,
    inputElevation,
    inputBorderRadius,
    inputContainerDecoration,
    inputMargin,
    inputPadding,
    inputTextColor,
    inputTextCursorColor,
    inputTextDecoration,
    inputTextStyle,
    messageBorderRadius,
    messageInsetsHorizontal,
    messageInsetsVertical,
    messageMaxWidth,
    primaryColor,
    receivedEmojiMessageTextStyle,
    receivedMessageBodyBoldTextStyle,
    receivedMessageBodyCodeTextStyle,
    receivedMessageBodyLinkTextStyle,
    receivedMessageBodyTextStyle,
    receivedMessageCaptionTextStyle,
    receivedMessageDocumentIconColor,
    receivedMessageLinkDescriptionTextStyle,
    receivedMessageLinkTitleTextStyle,
    secondaryColor,
    seenIcon,
    sendButtonIcon,
    sendButtonMargin,
    sendingIcon,
    sentEmojiMessageTextStyle,
    sentMessageBodyBoldTextStyle,
    sentMessageBodyCodeTextStyle,
    sentMessageBodyLinkTextStyle,
    sentMessageBodyTextStyle,
    sentMessageCaptionTextStyle,
    sentMessageDocumentIconColor,
    sentMessageLinkDescriptionTextStyle,
    sentMessageLinkTitleTextStyle,
    statusIconPadding,
    typingIndicatorTheme,
    unreadHeaderTheme,
    userAvatarImageBackgroundColor,
    Object.hashAll(userAvatarNameColors),
    userAvatarTextStyle,
    userNameTextStyle,
    highlightMessageColor,
  ]);
}

/// Default chat theme which extends [ChatTheme].
/// Colors are basic on purpose to encourage changing to match application theme.
@immutable
class DefaultChatTheme extends ChatTheme {
  /// Creates a default chat theme. Use this constructor if you want to
  /// override only a couple of properties, otherwise create a new class
  /// which extends [ChatTheme].
  const DefaultChatTheme({
    super.attachmentButtonIcon,
    super.attachmentButtonMargin,
    super.backgroundColor = Colors.white24,
    super.dateDividerMargin = const EdgeInsets.only(bottom: 32, top: 16),
    super.dateDividerTextStyle = const TextStyle(
      color: Colors.grey,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    super.deliveredIcon,
    super.documentIcon,
    super.emptyChatPlaceholderTextStyle = const TextStyle(
      color: Color(0xff9e9cab),
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.errorColor = const Color(0xffff6767),
    super.errorIcon,
    super.inputBackgroundColor = Colors.white70,
    super.inputSurfaceTintColor = const Color(0xff1d1c21),
    super.inputElevation = 0,
    super.inputBorderRadius = const BorderRadius.vertical(
      top: Radius.circular(20),
    ),
    super.inputContainerDecoration,
    super.inputMargin = EdgeInsets.zero,
    super.inputPadding = const EdgeInsets.fromLTRB(24, 20, 24, 20),
    super.inputTextColor = Colors.black,
    super.inputTextCursorColor,
    super.inputTextDecoration = const InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero,
      isCollapsed: true,
    ),
    super.inputTextStyle = const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.messageBorderRadius = 20,
    super.messageInsetsHorizontal = 20,
    super.messageInsetsVertical = 16,
    super.messageMaxWidth = 440,
    super.primaryColor = Colors.blue,
    super.receivedEmojiMessageTextStyle = const TextStyle(fontSize: 40),
    super.receivedMessageBodyBoldTextStyle,
    super.receivedMessageBodyCodeTextStyle,
    super.receivedMessageBodyLinkTextStyle,
    super.receivedMessageBodyTextStyle = const TextStyle(
      color: Color(0xff1d1c21),
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.receivedMessageCaptionTextStyle = const TextStyle(
      color: Color(0xff9e9cab),
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.333,
    ),
    super.receivedMessageDocumentIconColor = Colors.blue,
    super.receivedMessageLinkDescriptionTextStyle = const TextStyle(
      color: Color(0xff1d1c21),
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.428,
    ),
    super.receivedMessageLinkTitleTextStyle = const TextStyle(
      color: Color(0xff1d1c21),
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.375,
    ),
    super.secondaryColor = Colors.white30,
    super.seenIcon,
    super.sendButtonIcon,
    super.sendButtonMargin,
    super.sendingIcon,
    super.sentEmojiMessageTextStyle = const TextStyle(fontSize: 40),
    super.sentMessageBodyBoldTextStyle,
    super.sentMessageBodyCodeTextStyle,
    super.sentMessageBodyLinkTextStyle,
    super.sentMessageBodyTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w500,
      height: 1.5,
    ),
    super.sentMessageCaptionTextStyle = const TextStyle(
      color: Colors.white70,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.333,
    ),
    super.sentMessageDocumentIconColor = Colors.white,
    super.sentMessageLinkDescriptionTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.428,
    ),
    super.sentMessageLinkTitleTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w800,
      height: 1.375,
    ),
    super.statusIconPadding = const EdgeInsets.symmetric(horizontal: 4),
    super.typingIndicatorTheme = const TypingIndicatorTheme(
      animatedCirclesColor: Colors.grey,
      animatedCircleSize: 5.0,
      bubbleBorder: BorderRadius.all(Radius.circular(27.0)),
      bubbleColor: Colors.white,
      countAvatarColor: Colors.blue,
      countTextColor: Colors.white,
      multipleUserTextStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.grey,
      ),
    ),
    super.unreadHeaderTheme = const UnreadHeaderTheme(
      color: Colors.white,
      textStyle: TextStyle(
        color: Colors.grey,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.333,
      ),
    ),
    super.userAvatarImageBackgroundColor = Colors.transparent,
    super.userAvatarNameColors = colors,
    super.userAvatarTextStyle = const TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    super.userNameTextStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w800,
      height: 1.333,
    ),
    super.highlightMessageColor,
  });
}
