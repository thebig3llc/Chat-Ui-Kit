import 'package:chat_message_core/chat_message_core.dart' show ParsedType, regexEmail, regexLink;
import '../models/match_text.dart';
import '../models/pattern_style.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Function used to check message text for possible email to highlight and
/// hyperlink
MatchText mailToMatcher({final TextStyle? style}) {
  return MatchText(
    onTap: (mail) async {
      final url = Uri(scheme: 'mailto', path: mail);
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      }
    },
    pattern: regexEmail,
    style: style,
    parsedType: ParsedType.email,
  );
}

/// Function to check message text for url to hyperlink
MatchText urlMatcher({
  final TextStyle? style,
  final Function(String url)? onLinkPressed,
}) {
  return MatchText(
    onTap: (urlText) async {
      final protocolRegex = RegExp(
        r'^((http|ftp|https):\/\/)',
        caseSensitive: false,
      );
      if (!urlText.startsWith(protocolRegex)) {
        urlText = 'https://$urlText';
      }
      if (onLinkPressed != null) {
        onLinkPressed(urlText);
      } else {
        final url = Uri.tryParse(urlText);
        if (url != null && await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        }
      }
    },
    pattern: regexLink,
    style: style,
    parsedType: ParsedType.url,
  );
}

MatchText _patternStyleMatcher({
  required final PatternStyle patternStyle,
  final TextStyle? style,
}) {
  return MatchText(
    pattern: patternStyle.pattern,
    style: style,
    renderText:
        ({required String str, required String pattern}) => {
          'display': str.replaceAll(patternStyle.from, patternStyle.replace),
        },
  );
}

MatchText boldMatcher({final TextStyle? style}) {
  return _patternStyleMatcher(patternStyle: PatternStyle.bold, style: style);
}

MatchText italicMatcher({final TextStyle? style}) {
  return _patternStyleMatcher(patternStyle: PatternStyle.italic, style: style);
}

MatchText lineThroughMatcher({final TextStyle? style}) {
  return _patternStyleMatcher(
    patternStyle: PatternStyle.lineThrough,
    style: style,
  );
}

MatchText codeMatcher({final TextStyle? style}) {
  return _patternStyleMatcher(patternStyle: PatternStyle.code, style: style);
}
