## 0.0.3

### Bug Fixes
* Fixed crash when `charset` attribute is missing in HTML meta tags during link preview fetch (`preview_data.dart`).
* Fixed crash in link preview widget when `PreviewData.link` is null but preview title/image are present — tapping the preview no longer throws (`link_preview.dart`).
* Fixed link preview `aspectRatio` calculation ignoring the local null-checked variable and re-force-unwrapping `widget.previewData!` (`link_preview.dart`).
* Fixed crash in `Chat.scrollToMessage()` and `Chat.highlightMessage()` when called with a message ID that is not currently in the visible list (`chat.dart`).
* Fixed unsafe `user.firstName!` / `user.lastName!` force-unwraps in `getUserInitials()` that could throw when either name field is null (`functions.dart`).

### New Features
* Replied message UI: messages with a `repliedMessage` set now render an inline reply preview (author name + truncated content) above the message bubble (`message.dart`).

### Improvements
* Cached compiled `RegExp` objects for emoji detection and URL matching at module level — avoids recompiling the patterns on every message build (`functions.dart`, `text_message.dart`).
* Input widget `setState` is now guarded to only fire when send-button visibility actually changes, eliminating per-keystroke rebuilds (`input.dart`).
* Removed unused `freezed` dev dependency from `pubspec.yaml`.
* Updated Flutter SDK constraint from `>=1.17.0` to `>=3.19.0` to match actual Dart 3 requirements.
* Removed orphaned `//TODO: Continue from here with refactoring` comment from `link_preview.dart`.

### Tests
* Added widget tests for `Input`: send button visibility, text clearing, whitespace rejection, and trimmed text delivery.
* Added unit tests for `getUserInitials` and `consistsOfEmojis` covering edge cases (null names, empty string, emoji-only, mixed content).

## 0.0.2

* misc fixes and improvements

## 0.0.1

* Initial release.
