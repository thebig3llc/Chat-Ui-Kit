import 'package:flutter/widgets.dart';

import '../themes/chat_theme.dart';

/// Aspects of [ChatTheme] that widgets can independently depend on.
/// Widgets using [InheritedChatTheme.aspectOf] will only rebuild when
/// the specific aspect they care about changes.
enum ChatThemeAspect { colors, textStyles, dimensions, icons }

/// InheritedModel that provides ChatTheme configuration to all descendant
/// widgets. Widgets that only care about a specific theme aspect (e.g. colors)
/// can subscribe via [aspectOf] and avoid rebuilds caused by unrelated changes.
class InheritedChatTheme extends InheritedModel<ChatThemeAspect> {
  const InheritedChatTheme({
    super.key,
    required this.theme,
    required super.child,
  });

  /// Retrieves the nearest InheritedChatTheme from the widget tree.
  static InheritedChatTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedChatTheme>()!;

  /// Subscribe to a specific [aspect] of the theme.
  /// The calling widget only rebuilds when that aspect changes.
  static InheritedChatTheme aspectOf(
    BuildContext context,
    ChatThemeAspect aspect,
  ) =>
      InheritedModel.inheritFrom<InheritedChatTheme>(context, aspect: aspect)!;

  /// The chat theme configuration containing all styling properties.
  final ChatTheme theme;

  /// Rebuilds dependents only when the theme has actually changed structurally.
  /// Relies on [ChatTheme.==] which compares all fields.
  @override
  bool updateShouldNotify(InheritedChatTheme old) => theme != old.theme;

  @override
  bool updateShouldNotifyDependent(
    InheritedChatTheme old,
    Set<ChatThemeAspect> dependencies,
  ) {
    if (dependencies.contains(ChatThemeAspect.colors)) {
      if (theme.primaryColor != old.theme.primaryColor ||
          theme.secondaryColor != old.theme.secondaryColor ||
          theme.backgroundColor != old.theme.backgroundColor ||
          theme.errorColor != old.theme.errorColor) {
        return true;
      }
    }
    if (dependencies.contains(ChatThemeAspect.textStyles)) {
      if (theme.sentMessageBodyTextStyle != old.theme.sentMessageBodyTextStyle ||
          theme.receivedMessageBodyTextStyle !=
              old.theme.receivedMessageBodyTextStyle) {
        return true;
      }
    }
    if (dependencies.contains(ChatThemeAspect.dimensions)) {
      if (theme.messageBorderRadius != old.theme.messageBorderRadius ||
          theme.messageMaxWidth != old.theme.messageMaxWidth ||
          theme.messageInsetsHorizontal != old.theme.messageInsetsHorizontal ||
          theme.messageInsetsVertical != old.theme.messageInsetsVertical) {
        return true;
      }
    }
    if (dependencies.contains(ChatThemeAspect.icons)) {
      if (theme.sendButtonIcon != old.theme.sendButtonIcon ||
          theme.deliveredIcon != old.theme.deliveredIcon ||
          theme.seenIcon != old.theme.seenIcon ||
          theme.errorIcon != old.theme.errorIcon) {
        return true;
      }
    }
    return false;
  }
}
