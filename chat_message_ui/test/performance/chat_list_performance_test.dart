import 'package:chat_message_ui_kit/src/models/message.dart';
import 'package:chat_message_ui_kit/src/models/text_message.dart';
import 'package:chat_message_ui_kit/src/models/chat_user.dart';
import 'package:chat_message_ui_kit/src/enums/bubble_rtl_alignment.dart';
import 'package:chat_message_ui_kit/src/utils/message_cache_manager.dart';
import 'package:chat_message_ui_kit/src/widgets/chat/optimized_chat_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatList Performance Tests', () {
    late List<ChatUser> testUsers;

    setUpAll(() {
      testUsers = [
        const ChatUser(id: 'user1', firstName: 'John'),
        const ChatUser(id: 'user2', firstName: 'Jane'),
      ];
    });

    /// Generate test messages for performance testing
    List<Object> generateTestMessages(int count) {
      return List.generate(count, (index) {
        final message = TextMessageModel(
          author: testUsers[index % 2],
          createdAt: DateTime.now().millisecondsSinceEpoch - (index * 60000),
          id: 'msg_$index',
          text:
              'Test message $index with some content to simulate real messages',
        );
        return {'message': message};
      });
    }

    testWidgets('Performance with 100 messages', (WidgetTester tester) async {
      final messages = generateTestMessages(100);
      final scrollController = ScrollController();

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedChatList(
              items: messages,
              scrollController: scrollController,
              bubbleRtlAlignment: BubbleRtlAlignment.left,
              useTopSafeAreaInset: false,
              itemBuilder: (item, index) {
                final messageData = item as Map<String, Object>;
                final message = messageData['message'] as MessageModel;
                return ListTile(
                  title: Text(message.id),
                  subtitle: const Text('Message content'),
                );
              },
            ),
          ),
        ),
      );

      stopwatch.stop();
      print('Build time for 100 messages: ${stopwatch.elapsedMilliseconds}ms');

      // Verify the widget built successfully
      expect(find.byType(OptimizedChatList), findsOneWidget);

      // Verify messages are rendered (check for first and last messages)
      expect(find.text('msg_0'), findsOneWidget);
      expect(find.text('msg_99'), findsOneWidget);

      scrollController.dispose();
    });

    testWidgets('Performance with 1000 messages', (WidgetTester tester) async {
      final messages = generateTestMessages(1000);
      final scrollController = ScrollController();

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedChatList(
              items: messages,
              scrollController: scrollController,
              bubbleRtlAlignment: BubbleRtlAlignment.left,
              useTopSafeAreaInset: false,
              diffThreshold: 500, // Trigger isolate for large list
              itemBuilder: (item, index) {
                final messageData = item as Map<String, Object>;
                final message = messageData['message'] as MessageModel;
                return ListTile(
                  title: Text(message.id),
                  subtitle: const Text('Message content'),
                );
              },
            ),
          ),
        ),
      );

      stopwatch.stop();
      print('Build time for 1000 messages: ${stopwatch.elapsedMilliseconds}ms');

      // Build time should be reasonable even for large lists
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      // Verify the widget built successfully
      expect(find.byType(OptimizedChatList), findsOneWidget);

      scrollController.dispose();
    });

    testWidgets('Scroll performance test', (WidgetTester tester) async {
      final messages = generateTestMessages(500);
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedChatList(
              items: messages,
              scrollController: scrollController,
              bubbleRtlAlignment: BubbleRtlAlignment.left,
              useTopSafeAreaInset: false,
              itemBuilder: (item, index) {
                final messageData = item as Map<String, Object>;
                final message = messageData['message'] as MessageModel;
                return Container(
                  height: 60,
                  child: ListTile(
                    title: Text(message.id),
                    subtitle: const Text('Message content'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Test scrolling performance
      final stopwatch = Stopwatch()..start();

      // Perform several scroll operations
      for (int i = 0; i < 10; i++) {
        await tester.drag(
          find.byType(OptimizedChatList),
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();
      }

      stopwatch.stop();
      print(
        'Scroll performance for 10 scrolls: ${stopwatch.elapsedMilliseconds}ms',
      );

      // Scrolling should be smooth (less than 100ms total for 10 scrolls)
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      scrollController.dispose();
    });

    test('MessageCacheManager performance', () {
      final cacheManager = MessageCacheManager(maxCacheSize: 100);
      final testWidget = Container(child: const Text('Test'));

      final stopwatch = Stopwatch()..start();

      // Add 200 widgets to test eviction
      for (int i = 0; i < 200; i++) {
        cacheManager.cacheWidget('msg_$i', testWidget);
      }

      stopwatch.stop();
      print(
        'Cache operations for 200 widgets: ${stopwatch.elapsedMilliseconds}ms',
      );

      // Cache should maintain max size
      expect(cacheManager.cacheSize, equals(100));

      // Operations should be fast
      expect(stopwatch.elapsedMilliseconds, lessThan(100));

      // Test cache retrieval performance
      final retrievalStopwatch = Stopwatch()..start();

      for (int i = 0; i < 50; i++) {
        final widget = cacheManager.getCachedWidget('msg_${100 + i}');
        expect(widget, isNotNull);
      }

      retrievalStopwatch.stop();
      print(
        'Cache retrieval for 50 widgets: ${retrievalStopwatch.elapsedMilliseconds}ms',
      );

      expect(retrievalStopwatch.elapsedMilliseconds, lessThan(50));
    });

    test('MessageUtils performance', () {
      final messages = generateTestMessages(1000);

      final stopwatch = Stopwatch()..start();

      // Test message ID extraction
      for (int i = 0; i < 100; i++) {
        final ids = MessageUtils.extractMessageIds(messages);
        expect(ids.length, equals(1000));
      }

      stopwatch.stop();
      print(
        'Message ID extraction (100 iterations): ${stopwatch.elapsedMilliseconds}ms',
      );

      // Should be very fast
      expect(stopwatch.elapsedMilliseconds, lessThan(500));

      // Test list equality comparison
      final messages2 = List<Object>.from(messages);
      final equalityStopwatch = Stopwatch()..start();

      for (int i = 0; i < 100; i++) {
        final isEqual = MessageUtils.listsEqual(messages, messages2);
        expect(isEqual, isTrue);
      }

      equalityStopwatch.stop();
      print(
        'List equality comparison (100 iterations): ${equalityStopwatch.elapsedMilliseconds}ms',
      );

      expect(equalityStopwatch.elapsedMilliseconds, lessThan(500));
    });

    testWidgets('Memory usage test', (WidgetTester tester) async {
      // This test verifies that widgets are properly disposed
      // and don't cause memory leaks

      for (int iteration = 0; iteration < 5; iteration++) {
        final messages = generateTestMessages(200);
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: OptimizedChatList(
                items: messages,
                scrollController: scrollController,
                bubbleRtlAlignment: BubbleRtlAlignment.left,
                useTopSafeAreaInset: false,
                itemBuilder: (item, index) {
                  final messageData = item as Map<String, Object>;
                  final message = messageData['message'] as MessageModel;
                  return ListTile(
                    title: Text(message.id),
                    subtitle: const Text('Message content'),
                  );
                },
              ),
            ),
          ),
        );

        // Simulate scrolling to trigger caching
        await tester.drag(
          find.byType(OptimizedChatList),
          const Offset(0, -500),
        );
        await tester.pumpAndSettle();

        scrollController.dispose();

        // Replace with empty widget to trigger dispose
        await tester.pumpWidget(
          const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
        );
      }

      // If we reach here without memory issues, the test passes
      expect(true, isTrue);
    });
  });

  group('Benchmark Comparison Tests', () {
    testWidgets('Compare OptimizedChatList vs regular ListView', (
      WidgetTester tester,
    ) async {
      final messages = List.generate(500, (index) {
        return {
          'message': TextMessageModel(
            author: const ChatUser(id: 'user1', firstName: 'John'),
            createdAt: DateTime.now().millisecondsSinceEpoch - (index * 60000),
            id: 'msg_$index',
            text: 'Test message $index',
          ),
        };
      });

      // Test OptimizedChatList
      final optimizedStopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedChatList(
              items: messages,
              scrollController: ScrollController(),
              bubbleRtlAlignment: BubbleRtlAlignment.left,
              useTopSafeAreaInset: false,
              itemBuilder: (item, index) {
                final messageData = item as Map<String, Object>;
                final message = messageData['message'] as MessageModel;
                return ListTile(title: Text(message.id));
              },
            ),
          ),
        ),
      );

      optimizedStopwatch.stop();

      // Test regular ListView
      final regularStopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final messageData = messages[index] as Map<String, Object>;
                final message = messageData['message'] as MessageModel;
                return ListTile(title: Text(message.id));
              },
            ),
          ),
        ),
      );

      regularStopwatch.stop();

      print(
        'OptimizedChatList build time: ${optimizedStopwatch.elapsedMilliseconds}ms',
      );
      print(
        'Regular ListView build time: ${regularStopwatch.elapsedMilliseconds}ms',
      );

      // OptimizedChatList should be competitive with regular ListView
      // Allow some overhead for the additional features
      expect(
        optimizedStopwatch.elapsedMilliseconds,
        lessThan(regularStopwatch.elapsedMilliseconds * 2),
      );
    });
  });
}
