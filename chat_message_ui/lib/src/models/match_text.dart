import 'package:chat_message_core/chat_message_core.dart' show ParsedType;
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

class MatchText extends Equatable {
  const MatchText({
    this.parsedType,
    this.pattern,
    this.style,
    this.onTap,
    this.renderText,
    this.renderWidget,
  });

  final ParsedType? parsedType;

  final String? pattern;

  final TextStyle? style;

  // Function fields are intentionally excluded from props because Dart
  // closures do not support value equality. Cache MatchText instances
  // (e.g., as static const or at class/state scope) to avoid rebuild churn.
  final Function(String)? onTap;

  /// A callback function that takes two parameter String & pattern
  ///
  /// @param str - is the word that is being matched
  /// @param pattern - pattern passed to the MatchText class
  ///
  /// eg: Your str is 'Mention [@allison:5455345]' where 5455345 is ID of this user
  /// and @allison the value to display on interface.
  /// Your pattern for ID & username extraction : `/\[(@[^:]+):([^\]]+)\]/`i
  /// Displayed text will be : Mention `@allison`
  final Map<String, String> Function({
    required String str,
    required String pattern,
  })? renderText;

  /// A callback function that takes the [text] the matches the [pattern] and returns
  /// the [Widget] to be displayed inside a [WidgetSpan]
  final Widget Function({required String text, required String pattern})?
  renderWidget;

  @override
  List<Object?> get props => [parsedType, pattern, style];
}
