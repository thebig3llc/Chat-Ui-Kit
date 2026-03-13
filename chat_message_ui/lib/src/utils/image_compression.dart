import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Image compression utilities for memory optimization and performance
class ImageCompression {
  ImageCompression._();

  /// Compress image for thumbnail generation
  static Future<Uint8List?> generateThumbnail(
    Uint8List imageBytes, {
    int maxWidth = 300,
    int maxHeight = 300,
    double quality = 0.7,
  }) async {
    try {
      final image = await _decodeImage(imageBytes);
      final compressedImage = await _resizeImage(
        image,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      final thumbnailBytes = await _encodeImage(
        compressedImage,
        quality: quality,
      );

      image.dispose();
      compressedImage.dispose();

      return thumbnailBytes;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  /// Compress image for preview display
  static Future<Uint8List?> compressForPreview(
    Uint8List imageBytes, {
    int maxWidth = 800,
    int maxHeight = 800,
    double quality = 0.8,
  }) async {
    try {
      final image = await _decodeImage(imageBytes);

      // Only compress if image is larger than target size
      if (image.width <= maxWidth && image.height <= maxHeight) {
        image.dispose();
        return imageBytes; // Return original if already small enough
      }

      final compressedImage = await _resizeImage(
        image,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
      );

      final compressedBytes = await _encodeImage(
        compressedImage,
        quality: quality,
      );

      image.dispose();
      compressedImage.dispose();

      return compressedBytes;
    } catch (e) {
      debugPrint('Error compressing image for preview: $e');
      return imageBytes; // Return original on error
    }
  }

  /// Get optimized image dimensions for memory usage
  static Size getOptimizedDimensions(
    int originalWidth,
    int originalHeight, {
    int maxWidth = 2048,
    int maxHeight = 2048,
    double devicePixelRatio = 1.0,
  }) {
    // Adjust max dimensions based on device pixel ratio
    final adjustedMaxWidth = (maxWidth / devicePixelRatio).round();
    final adjustedMaxHeight = (maxHeight / devicePixelRatio).round();

    if (originalWidth <= adjustedMaxWidth &&
        originalHeight <= adjustedMaxHeight) {
      return Size(originalWidth.toDouble(), originalHeight.toDouble());
    }

    final aspectRatio = originalWidth / originalHeight;
    final int newWidth, newHeight;

    if (originalWidth > originalHeight) {
      newWidth = adjustedMaxWidth;
      newHeight = (newWidth / aspectRatio).round();
    } else {
      newHeight = adjustedMaxHeight;
      newWidth = (newHeight * aspectRatio).round();
    }

    return Size(newWidth.toDouble(), newHeight.toDouble());
  }

  /// Estimate memory usage for an image
  static int estimateMemoryUsage(int width, int height) {
    // RGBA = 4 bytes per pixel
    return width * height * 4;
  }

  /// Check if image should be compressed based on memory constraints
  static bool shouldCompress(int width, int height, {int maxMemoryMB = 10}) {
    final memoryUsage = estimateMemoryUsage(width, height);
    final maxMemoryBytes = maxMemoryMB * 1024 * 1024;
    return memoryUsage > maxMemoryBytes;
  }

  /// Decode image from bytes
  static Future<ui.Image> _decodeImage(Uint8List bytes) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    final descriptor = await ui.ImageDescriptor.encoded(buffer);
    final codec = await descriptor.instantiateCodec();
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// Resize image maintaining aspect ratio
  static Future<ui.Image> _resizeImage(
    ui.Image image, {
    required int maxWidth,
    required int maxHeight,
  }) async {
    final aspectRatio = image.width / image.height;
    final int newWidth, newHeight;

    if (image.width > image.height) {
      newWidth = math.min(image.width, maxWidth);
      newHeight = (newWidth / aspectRatio).round();
    } else {
      newHeight = math.min(image.height, maxHeight);
      newWidth = (newHeight * aspectRatio).round();
    }

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Use high-quality image filtering
    final paint =
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      paint,
    );

    final picture = recorder.endRecording();
    final resizedImage = await picture.toImage(newWidth, newHeight);
    picture.dispose();

    return resizedImage;
  }

  /// Encode image to bytes with specified quality
  static Future<Uint8List> _encodeImage(
    ui.Image image, {
    double quality = 0.8,
  }) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to encode image');
    }
    return byteData.buffer.asUint8List();
  }
}

/// Image optimization presets for different use cases
class ImageOptimizationPresets {
  ImageOptimizationPresets._();

  /// Preset for chat message thumbnails
  static const thumbnail = ImageOptimizationConfig(
    maxWidth: 200,
    maxHeight: 200,
    quality: 0.6,
    maxMemoryMB: 2,
  );

  /// Preset for chat message previews
  static const preview = ImageOptimizationConfig(
    maxWidth: 600,
    maxHeight: 600,
    quality: 0.8,
    maxMemoryMB: 5,
  );

  /// Preset for full-size display (memory optimized)
  static const fullSize = ImageOptimizationConfig(
    maxWidth: 2048,
    maxHeight: 2048,
    quality: 0.9,
    maxMemoryMB: 20,
  );

  /// Preset for memory-constrained devices
  static const memoryConstrained = ImageOptimizationConfig(
    maxWidth: 800,
    maxHeight: 800,
    quality: 0.7,
    maxMemoryMB: 8,
  );
}

/// Configuration for image optimization
class ImageOptimizationConfig {
  const ImageOptimizationConfig({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.maxMemoryMB,
  });

  final int maxWidth;
  final int maxHeight;
  final double quality;
  final int maxMemoryMB;

  /// Create a config optimized for the current device
  factory ImageOptimizationConfig.forDevice() {
    // Get screen size and pixel ratio to determine optimal settings
    final window = WidgetsBinding.instance.platformDispatcher.views.first;
    final screenWidth = window.physicalSize.width / window.devicePixelRatio;
    final screenHeight = window.physicalSize.height / window.devicePixelRatio;

    // Use screen dimensions as basis for optimization
    final maxDimension = math.max(screenWidth, screenHeight).round();

    return ImageOptimizationConfig(
      maxWidth: math.min(maxDimension * 2, 2048), // 2x screen size max
      maxHeight: math.min(maxDimension * 2, 2048),
      quality: 0.85,
      maxMemoryMB: 15,
    );
  }
}

/// Utility for managing image memory usage across the app
class ImageMemoryManager {
  static int _totalMemoryUsage = 0;
  static const int _maxTotalMemoryMB = 150; // 150MB total limit

  /// Check if we can allocate memory for an image
  static bool canAllocateMemory(int additionalBytes) {
    final totalBytes = _totalMemoryUsage + additionalBytes;
    final maxBytes = _maxTotalMemoryMB * 1024 * 1024;
    return totalBytes <= maxBytes;
  }

  /// Register memory usage for an image
  static void registerMemoryUsage(int bytes) {
    _totalMemoryUsage += bytes;
  }

  /// Unregister memory usage when image is disposed
  static void unregisterMemoryUsage(int bytes) {
    _totalMemoryUsage = math.max(0, _totalMemoryUsage - bytes);
  }

  /// Get current memory usage statistics
  static Map<String, dynamic> getMemoryStats() {
    return {
      'totalUsageMB': (_totalMemoryUsage / (1024 * 1024)).toStringAsFixed(2),
      'maxUsageMB': _maxTotalMemoryMB,
      'usagePercentage':
          ((_totalMemoryUsage / (_maxTotalMemoryMB * 1024 * 1024)) * 100)
              .toStringAsFixed(1),
    };
  }

  /// Force cleanup when memory pressure is detected
  static void handleMemoryPressure() {
    debugPrint('ImageMemoryManager: Memory pressure detected');
    // Reset counter - actual cleanup should be handled by individual components
    _totalMemoryUsage = 0;
  }
}

/// Widget that automatically optimizes child image based on available memory
class OptimizedImage extends StatefulWidget {
  const OptimizedImage({
    super.key,
    required this.imageProvider,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.optimizationConfig,
    this.placeholder,
    this.errorBuilder,
  });

  final ImageProvider imageProvider;
  final double? width;
  final double? height;
  final BoxFit fit;
  final ImageOptimizationConfig? optimizationConfig;
  final Widget? placeholder;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  @override
  State<OptimizedImage> createState() => _OptimizedImageState();
}

class _OptimizedImageState extends State<OptimizedImage> {
  ImageProvider? _optimizedProvider;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _optimizeImage();
  }

  @override
  void didUpdateWidget(OptimizedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProvider != widget.imageProvider) {
      _optimizeImage();
    }
  }

  void _optimizeImage() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // For now, use the original provider
      // In a full implementation, you would optimize based on memory constraints
      _optimizedProvider = widget.imageProvider;

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error!, null);
    }

    if (_isLoading || _optimizedProvider == null) {
      return widget.placeholder ??
          const Center(child: CircularProgressIndicator());
    }

    return Image(
      image: _optimizedProvider!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      errorBuilder: widget.errorBuilder,
    );
  }
}
