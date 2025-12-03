// lib/widgets/paginated_list_view.dart
import 'package:flutter/material.dart';

/// A widget that provides infinite scroll pagination for large lists.
/// 
/// Automatically loads more items when user scrolls near the bottom.
/// 
/// Example:
/// ```dart
/// PaginatedListView<Course>(
///   fetcher: (page) => courseService.getCourses(page: page, limit: 20),
///   itemBuilder: (context, course) => CourseCard(course: course),
///   emptyMessage: 'No courses available',
/// )
/// ```
class PaginatedListView<T> extends StatefulWidget {
  /// Function to fetch data for a given page.
  /// Should return a Future<List<T>>.
  final Future<List<T>> Function(int page) fetcher;
  
  /// Builder function to create widget for each item.
  final Widget Function(BuildContext context, T item) itemBuilder;
  
  /// Message to show when list is empty.
  final String emptyMessage;
  
  /// Number of items per page (default: 20).
  final int itemsPerPage;
  
  /// Threshold percentage to trigger load more (default: 0.8 = 80%).
  final double loadMoreThreshold;
  
  /// Optional separator between items.
  final Widget? separator;
  
  /// Optional pull-to-refresh callback.
  final Future<void> Function()? onRefresh;

  const PaginatedListView({
    super.key,
    required this.fetcher,
    required this.itemBuilder,
    this.emptyMessage = 'No items found',
    this.itemsPerPage = 20,
    this.loadMoreThreshold = 0.8,
    this.separator,
    this.onRefresh,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * widget.loadMoreThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final items = await widget.fetcher(1);
      setState(() {
        _items.clear();
        _items.addAll(items);
        _currentPage = 1;
        _hasMore = items.length >= widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final newItems = await widget.fetcher(nextPage);
      
      setState(() {
        _items.addAll(newItems);
        _currentPage = nextPage;
        _hasMore = newItems.length >= widget.itemsPerPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load more items';
        _isLoadingMore = false;
      });
      
      // Show snackbar for load more errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load more: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh != null) {
      await widget.onRefresh!();
    }
    await _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null && _items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              widget.emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      );
    }

    final listView = ListView.separated(
      controller: _scrollController,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      separatorBuilder: (context, index) => 
          widget.separator ?? const SizedBox.shrink(),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          // Loading indicator at bottom
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: _isLoadingMore
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }
        return widget.itemBuilder(context, _items[index]);
      },
    );

    if (widget.onRefresh != null) {
      return RefreshIndicator(
        onRefresh: _handleRefresh,
        child: listView,
      );
    }

    return listView;
  }
}

/// A simpler paginated grid view for grid layouts.
class PaginatedGridView<T> extends StatefulWidget {
  final Future<List<T>> Function(int page) fetcher;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final int itemsPerPage;
  final int crossAxisCount;
  final double childAspectRatio;
  final double crossAxisSpacing;
  final double mainAxisSpacing;

  const PaginatedGridView({
    super.key,
    required this.fetcher,
    required this.itemBuilder,
    this.emptyMessage = 'No items found',
    this.itemsPerPage = 20,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.0,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
  });

  @override
  State<PaginatedGridView<T>> createState() => _PaginatedGridViewState<T>();
}

class _PaginatedGridViewState<T> extends State<PaginatedGridView<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  
  int _currentPage = 0;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    try {
      final items = await widget.fetcher(1);
      setState(() {
        _items.clear();
        _items.addAll(items);
        _currentPage = 1;
        _hasMore = items.length >= widget.itemsPerPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() => _isLoadingMore = true);
    try {
      final newItems = await widget.fetcher(_currentPage + 1);
      setState(() {
        _items.addAll(newItems);
        _currentPage++;
        _hasMore = newItems.length >= widget.itemsPerPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return Center(
        child: Text(widget.emptyMessage),
      );
    }

    return GridView.builder(
      controller: _scrollController,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        childAspectRatio: widget.childAspectRatio,
        crossAxisSpacing: widget.crossAxisSpacing,
        mainAxisSpacing: widget.mainAxisSpacing,
      ),
      itemCount: _items.length + (_hasMore && _isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return widget.itemBuilder(context, _items[index]);
      },
    );
  }
}
