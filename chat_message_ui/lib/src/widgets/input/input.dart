import 'package:chat_message_core/src/models/partial_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../enums/input_clear_mode.dart';
import '../../enums/send_button_visibility_mode.dart';
import '../../utils/functions.dart';
import '../../inherited/inherited_chat_theme.dart';
import '../../inherited/inherited_l10n.dart';
import 'attachment_button.dart';
import 'input_text_field_controller.dart';
import 'send_button.dart';

/// The main input widget for composing and sending messages in the chat.
/// Provides a text field for typing messages, optional attachment button, and a send button.
/// Handles keyboard shortcuts, text validation, and various input behaviors like auto-clear.
class Input extends StatefulWidget {
  /// Creates an Input widget with message composition and sending capabilities.
  /// Requires onSendPressed callback and inputWidgetHeight for proper layout.
  const Input({
    super.key,
    this.isAttachmentUploading,
    this.onAttachmentPressed,
    required this.onSendPressed,
    this.options = const InputOptions(),
    required this.inputWidgetHeight,
  });

  /// Indicates whether an attachment is currently being uploaded.
  /// When true, replaces the attachment button with a loading indicator.
  /// Must be managed manually by the parent widget since this package doesn't handle file uploads.
  final bool? isAttachmentUploading;

  /// Callback triggered when the attachment button is pressed.
  /// If null, the attachment button is hidden. Used to initiate file/media selection.
  final VoidCallback? onAttachmentPressed;

  /// Callback invoked when the send button is tapped or Enter key is pressed.
  /// Receives a PartialTextModel containing the trimmed text content to be sent as a message.
  final void Function(PartialTextModel) onSendPressed;

  /// Configuration options controlling input behavior, styling, and interactions.
  /// Includes settings for keyboard type, auto-clear mode, and text field behavior.
  final InputOptions options;

  /// Height constraint for the input text field area.
  /// Used to maintain consistent input height regardless of button sizes.
  final double inputWidgetHeight;

  @override
  State<Input> createState() => _InputState();
}

/// State class for the Input widget managing text input, keyboard handling, and UI updates.
/// Handles focus management, send button visibility, and keyboard shortcuts.
class _InputState extends State<Input> {
  /// Focus node for the input text field with keyboard shortcut handling.
  /// Implements Enter key to send messages (Shift+Enter for new lines).
  late final _inputFocusNode = FocusNode(
    onKeyEvent: (node, event) {
      // Handle Enter key press without Shift modifier
      if (event.physicalKey == PhysicalKeyboardKey.enter &&
          !HardwareKeyboard.instance.physicalKeysPressed.any(
            (el) => <PhysicalKeyboardKey>{
              PhysicalKeyboardKey.shiftLeft,
              PhysicalKeyboardKey.shiftRight,
            }.contains(el),
          )) {
        // Skip if text is being composed (IME input on web)
        if (kIsWeb && _textController.value.isComposingRangeValid) {
          return KeyEventResult.ignored;
        }
        // Send message on key down event
        if (event is KeyDownEvent) {
          _handleSendPressed();
        }
        return KeyEventResult.handled;
      } else {
        return KeyEventResult.ignored;
      }
    },
  );

  /// Controls whether the send button is currently visible.
  /// Updated based on text content and SendButtonVisibilityMode setting.
  bool _sendButtonVisible = false;

  /// Controller for the input text field, handles text content and cursor position.
  /// Can be custom controller or defaults to InputTextFieldController with markdown support.
  late TextEditingController _textController;

  /// Initializes the input state with text controller and send button visibility.
  /// Sets up the appropriate text controller and configures button visibility behavior.
  @override
  void initState() {
    super.initState();

    // Use provided controller or default to InputTextFieldController with markdown support
    _textController =
        widget.options.textEditingController ?? InputTextFieldController();
    _handleSendButtonVisibilityModeChange();
  }

  /// Updates send button visibility behavior based on the current visibility mode setting.
  /// Manages text controller listeners and sets initial visibility state.
  void _handleSendButtonVisibilityModeChange() {
    // Remove any existing listener before reconfiguring
    _textController.removeListener(_handleTextControllerChange);

    // Configure visibility based on the selected mode
    if (widget.options.sendButtonVisibilityMode ==
        SendButtonVisibilityMode.hidden) {
      // Never show send button
      _sendButtonVisible = false;
    } else if (widget.options.sendButtonVisibilityMode ==
        SendButtonVisibilityMode.editing) {
      // Show button only when there's text to send
      _sendButtonVisible = _textController.text.trim() != '';
      _textController.addListener(_handleTextControllerChange);
    } else {
      // Always show send button (SendButtonVisibilityMode.always)
      _sendButtonVisible = true;
    }
  }

  /// Handles message sending when the send button is tapped or Enter is pressed.
  /// Validates text content, creates message data, and optionally clears the input.
  void _handleSendPressed() {
    final trimmedText = _textController.text.trim();
    if (trimmedText != '') {
      // Create partial message data with the text content
      final partialText = PartialTextModel(text: trimmedText);
      widget.onSendPressed(partialText);

      // Clear input if configured to do so
      if (widget.options.inputClearMode == InputClearMode.always) {
        _textController.clear();
      }
    }
  }

  /// Handles text field changes to update send button visibility in editing mode.
  /// Ignores changes during text composition (IME input) to avoid UI flicker.
  void _handleTextControllerChange() {
    // Skip updates during text composition (e.g., typing in Asian languages)
    if (_textController.value.isComposingRangeValid) {
      return;
    }
    // Only rebuild when visibility actually changes to avoid per-keystroke rebuilds.
    final shouldShow = _textController.text.trim().isNotEmpty;
    if (shouldShow != _sendButtonVisible) {
      setState(() {
        _sendButtonVisible = shouldShow;
      });
    }
  }

  /// Builds the complete input widget with text field, attachment button, and send button.
  /// Handles responsive layout, theming, and proper padding for all screen sizes.
  Widget _inputBuilder() {
    // Get screen dimensions and theme information
    final query = MediaQuery.of(context);
    final buttonPadding = InheritedChatTheme.of(
      context,
    ).theme.inputPadding.copyWith(left: 16, right: 16);

    // Configure safe area insets for mobile devices (keyboard, notches, etc.)
    final safeAreaInsets =
        isMobile
            ? EdgeInsets.fromLTRB(
              query.padding.left,
              0,
              query.padding.right,
              query.viewInsets.bottom + query.padding.bottom,
            )
            : EdgeInsets.zero;

    // Calculate text field padding based on button visibility
    final textPadding = InheritedChatTheme.of(context).theme.inputPadding
        .copyWith(left: 0, right: 0)
        .add(
          EdgeInsets.fromLTRB(
            widget.onAttachmentPressed != null
                ? 0
                : 24, // Left padding when no attachment button
            0,
            _sendButtonVisible ? 0 : 24, // Right padding when no send button
            0,
          ),
        );

    // Build the complete input widget with theming and layout
    return Focus(
      autofocus:
          !widget.options.autofocus, // Inverted for proper focus behavior
      child: Padding(
        padding: InheritedChatTheme.of(context).theme.inputMargin,
        child: Material(
          borderRadius: InheritedChatTheme.of(context).theme.inputBorderRadius,
          color: InheritedChatTheme.of(context).theme.inputBackgroundColor,
          surfaceTintColor:
              InheritedChatTheme.of(context).theme.inputSurfaceTintColor,
          elevation: InheritedChatTheme.of(context).theme.inputElevation,
          child: Container(
            decoration:
                InheritedChatTheme.of(context).theme.inputContainerDecoration,
            padding: safeAreaInsets,
            child: Row(
              textDirection:
                  TextDirection.ltr, // Ensure consistent button layout
              children: [
                // Show attachment button if callback is provided
                if (widget.onAttachmentPressed != null)
                  AttachmentButton(
                    isLoading: widget.isAttachmentUploading ?? false,
                    onPressed: widget.onAttachmentPressed,
                    padding: buttonPadding,
                  ),
                // Main text input field with full configuration
                Expanded(
                  child: Padding(
                    padding: textPadding,
                    child: TextField(
                      enabled: widget.options.enabled,
                      autocorrect: widget.options.autocorrect,
                      autofocus: widget.options.autofocus,
                      enableSuggestions: widget.options.enableSuggestions,
                      controller: _textController,
                      cursorColor:
                          InheritedChatTheme.of(
                            context,
                          ).theme.inputTextCursorColor,
                      decoration: InheritedChatTheme.of(
                        context,
                      ).theme.inputTextDecoration.copyWith(
                        hintStyle: InheritedChatTheme.of(
                          context,
                        ).theme.inputTextStyle.copyWith(
                          color: InheritedChatTheme.of(
                            context,
                          ).theme.inputTextColor.withValues(alpha: 0.5),
                        ),
                        hintText:
                            InheritedL10n.of(context).l10n.inputPlaceholder,
                      ),
                      focusNode: _inputFocusNode,
                      keyboardType: widget.options.keyboardType,
                      maxLines: 5, // Allow multi-line input up to 5 lines
                      minLines: 1, // Start with single line
                      onChanged: widget.options.onTextChanged,
                      onTap: widget.options.onTextFieldTap,
                      style: InheritedChatTheme.of(
                        context,
                      ).theme.inputTextStyle.copyWith(
                        color:
                            InheritedChatTheme.of(context).theme.inputTextColor,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                // Send button with consistent height and conditional visibility
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        buttonPadding.bottom +
                        buttonPadding.top +
                        widget.inputWidgetHeight,
                  ),
                  child: Visibility(
                    visible: _sendButtonVisible,
                    child: SendButton(
                      onPressed: _handleSendPressed,
                      padding: buttonPadding,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Called when the widget configuration changes.
  /// Updates send button visibility behavior if the mode changed.
  @override
  void didUpdateWidget(covariant Input oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.options.sendButtonVisibilityMode !=
        oldWidget.options.sendButtonVisibilityMode) {
      _handleSendButtonVisibilityModeChange();
    }
  }

  /// Cleans up resources when the widget is removed from the widget tree.
  /// Disposes of focus node and text controller to prevent memory leaks.
  @override
  void dispose() {
    _inputFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  /// Builds the input widget wrapped in a gesture detector for focus management.
  /// Tapping anywhere on the input area will focus the text field.
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () {
      _inputFocusNode.requestFocus();
    },
    child: _inputBuilder(),
  );
}

/// Configuration options for customizing Input widget behavior and appearance.
/// Controls text input behavior, keyboard settings, button visibility, and interaction callbacks.
@immutable
class InputOptions {
  /// Creates input options with sensible defaults for most chat applications.
  /// Auto-clear is enabled, multiline keyboard is used, and send button appears during editing.
  const InputOptions({
    this.inputClearMode = InputClearMode.always,
    this.keyboardType = TextInputType.multiline,
    this.onTextChanged,
    this.onTextFieldTap,
    this.sendButtonVisibilityMode = SendButtonVisibilityMode.editing,
    this.textEditingController,
    this.autocorrect = true,
    this.autofocus = false,
    this.enableSuggestions = true,
    this.enabled = true,
  });

  /// Determines when the input field is cleared after sending a message.
  /// 'always' clears after every send, 'never' keeps the text for editing.
  final InputClearMode inputClearMode;

  /// Type of keyboard to display when the input is focused.
  /// Multiline allows Enter key for line breaks and proper text input.
  final TextInputType keyboardType;

  /// Callback invoked whenever the text content changes.
  /// Useful for implementing real-time features like typing indicators.
  final void Function(String)? onTextChanged;

  /// Callback invoked when the user taps on the text field.
  /// Can be used for analytics, UI adjustments, or custom behaviors.
  final VoidCallback? onTextFieldTap;

  /// Controls when the send button is visible based on input state.
  /// 'editing' shows button only when there's text, 'always' keeps it visible, 'hidden' hides it.
  final SendButtonVisibilityMode sendButtonVisibilityMode;

  /// Custom text editing controller for advanced text manipulation.
  /// If null, uses InputTextFieldController with built-in markdown support.
  /// Provide a custom controller for specific text handling requirements.
  final TextEditingController? textEditingController;

  /// Whether the system should provide automatic spelling corrections.
  /// Generally recommended for chat inputs to help users with typos.
  final bool autocorrect;

  /// Whether the input field should automatically receive focus when displayed.
  /// False by default to avoid unwanted keyboard popups.
  final bool autofocus;

  /// Whether the system should provide text suggestions while typing.
  /// Helps users with word completion and common phrases.
  final bool enableSuggestions;

  /// Whether the text input field is enabled for user interaction.
  /// When false, the field becomes read-only and non-interactive.
  final bool enabled;
}
