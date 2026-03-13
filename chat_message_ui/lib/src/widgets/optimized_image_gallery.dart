import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../utils/conditional.dart';
import '../models/preview_image.dart';

/// Memory-optimized image gallery with lazy loading and automatic disposal
/// of off-screen images to prevent memory leaks and OOM crashes.
class OptimizedImageGallery extends StatefulWidget {
  const OptimizedImageGallery({
    super.key,
    this.imageHeaders,
    this.imageProviderBuilder,
    required this.images,
    required this.onClosePressed,
    this.options = const OptimizedImageGalleryOptions(),
    required this.pageController,
    this.preloadDistance = 1,
  });

  final Map<String, String>? imageHeaders;
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })?
  imageProviderBuilder;

  /// Images to show in the gallery
  final List<PreviewImage> images;

  /// Triggered when the gallery is closed
  final VoidCallback onClosePressed;

  /// Gallery customization options
  final OptimizedImageGalleryOptions options;

  /// Page controller for the image pages
  final PageController pageController;

  /// Number of images to preload before/after current page (default: 1)
  final int preloadDistance;

  @override
  State<OptimizedImageGallery> createState() => _OptimizedImageGalleryState();
}

class _OptimizedImageGalleryState extends State<OptimizedImageGallery>
    with WidgetsBindingObserver {
  /// Current page index
  int _currentPage = 0;

  /// Map to track loaded image providers to enable disposal
  final Map<int, ImageProvider> _loadedProviders = {};

  /// Set of indices that should be preloaded
  final Set<int> _preloadedIndices = {};

  /// Timer for delayed cleanup of off-screen images
  Timer? _cleanupTimer;

  /// Memory pressure listener
  StreamSubscription<void>? _memoryPressureSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentPage = widget.pageController.initialPage.clamp(
      0,
      widget.images.length - 1,
    );
    _updatePreloadIndices();

    // Listen to page changes
    widget.pageController.addListener(_onPageChanged);

    // Set up periodic cleanup
    _scheduleCleanup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.pageController.removeListener(_onPageChanged);
    _cleanupTimer?.cancel();
    _memoryPressureSubscription?.cancel();

    // Clean up all loaded providers
    _disposeAllProviders();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Aggressive cleanup when app goes to background
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _performMemoryCleanup(aggressive: true);
    }
  }

  @override
  void didHaveMemoryPressure() {
    super.didHaveMemoryPressure();

    // Emergency cleanup on memory pressure
    _performMemoryCleanup(aggressive: true);
  }

  /// Handle page changes to update preloading
  void _onPageChanged() {
    final page = widget.pageController.page?.round() ?? _currentPage;
    if (page != _currentPage) {
      setState(() {
        _currentPage = page;
      });
      _updatePreloadIndices();
      _scheduleCleanup();
    }
  }

  /// Update which images should be preloaded based on current page
  void _updatePreloadIndices() {
    final newPreloadIndices = <int>{};

    for (
      int i = math.max(0, _currentPage - widget.preloadDistance);
      i <=
          math.min(
            widget.images.length - 1,
            _currentPage + widget.preloadDistance,
          );
      i++
    ) {
      newPreloadIndices.add(i);
    }

    _preloadedIndices.clear();
    _preloadedIndices.addAll(newPreloadIndices);
  }

  /// Schedule cleanup of off-screen images
  void _scheduleCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer(
      Duration(seconds: widget.options.cleanupDelaySeconds),
      () => _performMemoryCleanup(),
    );
  }

  /// Perform memory cleanup by disposing off-screen images
  void _performMemoryCleanup({bool aggressive = false}) {
    final indicesToRemove = <int>[];

    for (final index in _loadedProviders.keys) {
      final shouldKeep =
          aggressive
              ? index ==
                  _currentPage // Only keep current image if aggressive
              : _preloadedIndices.contains(
                index,
              ); // Keep preloaded images normally

      if (!shouldKeep) {
        indicesToRemove.add(index);
      }
    }

    for (final index in indicesToRemove) {
      _disposeImageProvider(index);
    }

    if (indicesToRemove.isNotEmpty) {
      debugPrint(
        'OptimizedImageGallery: Cleaned up ${indicesToRemove.length} images',
      );
    }
  }

  /// Dispose a specific image provider
  void _disposeImageProvider(int index) {
    final provider = _loadedProviders.remove(index);
    if (provider != null) {
      // For network images, we can't directly dispose the provider,
      // but removing the reference allows GC to clean it up
      provider.evict();
    }
  }

  /// Dispose all image providers
  void _disposeAllProviders() {
    for (final provider in _loadedProviders.values) {
      provider.evict();
    }
    _loadedProviders.clear();
    _preloadedIndices.clear();
  }

  /// Get or create image provider for the given index
  ImageProvider? _getImageProvider(int index) {
    if (!_preloadedIndices.contains(index)) {
      return null; // Don't load if not in preload range
    }

    if (_loadedProviders.containsKey(index)) {
      return _loadedProviders[index];
    }

    // Create new provider
    final provider =
        widget.imageProviderBuilder != null
            ? widget.imageProviderBuilder!(
              uri: widget.images[index].uri,
              imageHeaders: widget.imageHeaders,
              conditional: Conditional(),
            )
            : Conditional().createImageProvider(
              widget.images[index].uri,
              headers: widget.imageHeaders,
            );

    // Apply memory optimizations
    ImageProvider optimizedProvider = provider;

    if (widget.options.enableCaching) {
      // Wrap with memory-limited cached provider if needed
      optimizedProvider = _wrapWithMemoryLimits(provider);
    }

    _loadedProviders[index] = optimizedProvider;
    return optimizedProvider;
  }

  /// Wrap image provider with memory limits
  ImageProvider _wrapWithMemoryLimits(ImageProvider provider) {
    // If using ResizeImage, apply it here for memory optimization
    if (widget.options.maxImageWidth != null ||
        widget.options.maxImageHeight != null) {
      return ResizeImage(
        provider,
        width: widget.options.maxImageWidth,
        height: widget.options.maxImageHeight,
        allowUpscaling: false,
      );
    }
    return provider;
  }

  /// Loading widget for gallery images
  Widget _imageGalleryLoadingBuilder(ImageChunkEvent? event) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value:
                  event == null || event.expectedTotalBytes == null
                      ? null
                      : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
              strokeWidth: 3,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading image ${_currentPage + 1} of ${widget.images.length}',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  /// Error widget for failed image loads
  Widget _imageGalleryErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.white70),
          const SizedBox(height: 16),
          const Text(
            'Failed to load image',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Retry loading by disposing and recreating the provider
              _disposeImageProvider(_currentPage);
              setState(() {}); // Trigger rebuild
            },
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          widget.onClosePressed();
        }
      },
      child: Dismissible(
        key: const Key('optimized_photo_view_gallery'),
        direction: DismissDirection.down,
        onDismissed: (direction) => widget.onClosePressed(),
        child: Container(
          color: Colors.black,
          child: Stack(
            children: [
              PhotoViewGallery.builder(
                builder: (BuildContext context, int index) {
                  final imageProvider = _getImageProvider(index);

                  if (imageProvider == null) {
                    // Show placeholder for non-preloaded images
                    return PhotoViewGalleryPageOptions.customChild(
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    );
                  }

                  return PhotoViewGalleryPageOptions(
                    imageProvider: imageProvider,
                    minScale: widget.options.minScale,
                    maxScale: widget.options.maxScale,
                    errorBuilder: _imageGalleryErrorBuilder,
                  );
                },
                itemCount: widget.images.length,
                loadingBuilder:
                    (context, event) => _imageGalleryLoadingBuilder(event),
                pageController: widget.pageController,
                scrollPhysics: const ClampingScrollPhysics(),
                onPageChanged: (index) {
                  _currentPage = index;
                  _updatePreloadIndices();
                  _scheduleCleanup();
                },
              ),

              // Close button
              Positioned.directional(
                end: 16,
                textDirection: Directionality.of(context),
                top: 56,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CloseButton(
                    color: Colors.white,
                    onPressed: widget.onClosePressed,
                  ),
                ),
              ),

              // Image counter
              Positioned.directional(
                start: 16,
                textDirection: Directionality.of(context),
                top: 64,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${widget.images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ),

              // Memory usage indicator (debug mode)
              if (widget.options.showMemoryUsage && kDebugMode)
                Positioned.directional(
                  end: 16,
                  textDirection: Directionality.of(context),
                  bottom: 100,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Loaded: ${_loadedProviders.length}/${widget.images.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Configuration options for the optimized image gallery
class OptimizedImageGalleryOptions {
  const OptimizedImageGalleryOptions({
    this.maxScale,
    this.minScale,
    this.enableCaching = true,
    this.maxImageWidth,
    this.maxImageHeight,
    this.cleanupDelaySeconds = 10,
    this.showMemoryUsage = false,
  });

  /// See [PhotoViewGalleryPageOptions.maxScale]
  final dynamic maxScale;

  /// See [PhotoViewGalleryPageOptions.minScale]
  final dynamic minScale;

  /// Whether to enable memory-optimized caching
  final bool enableCaching;

  /// Maximum width for loaded images (for memory optimization)
  final int? maxImageWidth;

  /// Maximum height for loaded images (for memory optimization)
  final int? maxImageHeight;

  /// Delay before cleaning up off-screen images (seconds)
  final int cleanupDelaySeconds;

  /// Whether to show memory usage indicator (debug mode)
  final bool showMemoryUsage;

  /// High memory efficiency preset
  static const OptimizedImageGalleryOptions memoryEfficient =
      OptimizedImageGalleryOptions(
        enableCaching: true,
        maxImageWidth: 1920,
        maxImageHeight: 1920,
        cleanupDelaySeconds: 5,
      );

  /// Balanced performance preset
  static const OptimizedImageGalleryOptions balanced =
      OptimizedImageGalleryOptions(
        enableCaching: true,
        maxImageWidth: 2560,
        maxImageHeight: 2560,
        cleanupDelaySeconds: 10,
      );
}
