import 'package:chat_message_ui_kit/src/models/match_text.dart';
import 'package:chat_message_ui_kit/src/models/text_message.dart';
import 'package:chat_message_ui_kit/src/models/preview_data.dart';
import 'package:chat_message_ui_kit/src/models/chat_user.dart';
import 'package:chat_message_ui_kit/src/utils/regex.dart';
import 'package:chat_message_ui_kit/src/widgets/linking/link_preview.dart';
import 'package:chat_message_ui_kit/src/widgets/parsed_text.dart';
import 'package:flutter/material.dart';

import '../../enums/emoji_enlargement_behavior.dart';
import '../../utils/matchers.dart';
import '../../models/pattern_style.dart';
import '../../utils/functions.dart';
import '../../inherited/inherited_chat_theme.dart';
import '../../inherited/inherited_user.dart';
import 'user_name.dart';

// Cached compiled regex for URL detection — avoids recompiling on every build call.
final _urlRegExp = RegExp(regexLink, caseSensitive: false);

/// Widget that renders text messages with support for markdown, link previews, and emoji enlargement.
/// This is the most common message type, handling plain text with advanced formatting capabilities
/// including clickable links, preview cards for URLs, and special handling for emoji-only messages.
class TextMessage extends StatelessWidget {
  /// Creates a text message widget with comprehensive formatting and interaction options.
  /// Supports link previews, custom styling, emoji enlargement, and user name display.
  const TextMessage({
    super.key,
    required this.emojiEnlargementBehavior,
    required this.hideBackgroundOnEmojiMessages,
    required this.message,
    this.nameBuilder,
    this.onPreviewDataFetched,
    this.options = const TextMessageOptions(),
    required this.showName,
    required this.usePreviewData,
    this.userAgent,
  });

  /// Controls how emoji-only messages are displayed (never, single, multi).
  /// When set to enlarge emojis, text messages containing only emojis are rendered larger.
  final EmojiEnlargementBehavior emojiEnlargementBehavior;

  /// Whether to hide the message bubble background for emoji-only messages.
  /// This creates a cleaner look for emoji reactions and expressions.
  final bool hideBackgroundOnEmojiMessages;

  /// The text message data containing the actual text content and metadata.
  /// Includes text, optional preview data, author info, and timestamps.
  final TextMessageModel message;

  /// Optional custom builder for rendering user names above messages.
  /// Allows dynamic user info fetching and custom name styling based on user data.
  /// If null, uses the default UserName widget.
  final Widget Function(ChatUser)? nameBuilder;

  /// Callback invoked when link preview data is successfully fetched from a URL.
  /// Used to update the message model with preview data for caching and display.
  final void Function(TextMessageModel, PreviewData)? onPreviewDataFetched;

  /// Configuration options controlling text behavior, link handling, and interactions.
  /// Includes settings for text selection, link callbacks, and preview tap behavior.
  final TextMessageOptions options;

  /// Whether to display the sender's name above the message text.
  /// Primarily useful in group chats to identify message authors.
  final bool showName;

  /// Whether to automatically fetch and display previews for URLs found in the text.
  /// When enabled, URLs are parsed and preview cards are shown below the message.
  final bool usePreviewData;

  /// User agent string sent with HTTP requests when fetching link preview data.
  /// Some websites require specific user agents for proper preview generation.
  final String? userAgent;

  /// Builds the link preview widget when URLs are detected in the message text.
  /// Creates a preview card with website metadata, title, description, and thumbnail.
  Widget _linkPreview(ChatUser user, double width, BuildContext context) {
    // Choose appropriate text styles based on whether this is a sent or received message
    final linkDescriptionTextStyle =
        user.id == message.author.id
            ? InheritedChatTheme.of(
              context,
            ).theme.sentMessageLinkDescriptionTextStyle
            : InheritedChatTheme.of(
              context,
            ).theme.receivedMessageLinkDescriptionTextStyle;
    final linkTitleTextStyle =
        user.id == message.author.id
            ? InheritedChatTheme.of(context).theme.sentMessageLinkTitleTextStyle
            : InheritedChatTheme.of(
              context,
            ).theme.receivedMessageLinkTitleTextStyle;

    // Build the complete link preview widget with text and preview card
    return LinkPreview(
      enableAnimation: true, // Smooth animations for preview loading
      metadataTextStyle: linkDescriptionTextStyle,
      metadataTitleStyle: linkTitleTextStyle,
      onLinkPressed: options.onLinkPressed,
      onPreviewDataFetched: _onDataPreview,
      openOnPreviewImageTap: options.openOnPreviewImageTap,
      openOnPreviewTitleTap: options.openOnPreviewTitleTap,
      padding: EdgeInsets.symmetric(
        horizontal:
            InheritedChatTheme.of(context).theme.messageInsetsHorizontal,
        vertical: InheritedChatTheme.of(context).theme.messageInsetsVertical,
      ),
      previewData: message.previewData, // Cached preview data if available
      text: message.text,
      textWidget: _textWidgetBuilder(user, context, false),
      userAgent: userAgent,
      width: width,
    );
  }

  /// Handles the completion of link preview data fetching.
  /// Only triggers the callback if preview data hasn't been cached yet,
  /// preventing duplicate API calls and unnecessary updates.
  void _onDataPreview(PreviewData previewData) {
    if (message.previewData == null) {
      onPreviewDataFetched?.call(message, previewData);
    }
  }

  /// Builds the text content widget with appropriate styling and optional user name.
  /// Handles different text styles for sent vs received messages and emoji enlargement.
  Widget _textWidgetBuilder(
    ChatUser user,
    BuildContext context,
    bool enlargeEmojis,
  ) {
    // Get theme and determine appropriate text styles based on message direction
    final theme = InheritedChatTheme.of(context).theme;
    final bodyLinkTextStyle =
        user.id == message.author.id
            ? InheritedChatTheme.of(context).theme.sentMessageBodyLinkTextStyle
            : InheritedChatTheme.of(
              context,
            ).theme.receivedMessageBodyLinkTextStyle;
    final bodyTextStyle =
        user.id == message.author.id
            ? theme.sentMessageBodyTextStyle
            : theme.receivedMessageBodyTextStyle;
    final boldTextStyle =
        user.id == message.author.id
            ? theme.sentMessageBodyBoldTextStyle
            : theme.receivedMessageBodyBoldTextStyle;
    final codeTextStyle =
        user.id == message.author.id
            ? theme.sentMessageBodyCodeTextStyle
            : theme.receivedMessageBodyCodeTextStyle;
    final emojiTextStyle =
        user.id == message.author.id
            ? theme.sentEmojiMessageTextStyle
            : theme.receivedEmojiMessageTextStyle;

    // Build the complete text widget with optional name and styled content
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show user name if requested (typically in group chats)
        if (showName)
          nameBuilder?.call(message.author) ?? UserName(author: message.author),
        // Use enlarged emoji styling for emoji-only messages
        if (enlargeEmojis)
          if (options.isTextSelectable)
            SelectableText(message.text, style: emojiTextStyle)
          else
            Text(message.text, style: emojiTextStyle)
        // Use rich text parsing for regular messages with markdown support
        else
          TextMessageText(
            bodyLinkTextStyle: bodyLinkTextStyle,
            bodyTextStyle: bodyTextStyle,
            boldTextStyle: boldTextStyle,
            codeTextStyle: codeTextStyle,
            options: options,
            text: message.text,
          ),
      ],
    );
  }

  /// Builds the complete text message widget with conditional link preview support.
  /// Determines whether to show link previews, emoji enlargement, and appropriate styling.
  @override
  Widget build(BuildContext context) {
    // Determine if emojis should be enlarged based on content and settings
    final enlargeEmojis =
        emojiEnlargementBehavior != EmojiEnlargementBehavior.never &&
        consistsOfEmojis(emojiEnlargementBehavior, message);
    final theme = InheritedChatTheme.of(context).theme;
    final user = InheritedUser.of(context).user;
    final width = MediaQuery.of(context).size.width;

    // Check if link preview should be shown (if enabled and URLs detected)
    if (usePreviewData && onPreviewDataFetched != null) {
      final matches = _urlRegExp.allMatches(message.text);

      // Show link preview widget if URLs are found in the text
      if (matches.isNotEmpty) {
        return _linkPreview(user, width, context);
      }
    }

    // Render regular text message without link preview
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: theme.messageInsetsHorizontal,
        vertical: theme.messageInsetsVertical,
      ),
      child: _textWidgetBuilder(user, context, enlargeEmojis),
    );
  }
}

/// Reusable widget for rendering rich text with markdown support and link detection.
/// This widget parses text for various patterns (links, bold, italic, code) and applies
/// appropriate styling. Used both in regular messages and link previews.
class TextMessageText extends StatelessWidget {
  /// Creates a rich text widget with markdown parsing and custom styling options.
  /// All style parameters are optional and fall back to default styling when null.
  const TextMessageText({
    super.key,
    this.bodyLinkTextStyle,
    required this.bodyTextStyle,
    this.boldTextStyle,
    this.codeTextStyle,
    this.maxLines,
    this.options = const TextMessageOptions(),
    this.overflow = TextOverflow.clip,
    required this.text,
  });

  /// Text style applied to detected URLs and email addresses.
  /// If null, uses bodyTextStyle with underline decoration.
  final TextStyle? bodyLinkTextStyle;

  /// Base text style for regular text content.
  /// Also serves as the foundation for other styles when they're not provided.
  final TextStyle bodyTextStyle;

  /// Text style for bold markdown (**text** or __text__).
  /// If null, uses bodyTextStyle with bold font weight.
  final TextStyle? boldTextStyle;

  /// Text style for inline code markdown (`code`).
  /// If null, uses bodyTextStyle with monospace font and background.
  final TextStyle? codeTextStyle;

  /// Maximum number of lines to display before truncating.
  /// If null, text can expand to any number of lines.
  final int? maxLines;

  /// Configuration options for text selection and link interactions.
  /// Controls whether text is selectable and how links are handled.
  final TextMessageOptions options;

  /// How to handle text overflow when maxLines is reached.
  /// Common values are clip, ellipsis, fade, or visible.
  final TextOverflow overflow;

  /// The raw text content to be parsed and displayed with markdown formatting.
  /// Can contain URLs, bold/italic markdown, and other supported patterns.
  final String text;

  /// Builds the parsed text widget with all formatting patterns applied.
  /// Uses ParsedText to detect and style various text patterns like links and markdown.
  @override
  Widget build(BuildContext context) {
    return ParsedText(
      // Define all the text parsing patterns in priority order
      parse: [
        ...options.matchers,
        mailToMatcher(
          style:
              bodyLinkTextStyle ??
              bodyTextStyle.copyWith(decoration: TextDecoration.underline),
        ),
        urlMatcher(
          onLinkPressed: options.onLinkPressed,
          style:
              bodyLinkTextStyle ??
              bodyTextStyle.copyWith(decoration: TextDecoration.underline),
        ),
        boldMatcher(
          style:
              boldTextStyle ?? bodyTextStyle.merge(PatternStyle.bold.textStyle),
        ),
        italicMatcher(
          style: bodyTextStyle.merge(PatternStyle.italic.textStyle),
        ),
        lineThroughMatcher(
          style: bodyTextStyle.merge(PatternStyle.lineThrough.textStyle),
        ),
        codeMatcher(
          style:
              codeTextStyle ?? bodyTextStyle.merge(PatternStyle.code.textStyle),
        ),
      ],
      maxLines: maxLines,
      overflow: overflow,
      regexOptions: const RegexOptions(multiLine: true, dotAll: true),
      selectable: options.isTextSelectable,
      style: bodyTextStyle,
      text: text,
      textWidthBasis: TextWidthBasis.longestLine,
    );
  }
}

/// Configuration options for text message behavior and appearance.
/// Controls text selection, link handling, preview interactions, and custom text parsing.
@immutable
class TextMessageOptions {
  /// Creates text message options with default values optimized for typical chat usage.
  /// Text selection is enabled by default, while preview interactions are disabled for safety.
  const TextMessageOptions({
    this.isTextSelectable = true,
    this.onLinkPressed,
    this.openOnPreviewImageTap = false,
    this.openOnPreviewTitleTap = false,
    this.matchers = const [],
  });

  /// Whether users can select text by tapping and holding.
  /// When true, enables text selection with copy/paste functionality.
  final bool isTextSelectable;

  /// Callback invoked when a user taps on a detected link in the message.
  /// Receives the URL as a parameter for custom link handling (e.g., in-app browser).
  final void Function(String)? onLinkPressed;

  /// Whether tapping on link preview images should open them.
  /// When false, preview images are display-only for security reasons.
  final bool openOnPreviewImageTap;

  /// Whether tapping on link preview titles should navigate to the URL.
  /// When false, only the original link in text is interactive.
  final bool openOnPreviewTitleTap;

  /// Additional custom text patterns to detect and style in messages.
  /// Allows extending the built-in link, bold, italic, and code detection.
  final List<MatchText> matchers;
}
