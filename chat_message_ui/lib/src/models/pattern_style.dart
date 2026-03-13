import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Defines a markdown-style text pattern and its corresponding visual styling.
/// This class is used to implement real-time text formatting in the chat input field
/// and message display, allowing users to see styled text as they type markdown syntax.
///
/// Each PatternStyle instance represents one formatting rule, such as bold, italic,
/// code, or strikethrough text. The class contains both the regex pattern to detect
/// the markdown syntax and the TextStyle to apply when rendering the matched text.
///
/// Used by:
/// - InputTextFieldController for real-time input formatting
/// - ParsedText widget for message display formatting
/// - TextMessageText widget for rich text rendering
class PatternStyle {
  /// Creates a PatternStyle with the specified pattern detection and styling rules.
  ///
  /// [from] - The character or string that starts the pattern (used for identification)
  /// [regExp] - Regular expression that matches the complete markdown pattern
  /// [replace] - String to replace the matched pattern with (typically empty for styling)
  /// [textStyle] - Flutter TextStyle to apply to the matched text content
  PatternStyle(this.from, this.regExp, this.replace, this.textStyle);

  /// The starting character or pattern that identifies this formatting type.
  /// Used for quick pattern identification and matching optimization.
  /// Examples: '*' for bold, '_' for italic, '`' for code, '~' for strikethrough
  final Pattern from;

  /// Regular expression that matches the complete markdown pattern in text.
  /// Defines both the syntax boundaries and the content that should be styled.
  /// Examples: \*[^\*]+\* matches *bold text*, `[^`]+` matches `code text`
  final RegExp regExp;

  /// Replacement string for the matched pattern (typically empty for styling).
  /// Could be used to transform the text content, but usually just applies styling
  /// without changing the actual text content.
  final String replace;

  /// Flutter TextStyle that defines the visual appearance of the matched text.
  /// Contains properties like fontWeight, fontStyle, decoration, fontFamily, etc.
  /// Applied to the text content within the markdown boundaries.
  final TextStyle textStyle;

  /// Convenience getter that returns the regex pattern string.
  /// Used by text parsing systems that need the raw pattern for combining
  /// multiple patterns or building composite regular expressions.
  String get pattern => regExp.pattern;

  /// Predefined pattern for bold text formatting using asterisk syntax.
  ///
  /// Matches text wrapped in single asterisks: *bold text*
  /// Renders the content with FontWeight.bold styling.
  ///
  /// Regex explanation:
  /// - \\* matches the opening asterisk
  /// - [^\\*]+ matches one or more characters that are not asterisks
  /// - \\* matches the closing asterisk
  ///
  /// Usage: *this text will be bold*
  static PatternStyle get bold {
    return PatternStyle(
      '*',
      RegExp('\\*[^\\*]+\\*'),
      '',
      const TextStyle(fontWeight: FontWeight.bold),
    );
  }

  /// Predefined pattern for inline code formatting using backtick syntax.
  ///
  /// Matches text wrapped in single backticks: `code text`
  /// Renders the content with a monospace font family.
  ///
  /// Regex explanation:
  /// - ` matches the opening backtick
  /// - [^`]+ matches one or more characters that are not backticks
  /// - ` matches the closing backtick
  ///
  /// Font selection:
  /// - iOS: Uses 'Courier' system font
  /// - Other platforms: Uses generic 'monospace' font
  ///
  /// Usage: `this text will be monospace`
  static PatternStyle get code {
    return PatternStyle(
      '`',
      RegExp('`[^`]+`'),
      '',
      TextStyle(
        fontFamily:
            defaultTargetPlatform == TargetPlatform.iOS
                ? 'Courier'
                : 'monospace',
      ),
    );
  }

  /// Predefined pattern for italic text formatting using underscore syntax.
  ///
  /// Matches text wrapped in single underscores: _italic text_
  /// Renders the content with FontStyle.italic styling.
  ///
  /// Regex explanation:
  /// - _ matches the opening underscore
  /// - [^_]+ matches one or more characters that are not underscores
  /// - _ matches the closing underscore
  ///
  /// Usage: _this text will be italic_
  static PatternStyle get italic {
    return PatternStyle(
      '_',
      RegExp('_[^_]+_'),
      '',
      const TextStyle(fontStyle: FontStyle.italic),
    );
  }

  /// Predefined pattern for strikethrough text formatting using tilde syntax.
  ///
  /// Matches text wrapped in single tildes: ~strikethrough text~
  /// Renders the content with TextDecoration.lineThrough styling.
  ///
  /// Regex explanation:
  /// - ~ matches the opening tilde
  /// - [^~]+ matches one or more characters that are not tildes
  /// - ~ matches the closing tilde
  ///
  /// Usage: ~this text will be crossed out~
  static PatternStyle get lineThrough {
    return PatternStyle(
      '~',
      RegExp('~[^~]+~'),
      '',
      const TextStyle(decoration: TextDecoration.lineThrough),
    );
  }
}
