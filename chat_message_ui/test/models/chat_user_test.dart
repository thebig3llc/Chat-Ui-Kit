import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatUser', () {
    test('creates user with required id', () {
      const user = ChatUser(id: 'user123');

      expect(user.id, equals('user123'));
      expect(user.firstName, isNull);
      expect(user.lastName, isNull);
      expect(user.imageUrl, isNull);
      expect(user.createdAt, isNull);
    });

    test('creates user with all fields', () {
      const user = ChatUser(
        id: 'user123',
        firstName: 'John',
        lastName: 'Doe',
        imageUrl: 'https://example.com/avatar.jpg',
        createdAt: 1640995200000,
      );

      expect(user.id, equals('user123'));
      expect(user.firstName, equals('John'));
      expect(user.lastName, equals('Doe'));
      expect(user.imageUrl, equals('https://example.com/avatar.jpg'));
      expect(user.createdAt, equals(1640995200000));
    });

    test('equality works correctly', () {
      const user1 = ChatUser(id: 'user123', firstName: 'John');
      const user2 = ChatUser(id: 'user123', firstName: 'John');
      const user3 = ChatUser(id: 'user456', firstName: 'John');

      expect(user1, equals(user2));
      expect(user1, isNot(equals(user3)));
    });

    test('JSON serialization works', () {
      const user = ChatUser(
        id: 'user123',
        firstName: 'John',
        lastName: 'Doe',
        imageUrl: 'https://example.com/avatar.jpg',
        createdAt: 1640995200000,
      );

      final json = user.toJson();
      final fromJson = ChatUser.fromJson(json);

      expect(fromJson, equals(user));
      expect(json['id'], equals('user123'));
      expect(json['firstName'], equals('John'));
      expect(json['lastName'], equals('Doe'));
      expect(json['imageUrl'], equals('https://example.com/avatar.jpg'));
      expect(json['createdAt'], equals(1640995200000));
    });

    test('JSON serialization handles null values', () {
      const user = ChatUser(id: 'user123');

      final json = user.toJson();
      final fromJson = ChatUser.fromJson(json);

      expect(fromJson, equals(user));
      expect(json['id'], equals('user123'));
      expect(json.containsKey('firstName'), isFalse);
      expect(json.containsKey('lastName'), isFalse);
      expect(json.containsKey('imageUrl'), isFalse);
      expect(json.containsKey('createdAt'), isFalse);
    });

    test('props includes all fields for equality', () {
      const user = ChatUser(
        id: 'user123',
        firstName: 'John',
        lastName: 'Doe',
        imageUrl: 'https://example.com/avatar.jpg',
        createdAt: 1640995200000,
      );

      expect(user.props, contains('user123'));
      expect(user.props, contains('John'));
      expect(user.props, contains('Doe'));
      expect(user.props, contains('https://example.com/avatar.jpg'));
      expect(user.props, contains(1640995200000));
    });
  });
}
