import 'package:flutter/material.dart';

/// Widget yang mengoptimalkan rebuilds dengan memcache child widget
class CachedBuilder<T> extends StatefulWidget {
  final T? value;
  final Widget Function(BuildContext context, T value) builder;
  final bool Function(T? oldValue, T? newValue)? shouldRebuild;

  const CachedBuilder({
    super.key,
    required this.value,
    required this.builder,
    this.shouldRebuild,
  });

  @override
  State<CachedBuilder<T>> createState() => _CachedBuilderState<T>();
}

class _CachedBuilderState<T> extends State<CachedBuilder<T>> {
  Widget? _cachedWidget;
  T? _lastValue;

  @override
  Widget build(BuildContext context) {
    final shouldRebuild = widget.shouldRebuild?.call(_lastValue, widget.value) ??
        (_lastValue != widget.value);

    if (_cachedWidget == null || shouldRebuild) {
      if (widget.value != null) {
        _cachedWidget = widget.builder(context, widget.value!);
        _lastValue = widget.value;
      }
    }

    return _cachedWidget ?? const SizedBox.shrink();
  }
}

/// Widget untuk lazy loading list items
class LazyLoadingList<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int initialLoadCount;
  final int loadMoreThreshold;
  final ScrollController? controller;
  final EdgeInsets? padding;

  const LazyLoadingList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialLoadCount = 10,
    this.loadMoreThreshold = 5,
    this.controller,
    this.padding,
  });

  @override
  State<LazyLoadingList<T>> createState() => _LazyLoadingListState<T>();
}

class _LazyLoadingListState<T> extends State<LazyLoadingList<T>> {
  late ScrollController _scrollController;
  int _loadedCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _loadedCount = widget.initialLoadCount.clamp(0, widget.items.length);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 
        (widget.loadMoreThreshold * 100)) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_loadedCount < widget.items.length) {
      setState(() {
        _loadedCount = (_loadedCount + 10).clamp(0, widget.items.length);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = widget.items.take(_loadedCount).toList();

    return ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      itemCount: visibleItems.length + (_loadedCount < widget.items.length ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= visibleItems.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator.adaptive(),
            ),
          );
        }

        return widget.itemBuilder(context, visibleItems[index], index);
      },
    );
  }
}

/// Widget untuk menghindari rebuilds yang tidak perlu di StatefulWidget
mixin AutomaticKeepAliveMixin<T extends StatefulWidget> on State<T>
    implements AutomaticKeepAliveClientMixin<T> {
  @override
  bool get wantKeepAlive => true;
}

/// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String? label;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.label,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  int _buildCount = 0;
  DateTime? _lastBuild;

  @override
  Widget build(BuildContext context) {
    _buildCount++;
    final now = DateTime.now();
    final timeSinceLastBuild = _lastBuild != null 
        ? now.difference(_lastBuild!).inMilliseconds
        : 0;
    _lastBuild = now;

    if (timeSinceLastBuild < 16) { // Less than 60fps
      debugPrint('⚠️  Fast rebuild detected in ${widget.label}: ${timeSinceLastBuild}ms');
    }

    if (_buildCount % 10 == 0) {
      debugPrint('📊 ${widget.label} build count: $_buildCount');
    }

    return widget.child;
  }
}