import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';
import 'package:chat_message_ui_kit/src/models/preview_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TextMessageModel', () {
    const testUser = ChatUser(id: 'user123', firstName: 'John');

    test('creates text message with required fields', () {
      const message = TextMessageModel(
        author: testUser,
        id: 'msg123',
        text: 'Hello world!',
      );

      expect(message.author, equals(testUser));
      expect(message.id, equals('msg123'));
      expect(message.text, equals('Hello world!'));
      expect(message.type, equals(MessageType.text));
      expect(message.previewData, isNull);
      expect(message.status, isNull);
      expect(message.createdAt, isNull);
    });

    test('creates text message with all fields', () {
      final createdAt = DateTime.now().millisecondsSinceEpoch;
      final previewData = const PreviewData(
        title: 'Example Title',
        description: 'Example description',
        link: 'https://example.com',
      );

      final message = TextMessageModel(
        author: testUser,
        id: 'msg123',
        text: 'Check out this link: https://example.com',
        status: Status.sent,
        createdAt: createdAt,
        previewData: previewData,
        roomId: 'room456',
        showStatus: true,
      );

      expect(message.text, equals('Check out this link: https://example.com'));
      expect(message.status, equals(Status.sent));
      expect(message.createdAt, equals(createdAt));
      expect(message.previewData, equals(previewData));
      expect(message.roomId, equals('room456'));
      expect(message.showStatus, isTrue);
    });

    test('equality works correctly', () {
      const message1 = TextMessageModel(
        author: testUser,
        id: 'msg123',
        text: 'Hello world!',
      );

      const message2 = TextMessageModel(
        author: testUser,
        id: 'msg123',
        text: 'Hello world!',
      );

      const message3 = TextMessageModel(
        author: testUser,
        id: 'msg456',
        text: 'Hello world!',
      );

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });

    test('JSON serialization works', () {
      final previewData = const PreviewData(
        title: 'Example Title',
        link: 'https://example.com',
      );

      final message = TextMessageModel(
        author: testUser,
        id: 'msg123',
        text: 'Hello world!',
        status: Status.sent,
        createdAt: 1640995200000,
        previewData: previewData,
      );

      final json = message.toJson();
      final fromJson = TextMessageModel.fromJson(json);

      expect(fromJson.id, equals(message.id));
      expect(fromJson.text, equals(message.text));
      expect(fromJson.status, equals(message.status));
      expect(fromJson.createdAt, equals(message.createdAt));
      expect(fromJson.author.id, equals(message.author.id));
    });

    test('copyWith works correctly', () {
      const originalMessage = TextMessageModel(
        author: testUser,
        id: 'msg123',
        text: 'Original text',
        status: Status.sending,
      );

      final updatedMessage =
          originalMessage.copyWith(text: 'Updated text', status: Status.sent)
              as TextMessageModel;

      expect(updatedMessage.text, equals('Updated text'));
      expect(updatedMessage.status, equals(Status.sent));
      expect(updatedMessage.id, equals(originalMessage.id));
      expect(updatedMessage.author, equals(originalMessage.author));
    });

    test('copyWith with null values preserves original', () {
      const originalMessage = TextMessageModel(
        author: testUser,
        id: 'msg123',
        text: 'Original text',
        status: Status.sent,
      );

      final updatedMessage = originalMessage.copyWith();

      expect(updatedMessage, equals(originalMessage));
    });

    test('fromPartial creates TextMessageModel from PartialTextModel', () {
      const partialText = PartialTextModel(text: 'Hello world!');

      final message = TextMessageModel.fromPartial(
        author: testUser,
        id: 'msg123',
        partialText: partialText,
      );

      expect(message, isA<TextMessageModel>());
      expect(message.text, equals('Hello world!'));
      expect(message.author, equals(testUser));
      expect(message.id, equals('msg123'));
    });
  });
}
