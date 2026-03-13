import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ImageMessageModel', () {
    const testUser = ChatUser(id: 'user123', firstName: 'John');

    test('creates image message with required fields', () {
      const message = ImageMessageModel(
        author: testUser,
        id: 'img123',
        name: 'image.jpg',
        size: 1024000,
        uri: 'https://example.com/image.jpg',
        width: 1920,
        height: 1080,
      );

      expect(message.author, equals(testUser));
      expect(message.id, equals('img123'));
      expect(message.name, equals('image.jpg'));
      expect(message.size, equals(1024000));
      expect(message.uri, equals('https://example.com/image.jpg'));
      expect(message.width, equals(1920));
      expect(message.height, equals(1080));
      expect(message.type, equals(MessageType.image));
    });

    test('creates image message with all fields', () {
      final createdAt = DateTime.now().millisecondsSinceEpoch;

      final message = ImageMessageModel(
        author: testUser,
        id: 'img123',
        name: 'vacation_photo.jpg',
        size: 2048000,
        uri: 'https://example.com/vacation_photo.jpg',
        width: 3840,
        height: 2160,
        status: Status.delivered,
        createdAt: createdAt,
        roomId: 'room456',
        showStatus: true,
      );

      expect(message.name, equals('vacation_photo.jpg'));
      expect(message.size, equals(2048000));
      expect(message.status, equals(Status.delivered));
      expect(message.createdAt, equals(createdAt));
      expect(message.roomId, equals('room456'));
      expect(message.showStatus, isTrue);
      expect(message.width, equals(3840));
      expect(message.height, equals(2160));
    });

    test('equality works correctly', () {
      const message1 = ImageMessageModel(
        author: testUser,
        id: 'img123',
        name: 'image.jpg',
        size: 1024000,
        uri: 'https://example.com/image.jpg',
        width: 1920,
        height: 1080,
      );

      const message2 = ImageMessageModel(
        author: testUser,
        id: 'img123',
        name: 'image.jpg',
        size: 1024000,
        uri: 'https://example.com/image.jpg',
        width: 1920,
        height: 1080,
      );

      const message3 = ImageMessageModel(
        author: testUser,
        id: 'img456',
        name: 'image.jpg',
        size: 1024000,
        uri: 'https://example.com/image.jpg',
        width: 1920,
        height: 1080,
      );

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });

    test('JSON serialization works', () {
      const message = ImageMessageModel(
        author: testUser,
        id: 'img123',
        name: 'test_image.png',
        size: 512000,
        uri: 'https://example.com/test_image.png',
        width: 800,
        height: 600,
        status: Status.seen,
        createdAt: 1640995200000,
      );

      final json = message.toJson();
      final fromJson = ImageMessageModel.fromJson(json);

      expect(fromJson.id, equals(message.id));
      expect(fromJson.name, equals(message.name));
      expect(fromJson.size, equals(message.size));
      expect(fromJson.uri, equals(message.uri));
      expect(fromJson.width, equals(message.width));
      expect(fromJson.height, equals(message.height));
      expect(fromJson.status, equals(message.status));
      expect(fromJson.createdAt, equals(message.createdAt));
      expect(fromJson.author.id, equals(message.author.id));
    });

    test('copyWith works correctly', () {
      const originalMessage = ImageMessageModel(
        author: testUser,
        id: 'img123',
        name: 'old_name.jpg',
        size: 1024000,
        uri: 'https://example.com/old_image.jpg',
        width: 1920,
        height: 1080,
        status: Status.sending,
      );

      final updatedMessage =
          originalMessage.copyWith(
                name: 'new_name.jpg',
                uri: 'https://example.com/new_image.jpg',
                status: Status.delivered,
              )
              as ImageMessageModel;

      expect(updatedMessage.name, equals('new_name.jpg'));
      expect(updatedMessage.uri, equals('https://example.com/new_image.jpg'));
      expect(updatedMessage.status, equals(Status.delivered));
      expect(updatedMessage.id, equals(originalMessage.id));
      expect(updatedMessage.size, equals(originalMessage.size));
      expect(updatedMessage.width, equals(originalMessage.width));
      expect(updatedMessage.height, equals(originalMessage.height));
    });

    test('fromPartial creates ImageMessageModel from PartialImageModel', () {
      const partialImage = PartialImageModel(
        name: 'image.jpg',
        size: 1024000,
        uri: 'https://example.com/image.jpg',
        width: 1920,
        height: 1080,
      );

      final message = ImageMessageModel.fromPartial(
        author: testUser,
        id: 'img123',
        partialImage: partialImage,
      );

      expect(message, isA<ImageMessageModel>());
      expect(message.name, equals('image.jpg'));
      expect(message.size, equals(1024000));
      expect(message.uri, equals('https://example.com/image.jpg'));
      expect(message.width, equals(1920));
      expect(message.height, equals(1080));
    });
  });
}
