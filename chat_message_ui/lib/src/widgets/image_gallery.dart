import 'package:flutter/material.dart';
import 'package:photo_view/photo_view_gallery.dart';

import '../utils/conditional.dart';
import '../models/preview_image.dart';
import 'optimized_image_gallery.dart';

/// Image gallery widget with automatic memory optimization.
/// This widget now uses OptimizedImageGallery internally for better performance
/// with large image sets while maintaining the same API for backward compatibility.
class ImageGallery extends StatelessWidget {
  const ImageGallery({
    super.key,
    this.imageHeaders,
    this.imageProviderBuilder,
    required this.images,
    required this.onClosePressed,
    this.options = const ImageGalleryOptions(),
    required this.pageController,
    this.enableOptimization = true,
  });

  /// See [Chat.imageHeaders].
  final Map<String, String>? imageHeaders;

  /// See [Chat.imageProviderBuilder].
  final ImageProvider Function({
    required String uri,
    required Map<String, String>? imageHeaders,
    required Conditional conditional,
  })?
  imageProviderBuilder;

  /// Images to show in the gallery.
  final List<PreviewImage> images;

  /// Triggered when the gallery is swiped down or closed via the icon.
  final VoidCallback onClosePressed;

  /// Customisation options for the gallery.
  final ImageGalleryOptions options;

  /// Page controller for the image pages.
  final PageController pageController;

  /// Whether to enable memory optimization (default: true)
  final bool enableOptimization;

  @override
  Widget build(BuildContext context) {
    if (enableOptimization) {
      // Use optimized gallery with memory management
      return OptimizedImageGallery(
        imageHeaders: imageHeaders,
        imageProviderBuilder: imageProviderBuilder,
        images: images,
        onClosePressed: onClosePressed,
        options: OptimizedImageGalleryOptions(
          maxScale: options.maxScale,
          minScale: options.minScale,
          enableCaching: true,
          maxImageWidth: 2048,
          maxImageHeight: 2048,
          cleanupDelaySeconds: 10,
        ),
        pageController: pageController,
        preloadDistance: 1,
      );
    } else {
      // Use original implementation (fallback)
      return _buildOriginalGallery(context);
    }
  }

  /// Build original gallery implementation (fallback)
  Widget _buildOriginalGallery(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          onClosePressed();
        }
      },
      child: Dismissible(
        key: const Key('photo_view_gallery'),
        direction: DismissDirection.down,
        onDismissed: (direction) => onClosePressed(),
        child: Stack(
          children: [
            PhotoViewGallery.builder(
              builder: (BuildContext context, int index) {
                return PhotoViewGalleryPageOptions(
                  imageProvider:
                      imageProviderBuilder != null
                          ? imageProviderBuilder!(
                            uri: images[index].uri,
                            imageHeaders: imageHeaders,
                            conditional: Conditional(),
                          )
                          : Conditional().createImageProvider(
                            images[index].uri,
                            headers: imageHeaders,
                          ),
                  minScale: options.minScale,
                  maxScale: options.maxScale,
                );
              },
              itemCount: images.length,
              loadingBuilder: (context, event) {
                return _imageGalleryLoadingBuilder(event);
              },
              pageController: pageController,
              scrollPhysics: const ClampingScrollPhysics(),
            ),
            Positioned.directional(
              end: 16,
              textDirection: Directionality.of(context),
              top: 56,
              child: CloseButton(
                color: Colors.white,
                onPressed: onClosePressed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageGalleryLoadingBuilder(ImageChunkEvent? event) {
    return Center(
      child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          value:
              event == null || event.expectedTotalBytes == null
                  ? 0
                  : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
        ),
      ),
    );
  }
}

class ImageGalleryOptions {
  const ImageGalleryOptions({this.maxScale, this.minScale});

  /// See [PhotoViewGalleryPageOptions.maxScale].
  final dynamic maxScale;

  /// See [PhotoViewGalleryPageOptions.minScale].
  final dynamic minScale;
}
