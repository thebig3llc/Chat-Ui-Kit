import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('contains image message', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Chat(
            messages: const [
              ImageMessageModel(
                author: ChatUser(id: '123'),
                height: 1080,
                id: 'id',
                name: 'image',
                size: 100,
                uri: 'image',
                width: 1920,
              ),
            ],
            onSendPressed: (p0) {},
            user: const ChatUser(id: '123'),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(ImageMessage), findsOneWidget);
  });
}
