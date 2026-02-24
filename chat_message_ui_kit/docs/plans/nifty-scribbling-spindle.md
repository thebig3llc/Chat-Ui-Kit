# Chat-Message-UI-Kit — Full Project Plan
## Package Split + Performance Improvements

> **Status:** Analysis & Plan (no code changes made yet)
> **Scope:** Split monolithic package into `chat_message_core` (pure Dart) + `chat_message_ui_kit` (Flutter). Fix 8 performance/correctness issues.

---

## Table of Contents

1. [Package Split Architecture](#package-split-architecture)
2. [New Package Structure & File Maps](#new-package-structure)
3. [New pubspec.yaml Files](#pubspec-files)
4. [New Barrel Export Files](#barrel-exports)
5. [Performance Fix 1 — calculateChatMessages Sync](#fix-1)
6. [Performance Fix 2 — InheritedWidget → InheritedModel](#fix-2)
7. [Performance Fix 3 — Room.lastMessages in Props](#fix-3)
8. [Performance Fix 4 — MatchText Equatable](#fix-4)
9. [Performance Fix 5 — MessageCacheManager Stale Widgets](#fix-5)
10. [Performance Fix 6 — Regex Recompile on Keystroke](#fix-6)
11. [Performance Fix 7 — ImageStream Listener Leak](#fix-7)
12. [Performance Fix 8 — OptimizedChatList Isolate Overhead](#fix-8)
13. [Migration Guide for Consumers](#migration-guide)
14. [Rollout Phases](#rollout)

---

<a name="package-split-architecture"></a>
## 1. Package Split Architecture

### Why Split?

The current single package mixes pure data logic with Flutter UI. This means:
- Models cannot be used in server-side Dart, CLI tools, or background isolates without pulling in the entire Flutter SDK.
- `http` + `html` are transitive dependencies for any Flutter consumer even if they never use link previews.
- `calculateChatMessages()` runs pure data transformation but is stuck on the Flutter thread.

### Two-Package Design

```
chat_message_core/          ← Pure Dart. No Flutter. No dart:ui.
  Models, enums, JSON serialization, l10n strings, core utilities,
  link preview HTTP fetcher (no image size resolution).

chat_message_ui_kit/        ← Flutter. Depends on chat_message_core.
  All widgets, themes, inherited widgets, Flutter-coupled utilities,
  image size resolution, markdown-aware input controller.
```

### Zero-Cost Consumer Migration

The UI kit barrel re-exports everything from core:

```dart
// lib/chat_message_ui_kit.dart
export 'package:chat_message_core/chat_message_core.dart'; // ← one line shim
// ... rest of exports unchanged
```

Existing consumers who only use `import 'package:chat_message_ui_kit/chat_message_ui_kit.dart'` need **zero changes**. Type identity is preserved — `MessageModel` from core and from the UI kit re-export are the same type.

---

<a name="new-package-structure"></a>
## 2. New Package Structure & File Maps

### Pre-requisite: Remove Flutter from 4 Model Files

These 4 files only use `@immutable` from Flutter. Change one import per file:

```dart
// BEFORE (in date_header.dart, message_spacer.dart, unread_header_data.dart, preview_image.dart)
import 'package:flutter/material.dart';

// AFTER
import 'package:meta/meta.dart';
```

That single change per file makes them pure Dart and eligible for `chat_message_core`.

Same fix for `chat_l10n.dart`:
```dart
// BEFORE
import 'package:flutter/material.dart';

// AFTER
import 'package:meta/meta.dart';
```

---

### `chat_message_core` File Map

```
chat_message_core/
├── lib/
│   ├── chat_message_core.dart          ← barrel export (see below)
│   └── src/
│       ├── enums/
│       │   ├── message_status.dart     (Status: delivered, error, seen, sending, sent)
│       │   ├── message_type.dart       (MessageType: audio, image, text, video)
│       │   └── parsed_type.dart        (ParsedType: email, phone, url)
│       ├── models/
│       │   ├── message.dart            (abstract MessageModel)
│       │   ├── text_message.dart       (TextMessageModel)
│       │   ├── image_message.dart      (ImageMessageModel)
│       │   ├── audio_message.dart      (AudioMessageModel)
│       │   ├── video_message.dart      (VideoMessageModel)
│       │   ├── partial_text.dart       (PartialTextModel)
│       │   ├── partial_image.dart      (PartialImageModel)
│       │   ├── partial_audio.dart      (PartialAudioModel)
│       │   ├── partial_video.dart      (PartialVideoModel)
│       │   ├── chat_user.dart          (ChatUser)
│       │   ├── room.dart               (Room)
│       │   ├── preview_data.dart       (PreviewData, PreviewDataImage)
│       │   ├── date_header.dart        (after @immutable fix)
│       │   ├── message_spacer.dart     (after @immutable fix)
│       │   ├── unread_header_data.dart (after @immutable fix)
│       │   └── preview_image.dart      (after @immutable fix)
│       └── utils/
│           ├── chat_l10n.dart          (all language impls — after @immutable fix)
│           ├── regex.dart              (regexEmail, regexLink)
│           ├── functions.dart          (calculateChatMessages, formatBytes,
│           │                            getUserInitials, getUserName)
│           └── preview_data_fetcher.dart (HTTP+HTML fetch — no image dims)
└── pubspec.yaml
```

---

### `chat_message_ui_kit` File Map (unchanged except new dependency + shim barrel)

```
chat_message_ui_kit/
├── lib/
│   ├── chat_message_ui_kit.dart   ← add re-export shim at top
│   └── src/
│       ├── enums/
│       │   ├── bubble_rtl_alignment.dart
│       │   ├── emoji_enlargement_behavior.dart
│       │   ├── input_clear_mode.dart
│       │   ├── send_button_visibility_mode.dart
│       │   └── typing_indicator_mode.dart
│       ├── inherited/
│       │   ├── inherited_chat_theme.dart  ← Fix 2 (InheritedModel)
│       │   ├── inherited_user.dart        ← Fix 2 (full equality)
│       │   └── inherited_l10n.dart
│       ├── models/
│       │   ├── match_text.dart     ← Fix 4 (add Equatable)
│       │   └── pattern_style.dart
│       ├── themes/
│       │   └── chat_theme.dart     ← Fix 2 (add == / hashCode)
│       ├── utils/
│       │   ├── conditional.dart
│       │   ├── functions.dart      ← (getUserAvatarNameColor, consistsOfEmojis, isMobile)
│       │   ├── linkifier.dart
│       │   ├── matchers.dart
│       │   ├── message_cache_manager.dart  ← Fix 5 (add hash guard)
│       │   └── preview_data.dart   ← (_getImageSize stays; wraps core fetcher)
│       └── widgets/
│           ├── chat/
│           │   ├── chat.dart           ← Fix 1 (listEquals guard + compute)
│           │   └── chat_list.dart
│           ├── input/
│           │   ├── input.dart
│           │   ├── input_text_field_controller.dart  ← Fix 6 (cache regex)
│           │   ├── attachment_button.dart
│           │   └── send_button.dart
│           ├── message/
│           │   ├── message.dart
│           │   ├── text_message.dart
│           │   ├── image_message.dart  ← Fix 7 (ImageStream leak)
│           │   ├── user_avatar.dart
│           │   ├── user_name.dart
│           │   └── message_status.dart
│           ├── linking/
│           │   ├── link_preview.dart
│           │   └── selectable_link.dart
│           ├── optimized_chat_list.dart  ← Fix 8 (remove isolate, use diffutil_dart)
│           ├── typing_indicator.dart
│           ├── unread_header.dart
│           ├── parsed_text.dart
│           ├── image_gallery.dart
│           └── optimized_image_gallery.dart
└── pubspec.yaml
```

---

<a name="pubspec-files"></a>
## 3. New pubspec.yaml Files

### `chat_message_core/pubspec.yaml`

```yaml
name: chat_message_core
description: Pure Dart data models and core logic for chat messaging.
version: 0.0.1
homepage: https://github.com/thebig3llc/Chat-Message-Ui-Kit

environment:
  sdk: ^3.7.2

dependencies:
  equatable: ^2.0.7
  json_annotation: ^4.9.0
  intl: ^0.20.2
  meta: ^1.9.0
  http: ^1.5.0
  html: ^0.15.6

dev_dependencies:
  build_runner: ^2.8.0
  json_serializable: ^6.11.1
  freezed: ^3.2.3
  freezed_annotation: ^3.0.0
  lints: ^5.0.0
```

> **Removed from current deps:** flutter, url_launcher, linkify, visibility_detector,
> diffutil_dart, photo_view, scroll_to_index, cached_network_image

---

### `chat_message_ui_kit/pubspec.yaml`

```yaml
name: chat_message_ui_kit
description: Flutter chat UI kit. Requires chat_message_core.
version: 0.0.2
homepage: https://github.com/thebig3llc/Chat-Message-Ui-Kit

environment:
  sdk: ^3.7.2
  flutter: ">=1.17.0"

dependencies:
  flutter:
    sdk: flutter
  chat_message_core: ^0.0.1       # ← NEW: replaces inline models
  url_launcher: ^6.3.2
  linkify: ^5.0.0
  intl: ^0.20.2
  visibility_detector: ^0.4.0+2
  diffutil_dart: ^4.0.1
  photo_view: ^0.15.0
  scroll_to_index: ^3.0.1
  cached_network_image: ^3.4.1
  # http and html REMOVED — they are now deps of chat_message_core only

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  build_runner: ^2.8.0
  json_serializable: ^6.11.1
```

---

<a name="barrel-exports"></a>
## 4. New Barrel Export Files

### `chat_message_core/lib/chat_message_core.dart`

```dart
library chat_message_core;

// ── Enums ────────────────────────────────────────────────────────────────────
export 'src/enums/message_status.dart';
export 'src/enums/message_type.dart';
export 'src/enums/parsed_type.dart';

// ── Models ───────────────────────────────────────────────────────────────────
export 'src/models/message.dart';
export 'src/models/text_message.dart';
export 'src/models/image_message.dart';
export 'src/models/audio_message.dart';
export 'src/models/video_message.dart';
export 'src/models/partial_text.dart';
export 'src/models/partial_image.dart';
export 'src/models/partial_audio.dart';
export 'src/models/partial_video.dart';
export 'src/models/chat_user.dart';
export 'src/models/room.dart';
export 'src/models/preview_data.dart';
export 'src/models/date_header.dart';
export 'src/models/message_spacer.dart';
export 'src/models/unread_header_data.dart';
export 'src/models/preview_image.dart';

// ── Utils ────────────────────────────────────────────────────────────────────
export 'src/utils/chat_l10n.dart';
export 'src/utils/regex.dart' show regexEmail, regexLink;
export 'src/utils/functions.dart'
    show formatBytes, getUserInitials, getUserName, calculateChatMessages;
export 'src/utils/preview_data_fetcher.dart' show getPreviewData;
```

---

### `chat_message_ui_kit/lib/chat_message_ui_kit.dart` (updated)

```dart
library chat_message_ui_kit;

// ── Core re-export (zero migration cost for existing consumers) ───────────────
export 'package:chat_message_core/chat_message_core.dart';

// ── UI-only Enums ─────────────────────────────────────────────────────────────
export 'src/enums/bubble_rtl_alignment.dart';
export 'src/enums/emoji_enlargement_behavior.dart';
export 'src/enums/input_clear_mode.dart';
export 'src/enums/send_button_visibility_mode.dart';
export 'src/enums/typing_indicator_mode.dart';

// ── UI-only Models ────────────────────────────────────────────────────────────
export 'src/models/match_text.dart';
export 'src/models/pattern_style.dart';

// ── Themes ────────────────────────────────────────────────────────────────────
export 'src/themes/chat_theme.dart';

// ── Utils (UI) ────────────────────────────────────────────────────────────────
export 'src/utils/matchers.dart';
export 'src/utils/functions.dart'
    show consistsOfEmojis, getUserAvatarNameColor, isMobile;

// ── Widgets ───────────────────────────────────────────────────────────────────
export 'src/widgets/input/send_button.dart';
export 'src/widgets/chat/chat.dart';
export 'src/widgets/chat/chat_list.dart';
export 'src/widgets/image_gallery.dart';
export 'src/widgets/input/attachment_button.dart';
export 'src/widgets/input/input_text_field_controller.dart';
export 'src/widgets/input/input.dart';
export 'src/widgets/message/image_message.dart';
export 'src/widgets/message/message.dart';
export 'src/widgets/message/message_status.dart';
export 'src/widgets/message/text_message.dart';
export 'src/widgets/message/user_avatar.dart';
export 'src/widgets/message/user_name.dart';
export 'src/widgets/typing_indicator.dart';
export 'src/widgets/unread_header.dart';
export 'src/widgets/linking/link_preview.dart';
```

---

<a name="fix-1"></a>
## 5. Fix 1 — `calculateChatMessages()` Is Synchronous in `didUpdateWidget()`

**File:** `lib/src/widgets/chat/chat.dart`

**Problem:** Full O(n) message list recomputation runs on the UI thread every time the parent calls `setState()`, even when messages haven't changed.

### Change 1: Add `isWeb` parameter to `calculateChatMessages()` in core

**File:** `chat_message_core/lib/src/utils/functions.dart`

```dart
// BEFORE
List<Object> calculateChatMessages(
  List<MessageModel> messages,
  ChatUser user, {
  required String Function(DateTime) dateHeaderBuilder,
  required int Function(DateTime, DateTime) dateHeaderThreshold,
  // ...
}) {
  final isWeb = kIsWeb; // ← Flutter-only constant
  // ...
}

// AFTER — inject isWeb as a parameter
List<Object> calculateChatMessages(
  List<MessageModel> messages,
  ChatUser user, {
  required String Function(DateTime) dateHeaderBuilder,
  required int Function(DateTime, DateTime) dateHeaderThreshold,
  bool isWeb = false, // ← injected, defaults to false for pure Dart callers
  // ...
}) {
  // use isWeb directly instead of kIsWeb
}
```

### Change 2: Guard and optionally offload in `chat.dart`

```dart
// BEFORE
@override
void didUpdateWidget(covariant Chat oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.messages.isNotEmpty) {
    final result = calculateChatMessages(
      widget.messages,
      widget.user,
      // ...
    );
    _chatMessages = result[0] as List<Object>;
    _gallery = result[1] as List<PreviewImage>;
    _refreshAutoScrollMapping();
    _maybeScrollToFirstUnread();
  }
}

// AFTER
@override
void didUpdateWidget(covariant Chat oldWidget) {
  super.didUpdateWidget(oldWidget);

  final messagesChanged =
      !listEquals(widget.messages, oldWidget.messages);
  final configChanged =
      widget.dateHeaderThreshold != oldWidget.dateHeaderThreshold ||
      widget.groupMessagesThreshold != oldWidget.groupMessagesThreshold ||
      widget.showUserNames != oldWidget.showUserNames ||
      widget.scrollToUnreadOptions.lastReadMessageId !=
          oldWidget.scrollToUnreadOptions.lastReadMessageId;

  if (widget.messages.isNotEmpty && (messagesChanged || configChanged)) {
    _recomputeChatMessages();
  }
}

void _recomputeChatMessages() {
  if (widget.messages.length > 200) {
    // Offload to isolate for large lists to avoid jank
    compute(
      _calculateChatMessagesIsolate,
      _ChatMessagesIsolateParams(
        messages: widget.messages,
        user: widget.user,
        isWeb: kIsWeb,
        // pass serialized config (DateFormat locale string, thresholds, etc.)
        dateLocale: widget.dateLocale,
        dateHeaderThreshold: widget.dateHeaderThreshold,
        groupMessagesThreshold: widget.groupMessagesThreshold,
        showUserNames: widget.showUserNames,
        scrollToUnreadOptions: widget.scrollToUnreadOptions,
      ),
    ).then((result) {
      if (mounted) {
        setState(() {
          _chatMessages = result.chatMessages;
          _gallery = result.gallery;
        });
        _refreshAutoScrollMapping();
        _maybeScrollToFirstUnread();
      }
    });
  } else {
    // Synchronous for small lists — fast enough on UI thread
    final result = calculateChatMessages(
      widget.messages,
      widget.user,
      isWeb: kIsWeb,
      // ...
    );
    setState(() {
      _chatMessages = result[0] as List<Object>;
      _gallery = result[1] as List<PreviewImage>;
    });
    _refreshAutoScrollMapping();
    _maybeScrollToFirstUnread();
  }
}

// Top-level function for compute() (must be top-level or static)
_ChatMessagesIsolateResult _calculateChatMessagesIsolate(
    _ChatMessagesIsolateParams params) {
  final result = calculateChatMessages(
    params.messages,
    params.user,
    isWeb: params.isWeb,
    // ...
  );
  return _ChatMessagesIsolateResult(
    chatMessages: result[0] as List<Object>,
    gallery: result[1] as List<PreviewImage>,
  );
}

// Simple data classes for isolate params/result (no Flutter types)
class _ChatMessagesIsolateParams {
  const _ChatMessagesIsolateParams({
    required this.messages,
    required this.user,
    required this.isWeb,
    required this.dateLocale,
    required this.dateHeaderThreshold,
    required this.groupMessagesThreshold,
    required this.showUserNames,
    required this.scrollToUnreadOptions,
  });
  final List<MessageModel> messages;
  final ChatUser user;
  final bool isWeb;
  final String? dateLocale;
  final int dateHeaderThreshold;
  final int groupMessagesThreshold;
  final bool showUserNames;
  final ScrollToUnreadOptions scrollToUnreadOptions;
}

class _ChatMessagesIsolateResult {
  const _ChatMessagesIsolateResult({
    required this.chatMessages,
    required this.gallery,
  });
  final List<Object> chatMessages;
  final List<PreviewImage> gallery;
}
```

---

<a name="fix-2"></a>
## 6. Fix 2 — `InheritedWidget` → `InheritedModel` for Granular Rebuilds

**Files:**
- `lib/src/themes/chat_theme.dart`
- `lib/src/inherited/inherited_chat_theme.dart`
- `lib/src/inherited/inherited_user.dart`

### Step A: Add `==` and `hashCode` to `ChatTheme`

```dart
// lib/src/themes/chat_theme.dart

@immutable
abstract class ChatTheme {
  const ChatTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    // ... all other fields
  });

  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  // ... all fields

  // ADD these two methods so InheritedWidget comparisons work structurally
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ChatTheme) return false;
    return primaryColor == other.primaryColor &&
        secondaryColor == other.secondaryColor &&
        backgroundColor == other.backgroundColor;
        // ... all other fields
  }

  @override
  int get hashCode => Object.hashAll([
    primaryColor,
    secondaryColor,
    backgroundColor,
    // ... all other fields
  ]);
}
```

### Step B: Upgrade `InheritedChatTheme` to `InheritedModel`

```dart
// lib/src/inherited/inherited_chat_theme.dart

// Define which aspects of the theme widgets can depend on
enum ChatThemeAspect { colors, textStyles, dimensions, icons }

class InheritedChatTheme extends InheritedModel<ChatThemeAspect> {
  const InheritedChatTheme({
    super.key,
    required this.theme,
    required super.child,
  });

  final ChatTheme theme;

  static InheritedChatTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedChatTheme>()!;

  /// Use this in widgets that only care about a specific theme aspect.
  /// Only those widgets will rebuild when that aspect changes.
  static InheritedChatTheme aspectOf(
    BuildContext context,
    ChatThemeAspect aspect,
  ) {
    return InheritedModel.inheritFrom<InheritedChatTheme>(
      context,
      aspect: aspect,
    )!;
  }

  @override
  bool updateShouldNotify(InheritedChatTheme old) =>
      theme != old.theme; // Uses ChatTheme == (structural)

  @override
  bool updateShouldNotifyDependent(
    InheritedChatTheme old,
    Set<ChatThemeAspect> dependencies,
  ) {
    if (dependencies.contains(ChatThemeAspect.colors)) {
      return theme.primaryColor != old.theme.primaryColor ||
          theme.secondaryColor != old.theme.secondaryColor ||
          theme.backgroundColor != old.theme.backgroundColor ||
          theme.errorColor != old.theme.errorColor;
    }
    if (dependencies.contains(ChatThemeAspect.textStyles)) {
      return theme.sentMessageBodyTextStyle !=
              old.theme.sentMessageBodyTextStyle ||
          theme.receivedMessageBodyTextStyle !=
              old.theme.receivedMessageBodyTextStyle;
    }
    if (dependencies.contains(ChatThemeAspect.dimensions)) {
      return theme.messageBorderRadius != old.theme.messageBorderRadius ||
          theme.messageMaxWidth != old.theme.messageMaxWidth ||
          theme.messageInsetsHorizontal != old.theme.messageInsetsHorizontal ||
          theme.messageInsetsVertical != old.theme.messageInsetsVertical;
    }
    if (dependencies.contains(ChatThemeAspect.icons)) {
      return theme.sendButtonIcon != old.theme.sendButtonIcon ||
          theme.deliveredIcon != old.theme.deliveredIcon ||
          theme.seenIcon != old.theme.seenIcon ||
          theme.errorIcon != old.theme.errorIcon;
    }
    return false;
  }
}
```

### Step C: Fix `InheritedUser` (compares only `id` today)

```dart
// lib/src/inherited/inherited_user.dart

class InheritedUser extends InheritedWidget {
  const InheritedUser({
    super.key,
    required this.user,
    required super.child,
  });

  final ChatUser user;

  static InheritedUser of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InheritedUser>()!;

  @override
  bool updateShouldNotify(InheritedUser old) =>
      user != old.user; // ChatUser already uses Equatable — full field comparison
      // BEFORE was: user.id != old.user.id (which missed avatar/name changes)
}
```

---

<a name="fix-3"></a>
## 7. Fix 3 — `Room.lastMessages` in Equatable Props

**File:** `lib/src/models/room.dart`

```dart
// BEFORE
@override
List<Object?> get props => [
  createdAt,
  id,
  imageUrl,
  lastMessages,  // ← causes O(n*m) equality checks; documented as in-memory only
  name,
  updatedAt,
  users,
];

// AFTER
@override
List<Object?> get props => [
  createdAt,
  id,
  imageUrl,
  // lastMessages intentionally excluded — it is in-memory state, not identity.
  // Compare lastMessages explicitly where needed: room.lastMessages == other.lastMessages
  name,
  updatedAt,
  users,
];
```

**Why it is safe:** The field is already documented in the codebase as: *"In-memory only — should not be used to serialize directly into a document database."* It represents cached UI state, not the canonical identity of a room.

---

<a name="fix-4"></a>
## 8. Fix 4 — `MatchText` Has No Equatable

**File:** `lib/src/models/match_text.dart`

```dart
// BEFORE
class MatchText {
  MatchText({
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
  final Function(String)? onTap;
  final Map<String, String> Function({
    required String str,
    required String pattern,
  })? renderText;
  final Widget Function({required String text, required String pattern})?
      renderWidget;
}

// AFTER
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
  final Map<String, String> Function({
    required String str,
    required String pattern,
  })? renderText;
  final Widget Function({required String text, required String pattern})?
      renderWidget;

  @override
  List<Object?> get props => [parsedType, pattern, style];
}
```

**Usage guidance for consumers:**

```dart
// BAD — creates new MatchText on every build(), always looks "changed"
Widget build(BuildContext context) {
  return Chat(
    textMessageOptions: TextMessageOptions(
      matchers: [
        MatchText(
          pattern: r'@\w+',
          style: const TextStyle(color: Colors.blue),
          onTap: (mention) => print(mention),
        ),
      ],
    ),
  );
}

// GOOD — cached at state scope, stable identity
class _ChatScreenState extends State<ChatScreen> {
  late final List<MatchText> _matchers = [
    MatchText(
      pattern: r'@\w+',
      style: const TextStyle(color: Colors.blue),
      onTap: (mention) => print(mention),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Chat(
      textMessageOptions: TextMessageOptions(matchers: _matchers),
    );
  }
}
```

---

<a name="fix-5"></a>
## 9. Fix 5 — `MessageCacheManager` Caches Stale Widgets

**File:** `lib/src/utils/message_cache_manager.dart`

The current cache stores built `Widget` objects without any content validation. A status change (`sending → sent`) returns a cached widget with the wrong delivery indicator.

### Option A (Recommended) — Add Message Hash Guard

```dart
// lib/src/utils/message_cache_manager.dart

class MessageCacheManager {
  final int maxCacheSize;

  MessageCacheManager({this.maxCacheSize = 50});

  // LinkedHashMap preserves insertion order for LRU eviction
  final LinkedHashMap<String, _CachedEntry> _cache =
      LinkedHashMap<String, _CachedEntry>();

  /// Returns a cached widget only if the message content hasn't changed.
  /// Pass [messageHashCode] from [MessageModel.hashCode] (Equatable-based).
  Widget? getCachedWidget(String messageId, int messageHashCode) {
    final entry = _cache[messageId];
    if (entry == null) return null;

    // If the message changed (status, text, etc.), invalidate and return null
    if (entry.messageHashCode != messageHashCode) {
      _cache.remove(messageId);
      return null;
    }

    // LRU: move to end (most recently used)
    _cache.remove(messageId);
    _cache[messageId] = entry;
    return entry.widget;
  }

  /// Cache a widget with its message's current hash for invalidation.
  void cacheWidget(String messageId, Widget widget, int messageHashCode) {
    // Remove existing entry if present (will be re-added at end = most recent)
    _cache.remove(messageId);
    _cache[messageId] = _CachedEntry(widget: widget, messageHashCode: messageHashCode);

    // Evict oldest entries when over capacity
    while (_cache.length > maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  void invalidate(String messageId) => _cache.remove(messageId);

  void clear() => _cache.clear();
}

class _CachedEntry {
  const _CachedEntry({required this.widget, required this.messageHashCode});
  final Widget widget;
  final int messageHashCode;
}
```

### Option B (Simpler) — Replace with Layout-Parameter Cache

If widget caching proves too complex to maintain correctly, replace with a cheaper layout-parameter cache:

```dart
/// Caches only the O(1) layout parameters for each message.
/// Flutter's SliverList already handles widget recycling efficiently —
/// we only need to cache the expensive grouping/layout calculations.
class MessageLayoutCache {
  final Map<String, MessageLayoutInfo> _cache = {};

  MessageLayoutInfo? getLayout(String messageId) => _cache[messageId];

  void setLayout(String messageId, MessageLayoutInfo info) {
    _cache[messageId] = info;
  }

  void invalidate(String messageId) => _cache.remove(messageId);
  void clear() => _cache.clear();
}

class MessageLayoutInfo {
  const MessageLayoutInfo({
    required this.roundBorder,
    required this.showName,
    required this.showStatus,
    required this.nextMessageInGroup,
    required this.previousMessageInGroup,
  });

  final bool roundBorder;
  final bool showName;
  final bool showStatus;
  final bool nextMessageInGroup;
  final bool previousMessageInGroup;
}
```

---

<a name="fix-6"></a>
## 10. Fix 6 — `InputTextFieldController` Recompiles Regex on Every Keystroke

**File:** `lib/src/widgets/input/input_text_field_controller.dart`

```dart
// BEFORE — RegExp constructed on every buildTextSpan() call (every keystroke)
@override
TextSpan buildTextSpan({
  required BuildContext context,
  TextStyle? style,
  required bool withComposing,
}) {
  final children = <InlineSpan>[];

  text.splitMapJoin(
    RegExp(                                          // ← allocated every keystroke
      _listPatternStyle.map((e) => e.regExp.pattern).join('|'),
    ),
    onMatch: (match) {
      final patternStyle = _listPatternStyle.firstWhere(
        (e) => e.regExp.hasMatch(match[0]!),         // ← re-runs each regex per match
      );
      // ...
    },
    onNonMatch: (text) {
      children.add(TextSpan(text: text, style: style));
      return '';
    },
  );

  return TextSpan(style: style, children: children);
}

// AFTER — RegExp compiled once at initialization
class InputTextFieldController extends TextEditingController {
  InputTextFieldController({List<PatternStyle>? patternList})
      : _listPatternStyle = patternList ??
            [
              PatternStyle.bold,
              PatternStyle.italic,
              PatternStyle.lineThrough,
              PatternStyle.code,
            ];

  final List<PatternStyle> _listPatternStyle;

  // Compiled once — not on every keystroke
  late final RegExp _combinedPattern = RegExp(
    _listPatternStyle.map((e) => e.regExp.pattern).join('|'),
  );

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final children = <InlineSpan>[];

    text.splitMapJoin(
      _combinedPattern,  // ← reused, no recompilation
      onMatch: (match) {
        // Find which pattern matched by testing each against the matched text.
        // This inner loop is unavoidable without named capture groups,
        // but at least the outer RegExp is not being recompiled.
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
              text: matchedText
                  .replaceAll(RegExp(matchedStyle.replace), ''),
              style: style?.merge(matchedStyle.textStyle) ??
                  matchedStyle.textStyle,
            ),
          );
        }
        return '';
      },
      onNonMatch: (text) {
        children.add(TextSpan(text: text, style: style));
        return '';
      },
    );

    return TextSpan(style: style, children: children);
  }
}
```

**Further optimization (optional):** Use named capture groups so the `firstWhere`/loop is eliminated entirely:

```dart
// Named capture group approach — each pattern gets its own named group
late final RegExp _namedPattern = RegExp(
  _listPatternStyle
      .asMap()
      .entries
      .map((e) => '(?P<p${e.key}>${e.value.regExp.pattern})')
      .join('|'),
);

// In onMatch — check which group matched by name
onMatch: (match) {
  for (var i = 0; i < _listPatternStyle.length; i++) {
    if (match.namedGroup('p$i') != null) {
      final ps = _listPatternStyle[i];
      children.add(TextSpan(
        text: match[0]!.replaceAll(RegExp(ps.replace), ''),
        style: style?.merge(ps.textStyle) ?? ps.textStyle,
      ));
      break;
    }
  }
  return '';
},
```

---

<a name="fix-7"></a>
## 11. Fix 7 — `ImageStream` Listener Leak in `ImageMessage`

**File:** `lib/src/widgets/message/image_message.dart`

```dart
// BEFORE — listener object created fresh each time (identity mismatch → leak)
class _ImageMessageState extends State<ImageMessage> {
  ImageProvider? _image;
  Size _size = Size.zero;
  ImageStream? _stream;

  void _getImage() {
    final oldImageStream = _stream;
    _stream = _image?.resolve(createLocalImageConfiguration(context));
    if (_stream?.key == oldImageStream?.key) return;

    // BUG: new ImageStreamListener object — never matches the registered one
    final listener = ImageStreamListener(_updateImage);
    oldImageStream?.removeListener(listener); // ← does NOT remove the real listener
    _stream?.addListener(listener);
  }

  void _updateImage(ImageInfo info, bool _) {
    setState(() {
      _size = Size(info.image.width.toDouble(), info.image.height.toDouble());
    });
  }

  @override
  void dispose() {
    // BUG: creates yet another new object — real listener is never removed
    _stream?.removeListener(ImageStreamListener(_updateImage));
    super.dispose();
  }
}

// AFTER — listener stored as field for consistent identity
class _ImageMessageState extends State<ImageMessage> {
  ImageProvider? _image;
  Size _size = Size.zero;
  ImageStream? _stream;
  ImageStreamListener? _listener; // ← stored as field

  void _getImage() {
    final oldStream = _stream;
    _stream = _image?.resolve(createLocalImageConfiguration(context));
    if (_stream?.key == oldStream?.key) return;

    // Remove the SAME listener object from the old stream
    if (_listener != null && oldStream != null) {
      oldStream.removeListener(_listener!);
    }

    // Create listener once; reuse the same object
    _listener = ImageStreamListener(_updateImage);
    _stream?.addListener(_listener!);
  }

  void _updateImage(ImageInfo info, bool _) {
    if (!mounted) return; // Guard against post-dispose callbacks
    setState(() {
      _size = Size(info.image.width.toDouble(), info.image.height.toDouble());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _image = widget.message.width != null && widget.message.height != null
        ? null // Dimensions already known — skip stream
        : _resolveImageProvider();
    if (_image != null && _size.isEmpty) {
      _getImage();
    }
  }

  @override
  void dispose() {
    // Remove the SAME listener object — guaranteed to succeed
    if (_listener != null) {
      _stream?.removeListener(_listener!);
    }
    super.dispose();
  }
}
```

**Longer-term recommendation:** Populate `ImageMessageModel.width` and `height` on the server side when images are uploaded. This eliminates the entire `_getImage()` / `ImageStream` path — `_size` is initialized from model data and the widget never needs a stream listener.

---

<a name="fix-8"></a>
## 12. Fix 8 — `OptimizedChatList` Isolate Overhead Exceeds Benefit

**File:** `lib/src/widgets/chat/chat_list.dart` (and `optimized_chat_list.dart` if separate)

**Problem:** Isolate spawning costs 2–20 ms. The work it performs (a `Set.difference()` of message IDs) takes ~0.1 ms synchronously. The `diffutil_dart` package is a declared dependency but is never used.

### Remove Isolate; Integrate `diffutil_dart` Properly

```dart
// BEFORE — isolate for a Set.difference() that takes 0.1ms
void _calculateDiffsInIsolate(List<Object> newMessages) {
  if (newMessages.length > diffThreshold) {
    Isolate.spawn(_isolateWorker, _IsolateMessage(
      oldIds: _currentMessages.whereType<Map>()
          .map((m) => (m['message'] as MessageModel).id).toSet(),
      newIds: newMessages.whereType<Map>()
          .map((m) => (m['message'] as MessageModel).id).toSet(),
    )).then((isolate) {
      // ...apply result to SliverList
    });
  }
}

// AFTER — use diffutil_dart with SliverAnimatedList for proper diff + animations
import 'package:diffutil_dart/diffutil.dart';

class _OptimizedChatListState extends State<OptimizedChatList> {
  final GlobalKey<SliverAnimatedListState> _listKey =
      GlobalKey<SliverAnimatedListState>();
  List<Object> _items = [];

  void _updateItems(List<Object> newItems) {
    // diffutil_dart computes the Myers diff (same algorithm as Android RecyclerView)
    final diff = calculateListDiff<Object>(
      _items,
      newItems,
      equalityChecker: (a, b) => a == b, // Uses Equatable == on models
      detectMoves: false, // Chat lists only append/prepend; moves are rare
    );

    // Apply the diff to the animated list — this drives insert/remove animations
    diff.dispatchUpdatesTo(SliverAnimatedListDataSource(_listKey));

    _items = newItems;
  }

  @override
  void didUpdateWidget(covariant OptimizedChatList old) {
    super.didUpdateWidget(old);
    if (!listEquals(widget.messages, old.messages)) {
      _updateItems(widget.messages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: widget.scrollController,
      reverse: true, // Chat lists show newest at bottom
      slivers: [
        SliverAnimatedList(
          key: _listKey,
          initialItemCount: _items.length,
          itemBuilder: (context, index, animation) {
            return _buildItem(_items[index], animation);
          },
        ),
      ],
    );
  }

  Widget _buildItem(Object item, Animation<double> animation) {
    return SizeTransition(
      sizeFactor: animation,
      axisAlignment: -1,
      child: _buildMessageItem(item),
    );
  }
}

/// Helper to adapt DiffUpdate to SliverAnimatedListState
class SliverAnimatedListDataSource implements ListUpdateCallback {
  SliverAnimatedListDataSource(this._key);
  final GlobalKey<SliverAnimatedListState> _key;

  @override
  void onInserted(int position, int count) {
    for (var i = 0; i < count; i++) {
      _key.currentState?.insertItem(position + i);
    }
  }

  @override
  void onRemoved(int position, int count) {
    // Need access to old items for the remove builder — store as a field
    for (var i = 0; i < count; i++) {
      _key.currentState?.removeItem(
        position,
        (context, animation) => SizeTransition(
          sizeFactor: animation,
          child: const SizedBox.shrink(),
        ),
      );
    }
  }

  @override
  void onMoved(int from, int to) {
    // For chat, treat as remove + insert
    onRemoved(from, 1);
    onInserted(to, 1);
  }

  @override
  void onChanged(int position, int count, Object? payload) {
    // Widget already handles this via Equatable — no explicit rebuild needed
  }
}
```

---

<a name="migration-guide"></a>
## 13. Migration Guide for Consumers

### Scenario A: Flutter app using only `Chat(...)` widget

**Zero changes required.** The `chat_message_ui_kit` barrel re-exports all core types. Consumers do not need to add `chat_message_core` to their `pubspec.yaml`.

---

### Scenario B: Server-side Dart or background isolate using models

**Add `chat_message_core` to your pubspec:**

```yaml
dependencies:
  chat_message_core: ^0.0.1
```

**Change imports:**

```dart
// BEFORE
import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';

// AFTER (in non-Flutter code)
import 'package:chat_message_core/chat_message_core.dart';
```

---

### Scenario C: Calling `calculateChatMessages()` directly

```dart
// BEFORE
final result = calculateChatMessages(messages, user, ...);

// AFTER — add isWeb parameter
import 'package:flutter/foundation.dart' show kIsWeb;

final result = calculateChatMessages(messages, user, ..., isWeb: kIsWeb);
```

---

### Scenario D: `Room` equality change (`lastMessages` removed from props)

If your code relies on `room1 == room2` to detect incoming messages, switch to explicit comparison:

```dart
// BEFORE — relied on Room equality checking lastMessages
if (oldRoom != newRoom) rebuildUI();

// AFTER — compare lastMessages explicitly where needed
if (oldRoom != newRoom ||
    !listEquals(oldRoom.lastMessages, newRoom.lastMessages)) {
  rebuildUI();
}
```

---

<a name="rollout"></a>
## 14. Rollout Phases

### Phase 1 — Preparatory (no API changes)
- [ ] Apply `@immutable` import fix to `date_header.dart`, `message_spacer.dart`, `unread_header_data.dart`, `preview_image.dart`, `chat_l10n.dart` (change `flutter/material.dart` → `meta/meta.dart`)
- [ ] Apply Fix 3: Remove `lastMessages` from `Room.props`
- [ ] Apply Fix 4: Add `Equatable` to `MatchText`
- [ ] Apply Fix 6: Cache `RegExp` in `InputTextFieldController`
- [ ] Apply Fix 7: Store `ImageStreamListener` as field in `ImageMessage`

### Phase 2 — Performance Improvements
- [ ] Apply Fix 1: Guard `didUpdateWidget`, add `compute()` isolate path for 200+ messages
- [ ] Apply Fix 2: Add `==`/`hashCode` to `ChatTheme`, upgrade `InheritedChatTheme` to `InheritedModel`
- [ ] Apply Fix 5: Add message hash guard to `MessageCacheManager`
- [ ] Apply Fix 8: Remove isolate from `OptimizedChatList`, integrate `diffutil_dart` + `SliverAnimatedList`

### Phase 3 — Package Split
- [ ] Create `chat_message_core/` package with its `pubspec.yaml` and barrel export
- [ ] Move all identified files to `chat_message_core`
- [ ] Split `preview_data.dart` into pure fetcher (core) and image-size resolver (UI kit)
- [ ] Update `chat_message_ui_kit/pubspec.yaml` to depend on `chat_message_core`
- [ ] Add re-export shim to `chat_message_ui_kit.dart` barrel

### Phase 4 — v0.1.0 (future)
- [ ] Remove the re-export shim from `chat_message_ui_kit.dart`
- [ ] Publish migration guide in CHANGELOG
- [ ] Require consumers to explicitly import from the correct package

---

## Summary Table

| # | Issue | File | Impact | Effort |
|---|---|---|---|---|
| 1 | `calculateChatMessages()` sync in `didUpdateWidget` | `chat.dart` | High — UI jank on every parent rebuild | Medium |
| 2 | `InheritedWidget` → `InheritedModel` | `inherited_chat_theme.dart`, `chat_theme.dart` | High — mass rebuilds on non-`const` theme | Medium |
| 3 | `Room.lastMessages` in Equatable props | `room.dart` | Medium — O(n*m) equality checks | Low |
| 4 | `MatchText` no `Equatable` | `match_text.dart` | Low-Medium — `ParsedText` cannot short-circuit | Low |
| 5 | `MessageCacheManager` returns stale widgets | `message_cache_manager.dart` | Medium — wrong status icons after updates | Low |
| 6 | `RegExp` recompiled on every keystroke | `input_text_field_controller.dart` | Medium — 0.5–2 ms per keystroke on low-end | Low |
| 7 | `ImageStream` listener leak | `image_message.dart` | High — "setState after dispose" crash | Low |
| 8 | Isolate overhead > work being done | `optimized_chat_list.dart` | Medium — 2–20 ms overhead for 0.1 ms work | Medium |
