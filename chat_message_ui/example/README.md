# App Messaging UI Example

This example demonstrates the full capabilities of the `app_messaging_ui` package with a comprehensive chat application.

## Features Demonstrated

### 🏠 Chat Room List
- Multiple chat rooms with different characteristics
- Message previews and participant counts
- Visual indicators for high-performance chats (120+ messages)
- Real-time timestamp display

### 💬 Chat Features
- **Text Messages**: Full emoji support with formatting
- **Image Messages**: Gallery view with lazy loading
- **File Attachments**: Document sharing capabilities
- **Message Status**: Sent, delivered, and seen indicators
- **User Avatars**: Profile pictures and fallback initials
- **Real-time Updates**: Simulated message status changes

### 🚀 Performance Demo
- **Large Message Lists**: 120+ messages in the "Performance Test Chat"
- **Optimized Scrolling**: Smooth performance with extensive chat history
- **Memory Efficient**: Proper list virtualization and image loading

### 🎨 Customization Examples
- Custom theming and colors
- Message bubble styling
- Input field customization
- Status indicator options
- Layout and spacing adjustments

## Chat Rooms

### 1. Travel Planning 🌍
- Small group chat with mixed message types
- Images, files, and emoji messages
- Demonstrates typical social messaging

### 2. Project Discussion 💼
- Professional work conversation
- Shows business-focused messaging patterns
- Includes status updates and collaboration

### 3. Performance Test Chat 🚀
- **120 messages** for performance testing
- Mix of text (80%), images (15%), and files (5%)
- Demonstrates package performance with large datasets
- Various message authors and timestamps

## Running the Example

```bash
cd app_messaging_ui/example
flutter pub get
flutter run
```

## Customization Guide

The example shows how to:

1. **Load Message Data**: From JSON assets or your backend
2. **Handle User Input**: Send messages and attachments
3. **Manage Message Status**: Update sent/delivered/seen states
4. **Customize Appearance**: Themes, colors, and styling
5. **Handle Navigation**: Between chat rooms and conversations
6. **Optimize Performance**: For large message lists

## Code Structure

- `main.dart`: Complete example with navigation and chat functionality
- `assets/messages.json`: Sample data with multiple chat rooms and 120+ messages
- Well-documented code with inline comments explaining customization options

## Integration Tips

This example provides a foundation for integrating the package into your app:

- Copy the chat data loading pattern for your backend integration
- Use the message handling functions as templates
- Adapt the theming examples to match your app's design
- Reference the performance optimizations for large chat histories

The package is designed to be highly customizable while providing excellent performance out of the box.