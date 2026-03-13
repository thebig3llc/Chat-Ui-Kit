import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Memory-efficient cached image provider with automatic cache management
/// and memory pressure handling to prevent OOM crashes.
class CachedImageProvider extends ImageProvider<CachedImageProvider> {
  const CachedImageProvider(
    this.url, {
    this.scale = 1.0,
    this.headers,
    this.maxCacheSize = 50,
    this.maxMemoryMB = 100,
    this.compressionQuality = 0.8,
  });

  /// Image URL
  final String url;

  /// Image scale factor
  final double scale;

  /// HTTP headers
  final Map<String, String>? headers;

  /// Maximum number of images to cache in memory
  final int maxCacheSize;

  /// Maximum memory usage in MB for image cache
  final int maxMemoryMB;

  /// Image compression quality (0.0 to 1.0)
  final double compressionQuality;

  /// Static memory cache for all instances.
  /// Dart's default `{}` literal creates a LinkedHashMap, so insertion order
  /// is preserved — we rely on this for O(1) LRU eviction (P-8).
  static final Map<String, _CacheEntry> _memoryCache = {};

  /// In-flight load completers keyed by URL.
  /// Prevents duplicate concurrent network requests for the same image (P-2).
  static final Map<String, Completer<ui.Image>> _inFlight = {};

  /// Current memory usage estimate in bytes
  static int _currentMemoryUsage = 0;

  /// Maximum memory usage in bytes
  static int get _maxMemoryBytes => 100 * 1024 * 1024; // 100MB default

  @override
  Future<CachedImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<CachedImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    CachedImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return OneFrameImageStreamCompleter(
      _loadAsync(key, decode),
      informationCollector:
          () => <DiagnosticsNode>[
            DiagnosticsProperty<CachedImageProvider>('Image provider', this),
            DiagnosticsProperty<String>('Image URL', url),
          ],
    );
  }

  /// Load image asynchronously with caching
  Future<ImageInfo> _loadAsync(
    CachedImageProvider key,
    ImageDecoderCallback decode,
  ) async {
    try {
      // P-8: Check memory cache and re-insert on hit to maintain LRU order.
      // Dart's LinkedHashMap preserves insertion order; remove+reinsert moves
      // the entry to the "most recently used" end.
      final cacheEntry = _memoryCache[url];
      if (cacheEntry != null && !cacheEntry.isExpired) {
        _memoryCache.remove(url);
        cacheEntry.lastAccessed = DateTime.now();
        _memoryCache[url] = cacheEntry;
        return ImageInfo(image: cacheEntry.image, scale: scale);
      }

      // P-2: Deduplicate concurrent loads for the same URL so we never issue
      // two network requests for the same image simultaneously.
      final existing = _inFlight[url];
      if (existing != null) {
        return ImageInfo(image: await existing.future, scale: scale);
      }
      final completer = Completer<ui.Image>();
      _inFlight[url] = completer;

      try {
        // Load from network
        final bytes = await _loadFromNetwork();

        // Decode and optionally compress
        final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
        final descriptor = await ui.ImageDescriptor.encoded(buffer);
        final codec = await descriptor.instantiateCodec();
        final frame = await codec.getNextFrame();
        ui.Image image = frame.image;

        // Apply memory optimization
        if (compressionQuality < 1.0) {
          image = await _compressImage(image);
        }

        // Cache the image
        await _cacheImage(url, image);

        completer.complete(image);
        return ImageInfo(image: image, scale: scale);
      } catch (loadError) {
        completer.completeError(loadError);
        rethrow;
      } finally {
        _inFlight.remove(url);
      }
    } catch (e) {
      // Return a placeholder or error image
      return _createErrorImage();
    }
  }

  /// Load image data from network
  Future<Uint8List> _loadFromNetwork() async {
    final request = await HttpClient().getUrl(Uri.parse(url));

    // Add headers if provided
    headers?.forEach((key, value) {
      request.headers.add(key, value);
    });

    final response = await request.close();

    if (response.statusCode != 200) {
      throw HttpException('Failed to load image: ${response.statusCode}');
    }

    final List<int> bytes = [];
    await for (final chunk in response) {
      bytes.addAll(chunk);
    }

    return Uint8List.fromList(bytes);
  }

  /// Compress image to reduce memory usage
  Future<ui.Image> _compressImage(ui.Image image) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Calculate compressed dimensions (maintain aspect ratio)
    const maxDimension = 2048; // Max width or height
    final aspectRatio = image.width / image.height;
    final int newWidth, newHeight;

    if (image.width > image.height) {
      newWidth = math.min(image.width, maxDimension);
      newHeight = (newWidth / aspectRatio).round();
    } else {
      newHeight = math.min(image.height, maxDimension);
      newWidth = (newHeight * aspectRatio).round();
    }

    // Draw compressed image
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      Paint()..isAntiAlias = true,
    );

    final picture = recorder.endRecording();
    final compressedImage = await picture.toImage(newWidth, newHeight);
    picture.dispose();

    return compressedImage;
  }

  /// Cache image in memory with size management
  Future<void> _cacheImage(String url, ui.Image image) async {
    final imageSize = _estimateImageSize(image);

    // Clean up memory if needed
    await _cleanupMemoryCache(additionalSize: imageSize);

    // Add to cache
    _memoryCache[url] = _CacheEntry(
      image: image,
      size: imageSize,
      lastAccessed: DateTime.now(),
    );

    _currentMemoryUsage += imageSize;
  }

  /// Estimate image memory usage in bytes
  int _estimateImageSize(ui.Image image) {
    // Rough estimate: width * height * 4 bytes (RGBA)
    return image.width * image.height * 4;
  }

  /// Clean up memory cache to make space.
  /// P-8: Uses O(1) LRU eviction from the front of the LinkedHashMap instead
  /// of an O(n log n) sort. The LRU order is maintained by remove+reinsert on
  /// every cache hit in [_loadAsync], so the first entry is always the least
  /// recently used.
  Future<void> _cleanupMemoryCache({int additionalSize = 0}) async {
    final targetSize = _maxMemoryBytes - additionalSize;

    // Remove expired entries first.
    _memoryCache.removeWhere((key, value) {
      if (value.isExpired) {
        _currentMemoryUsage -= value.size;
        value.image.dispose();
        return true;
      }
      return false;
    });

    // Evict the least-recently-used entry (map front) until under the limit.
    while (_currentMemoryUsage > targetSize && _memoryCache.isNotEmpty) {
      final lruKey = _memoryCache.keys.first;
      final lruEntry = _memoryCache.remove(lruKey)!;
      _currentMemoryUsage -= lruEntry.size;
      lruEntry.image.dispose();
    }
  }

  /// Create error image for failed loads
  ImageInfo _createErrorImage() {
    // Create a simple error image
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const size = 100.0;

    // Draw error placeholder
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, size, size),
      Paint()..color = Colors.grey[300]!,
    );

    // Draw X
    final paint =
        Paint()
          ..color = Colors.grey[600]!
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

    canvas.drawLine(const Offset(20, 20), const Offset(80, 80), paint);
    canvas.drawLine(const Offset(80, 20), const Offset(20, 80), paint);

    final picture = recorder.endRecording();
    final image = picture.toImageSync(size.toInt(), size.toInt());
    picture.dispose();

    return ImageInfo(image: image, scale: scale);
  }

  /// Clear all cached images (useful for memory pressure)
  static void clearCache() {
    for (final entry in _memoryCache.values) {
      entry.image.dispose();
    }
    _memoryCache.clear();
    _currentMemoryUsage = 0;
  }

  /// Get cache statistics
  static Map<String, dynamic> getCacheStats() {
    return {
      'cachedImages': _memoryCache.length,
      'memoryUsageMB': (_currentMemoryUsage / (1024 * 1024)).toStringAsFixed(2),
      'maxMemoryMB': (_maxMemoryBytes / (1024 * 1024)).toStringAsFixed(2),
    };
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is CachedImageProvider &&
        other.url == url &&
        other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(url, scale);

  @override
  String toString() =>
      '${objectRuntimeType(this, 'CachedImageProvider')}("$url", scale: $scale)';
}

/// Cache entry with metadata
class _CacheEntry {
  _CacheEntry({
    required this.image,
    required this.size,
    required this.lastAccessed,
  });

  final ui.Image image;
  final int size;
  DateTime lastAccessed;

  /// Check if entry is expired (older than 1 hour)
  bool get isExpired {
    return DateTime.now().difference(lastAccessed).inHours > 1;
  }
}

/// Memory pressure handler for the cached image system
class CacheMemoryManager {
  static Timer? _memoryCheckTimer;

  /// Start periodic memory monitoring
  static void startMonitoring() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = Timer.periodic(
      const Duration(minutes: 5),
      (_) => _checkMemoryUsage(),
    );
  }

  /// Stop memory monitoring
  static void stopMonitoring() {
    _memoryCheckTimer?.cancel();
    _memoryCheckTimer = null;
  }

  /// Check memory usage and clean up if needed
  static void _checkMemoryUsage() {
    final stats = CachedImageProvider.getCacheStats();
    final memoryUsageMB = double.tryParse(stats['memoryUsageMB']) ?? 0;

    if (memoryUsageMB > 80) {
      // Cleanup at 80MB
      debugPrint(
        'CacheMemoryManager: Memory usage high ($memoryUsageMB MB), cleaning up',
      );
      CachedImageProvider.clearCache();
    }
  }

  /// Handle system memory pressure
  static void handleMemoryPressure() {
    debugPrint(
      'CacheMemoryManager: Memory pressure detected, clearing image cache',
    );
    CachedImageProvider.clearCache();
  }
}
