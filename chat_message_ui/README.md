<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

A comprehensive Flutter package for building chat and messaging UIs. Provides customizable message bubbles, input components, image galleries, and URL preview support with built-in performance optimizations for handling large message lists.

## Features

- **Multiple Message Types**: Text, image, audio, and video messages with status indicators
- **Rich Input Component**: Attachment button, send button, customizable input modes and visibility
- **URL Previews**: Automatic link detection and preview generation with caching
- **Image Gallery**: Zoomable, pannable image viewer with memory optimizations
- **Performance Optimized**: Diff-based rendering, lazy loading, and efficient list updates for 1000+ messages
- **Customizable Theming**: Comprehensive `ChatTheme` system for full UI customization
- **Internationalization**: Built-in `ChatL10n` for multi-language support
- **Platform Support**: Cross-platform (iOS, Android, Web) with platform-specific optimizations
- **Emoji Support**: Smart emoji enlargement and rendering
- **Accessibility**: ARIA support and semantic widgets

## Getting started

** Installation: **

Add to your `pubspec.yaml`:
```yaml
dependencies:
  chat_message_ui_kit: ^0.0.2
```
Then run:
flutter pub get

## Usage

** Basic Example: **

```dart
import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';

class MyChatScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = ChatUser(id: 'user1', firstName: 'John');
    final messages = [
      TextMessage(
        id: 'msg1',
        author: user,
        text: 'Hello!',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    return Chat(
      messages: messages,
      onSendPressed: (PartialTextMessage message) {
        // Handle sending message
      },
      user: user,
    );
  }
}
``` 

With Custom Theme:
```dart
Chat(
  messages: messages,
  onSendPressed: onSend,
  user: user,
  theme: const DefaultChatTheme(
    primaryColor: Colors.blue,
    secondaryColor: Colors.grey,
  ),
)
Performance Optimized for Large Lists:
PerformanceOptimizedChat(
  messages: largeMessageList, // 1000+ messages
  onSendPressed: onSend,
  user: user,
)
```
See the /example folder for complete working examples.


## Additional information

```markdown
**Documentation:**
- Full API documentation: [pub.dev/documentation/chat_message_ui_kit](https://pub.dev/documentation/chat_message_ui_kit)
- Example app source: [`/example`](https://github.com/thebig3llc/Chat-Message-Ui-Kit/tree/main/chat_message_ui_kit/example)

**Contributing:**
Contributions are welcome! Please file issues and pull requests on the [GitHub repository](https://github.com/thebig3llc/Chat-Message-Ui-Kit).

**Support:**
- File issues: [GitHub Issues](https://github.com/thebig3llc/Chat-Message-Ui-Kit/issues)
- Package developed and maintained by [The Big 3]

**License:** MIT
```