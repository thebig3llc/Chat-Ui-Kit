import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chat Widget', () {
    const testUser = ChatUser(id: 'user123', firstName: 'John');
    const anotherUser = ChatUser(id: 'user456', firstName: 'Jane');

    testWidgets('renders empty state when no messages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Chat(messages: const [], onSendPressed: (_) {}, user: testUser),
        ),
      );

      expect(find.text('No messages here yet'), findsOneWidget);
    });

    testWidgets('renders single text message', (tester) async {
      const message = TextMessageModel(
        author: anotherUser,
        id: 'msg123',
        text: 'Hello world!',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: [message],
            onSendPressed: (_) {},
            user: testUser,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Hello world!'), findsOneWidget);
    });

    testWidgets('renders multiple messages', (tester) async {
      const messages = [
        TextMessageModel(
          author: testUser,
          id: 'msg1',
          text: 'Hello!',
          createdAt: 1640995200000,
        ),
        TextMessageModel(
          author: anotherUser,
          id: 'msg2',
          text: 'Hi there!',
          createdAt: 1640995260000,
        ),
        TextMessageModel(
          author: testUser,
          id: 'msg3',
          text: 'How are you?',
          createdAt: 1640995320000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(messages: messages, onSendPressed: (_) {}, user: testUser),
        ),
      );

      await tester.pump();

      expect(find.text('Hello!'), findsOneWidget);
      expect(find.text('Hi there!'), findsOneWidget);
      expect(find.text('How are you?'), findsOneWidget);
    });

    testWidgets('renders image message', (tester) async {
      const message = ImageMessageModel(
        author: anotherUser,
        id: 'img123',
        name: 'test_image.jpg',
        size: 1024000,
        uri: 'https://example.com/test_image.jpg',
        width: 800,
        height: 600,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: [message],
            onSendPressed: (_) {},
            user: testUser,
          ),
        ),
      );

      await tester.pump();

      // Should find image widget
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('shows user avatars when enabled', (tester) async {
      const message = TextMessageModel(
        author: anotherUser,
        id: 'msg123',
        text: 'Hello with avatar!',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: [message],
            onSendPressed: (_) {},
            user: testUser,
            showUserAvatars: true,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Hello with avatar!'), findsOneWidget);
      // Should find avatar widget
      expect(find.byType(CircleAvatar), findsWidgets);
    });

    testWidgets('shows user names when enabled', (tester) async {
      const message = TextMessageModel(
        author: anotherUser,
        id: 'msg123',
        text: 'Hello with name!',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: [message],
            onSendPressed: (_) {},
            user: testUser,
            showUserNames: true,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Hello with name!'), findsOneWidget);
      expect(find.text('Jane'), findsOneWidget);
    });

    testWidgets('has input widget at bottom', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Chat(messages: const [], onSendPressed: (_) {}, user: testUser),
        ),
      );

      // Should find input text field
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('calls onSendPressed when message sent', (tester) async {
      PartialTextModel? sentMessage;

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: const [],
            onSendPressed: (message) {
              sentMessage = message;
            },
            user: testUser,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();

      expect(sentMessage, isNotNull);
      expect(sentMessage!.text, equals('Test message'));
    });

    testWidgets('applies custom theme', (tester) async {
      const customTheme = DefaultChatTheme(primaryColor: Colors.purple);

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: const [],
            onSendPressed: (_) {},
            user: testUser,
            theme: customTheme,
          ),
        ),
      );

      await tester.pump();

      // Widget should be built without errors with custom theme
      expect(find.byType(Chat), findsOneWidget);
    });

    testWidgets('handles empty text input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: const [],
            onSendPressed: (_) {},
            user: testUser,
            inputOptions: const InputOptions(
              sendButtonVisibilityMode: SendButtonVisibilityMode.always,
            ),
          ),
        ),
      );

      await tester.pump();

      // Send button should be visible even with empty text
      expect(find.byType(SendButton), findsOneWidget);

      // Try to send empty message
      await tester.tap(find.byType(SendButton));
      await tester.pump();

      // Should not crash and input should remain empty
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('displays typing indicator when enabled', (tester) async {
      const typingUsers = [
        ChatUser(id: 'typing1', firstName: 'Alice'),
        ChatUser(id: 'typing2', firstName: 'Bob'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: const [
              TextMessageModel(
                author: testUser,
                id: 'msg1',
                text: 'Test message',
              ),
            ],
            onSendPressed: (_) {},
            user: testUser,
            typingIndicatorOptions: const TypingIndicatorOptions(
              typingUsers: typingUsers,
            ),
          ),
        ),
      );

      // Use pump instead of pumpAndSettle since TypingIndicator has continuous animations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should find typing indicator
      expect(find.byType(TypingIndicator), findsOneWidget);
    });
  });
}
