import 'package:chat_message_core/chat_message_core.dart' show ChatUser;
import 'package:flutter/widgets.dart';

/// InheritedWidget that provides the current user's information to all descendant widgets in the chat.
/// This widget makes the current user's data available throughout the entire chat widget tree,
/// enabling widgets to determine message ownership, display appropriate styling, and handle
/// user-specific interactions without manual data propagation.
///
/// The current user information is essential for:
/// - Determining which messages are sent vs received (message bubble alignment and styling)
/// - Auto-scrolling when the current user sends a message
/// - Showing/hiding user names and avatars appropriately
/// - Filtering typing indicators (don't show when current user is typing)
/// - Access control for message actions (edit, delete, etc.)
class InheritedUser extends InheritedWidget {
  /// Creates an InheritedUser widget that provides current user data to its descendants.
  ///
  /// The [user] parameter represents the currently authenticated/active user in the chat.
  /// This should be the user who is sending messages and viewing the conversation.
  /// The [child] parameter is the widget subtree that will have access to this user data.
  ///
  /// Example usage:
  /// ```dart
  /// InheritedUser(
  ///   user: ChatUser(id: 'user123', firstName: 'John', lastName: 'Doe'),
  ///   child: ChatWidget(),
  /// )
  /// ```
  const InheritedUser({super.key, required this.user, required super.child});

  /// Retrieves the nearest InheritedUser widget from the widget tree.
  ///
  /// This static method is used by child widgets to access the current user's information
  /// without needing direct access to the user object. It searches up the widget tree
  /// to find the closest InheritedUser ancestor.
  ///
  /// Throws an exception if no InheritedUser widget is found in the ancestor chain.
  /// This typically indicates that the widget trying to access user data is not properly
  /// wrapped in a Chat widget (which provides the InheritedUser).
  ///
  /// Usage examples:
  /// ```dart
  /// // Get the current user
  /// final currentUser = InheritedUser.of(context).user;
  ///
  /// // Check if a message is from the current user
  /// final isMyMessage = message.author.id == InheritedUser.of(context).user.id;
  ///
  /// // Get user's display name
  /// final userName = getUserName(InheritedUser.of(context).user);
  /// ```
  static InheritedUser of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<InheritedUser>()!;
  }

  /// The current user's information, representing the person using the chat interface.
  ///
  /// This user object is used throughout the chat system to:
  /// - Distinguish between sent and received messages (comparing message.author.id with user.id)
  /// - Apply appropriate styling (sent messages appear on the right, received on the left)
  /// - Determine when to auto-scroll (only when current user sends a message)
  /// - Control typing indicators (don't show current user in typing list)
  /// - Enable message interactions (current user can edit/delete their own messages)
  /// - Display user avatar and name in group chat contexts
  ///
  /// The user object contains essential identification and profile information:
  /// - id: Unique identifier used for message ownership comparison
  /// - firstName/lastName: Display name information
  /// - imageUrl: Profile picture for avatar display
  /// - createdAt: Account creation timestamp
  final ChatUser user;

  /// Determines whether dependent widgets should be rebuilt when the user changes.
  ///
  /// This method is called by Flutter when the InheritedUser widget is updated.
  /// It compares the user IDs of the old and new user objects to determine
  /// if the current user has actually changed (e.g., user switched accounts).
  ///
  /// Returns true only if the user ID has changed, which indicates a different user
  /// has logged in. This causes all dependent widgets to rebuild with the new user context,
  /// updating message ownership, styling, and user-specific behaviors.
  ///
  /// Returns false if the user ID is the same, even if other user properties
  /// (like name or avatar) have changed. This optimization prevents unnecessary rebuilds
  /// for minor profile updates, since most chat functionality only depends on user identity.
  ///
  /// Note: If you need widgets to update when user profile information changes,
  /// you should compare additional fields like user.hashCode instead of just the ID.
  @override
  bool updateShouldNotify(InheritedUser oldWidget) {
    return user != oldWidget.user;
  }
}
