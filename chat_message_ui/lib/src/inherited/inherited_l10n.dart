import 'package:flutter/widgets.dart';

import '../utils/chat_l10n.dart';

/// InheritedWidget that provides localization (l10n) data to all descendant widgets in the chat.
/// This widget makes localized text strings available throughout the entire chat widget tree
/// without requiring manual propagation of l10n data through constructor parameters.
///
/// The localization system supports multiple languages and allows customization of all
/// user-facing text in the chat interface, including placeholder text, button labels,
/// and accessibility strings.
class InheritedL10n extends InheritedWidget {
  /// Creates an InheritedL10n widget that provides localization data to its descendants.
  ///
  /// The [l10n] parameter contains all localized strings used throughout the chat interface.
  /// The [child] parameter is the widget subtree that will have access to this localization data.
  const InheritedL10n({super.key, required this.l10n, required super.child});

  /// Retrieves the nearest InheritedL10n widget from the widget tree.
  ///
  /// This static method is used by child widgets to access localized strings
  /// without needing direct access to the l10n object. It searches up the widget tree
  /// to find the closest InheritedL10n ancestor.
  ///
  /// Throws an exception if no InheritedL10n widget is found in the ancestor chain.
  /// This typically indicates that the widget trying to access l10n is not properly
  /// wrapped in a Chat widget (which provides the InheritedL10n).
  ///
  /// Usage example:
  /// ```dart
  /// final l10n = InheritedL10n.of(context).l10n;
  /// final placeholder = l10n.inputPlaceholder; // "Type a message"
  /// ```
  static InheritedL10n of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedL10n>()!;
  }

  /// The localization object containing all translated strings for the chat interface.
  ///
  /// This includes text for:
  /// - Input field placeholder text ("Type a message")
  /// - Empty chat state messages
  /// - Accessibility labels for buttons and interactive elements
  /// - Status indicators and timestamps
  /// - Error messages and loading states
  ///
  /// The ChatL10n class can be extended to provide custom translations
  /// or to support additional languages beyond the default English.
  final ChatL10n l10n;

  /// Determines whether dependent widgets should be rebuilt when localization changes.
  ///
  /// This method is called by Flutter when the InheritedL10n widget is updated.
  /// It compares the hash codes of the old and new l10n objects to determine
  /// if any localized strings have changed.
  ///
  /// Returns true if the l10n object has changed, causing all dependent widgets
  /// to rebuild with the new localized strings. This is essential for supporting
  /// runtime language switching in the application.
  ///
  /// Returns false if the l10n object is the same, avoiding unnecessary rebuilds
  /// and maintaining good performance.
  @override
  bool updateShouldNotify(InheritedL10n oldWidget) {
    return l10n.hashCode != oldWidget.l10n.hashCode;
  }
}
