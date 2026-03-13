import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _buildInput({void Function(PartialTextModel)? onSendPressed}) {
  return MaterialApp(
    home: Scaffold(
      body: Chat(
        messages: const [],
        onSendPressed: onSendPressed ?? (_) {},
        user: const ChatUser(id: 'user1'),
      ),
    ),
  );
}

void main() {
  group('Input widget', () {
    testWidgets('send button is hidden when text field is empty',
        (tester) async {
      await tester.pumpWidget(_buildInput());
      await tester.pump();

      // The send button should not be visible when input is empty.
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('send button appears after typing text', (tester) async {
      await tester.pumpWidget(_buildInput());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();

      expect(find.byIcon(Icons.send), findsOneWidget);
    });

    testWidgets('send button disappears when text is cleared', (tester) async {
      await tester.pumpWidget(_buildInput());
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.pump();
      expect(find.byIcon(Icons.send), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('whitespace-only text does not show send button',
        (tester) async {
      await tester.pumpWidget(_buildInput());
      await tester.pump();

      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump();

      expect(find.byIcon(Icons.send), findsNothing);
    });

    testWidgets('onSendPressed is called with trimmed text', (tester) async {
      PartialTextModel? received;
      await tester.pumpWidget(_buildInput(onSendPressed: (m) => received = m));
      await tester.pump();

      await tester.enterText(find.byType(TextField), ' Hello ');
      await tester.pump();

      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();

      expect(received, isNotNull);
      expect(received!.text, equals('Hello'));
    });
  });
}
