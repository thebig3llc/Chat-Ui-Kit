import 'dart:collection';
import 'package:flutter/widgets.dart';
import '../models/message.dart';

/// A cached widget entry pairing the built widget with the hash of the message
/// it was built from. When the message changes (e.g. status update), the hash
/// no longer matches and the entry is evicted before returning null.
class _CachedEntry {
  const _CachedEntry({required this.widget, required this.messageHashCode});
  final Widget widget;
  final int messageHashCode;
}

/// Manages widget caching and memory usage for chat messages.
/// Uses a message-content hash guard so stale widgets (e.g. status transitions
/// sending → sent → delivered) are never returned from the cache.
class MessageCacheManager {
  MessageCacheManager({this.maxCacheSize = 50});

  /// Maximum number of widgets to cache.
  final int maxCacheSize;

  /// LRU cache: insertion-ordered so the oldest entry is always first.
  final LinkedHashMap<String, _CachedEntry> _cache = LinkedHashMap();

  /// Set of message IDs currently being animated.
  final Set<String> _animatingIds = <String>{};

  /// Returns a cached widget only if the message content hasn't changed.
  /// Pass [messageHashCode] from [MessageModel.hashCode] (Equatable-based).
  Widget? getCachedWidget(String messageId, int messageHashCode) {
    final entry = _cache[messageId];
    if (entry == null) return null;

    // Content changed — evict stale entry.
    if (entry.messageHashCode != messageHashCode) {
      _cache.remove(messageId);
      return null;
    }

    // LRU: move to end (most recently used).
    _cache.remove(messageId);
    _cache[messageId] = entry;
    return entry.widget;
  }

  /// Cache a widget together with [messageHashCode] for future invalidation.
  void cacheWidget(String messageId, Widget widget, int messageHashCode) {
    _cache.remove(messageId);
    _cache[messageId] = _CachedEntry(
      widget: widget,
      messageHashCode: messageHashCode,
    );

    // Evict oldest entries when over capacity.
    while (_cache.length > maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Check if message is currently animating.
  bool isAnimating(String messageId) => _animatingIds.contains(messageId);

  /// Mark message as animating.
  void setAnimating(String messageId, bool animating) {
    if (animating) {
      _animatingIds.add(messageId);
    } else {
      _animatingIds.remove(messageId);
    }
  }

  /// Clear animation state for multiple messages.
  void clearAnimationState(Iterable<String> messageIds) {
    _animatingIds.removeAll(messageIds);
  }

  /// Remove a specific message from the cache.
  void invalidate(String messageId) => _cache.remove(messageId);

  /// Clear all cached widgets.
  void clear() => _cache.clear();

  /// Current cache size (for debugging).
  int get cacheSize => _cache.length;
}

/// Utility class for message ID extraction and comparison.
class MessageUtils {
  /// Extract message IDs from items list using whereType for type safety.
  static Set<String> extractMessageIds(List<Object> items) {
    return items.whereType<Map<String, Object>>().map((item) {
      final message = item['message'] as MessageModel;
      return message.id;
    }).toSet();
  }

  /// Compare two message lists efficiently (shallow comparison).
  static bool listsEqual(List<Object> list1, List<Object> list2) {
    if (list1.length != list2.length) return false;

    for (int i = 0; i < list1.length; i++) {
      final item1 = list1[i];
      final item2 = list2[i];

      if (item1 is Map<String, Object> && item2 is Map<String, Object>) {
        final message1 = item1['message'] as MessageModel;
        final message2 = item2['message'] as MessageModel;
        if (message1.id != message2.id) return false;
      } else if (item1 != item2) {
        return false;
      }
    }

    return true;
  }

  /// Extract message from item safely.
  static MessageModel? extractMessage(Object item) {
    if (item is Map<String, Object> && item.containsKey('message')) {
      return item['message'] as MessageModel;
    }
    return null;
  }
}
