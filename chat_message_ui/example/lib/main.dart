import 'package:example/chats.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

/// Flutter App Messaging UI - Complete Example
///
/// This example demonstrates the full capabilities of the app_messaging_ui package.
/// It includes multiple chat rooms with different message types and demonstrates
/// performance with 100+ messages in one chat.
///
/// Features demonstrated:
/// - Multiple chat rooms with navigation
/// - Text messages with emoji and formatting support
/// - Image messages with gallery view
/// - File attachments
/// - User avatars and status indicators
/// - High-performance chat list handling 100+ messages
/// - Custom theming and styling options
/// - Message status indicators (sent, delivered, seen)
/// - Real-time message updates
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Messaging UI Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // Custom theme to showcase theming capabilities
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ChatListScreen(),
    );
  }
}

/// Main screen showing available chat rooms
///
/// This demonstrates how to implement a chat list interface where users
/// can select different conversations. Each chat room has different
/// characteristics to showcase various features of the messaging UI.
class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  Map<String, dynamic>? chatData;
  Map<String, dynamic> users = {};

  @override
  void initState() {
    super.initState();
    _loadChatData();
  }

  /// Load chat data from assets
  ///
  /// The messages.json file contains structured data for multiple chat rooms:
  /// - travel-planning: Small chat with various message types
  /// - project-discussion: Work chat with professional conversations
  /// - large-performance-test: 120+ messages to demonstrate performance
  Future<void> _loadChatData() async {
    try {
      final response = await rootBundle.loadString('assets/messages.json');
      final data = jsonDecode(response) as Map<String, dynamic>;

      setState(() {
        chatData = data;
        users = data['users'] as Map<String, dynamic>;
      });
    } catch (e) {
      // Handle loading error
      debugPrint('Error loading chat data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (chatData == null) {
      // Loading state - you can customize this
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chats = chatData!['chats'] as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: Column(
        children: [
          // Header with example information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'App Messaging UI Package Demo',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Explore different chat features:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Travel Planning: Images, files, and emoji messages\n'
                  '• Project Discussion: Professional work conversation\n'
                  '• Performance Test: 120+ messages for performance demo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Chat rooms list
          Expanded(
            child: ListView.separated(
              itemCount: chats.keys.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, index) {
                final chatId = chats.keys.elementAt(index);
                final chat = chats[chatId] as Map<String, dynamic>;
                final messages = chat['messages'] as List<dynamic>;

                // Get the latest message for preview
                final latestMessage = messages.isNotEmpty
                    ? messages.first
                    : null;
                String previewText = 'No messages yet';
                String timeAgo = '';

                if (latestMessage != null) {
                  final msg = latestMessage as Map<String, dynamic>;
                  switch (msg['type']) {
                    case 'text':
                      previewText = msg['text'] as String;
                      break;
                    case 'image':
                      previewText = '📷 Image';
                      break;
                    case 'file':
                      previewText = '📁 ${msg['name']}';
                      break;
                  }

                  // Calculate time ago (simplified)
                  final timestamp = msg['createdAt'] as int;
                  final now = DateTime.now().millisecondsSinceEpoch;
                  final diff = now - timestamp;

                  if (diff < 3600000) {
                    timeAgo = '${(diff / 60000).floor()}m ago';
                  } else if (diff < 86400000) {
                    timeAgo = '${(diff / 3600000).floor()}h ago';
                  } else {
                    timeAgo = '${(diff / 86400000).floor()}d ago';
                  }
                }

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: _getChatColor(chatId),
                    child: Text(
                      _getChatInitials(chat['name'] as String),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (timeAgo.isNotEmpty)
                        Text(
                          timeAgo,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(chat['participants'] as List).join(', ')} - ${messages.length} messages',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        previewText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (messages.length > 50)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'PERF',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chatId,
                          chatName: chat['name'] as String,
                          messages: messages,
                          users: users,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Get color for chat room based on ID
  Color _getChatColor(String chatId) {
    switch (chatId) {
      case 'travel-planning':
        return Colors.green;
      case 'project-discussion':
        return Colors.blue;
      case 'large-performance-test':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  /// Get initials for chat room
  String _getChatInitials(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    } else {
      return name.substring(0, 2).toUpperCase();
    }
  }
}
