import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chat Integration Tests', () {
    const testUser = ChatUser(id: 'user123', firstName: 'John');
    const anotherUser = ChatUser(id: 'user456', firstName: 'Jane');

    testWidgets('Complete chat flow - send and display messages', (
      tester,
    ) async {
      final List<MessageModel> messages = [];

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: messages,
            onSendPressed: (partialMessage) {
              messages.add(
                TextMessageModel(
                  author: testUser,
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  text: partialMessage.text,
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                ),
              );
            },
            user: testUser,
          ),
        ),
      );

      // Initial state should show empty chat
      expect(find.text('No messages here yet'), findsOneWidget);

      // Type a message
      await tester.enterText(find.byType(TextField), 'Hello world!');
      await tester.pump();

      // Send the message
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();

      // Verify message was added (though not displayed due to rebuild needed)
      expect(messages, hasLength(1));
      expect((messages.first as TextMessageModel).text, equals('Hello world!'));
    });

    testWidgets('Displays existing messages correctly', (tester) async {
      final messages = [
        const TextMessageModel(
          author: testUser,
          id: 'msg1',
          text: 'First message',
          createdAt: 1640995200000,
        ),
        const TextMessageModel(
          author: anotherUser,
          id: 'msg2',
          text: 'Second message',
          createdAt: 1640995260000,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: messages,
            onSendPressed: (_) {},
            user: testUser,
            showUserNames: true,
          ),
        ),
      );

      await tester.pump();

      // Check both messages are displayed
      expect(find.text('First message'), findsOneWidget);
      expect(find.text('Second message'), findsOneWidget);

      // Check user name is shown for received message
      expect(find.text('Jane'), findsOneWidget);
    });

    testWidgets('Handles different message types', (tester) async {
      final messages = [
        const TextMessageModel(
          author: testUser,
          id: 'text1',
          text: 'Text message',
        ),
        const ImageMessageModel(
          author: anotherUser,
          id: 'img1',
          name: 'photo.jpg',
          size: 1024000,
          uri: 'https://example.com/photo.jpg',
          width: 800,
          height: 600,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(messages: messages, onSendPressed: (_) {}, user: testUser),
        ),
      );

      await tester.pump();

      // Text message should be displayed
      expect(find.text('Text message'), findsOneWidget);

      // Image should be rendered
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('Applies theme correctly', (tester) async {
      const customTheme = DefaultChatTheme(
        primaryColor: Colors.red,
        backgroundColor: Colors.grey,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: const [
              TextMessageModel(
                author: testUser,
                id: 'msg1',
                text: 'Themed message',
              ),
            ],
            onSendPressed: (_) {},
            user: testUser,
            theme: customTheme,
          ),
        ),
      );

      await tester.pump();

      // Message should be displayed
      expect(find.text('Themed message'), findsOneWidget);

      // Widget should build without errors with custom theme
      expect(find.byType(Chat), findsOneWidget);
    });

    testWidgets('Input validation and empty message handling', (tester) async {
      var messageCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(
            messages: const [],
            onSendPressed: (_) {
              messageCount++;
            },
            user: testUser,
          ),
        ),
      );

      // Try to send empty message
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();

      // Should not send empty message
      expect(messageCount, equals(0));

      // Type whitespace only
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();

      // Should not send whitespace-only message
      expect(messageCount, equals(0));

      // Type actual message
      await tester.enterText(find.byType(TextField), 'Real message');
      await tester.tap(find.byType(IconButton).last);
      await tester.pump();

      // Should send real message
      expect(messageCount, equals(1));
    });

    testWidgets('Message status display', (tester) async {
      final messages = [
        const TextMessageModel(
          author: testUser,
          id: 'msg1',
          text: 'Sent message',
          status: Status.sent,
        ),
        const TextMessageModel(
          author: testUser,
          id: 'msg2',
          text: 'Delivered message',
          status: Status.delivered,
        ),
        const TextMessageModel(
          author: testUser,
          id: 'msg3',
          text: 'Seen message',
          status: Status.seen,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(messages: messages, onSendPressed: (_) {}, user: testUser),
        ),
      );

      await tester.pump();

      // All messages should be displayed
      expect(find.text('Sent message'), findsOneWidget);
      expect(find.text('Delivered message'), findsOneWidget);
      expect(find.text('Seen message'), findsOneWidget);

      // Status icons should be present
      expect(find.byType(Icon), findsWidgets);
    });

    testWidgets('Large message list performance', (tester) async {
      final messages = List.generate(
        50,
        (index) => TextMessageModel(
          author: index % 2 == 0 ? testUser : anotherUser,
          id: 'msg_$index',
          text: 'Message $index',
          createdAt: 1640995200000 + (index * 60000),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Chat(messages: messages, onSendPressed: (_) {}, user: testUser),
        ),
      );

      await tester.pump();

      // Should handle large lists without crashing
      expect(find.byType(Chat), findsOneWidget);

      // Scroll to test performance
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pump();

      // Should still be functional
      expect(find.byType(Chat), findsOneWidget);
    });
  });
}
