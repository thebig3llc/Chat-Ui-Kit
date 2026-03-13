import 'dart:async';
import 'dart:math' as math;

import 'package:chat_message_ui_kit/src/models/image_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../utils/conditional.dart';
import '../../utils/functions.dart';
import '../../inherited/inherited_chat_theme.dart';
import '../../inherited/inherited_user.dart';

/// Performance-optimized image message widget with lazy loading capabilities.
/// Only loads images when they become visible and disposes them when scrolled away.
class LazyImageMessage extends StatefulWidget {
  const LazyImageMessage({
    super.key,
    this.imageHeaders,
    this.imageProviderBuilder,
    required this.message,
    required this.messageWidth,
    this.lazyLoadingEnabled = true,
    this.placeholderBuilder,
    this.errorBuilder,
    this.cacheWidth,
    this.cacheHeight,
  });

  final Map<String, String>? imageHeaders;
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })?
  imageProviderBuilder;
  final ImageMessageModel message;
  final int messageWidth;

  /// Whether to enable lazy loading (default: true)
  final bool lazyLoadingEnabled;

  /// Custom placeholder widget builder
  final Widget Function(BuildContext context, Size size)? placeholderBuilder;

  /// Custom error widget builder
  final Widget Function(BuildContext context, Object error, Size size)?
  errorBuilder;

  /// Cache width for memory optimization
  final int? cacheWidth;

  /// Cache height for memory optimization
  final int? cacheHeight;

  @override
  State<LazyImageMessage> createState() => _LazyImageMessageState();
}

class _LazyImageMessageState extends State<LazyImageMessage>
    with AutomaticKeepAliveClientMixin {
  ImageProvider? _image;
  Size _size = Size.zero;
  ImageStream? _stream;
  ImageStreamListener? _imageListener;
  Timer? _disposeTimer;
  bool _isVisible = false;
  bool _hasError = false;
  Object? _error;

  /// Key for managing the visibility detector
  late final GlobalKey _visibilityKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _size = Size(
      widget.message.width?.toDouble() ?? 0,
      widget.message.height?.toDouble() ?? 0,
    );

    // Only load image immediately if lazy loading is disabled
    if (!widget.lazyLoadingEnabled) {
      _loadImage();
    }
  }

  /// Load the image provider and start loading
  void _loadImage() {
    if (_image != null) return;

    try {
      _image =
          widget.imageProviderBuilder != null
              ? widget.imageProviderBuilder!(
                uri: widget.message.uri,
                imageHeaders: widget.imageHeaders,
                conditional: Conditional(),
              )
              : Conditional().createImageProvider(
                widget.message.uri,
                headers: widget.imageHeaders,
              );

      if (mounted) {
        _getImage();
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _error = e;
      });
    }
  }

  /// Resolve and listen to image stream
  void _getImage() {
    if (_image == null) return;

    final oldImageStream = _stream;
    _stream = _image?.resolve(
      createLocalImageConfiguration(
        context,
        size:
            widget.cacheWidth != null || widget.cacheHeight != null
                ? Size(
                  widget.cacheWidth?.toDouble() ?? double.infinity,
                  widget.cacheHeight?.toDouble() ?? double.infinity,
                )
                : null,
      ),
    );

    if (_stream?.key == oldImageStream?.key) {
      return;
    }

    // Reuse the same listener instance so removeListener can find it later (P-1).
    _imageListener ??= ImageStreamListener(_updateImage, onError: _onImageError);

    oldImageStream?.removeListener(_imageListener!);
    _stream?.addListener(_imageListener!);
  }

  void _updateImage(ImageInfo info, bool _) {
    if (mounted) {
      setState(() {
        _size = Size(info.image.width.toDouble(), info.image.height.toDouble());
        _hasError = false;
        _error = null;
      });
    }
  }

  void _onImageError(Object error, StackTrace? stackTrace) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _error = error;
      });
    }
  }

  /// Clean up image resources
  void _disposeImage() {
    if (_imageListener != null) {
      _stream?.removeListener(_imageListener!);
      _imageListener = null;
    }
    _stream = null;
    _image = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_size.isEmpty && _image != null) {
      _getImage();
    }
  }

  @override
  void dispose() {
    _disposeTimer?.cancel();
    _disposeTimer = null;
    _disposeImage();
    super.dispose();
  }

  /// Build placeholder widget
  Widget _buildPlaceholder() {
    if (widget.placeholderBuilder != null) {
      return widget.placeholderBuilder!(context, _size);
    }

    final aspectRatio = _size.aspectRatio > 0 ? _size.aspectRatio : 1.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.messageWidth.toDouble(),
        minWidth: 170,
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          color: InheritedChatTheme.of(
            context,
          ).theme.secondaryColor.withValues(alpha: 0.1),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildError() {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error!, _size);
    }

    final aspectRatio = _size.aspectRatio > 0 ? _size.aspectRatio : 1.0;

    return Container(
      constraints: BoxConstraints(
        maxHeight: widget.messageWidth.toDouble(),
        minWidth: 170,
      ),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Container(
          color: InheritedChatTheme.of(
            context,
          ).theme.errorColor.withValues(alpha: 0.1),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  color: InheritedChatTheme.of(context).theme.errorColor,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed to load image',
                  style: TextStyle(
                    color: InheritedChatTheme.of(context).theme.errorColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the main image content
  Widget _buildImageContent() {
    final user = InheritedUser.of(context).user;

    if (_hasError) {
      return _buildError();
    }

    if (_image == null) {
      return _buildPlaceholder();
    }

    if (_size.aspectRatio == 0) {
      return Container(
        color: InheritedChatTheme.of(context).theme.secondaryColor,
        height: _size.height,
        width: _size.width,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (_size.aspectRatio < 0.1 || _size.aspectRatio > 10) {
      // File-like display for extreme aspect ratios
      return Container(
        color:
            user.id == widget.message.author.id
                ? InheritedChatTheme.of(context).theme.primaryColor
                : InheritedChatTheme.of(context).theme.secondaryColor,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 64,
              margin: EdgeInsetsDirectional.fromSTEB(
                InheritedChatTheme.of(context).theme.messageInsetsVertical,
                InheritedChatTheme.of(context).theme.messageInsetsVertical,
                16,
                InheritedChatTheme.of(context).theme.messageInsetsVertical,
              ),
              width: 64,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image(
                  fit: BoxFit.cover,
                  image: _image!,
                  frameBuilder: (
                    context,
                    child,
                    frame,
                    wasSynchronouslyLoaded,
                  ) {
                    if (wasSynchronouslyLoaded || frame != null) {
                      return child;
                    }
                    return Container(
                      color:
                          InheritedChatTheme.of(context).theme.secondaryColor,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 1),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: InheritedChatTheme.of(
                        context,
                      ).theme.errorColor.withValues(alpha: 0.1),
                      child: Icon(
                        Icons.error_outline,
                        color: InheritedChatTheme.of(context).theme.errorColor,
                        size: 24,
                      ),
                    );
                  },
                ),
              ),
            ),
            Flexible(
              child: Container(
                margin: EdgeInsetsDirectional.fromSTEB(
                  0,
                  InheritedChatTheme.of(context).theme.messageInsetsVertical,
                  InheritedChatTheme.of(context).theme.messageInsetsHorizontal,
                  InheritedChatTheme.of(context).theme.messageInsetsVertical,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.message.name,
                      style:
                          user.id == widget.message.author.id
                              ? InheritedChatTheme.of(
                                context,
                              ).theme.sentMessageBodyTextStyle
                              : InheritedChatTheme.of(
                                context,
                              ).theme.receivedMessageBodyTextStyle,
                      textWidthBasis: TextWidthBasis.longestLine,
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatBytes(widget.message.size.truncate()),
                        style:
                            user.id == widget.message.author.id
                                ? InheritedChatTheme.of(
                                  context,
                                ).theme.sentMessageCaptionTextStyle
                                : InheritedChatTheme.of(
                                  context,
                                ).theme.receivedMessageCaptionTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Normal image display
      return Container(
        constraints: BoxConstraints(
          maxHeight: widget.messageWidth.toDouble(),
          minWidth: 170,
        ),
        child: AspectRatio(
          aspectRatio: _size.aspectRatio > 0 ? _size.aspectRatio : 1,
          child: Image(
            fit: BoxFit.contain,
            image: _image!,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return _buildPlaceholder();
            },
            errorBuilder: (context, error, stackTrace) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _hasError = true;
                    _error = error;
                  });
                }
              });
              return _buildError();
            },
          ),
        ),
      );
    }
  }

  @override
  bool get wantKeepAlive => _isVisible && _image != null;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (!widget.lazyLoadingEnabled) {
      return _buildImageContent();
    }

    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: (VisibilityInfo info) {
        final wasVisible = _isVisible;
        _isVisible =
            info.visibleFraction > 0.1; // Consider visible if >10% is shown

        if (_isVisible && !wasVisible) {
          // Became visible — cancel any pending dispose and load the image.
          _disposeTimer?.cancel();
          _disposeTimer = null;
          _loadImage();
        } else if (!_isVisible && wasVisible) {
          // Became invisible — schedule dispose after a short delay (P-9).
          // Cancel any previous timer so only one is active at a time.
          _disposeTimer?.cancel();
          _disposeTimer = Timer(const Duration(seconds: 5), () {
            if (!_isVisible && mounted) {
              _disposeImage();
              setState(() {});
            }
          });
        }
      },
      child: _buildImageContent(),
    );
  }
}

/// Simple visibility detector for lazy loading
class VisibilityDetector extends StatefulWidget {
  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  final Widget child;
  final ValueChanged<VisibilityInfo> onVisibilityChanged;

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  // P-11: gate so only one post-frame callback is queued at a time.
  bool _pendingVisibilityCheck = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkVisibility();
        return false;
      },
      child: widget.child,
    );
  }

  void _checkVisibility() {
    if (_pendingVisibilityCheck) return;
    _pendingVisibilityCheck = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingVisibilityCheck = false;
      if (!mounted) return;

      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox == null || !renderBox.attached) return;

      final size = renderBox.size;
      final position = renderBox.localToGlobal(Offset.zero);
      final viewport = RenderAbstractViewport.of(renderBox);

      final vpSize = viewport.paintBounds.size;
      final vpPosition = viewport.paintBounds.topLeft;

      // Calculate intersection
      final intersection = Rect.fromLTWH(
        math.max(position.dx, vpPosition.dx),
        math.max(position.dy, vpPosition.dy),
        math.min(position.dx + size.width, vpPosition.dx + vpSize.width) -
            math.max(position.dx, vpPosition.dx),
        math.min(position.dy + size.height, vpPosition.dy + vpSize.height) -
            math.max(position.dy, vpPosition.dy),
      );

      final visibleArea = intersection.width * intersection.height;
      final totalArea = size.width * size.height;
      final visibleFraction = totalArea > 0 ? visibleArea / totalArea : 0.0;

      widget.onVisibilityChanged(
        VisibilityInfo(visibleFraction: visibleFraction.clamp(0.0, 1.0)),
      );
    });
  }
}

/// Information about widget visibility
class VisibilityInfo {
  const VisibilityInfo({required this.visibleFraction});

  /// Fraction of the widget that is visible (0.0 to 1.0)
  final double visibleFraction;
}
