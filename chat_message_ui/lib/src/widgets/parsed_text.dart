import 'package:chat_message_ui_kit/src/models/match_text.dart';
import 'package:chat_message_core/src/enums/parsed_type.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Parse text and make them into multiple Flutter Text widgets
class ParsedText extends StatelessWidget {
  /// Creates a parsedText widget
  ///
  /// [text] paramtere should not be null and is always required.
  /// If the [style] argument is null, the text will use the style from the
  /// closest enclosing [DefaultTextStyle].
  const ParsedText({
    super.key,
    required this.text,
    this.parse = const <MatchText>[],
    this.style,
    this.alignment = TextAlign.start,
    this.textDirection,
    this.softWrap = true,
    this.overflow = TextOverflow.clip,
    this.textScaleFactor = 1.0,
    this.strutStyle,
    this.textWidthBasis = TextWidthBasis.parent,
    this.maxLines,
    this.onTap,
    this.selectable = false,
    this.regexOptions = const RegexOptions(),
  });

  /// If non-null, the style to use for the global text.
  ///
  /// It takes a [TextStyle] object as it's property to style all the non links text objects.
  final TextStyle? style;

  /// Takes a list of [MatchText] object.
  ///
  /// This list is used to find patterns in the String and assign onTap [Function] when its
  /// tapped and also to provide custom styling to the linkify text
  final List<MatchText> parse;

  /// Text that is rendered
  ///
  /// Takes a [String]
  final String text;

  /// A text alignment property used to align the the text enclosed
  ///
  /// Uses a [TextAlign] object and default value is [TextAlign.start]
  final TextAlign alignment;

  /// A text alignment property used to align the the text enclosed
  ///
  /// Uses a [TextDirection] object and default value is [TextDirection.start]
  final TextDirection? textDirection;

  /// Whether the text should break at soft line breaks.
  ///
  ///If false, the glyphs in the text will be positioned as if there was unlimited horizontal space.
  final bool softWrap;

  /// How visual overflow should be handled.
  final TextOverflow overflow;

  /// The number of font pixels for each logical pixel.
  ///
  /// For example, if the text scale factor is 1.5, text will be 50% larger than
  /// the specified font size.
  final double textScaleFactor;

  /// An optional maximum number of lines for the text to span, wrapping if necessary.
  /// If the text exceeds the given number of lines, it will be truncated according
  /// to [overflow].
  ///
  /// If this is 1, text will not wrap. Otherwise, text will be wrapped at the
  /// edge of the box.
  final int? maxLines;

  /// {@macro flutter.painting.textPainter.strutStyle}
  final StrutStyle? strutStyle;

  /// {@macro flutter.widgets.text.DefaultTextStyle.textWidthBasis}
  final TextWidthBasis textWidthBasis;

  /// Make this text selectable.
  ///
  /// SelectableText does not support softwrap, overflow, textScaleFactor
  final bool selectable;

  /// onTap function for the whole widget
  final Function? onTap;

  /// Global regex options for the whole string,
  ///
  /// Note: Removed support for regexOptions for MatchText and now it uses global regex options.
  final RegexOptions regexOptions;

  @override
  Widget build(BuildContext context) {
    // Seperate each word and create a new Array
    String newString = text;

    Map<String, MatchText> textMapping = <String, MatchText>{};

    for (var e in parse) {
      if (e.parsedType == ParsedType.email) {
        textMapping[emailPattern] = e;
      } else if (e.parsedType == ParsedType.phone) {
        textMapping[phonePattern] = e;
      } else if (e.parsedType == ParsedType.url) {
        textMapping[urlPattern] = e;
      } else {
        textMapping[e.pattern!] = e;
      }
    }

    final pattern = '(${textMapping.keys.toList().join('|')})';

    List<InlineSpan> widgets = [];

    newString.splitMapJoin(
      RegExp(
        pattern,
        multiLine: regexOptions.multiLine,
        caseSensitive: regexOptions.caseSensitive,
        dotAll: regexOptions.dotAll,
        unicode: regexOptions.unicode,
      ),
      onMatch: (Match match) {
        final matchText = match[0];

        final mapping =
            textMapping[matchText!] ??
            textMapping[textMapping.keys.firstWhere(
              (element) {
                final reg = RegExp(
                  element,
                  multiLine: regexOptions.multiLine,
                  caseSensitive: regexOptions.caseSensitive,
                  dotAll: regexOptions.dotAll,
                  unicode: regexOptions.unicode,
                );
                return reg.hasMatch(matchText);
              },
              orElse: () {
                return '';
              },
            )];

        InlineSpan widget;

        if (mapping != null) {
          if (mapping.renderText != null) {
            Map<String, String> result = mapping.renderText!(
              str: matchText,
              pattern: pattern,
            );

            widget = TextSpan(
              text: "${result['display']}",
              style: mapping.style ?? style,
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      final value = result['value'] ?? matchText;
                      mapping.onTap?.call(value);
                    },
            );
          } else if (mapping.renderWidget != null) {
            widget = WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: () => mapping.onTap!(matchText),
                child: mapping.renderWidget!(
                  text: matchText,
                  pattern: mapping.pattern!,
                ),
              ),
            );
          } else {
            widget = TextSpan(
              text: matchText,
              style: mapping.style ?? style,
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () => mapping.onTap!(matchText),
            );
          }
        } else {
          widget = TextSpan(text: matchText, style: style);
        }

        widgets.add(widget);

        return '';
      },
      onNonMatch: (String text) {
        widgets.add(TextSpan(text: text, style: style));

        return '';
      },
    );

    if (selectable) {
      return SelectableText.rich(
        TextSpan(children: <InlineSpan>[...widgets], style: style),
        maxLines: maxLines,
        strutStyle: strutStyle,
        textWidthBasis: textWidthBasis,
        textAlign: alignment,
        textDirection: textDirection,
        onTap: onTap as void Function()?,
      );
    }

    return RichText(
      softWrap: softWrap,
      overflow: overflow,
      maxLines: maxLines,
      strutStyle: strutStyle,
      textWidthBasis: textWidthBasis,
      textAlign: alignment,
      textScaler: TextScaler.linear(textScaleFactor),
      textDirection: textDirection,
      text: TextSpan(
        text: '',
        children: <InlineSpan>[...widgets],
        style: style,
      ),
    );
  }
}

/// RegexOptions
class RegexOptions {
  /// Creates a RegexOptions object
  /// If `multiLine` is enabled, then `^` and `$` will match the beginning and
  ///  end of a _line_, in addition to matching beginning and end of input,
  ///  respectively.
  ///
  ///  If `caseSensitive` is disabled, then case is ignored.
  ///
  ///  If `unicode` is enabled, then the pattern is treated as a Unicode
  ///  pattern as described by the ECMAScript standard.
  ///
  ///  If `dotAll` is enabled, then the `.` pattern will match _all_ characters,
  ///  including line terminators.
  const RegexOptions({
    this.multiLine = false,
    this.caseSensitive = true,
    this.unicode = false,
    this.dotAll = false,
  });

  final bool multiLine;
  final bool unicode;
  final bool caseSensitive;
  final bool dotAll;
}

/// Email Regex - A predefined type for handling email matching
const emailPattern = r"\b[\w\.-]+@[\w\.-]+\.\w{2,4}\b";

/// URL Regex - A predefined type for handling URL matching
const urlPattern =
    r"[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:._\+-~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:_\+.~#?&\/\/=]*)";

/// Phone Regex - A predefined type for handling phone matching
const phonePattern =
    r"(\+?( |-|\.)?\d{1,2}( |-|\.)?)?(\(?\d{3}\)?|\d{3})( |-|\.)?(\d{3}( |-|\.)?\d{4})";
