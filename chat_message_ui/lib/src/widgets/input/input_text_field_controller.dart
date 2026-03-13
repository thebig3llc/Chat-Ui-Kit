import 'package:flutter/material.dart';

import '../../models/pattern_style.dart';

/// Enhanced text editing controller that provides real-time markdown highlighting in the input field.
/// Extends TextEditingController to add visual formatting for bold, italic, strikethrough, and code patterns
/// while the user types, giving immediate visual feedback for markdown syntax.
class InputTextFieldController extends TextEditingController {
  InputTextFieldController({List<PatternStyle>? patternList})
      : _listPatternStyle = patternList ??
            [
              PatternStyle.bold,
              PatternStyle.italic,
              PatternStyle.lineThrough,
              PatternStyle.code,
            ];

  /// List of markdown patterns to detect and style in the input field.
  /// Each pattern defines a regex and corresponding TextStyle for visual highlighting.
  final List<PatternStyle> _listPatternStyle;

  /// Combined regex compiled once at initialization — not on every keystroke.
  late final RegExp _combinedPattern = RegExp(
    _listPatternStyle.map((e) => e.regExp.pattern).join('|'),
  );

  /// Builds a styled TextSpan with markdown formatting applied to the input text.
  /// Called by the TextField to render text with visual highlighting for markdown patterns.
  /// Splits text into segments and applies appropriate styling to each pattern match.
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    // Collection to store all text spans (styled and unstyled)
    final children = <InlineSpan>[];

    // Split text using the pre-compiled combined regex
    text.splitMapJoin(
      _combinedPattern,
      // Handle matched markdown patterns with styling
      onMatch: (match) {
        final matchedText = match[0]!;
        PatternStyle? matchedStyle;
        for (final ps in _listPatternStyle) {
          if (ps.regExp.hasMatch(matchedText)) {
            matchedStyle = ps;
            break;
          }
        }
        if (matchedStyle != null) {
          children.add(
            TextSpan(
              text: matchedText.replaceAll(RegExp(matchedStyle.replace), ''),
              style: style?.merge(matchedStyle.textStyle) ?? matchedStyle.textStyle,
            ),
          );
        }
        return '';
      },
      // Handle non-matched text with default styling
      onNonMatch: (text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    // Return the complete styled text span with all children
    return TextSpan(style: style, children: children);
  }
}
