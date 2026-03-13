import 'package:flutter/material.dart';
import 'package:chat_message_ui_kit/chat_message_ui_kit.dart';

/// Individual chat screen using the app_messaging_ui Chat widget
///
/// This demonstrates the main Chat widget with all its capabilities:
/// - Custom theming with ChatTheme
/// - Message handling and display
/// - User interactions
/// - Performance with large message lists
class ChatScreen extends StatefulWidget {
  final String chatId;
  final String chatName;
  final List<dynamic> messages;
  final Map<String, dynamic> users;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.chatName,
    required this.messages,
    required this.users,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<MessageModel> messages = [];
  late ChatUser currentUser;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// Initialize chat data and convert JSON to MessageModel objects
  void _initializeChat() {
    // Set current user
    currentUser = ChatUser(
      id: 'current-user',
      firstName: 'You',
      lastName: 'User',
    );

    // Convert JSON messages to MessageModel objects
    messages = widget.messages.map((messageData) {
      return MessageModel.fromJson(messageData as Map<String, dynamic>);
    }).toList();
  }

  /// Handle sending new messages
  ///
  /// This demonstrates how to add new messages to the chat.
  /// In a real app, you would send this to your backend service.
  void _handleSendMessage(String text) {
    if (text.trim().isEmpty) return;

    final newMessage = TextMessageModel(
      author: currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: 'msg-${DateTime.now().millisecondsSinceEpoch}',
      text: text.trim(),
      status: Status.sending, // Will change to sent/delivered/seen
    );

    setState(() {
      messages.insert(0, newMessage);
    });

    // Simulate message status updates (in real app, this comes from your backend)
    _simulateMessageStatusUpdates(newMessage);
  }

  /// Simulate message status changes for demo purposes
  void _simulateMessageStatusUpdates(MessageModel message) {
    // Simulate sent status
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final index = messages.indexWhere((m) => m.id == message.id);
        if (index >= 0) {
          final updatedMessage = message.copyWith(status: Status.sent);
          setState(() {
            messages[index] = updatedMessage;
          });
        }
      }
    });

    // Simulate delivered status
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        final index = messages.indexWhere((m) => m.id == message.id);
        if (index >= 0) {
          final updatedMessage = message.copyWith(status: Status.delivered);
          setState(() {
            messages[index] = updatedMessage;
          });
        }
      }
    });

    // Simulate seen status
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final index = messages.indexWhere((m) => m.id == message.id);
        if (index >= 0) {
          final updatedMessage = message.copyWith(status: Status.seen);
          setState(() {
            messages[index] = updatedMessage;
          });
        }
      }
    });
  }

  /// Handle attachment button press
  ///
  /// This demonstrates how to handle file/media attachments.
  /// You can integrate with image_picker, file_picker, etc.
  void _handleAttachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _addSampleImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _addSampleImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.insert_drive_file),
                title: const Text('Document'),
                onTap: () {
                  Navigator.pop(context);
                  _addSampleFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Add a sample image message for demonstration
  void _addSampleImage() {
    final imageMessage = ImageMessageModel(
      author: currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: 'img-${DateTime.now().millisecondsSinceEpoch}',
      name: 'sample_image.jpg',
      size: 1024 * 500, // 500KB
      uri: 'https://source.unsplash.com/800x600/?random',
      width: 800,
      height: 600,
      status: Status.sending,
    );

    setState(() {
      messages.insert(0, imageMessage);
    });

    _simulateMessageStatusUpdates(imageMessage);
  }

  /// Add a sample file message for demonstration
  void _addSampleFile() {
    // Note: FileMessage would need to be implemented in your app
    // This is just for demonstration
    final textMessage = TextMessageModel(
      author: currentUser,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: 'file-${DateTime.now().millisecondsSinceEpoch}',
      text: '📎 sample_document.pdf (245 KB)',
      status: Status.sending,
    );

    setState(() {
      messages.insert(0, textMessage);
    });

    _simulateMessageStatusUpdates(textMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.chatName),
            Text(
              '${messages.length} messages',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              _showChatInfo();
            },
          ),
        ],
      ),
      // The main Chat widget from app_messaging_ui package
      body: Chat(
        messages: messages,
        onSendPressed: (partialText) {
          _handleSendMessage(partialText.text);
        },
        user: currentUser,
        // Use default theme (you can customize by creating a DarkChatTheme() or LightChatTheme())
        // Enable attachment button
        onAttachmentPressed: _handleAttachmentPressed,
        // Customize input placeholder
        inputWidgetHeight: 56,
        // Enable various features
        showUserAvatars: true,
        showUserNames: true,
        // Performance optimization for large lists
        // useTopSafeAreaInsets: true, // This property might not exist
      ),
    );
  }

  /// Show chat information dialog
  void _showChatInfo() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(widget.chatName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Chat ID: ${widget.chatId}'),
              const SizedBox(height: 8),
              Text('Messages: ${messages.length}'),
              const SizedBox(height: 8),
              const Text('Features Demonstrated:'),
              const SizedBox(height: 4),
              const Text(
                '• Text messages with emoji support\n'
                '• Image messages with gallery view\n'
                '• File attachments\n'
                '• Message status indicators\n'
                '• User avatars and names\n'
                '• Custom theming\n'
                '• High-performance scrolling',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              const Text(
                'This package provides a complete chat UI solution '
                'that you can easily integrate into your Flutter app. '
                'Customize colors, fonts, layouts, and behavior to '
                'match your app\'s design.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
