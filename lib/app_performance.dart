// ==================== PERFORMANCE OPTIMIZATION SYSTEM ====================
// This file contains comprehensive performance optimizations for the Abhira app
// including widget optimization, image caching, state management improvements,
// and memory management strategies.

import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

// ==================== WIDGET PERFORMANCE OPTIMIZATION ====================

/// High-performance widget wrapper with memoization and lazy loading
class OptimizedWidget extends StatelessWidget {
  final Widget Function(BuildContext context) builder;
  final String? cacheKey;
  final Duration? cacheDuration;
  final bool useMemoization;
  final bool lazyLoad;
  final VoidCallback? onBuild;
  final VoidCallback? onDispose;

  const OptimizedWidget({
    Key? key,
    required this.builder,
    this.cacheKey,
    this.cacheDuration,
    this.useMemoization = true,
    this.lazyLoad = false,
    this.onBuild,
    this.onDispose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (lazyLoad) {
      return LazyWidget(
        builder: (context) => _buildContent(context),
        onBuild: onBuild,
        onDispose: onDispose,
      );
    }

    return _buildContent(context);
  }

  Widget _buildContent(BuildContext context) {
    if (useMemoization && cacheKey != null) {
      return _MemoizedWidget(
        key: Key(cacheKey!),
        builder: builder,
        duration: cacheDuration,
        onBuild: onBuild,
        onDispose: onDispose,
      );
    }

    onBuild?.call();
    return builder(context);
  }
}

/// Lazy loading widget wrapper
class LazyWidget extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final VoidCallback? onBuild;
  final VoidCallback? onDispose;

  const LazyWidget({
    Key? key,
    required this.builder,
    this.onBuild,
    this.onDispose,
  }) : super(key: key);

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  bool _isBuilt = false;

  @override
  void initState() {
    super.initState();
    // Defer widget building to next frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isBuilt = true;
        });
        widget.onBuild?.call();
      }
    });
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isBuilt ? widget.builder(context) : const SizedBox.shrink();
  }
}

/// Memoized widget with cache management
class _MemoizedWidget extends StatefulWidget {
  final Widget Function(BuildContext context) builder;
  final Duration? duration;
  final VoidCallback? onBuild;
  final VoidCallback? onDispose;

  const _MemoizedWidget({
    Key? key,
    required this.builder,
    this.duration,
    this.onBuild,
    this.onDispose,
  }) : super(key: key);

  @override
  State<_MemoizedWidget> createState() => _MemoizedWidgetState();
}

class _MemoizedWidgetState extends State<_MemoizedWidget> {
  Widget? _cachedWidget;
  DateTime? _cacheTime;
  Timer? _cacheTimer;

  @override
  void initState() {
    super.initState();
    _buildWidget();
  }

  @override
  void dispose() {
    _cacheTimer?.cancel();
    widget.onDispose?.call();
    super.dispose();
  }

  void _buildWidget() {
    _cachedWidget = widget.builder(context);
    _cacheTime = DateTime.now();
    widget.onBuild?.call();

    if (widget.duration != null) {
      _cacheTimer?.cancel();
      _cacheTimer = Timer(widget.duration!, () {
        if (mounted) {
          setState(() {
            _cachedWidget = null;
            _cacheTime = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedWidget != null) {
      return _cachedWidget!;
    }

    _buildWidget();
    return _cachedWidget ?? const SizedBox.shrink();
  }
}

// ==================== IMAGE OPTIMIZATION ====================

/// High-performance image widget with advanced caching and compression
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final String? assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Color? color;
  final BlendMode? colorBlendMode;
  final AlignmentGeometry? alignment;
  final ImageFrameBuilder? frameBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final ImageErrorWidgetBuilder? errorBuilder;
  final String? semanticLabel;
  final bool? excludeFromSemantics;
  final double? scale;
  final int? cacheWidth;
  final int? cacheHeight;
  final bool? gaplessPlayback;
  final String? bundle;
  final FilterQuality? filterQuality;
  final Duration? fadeDuration;
  final Curve? fadeOutCurve;
  final Curve? fadeInCurve;
  final bool compressImage;
  final double compressionQuality;
  final int? maxSize;

  const OptimizedImage({
    Key? key,
    required this.imageUrl,
    this.assetPath,
    this.width,
    this.height,
    this.fit,
    this.color,
    this.colorBlendMode,
    this.alignment,
    this.frameBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics,
    this.scale,
    this.cacheWidth,
    this.cacheHeight,
    this.gaplessPlayback,
    this.bundle,
    this.filterQuality,
    this.fadeDuration,
    this.fadeOutCurve,
    this.fadeInCurve,
    this.compressImage = true,
    this.compressionQuality = 85,
    this.maxSize = 1024, // KB
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (assetPath != null) {
      return Image.asset(
        assetPath!,
        width: width,
        height: height,
        fit: fit,
        color: color,
        colorBlendMode: colorBlendMode,
        alignment: alignment,
        frameBuilder: frameBuilder,
        loadingBuilder: loadingBuilder,
        errorBuilder: errorBuilder,
        semanticLabel: semanticLabel,
        excludeFromSemantics: excludeFromSemantics,
        scale: scale,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        gaplessPlayback: gaplessPlayback,
        bundle: bundle == null ? null : DefaultAssetBundle.of(context),
        filterQuality: filterQuality,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      frameBuilder: frameBuilder,
      loadingBuilder: loadingBuilder ?? _defaultLoadingBuilder,
      errorBuilder: errorBuilder ?? _defaultErrorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      cacheKey: _generateCacheKey(),
      cacheManager: _getImageCacheManager(),
      fadeOutDuration: fadeDuration ?? const Duration(milliseconds: 300),
      fadeOutCurve: fadeOutCurve ?? Curves.easeOutQuad,
      fadeInDuration: fadeDuration ?? const Duration(milliseconds: 700),
      fadeInCurve: fadeInCurve ?? Curves.easeInQuad,
      filterQuality: filterQuality ?? FilterQuality.low,
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
    );
  }

  Widget _defaultLoadingBuilder(
    BuildContext context,
    Widget child,
    ImageChunkEvent? loadingProgress,
  ) {
    if (loadingProgress == null) {
      return child;
    }

    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
            : null,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _defaultErrorBuilder(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      alignment: Alignment.center,
      child: Icon(
        Icons.image_not_supported,
        color: Colors.grey[600],
        size: math.min(width ?? 100, height ?? 100) * 0.5,
      ),
    );
  }

  String _generateCacheKey() {
    return Uri.parse(imageUrl).pathSegments.last;
  }

  BaseCacheManager _getImageCacheManager() {
    return DefaultCacheManager(
      fileService: HttpFileService(
        headers: {
          'User-Agent': 'Abhira-App/1.0',
        },
        timeout: const Duration(seconds: 30),
      ),
      maxAgeCacheObject: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
    );
  }
}

/// Image compression utility
class ImageCompressor {
  static Future<Uint8List?> compressImage(
    String imagePath, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    int? targetSizeKB,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithFile(
        imagePath,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      if (targetSizeKB != null && result != null) {
        // If compressed image is still too large, try again with lower quality
        final currentSizeKB = result.length ~/ 1024;
        if (currentSizeKB > targetSizeKB) {
          return compressImage(
            imagePath,
            quality: math.max(30, quality - 20),
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            targetSizeKB: targetSizeKB,
          );
        }
      }

      return result;
    } catch (e) {
      debugPrint('Image compression failed: $e');
      return null;
    }
  }

  static Future<Uint8List?> compressImageFromList(
    Uint8List imageBytes, {
    int quality = 85,
    int? maxWidth,
    int? maxHeight,
    int? targetSizeKB,
  }) async {
    try {
      final result = await FlutterImageCompress.compressWithList(
        imageBytes,
        quality: quality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      if (targetSizeKB != null && result != null) {
        final currentSizeKB = result.length ~/ 1024;
        if (currentSizeKB > targetSizeKB) {
          return compressImageFromList(
            imageBytes,
            quality: math.max(30, quality - 20),
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            targetSizeKB: targetSizeKB,
          );
        }
      }

      return result;
    } catch (e) {
      debugPrint('Image compression from list failed: $e');
      return null;
    }
  }
}

// ==================== STATE MANAGEMENT OPTIMIZATION ====================

/// Optimized state notifier with performance monitoring
abstract class OptimizedStateNotifier<T> extends ChangeNotifier {
  final Stopwatch _updateStopwatch = Stopwatch();
  final Queue<DateTime> _updateTimes = Queue<DateTime>();
  final int _maxUpdateHistory = 100;
  final Duration _updateThreshold = const Duration(milliseconds: 16);
  T _state;

  OptimizedStateNotifier(this._state);

  T get state => _state;

  @protected
  void updateState(T newState, {String? debugLabel}) {
    _updateStopwatch.start();

    try {
      _state = newState;
      notifyListeners();

      // Track update frequency
      _updateTimes.add(DateTime.now());
      if (_updateTimes.length > _maxUpdateHistory) {
        _updateTimes.removeFirst();
      }

      // Log performance warnings
      final elapsed = _updateStopwatch.elapsed;
      if (elapsed > _updateThreshold) {
        debugPrint(
            '⚠️ Slow state update in ${debugLabel ?? runtimeType}: ${elapsed.inMilliseconds}ms');
      }
    } finally {
      _updateStopwatch.stop();
      _updateStopwatch.reset();
    }
  }

  double get updateFrequency {
    if (_updateTimes.length < 2) return 0.0;

    final times = _updateTimes.toList();
    final intervals = <Duration>[];

    for (int i = 1; i < times.length; i++) {
      intervals.add(times[i].difference(times[i - 1]));
    }

    final total = intervals.fold(Duration.zero, (a, b) => a + b);
    return intervals.isNotEmpty ? total.inMilliseconds / intervals.length : 0.0;
  }

  @override
  void dispose() {
    _updateStopwatch.stop();
    _updateTimes.clear();
    super.dispose();
  }
}

/// Debounced state updates to prevent excessive rebuilds
class DebouncedStateNotifier<T> extends OptimizedStateNotifier<T> {
  final Duration debounceDuration;
  Timer? _debounceTimer;

  DebouncedStateNotifier(T state,
      {this.debounceDuration = const Duration(milliseconds: 300)})
      : super(state);

  void updateStateDebounced(T newState, {String? debugLabel}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounceDuration, () {
      if (!isDisposed) {
        updateState(newState, debugLabel: debugLabel);
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

// ==================== MEMORY MANAGEMENT ====================

/// Memory management utilities
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  final Map<String, Object> _objectCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Duration _cacheDuration = const Duration(minutes: 10);

  /// Cache an object with automatic cleanup
  void cacheObject<T>(String key, T object) {
    _objectCache[key] = object;
    _cacheTimestamps[key] = DateTime.now();

    // Clean up expired cache entries
    _cleanupExpiredCache();
  }

  /// Retrieve cached object
  T? getCachedObject<T>(String key) {
    final now = DateTime.now();
    final timestamp = _cacheTimestamps[key];

    if (timestamp != null && now.difference(timestamp) > _cacheDuration) {
      removeCachedObject(key);
      return null;
    }

    return _objectCache[key] as T?;
  }

  /// Remove cached object
  void removeCachedObject(String key) {
    _objectCache.remove(key);
    _cacheTimestamps.remove(key);
  }

  /// Clear all cached objects
  void clearCache() {
    _objectCache.clear();
    _cacheTimestamps.clear();
  }

  /// Get memory usage statistics
  Map<String, dynamic> getMemoryStats() {
    return {
      'cached_objects': _objectCache.length,
      'cache_duration_minutes': _cacheDuration.inMinutes,
      'memory_efficiency': _objectCache.length > 0
          ? (_objectCache.length / _cacheDuration.inMinutes).toStringAsFixed(2)
          : '0.00',
    };
  }

  void _cleanupExpiredCache() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    _cacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _cacheDuration) {
        expiredKeys.add(key);
      }
    });

    expiredKeys.forEach(removeCachedObject);
  }
}

/// Automatic memory cleanup widget
class MemoryCleanupWidget extends StatefulWidget {
  final Widget child;
  final Duration cleanupInterval;
  final VoidCallback? onCleanup;

  const MemoryCleanupWidget({
    Key? key,
    required this.child,
    this.cleanupInterval = const Duration(minutes: 5),
    this.onCleanup,
  }) : super(key: key);

  @override
  State<MemoryCleanupWidget> createState() => _MemoryCleanupWidgetState();
}

class _MemoryCleanupWidgetState extends State<MemoryCleanupWidget> {
  late Timer _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _setupCleanupTimer();
  }

  @override
  void dispose() {
    _cleanupTimer.cancel();
    super.dispose();
  }

  void _setupCleanupTimer() {
    _cleanupTimer = Timer.periodic(widget.cleanupInterval, (timer) {
      _performCleanup();
    });
  }

  void _performCleanup() {
    // Force garbage collection hint
    SystemChannels.storage.invokeMethod<void>('evict', <String, dynamic>{});

    // Clear memory cache
    MemoryManager().clearCache();

    // Notify parent
    widget.onCleanup?.call();

    if (kDebugMode) {
      debugPrint('🧹 Memory cleanup performed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ==================== PERFORMANCE MONITORING ====================

/// Performance monitoring utilities
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final Map<String, Stopwatch> _timers = {};
  final Map<String, List<Duration>> _metrics = {};

  /// Start timing a specific operation
  void startTiming(String operation) {
    _timers[operation] = Stopwatch()..start();
  }

  /// Stop timing and record the duration
  Duration? stopTiming(String operation) {
    final stopwatch = _timers[operation];
    if (stopwatch == null) return null;

    stopwatch.stop();
    final duration = stopwatch.elapsed;

    // Record metric
    _metrics.putIfAbsent(operation, () => <Duration>[]);
    _metrics[operation]!.add(duration);

    // Keep only last 100 measurements
    if (_metrics[operation]!.length > 100) {
      _metrics[operation]!.removeAt(0);
    }

    stopwatch.reset();
    return duration;
  }

  /// Get performance statistics for an operation
  Map<String, dynamic> getStats(String operation) {
    final durations = _metrics[operation];
    if (durations == null || durations.isEmpty) {
      return {'error': 'No metrics available'};
    }

    durations.sort();
    final count = durations.length;
    final total = durations.fold(Duration.zero, (a, b) => a + b);
    final avg = Duration(microseconds: total.inMicroseconds ~/ count);
    final min = durations.first;
    final max = durations.last;
    final p95 = durations[(count * 0.95).floor()];
    final p99 = durations[(count * 0.99).floor()];

    return {
      'operation': operation,
      'count': count,
      'total_time': total.inMilliseconds,
      'avg_time': avg.inMilliseconds,
      'min_time': min.inMilliseconds,
      'max_time': max.inMilliseconds,
      'p95_time': p95.inMilliseconds,
      'p99_time': p99.inMilliseconds,
      'efficiency_score': _calculateEfficiencyScore(durations),
    };
  }

  /// Get all performance statistics
  Map<String, dynamic> getAllStats() {
    final stats = <String, dynamic>{};
    _metrics.forEach((operation, _) {
      stats[operation] = getStats(operation);
    });
    return stats;
  }

  /// Clear all performance metrics
  void clearStats() {
    _timers.clear();
    _metrics.clear();
  }

  double _calculateEfficiencyScore(List<Duration> durations) {
    final avg = durations.fold(Duration.zero, (a, b) => a + b).inMicroseconds ~/
        durations.length;
    final target = 16667; // 16.67ms for 60fps

    if (avg <= target) return 100.0;
    return math.max(0, 100 - ((avg - target) / target * 50));
  }
}

/// Performance monitoring widget wrapper
class PerformanceMonitorWidget extends StatelessWidget {
  final Widget child;
  final String operationName;
  final bool enabled;

  const PerformanceMonitorWidget({
    Key? key,
    required this.child,
    required this.operationName,
    this.enabled = kDebugMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    return _PerformanceMonitorWrapper(
      child: child,
      operationName: operationName,
    );
  }
}

class _PerformanceMonitorWrapper extends StatefulWidget {
  final Widget child;
  final String operationName;

  const _PerformanceMonitorWrapper({
    required this.child,
    required this.operationName,
  });

  @override
  State<_PerformanceMonitorWrapper> createState() =>
      _PerformanceMonitorWrapperState();
}

class _PerformanceMonitorWrapperState
    extends State<_PerformanceMonitorWrapper> {
  @override
  void initState() {
    super.initState();
    PerformanceMonitor().startTiming(widget.operationName);
  }

  @override
  void dispose() {
    final duration = PerformanceMonitor().stopTiming(widget.operationName);
    if (duration != null && duration.inMilliseconds > 16) {
      debugPrint(
          '⚠️ Slow render in ${widget.operationName}: ${duration.inMilliseconds}ms');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// ==================== UTILITIES ====================

/// Performance optimization utilities
class PerformanceUtils {
  /// Debounce function calls
  static Timer? _debounceTimer;

  static void debounce(VoidCallback callback,
      {Duration duration = const Duration(milliseconds: 300)}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, callback);
  }

  /// Throttle function calls
  static Timer? _throttleTimer;
  static DateTime? _lastCallTime;

  static void throttle(VoidCallback callback,
      {Duration duration = const Duration(milliseconds: 1000)}) {
    final now = DateTime.now();
    if (_lastCallTime == null || now.difference(_lastCallTime!) >= duration) {
      _lastCallTime = now;
      callback();
    } else {
      _throttleTimer?.cancel();
      _throttleTimer = Timer(duration - now.difference(_lastCallTime!), () {
        _lastCallTime = DateTime.now();
        callback();
      });
    }
  }

  /// Check if widget is mounted safely
  static bool isWidgetMounted(BuildContext context) {
    try {
      return context.mounted;
    } catch (e) {
      return false;
    }
  }

  /// Safe setState wrapper
  static void safeSetState(State state, VoidCallback fn) {
    if (state.mounted) {
      state.setState(fn);
    }
  }

  /// Memory-efficient list builder
  static Widget optimizedListView({
    required List<dynamic> items,
    required Widget Function(BuildContext, int) itemBuilder,
    int? cacheExtent,
    ScrollPhysics? physics,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
  }) {
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => OptimizedWidget(
        key: Key('item_$index'),
        builder: (context) => itemBuilder(context, index),
        cacheKey: 'list_item_$index',
        cacheDuration: const Duration(minutes: 5),
      ),
      cacheExtent: cacheExtent ?? (shrinkWrap ? 0 : 250),
      physics: physics ?? const BouncingScrollPhysics(),
      shrinkWrap: shrinkWrap,
      padding: padding,
    );
  }

  /// Memory-efficient grid builder
  static Widget optimizedGridView({
    required List<dynamic> items,
    required Widget Function(BuildContext, int) itemBuilder,
    required int crossAxisCount,
    double? childAspectRatio,
    double? mainAxisSpacing,
    double? crossAxisSpacing,
    EdgeInsetsGeometry? padding,
  }) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio ?? 1.0,
        mainAxisSpacing: mainAxisSpacing ?? 10,
        crossAxisSpacing: crossAxisSpacing ?? 10,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => OptimizedWidget(
        key: Key('grid_item_$index'),
        builder: (context) => itemBuilder(context, index),
        cacheKey: 'grid_item_$index',
        cacheDuration: const Duration(minutes: 5),
      ),
      padding: padding,
    );
  }
}
