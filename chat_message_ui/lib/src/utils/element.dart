import 'package:flutter/material.dart';
import 'package:linkify/linkify.dart';

/// Represents an element containing a link.
@immutable
class UrlElement extends LinkableElement {
  /// Creates [UrlElement].
  UrlElement(String url, [String? text]) : super(text, url);

  @override
  // ignore: unnecessary_overrides
  int get hashCode {
    return super.hashCode;
  }

  @override
  bool operator ==(Object other) {
    return equals(other);
  }

  @override
  bool equals(other) {
    return other is UrlElement && super.equals(other);
  }

  @override
  String toString() {
    return "LinkElement: '$url' ($text)";
  }
}
