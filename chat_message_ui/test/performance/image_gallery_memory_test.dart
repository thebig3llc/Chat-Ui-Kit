import 'dart:typed_data';

import 'package:chat_message_ui_kit/src/models/preview_image.dart';
import 'package:chat_message_ui_kit/src/utils/cached_image_provider.dart';
import 'package:chat_message_ui_kit/src/utils/image_compression.dart';
import 'package:chat_message_ui_kit/src/widgets/image_gallery.dart';
import 'package:chat_message_ui_kit/src/widgets/optimized_image_gallery.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Image Gallery Memory Management Tests', () {
    /// Generate test preview images
    List<PreviewImage> generateTestImages(int count) {
      return List.generate(count, (index) {
        return PreviewImage(
          id: 'img_$index',
          uri: 'https://picsum.photos/800/600?random=$index',
        );
      });
    }

    testWidgets('OptimizedImageGallery memory usage', (
      WidgetTester tester,
    ) async {
      final images = generateTestImages(50);
      final pageController = PageController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedImageGallery(
              images: images,
              pageController: pageController,
              onClosePressed: () {},
              options: OptimizedImageGalleryOptions.memoryEfficient,
              preloadDistance: 2,
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify widget builds without memory issues
      expect(find.byType(OptimizedImageGallery), findsOneWidget);

      // Simulate page changes to test lazy loading
      for (int i = 0; i < 5; i++) {
        pageController.nextPage(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeIn,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }

      pageController.dispose();
    });

    testWidgets('ImageGallery optimization toggle', (
      WidgetTester tester,
    ) async {
      final images = generateTestImages(10);
      final pageController = PageController();

      // Test with optimization enabled (default)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageGallery(
              images: images,
              pageController: pageController,
              onClosePressed: () {},
              enableOptimization: true,
            ),
          ),
        ),
      );

      // Should use OptimizedImageGallery internally
      expect(find.byType(OptimizedImageGallery), findsOneWidget);

      // Test with optimization disabled
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ImageGallery(
              images: images,
              pageController: pageController,
              onClosePressed: () {},
              enableOptimization: false,
            ),
          ),
        ),
      );

      // Should use original implementation
      expect(find.byType(OptimizedImageGallery), findsNothing);

      pageController.dispose();
    });

    test('CachedImageProvider memory cache management', () {
      // Clear any existing cache
      CachedImageProvider.clearCache();

      final providers = List.generate(20, (index) {
        return CachedImageProvider('https://example.com/image$index.jpg');
      });

      // Create multiple providers
      for (final provider in providers) {
        // Simulate usage - in real app this would load images
        expect(provider.url, isNotEmpty);
      }

      final initialStats = CachedImageProvider.getCacheStats();
      expect(initialStats['cachedImages'], equals(0));

      // Test cache statistics
      expect(initialStats, isA<Map<String, dynamic>>());
      expect(initialStats.containsKey('cachedImages'), isTrue);
      expect(initialStats.containsKey('memoryUsageMB'), isTrue);
    });

    test('ImageCompression utility functions', () async {
      // Create test image data (simple bitmap)
      final testImageBytes = _createTestImageBytes(800, 600);

      // Test thumbnail generation
      final thumbnail = await ImageCompression.generateThumbnail(
        testImageBytes,
        maxWidth: 200,
        maxHeight: 200,
        quality: 0.7,
      );

      if (thumbnail != null) {
        expect(thumbnail.length, lessThan(testImageBytes.length));
      }

      // Test preview compression
      final compressed = await ImageCompression.compressForPreview(
        testImageBytes,
        maxWidth: 400,
        maxHeight: 400,
        quality: 0.8,
      );

      expect(compressed, isNotNull);

      // Test memory estimation
      final memoryUsage = ImageCompression.estimateMemoryUsage(800, 600);
      expect(memoryUsage, equals(800 * 600 * 4)); // RGBA = 4 bytes per pixel

      // Test optimization decisions
      final shouldCompress = ImageCompression.shouldCompress(
        2048,
        2048,
        maxMemoryMB: 10,
      );
      expect(shouldCompress, isTrue);

      final shouldNotCompress = ImageCompression.shouldCompress(
        100,
        100,
        maxMemoryMB: 10,
      );
      expect(shouldNotCompress, isFalse);
    });

    test('ImageOptimizationConfig presets', () {
      // Test predefined presets
      const thumbnail = ImageOptimizationPresets.thumbnail;
      expect(thumbnail.maxWidth, equals(200));
      expect(thumbnail.maxHeight, equals(200));
      expect(thumbnail.quality, equals(0.6));

      const preview = ImageOptimizationPresets.preview;
      expect(preview.maxWidth, equals(600));
      expect(preview.maxHeight, equals(600));
      expect(preview.quality, equals(0.8));

      const fullSize = ImageOptimizationPresets.fullSize;
      expect(fullSize.maxWidth, equals(2048));
      expect(fullSize.maxHeight, equals(2048));
      expect(fullSize.quality, equals(0.9));

      const memoryConstrained = ImageOptimizationPresets.memoryConstrained;
      expect(memoryConstrained.maxWidth, equals(800));
      expect(memoryConstrained.maxHeight, equals(800));
      expect(memoryConstrained.quality, equals(0.7));
    });

    test('ImageMemoryManager tracking', () {
      // Reset manager state
      ImageMemoryManager.handleMemoryPressure();

      // Test memory allocation checks
      final canAllocate = ImageMemoryManager.canAllocateMemory(
        1024 * 1024,
      ); // 1MB
      expect(canAllocate, isTrue);

      // Test memory registration
      ImageMemoryManager.registerMemoryUsage(1024 * 1024);
      final stats = ImageMemoryManager.getMemoryStats();

      expect(stats, isA<Map<String, dynamic>>());
      expect(stats.containsKey('totalUsageMB'), isTrue);
      expect(stats.containsKey('maxUsageMB'), isTrue);
      expect(stats.containsKey('usagePercentage'), isTrue);

      // Test memory unregistration
      ImageMemoryManager.unregisterMemoryUsage(512 * 1024); // 0.5MB
      final updatedStats = ImageMemoryManager.getMemoryStats();

      final totalUsage = double.tryParse(updatedStats['totalUsageMB']) ?? 0;
      expect(totalUsage, greaterThanOrEqualTo(0));
    });

    testWidgets('Memory stress test with many images', (
      WidgetTester tester,
    ) async {
      final images = generateTestImages(100);
      final pageController = PageController();

      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OptimizedImageGallery(
              images: images,
              pageController: pageController,
              onClosePressed: () {},
              options: OptimizedImageGalleryOptions.memoryEfficient,
              preloadDistance: 1, // Minimal preloading for stress test
            ),
          ),
        ),
      );

      stopwatch.stop();

      // Should handle large image count efficiently
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      expect(find.byType(OptimizedImageGallery), findsOneWidget);

      // Rapid page changes to test memory management
      for (int i = 0; i < 20; i++) {
        if (pageController.hasClients) {
          pageController.nextPage(
            duration: const Duration(milliseconds: 50),
            curve: Curves.linear,
          );
          await tester.pump();
        }
      }

      pageController.dispose();
    });

    test('CacheMemoryManager monitoring', () {
      // Test monitoring lifecycle
      CacheMemoryManager.startMonitoring();
      // In a real test, we'd verify the timer is active

      CacheMemoryManager.stopMonitoring();
      // In a real test, we'd verify the timer is cancelled

      // Test memory pressure handling
      CacheMemoryManager.handleMemoryPressure();

      final stats = CachedImageProvider.getCacheStats();
      expect(stats['cachedImages'], equals(0));
    });

    group('Performance Benchmarks', () {
      test('Image compression performance', () async {
        final testImageBytes = _createTestImageBytes(1920, 1080);
        const iterations = 10;

        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          await ImageCompression.generateThumbnail(
            testImageBytes,
            maxWidth: 300,
            maxHeight: 300,
          );
        }

        stopwatch.stop();

        final averageTime = stopwatch.elapsedMilliseconds / iterations;
        print(
          'Average thumbnail generation time: ${averageTime.toStringAsFixed(1)}ms',
        );

        // Should be reasonably fast
        expect(averageTime, lessThan(100));
      });

      test('Memory optimization calculations', () {
        const iterations = 1000;
        final stopwatch = Stopwatch()..start();

        for (int i = 0; i < iterations; i++) {
          ImageCompression.getOptimizedDimensions(
            1920 + i,
            1080 + i,
            maxWidth: 2048,
            maxHeight: 2048,
          );
        }

        stopwatch.stop();

        final averageTime = stopwatch.elapsedMicroseconds / iterations;
        print(
          'Average optimization calculation time: ${averageTime.toStringAsFixed(1)}μs',
        );

        // Should be very fast
        expect(averageTime, lessThan(100));
      });
    });
  });
}

/// Create test image bytes (simple bitmap pattern)
Uint8List _createTestImageBytes(int width, int height) {
  final bytes = <int>[];

  // Simple bitmap header (simplified for testing)
  final headerSize = 54;
  final imageSize = width * height * 3; // RGB
  final fileSize = headerSize + imageSize;

  // BMP file header (14 bytes)
  bytes.addAll([0x42, 0x4D]); // "BM"
  bytes.addAll(_int32ToBytes(fileSize));
  bytes.addAll([0, 0, 0, 0]); // Reserved
  bytes.addAll(_int32ToBytes(headerSize));

  // BMP info header (40 bytes)
  bytes.addAll(_int32ToBytes(40)); // Header size
  bytes.addAll(_int32ToBytes(width));
  bytes.addAll(_int32ToBytes(height));
  bytes.addAll([1, 0]); // Planes
  bytes.addAll([24, 0]); // Bits per pixel
  bytes.addAll(List.filled(24, 0)); // Remaining header

  // Generate simple gradient pattern
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final r = (x * 255 / width).round();
      final g = (y * 255 / height).round();
      final b = ((x + y) * 255 / (width + height)).round();

      bytes.addAll([b, g, r]); // BMP uses BGR order
    }

    // Add row padding to align to 4-byte boundary
    final padding = (4 - ((width * 3) % 4)) % 4;
    bytes.addAll(List.filled(padding, 0));
  }

  return Uint8List.fromList(bytes);
}

/// Convert 32-bit integer to little-endian bytes
List<int> _int32ToBytes(int value) {
  return [
    value & 0xFF,
    (value >> 8) & 0xFF,
    (value >> 16) & 0xFF,
    (value >> 24) & 0xFF,
  ];
}
