import 'package:flutter/material.dart';
import 'dart:async';

/// An advanced search widget with debouncing, filters, and suggestions.
///
/// Features:
/// - Search input with debouncing
/// - Filter chips
/// - Sort options
/// - Search history
/// - Customizable appearance
///
/// Example:
/// ```dart
/// AdvancedSearchBar(
///   onSearch: (query, filters) => searchCourses(query, filters),
///   filters: ['All', 'Active', 'Completed'],
///   sortOptions: ['Name', 'Date', 'Popular'],
/// )
/// ```
class AdvancedSearchBar extends StatefulWidget {
  final Function(String query, Map<String, dynamic> filters) onSearch;
  final List<String>? filters;
  final List<String>? sortOptions;
  final String hint;
  final Duration debounceDuration;
  final bool showFilters;
  final bool showSort;
  final Widget? leading;
  final List<String>? recentSearches;

  const AdvancedSearchBar({
    super.key,
    required this.onSearch,
    this.filters,
    this.sortOptions,
    this.hint = 'Search...',
    this.debounceDuration = const Duration(milliseconds: 500),
    this.showFilters = true,
    this.showSort = true,
    this.leading,
    this.recentSearches,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;
  
  String _selectedFilter = 'All';
  String _selectedSort = 'Name';
  bool _showRecentSearches = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.filters?.first ?? 'All';
    _selectedSort = widget.sortOptions?.first ?? 'Name';
    
    _focusNode.addListener(() {
      setState(() {
        _showRecentSearches = _focusNode.hasFocus && _controller.text.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(widget.debounceDuration, () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) {
    widget.onSearch(query, {
      'filter': _selectedFilter,
      'sort': _selectedSort,
    });
  }

  void _selectRecentSearch(String search) {
    _controller.text = search;
    _performSearch(search);
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: widget.hint,
              prefixIcon: widget.leading ?? const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        _performSearch('');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.cardColor,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        
        // Recent Searches
        if (_showRecentSearches && widget.recentSearches != null && widget.recentSearches!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Searches',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                ...widget.recentSearches!.take(5).map((search) => InkWell(
                      onTap: () => _selectRecentSearch(search),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            const Icon(Icons.history, size: 16, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                search,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        
        const SizedBox(height: 12),
        
        // Filters and Sort
        Row(
          children: [
            // Filter Chips
            if (widget.showFilters && widget.filters != null)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: widget.filters!.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(filter),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedFilter = filter);
                            _performSearch(_controller.text);
                          },
                          selectedColor: theme.primaryColor.withOpacity(0.2),
                          checkmarkColor: theme.primaryColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            
            // Sort Dropdown
            if (widget.showSort && widget.sortOptions != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedSort,
                    icon: const Icon(Icons.sort, size: 20),
                    items: widget.sortOptions!.map((sort) {
                      return DropdownMenuItem(
                        value: sort,
                        child: Text(sort, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedSort = value);
                        _performSearch(_controller.text);
                      }
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// A simpler search bar without advanced features
class SimpleSearchBar extends StatefulWidget {
  final Function(String) onSearch;
  final String hint;
  final Duration debounceDuration;
  final Widget? leading;
  final TextEditingController? controller;

  const SimpleSearchBar({
    super.key,
    required this.onSearch,
    this.hint = 'Search...',
    this.debounceDuration = const Duration(milliseconds: 500),
    this.leading,
    this.controller,
  });

  @override
  State<SimpleSearchBar> createState() => _SimpleSearchBarState();
}

class _SimpleSearchBarState extends State<SimpleSearchBar> {
  late TextEditingController _controller;
  Timer? _debounce;
  bool _isOwnController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _isOwnController = true;
    } else {
      _controller = widget.controller!;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_isOwnController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(widget.debounceDuration, () {
      widget.onSearch(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.leading ?? const Icon(Icons.search),
        suffixIcon: _controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _controller.clear();
                  widget.onSearch('');
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

/// Search delegate for full-screen search
class AdvancedSearchDelegate<T> extends SearchDelegate<T?> {
  final Future<List<T>> Function(String query) searchFunction;
  final Widget Function(BuildContext, T) itemBuilder;
  final String noResultsMessage;
  final List<String> suggestions;

  AdvancedSearchDelegate({
    required this.searchFunction,
    required this.itemBuilder,
    this.noResultsMessage = 'No results found',
    this.suggestions = const [],
  });

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<T>>(
      future: searchFunction(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final results = snapshot.data ?? [];
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  noResultsMessage,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) => itemBuilder(context, results[index]),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredSuggestions = suggestions
        .where((s) => s.toLowerCase().contains(query.toLowerCase()))
        .toList();

    if (filteredSuggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return ListView.builder(
      itemCount: filteredSuggestions.length,
      itemBuilder: (context, index) {
        final suggestion = filteredSuggestions[index];
        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(suggestion),
          onTap: () {
            query = suggestion;
            showResults(context);
          },
        );
      },
    );
  }
}
