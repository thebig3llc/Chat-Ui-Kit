import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';
import 'package:chat_message_ui_kit/src/utils/functions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('getUserInitials', () {
    test('returns initials from first and last name', () {
      const user = ChatUser(id: '1', firstName: 'John', lastName: 'Doe');
      expect(getUserInitials(user), equals('JD'));
    });

    test('returns only first initial when lastName is null', () {
      const user = ChatUser(id: '1', firstName: 'Alice');
      expect(getUserInitials(user), equals('A'));
    });

    test('returns only last initial when firstName is null', () {
      const user = ChatUser(id: '1', lastName: 'Smith');
      expect(getUserInitials(user), equals('S'));
    });

    test('returns empty string when both names are null', () {
      const user = ChatUser(id: '1');
      expect(getUserInitials(user), equals(''));
    });

    test('returns empty string when both names are empty strings', () {
      const user = ChatUser(id: '1', firstName: '', lastName: '');
      expect(getUserInitials(user), equals(''));
    });

    test('uppercases initials from lowercase names', () {
      const user = ChatUser(id: '1', firstName: 'alice', lastName: 'smith');
      expect(getUserInitials(user), equals('AS'));
    });
  });

  group('consistsOfEmojis', () {
    TextMessageModel makeMsg(String text) => TextMessageModel(
          author: const ChatUser(id: '1'),
          createdAt: 0,
          id: 'test',
          text: text,
        );

    test('single emoji matches single mode', () {
      expect(
        consistsOfEmojis(EmojiEnlargementBehavior.single, makeMsg('😀')),
        isTrue,
      );
    });

    test('multiple emojis match multi mode', () {
      expect(
        consistsOfEmojis(EmojiEnlargementBehavior.multi, makeMsg('😀😂🎉')),
        isTrue,
      );
    });

    test('multiple emojis do NOT match single mode', () {
      expect(
        consistsOfEmojis(EmojiEnlargementBehavior.single, makeMsg('😀😂')),
        isFalse,
      );
    });

    test('mixed text and emoji does not match', () {
      expect(
        consistsOfEmojis(EmojiEnlargementBehavior.multi, makeMsg('Hello 😀')),
        isFalse,
      );
    });

    test('plain text does not match', () {
      expect(
        consistsOfEmojis(
          EmojiEnlargementBehavior.multi,
          makeMsg('Hello world'),
        ),
        isFalse,
      );
    });

    test('returns false when text is emoji mixed with regular text', () {
      // The regex requires the entire string to be emoji characters.
      // Callers are responsible for not invoking with EmojiEnlargementBehavior.never.
      expect(
        consistsOfEmojis(EmojiEnlargementBehavior.multi, makeMsg('Hello 😀')),
        isFalse,
      );
    });
  });
}
