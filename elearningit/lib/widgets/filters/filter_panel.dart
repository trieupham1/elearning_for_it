import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A comprehensive filter system for courses, assignments, and other content.
///
/// Features:
/// - Multiple filter types (status, date range, category)
/// - Chip-based UI
/// - Reset functionality
/// - Customizable appearance
///
/// Example:
/// ```dart
/// FilterPanel(
///   onFiltersChanged: (filters) => applyFilters(filters),
///   availableFilters: {
///     'status': ['All', 'Active', 'Completed'],
///     'type': ['Course', 'Assignment', 'Quiz'],
///   },
/// )
/// ```
class FilterPanel extends StatefulWidget {
  final Function(Map<String, dynamic>) onFiltersChanged;
  final Map<String, List<String>> availableFilters;
  final Map<String, dynamic>? initialFilters;
  final bool showDateRange;
  final bool collapsible;

  const FilterPanel({
    super.key,
    required this.onFiltersChanged,
    required this.availableFilters,
    this.initialFilters,
    this.showDateRange = true,
    this.collapsible = true,
  });

  @override
  State<FilterPanel> createState() => _FilterPanelState();
}

class _FilterPanelState extends State<FilterPanel> {
  late Map<String, String> _selectedFilters;
  DateTimeRange? _dateRange;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _selectedFilters = {};
    
    // Initialize with first option from each filter category
    for (var entry in widget.availableFilters.entries) {
      _selectedFilters[entry.key] = entry.value.first;
    }
    
    // Apply initial filters if provided
    if (widget.initialFilters != null) {
      for (var entry in widget.initialFilters!.entries) {
        if (entry.value is String) {
          _selectedFilters[entry.key] = entry.value;
        }
      }
      _dateRange = widget.initialFilters!['dateRange'] as DateTimeRange?;
    }
  }

  void _updateFilters() {
    final filters = Map<String, dynamic>.from(_selectedFilters);
    if (_dateRange != null) {
      filters['dateRange'] = _dateRange;
      filters['startDate'] = _dateRange!.start;
      filters['endDate'] = _dateRange!.end;
    }
    widget.onFiltersChanged(filters);
  }

  void _resetFilters() {
    setState(() {
      for (var entry in widget.availableFilters.entries) {
        _selectedFilters[entry.key] = entry.value.first;
      }
      _dateRange = null;
    });
    _updateFilters();
  }

  bool get _hasActiveFilters {
    // Check if any filter is not set to the default (first option)
    for (var entry in widget.availableFilters.entries) {
      if (_selectedFilters[entry.key] != entry.value.first) {
        return true;
      }
    }
    return _dateRange != null;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
      _updateFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: widget.collapsible
                ? () => setState(() => _isExpanded = !_isExpanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 12),
                  const Text(
                    'Filters',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_hasActiveFilters) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (_hasActiveFilters)
                    TextButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  if (widget.collapsible)
                    Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),

          // Filter Content
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dynamic filters from availableFilters
                  ...widget.availableFilters.entries.map((entry) {
                    return _buildFilterSection(
                      entry.key,
                      entry.value,
                    );
                  }),

                  // Date Range Filter
                  if (widget.showDateRange) ...[
                    const SizedBox(height: 16),
                    _buildDateRangeFilter(),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterSection(String category, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatCategoryName(category),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = _selectedFilters[category] == option;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedFilters[category] = option);
                  _updateFilters();
                }
              },
              selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
              checkmarkColor: Theme.of(context).primaryColor,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDateRangeFilter() {
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date Range',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDateRange,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _dateRange == null
                        ? 'Select date range'
                        : '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}',
                    style: TextStyle(
                      color: _dateRange == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ),
                if (_dateRange != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() => _dateRange = null);
                      _updateFilters();
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatCategoryName(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

/// Quick filter chips for top of lists
class QuickFilters extends StatelessWidget {
  final List<QuickFilter> filters;
  final String selectedFilter;
  final Function(String) onFilterSelected;

  const QuickFilters({
    super.key,
    required this.filters,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter.id;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filter.icon != null) ...[
                    Icon(filter.icon, size: 16),
                    const SizedBox(width: 6),
                  ],
                  Text(filter.label),
                  if (filter.count != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.3)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${filter.count}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onFilterSelected(filter.id),
              selectedColor: Theme.of(context).primaryColor,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Data class for quick filters
class QuickFilter {
  final String id;
  final String label;
  final IconData? icon;
  final int? count;

  const QuickFilter({
    required this.id,
    required this.label,
    this.icon,
    this.count,
  });
}

/// Sort options dropdown
class SortDropdown extends StatelessWidget {
  final List<SortOption> options;
  final String selectedSort;
  final Function(String) onSortChanged;

  const SortDropdown({
    super.key,
    required this.options,
    required this.selectedSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedSort,
          icon: const Icon(Icons.sort, size: 20),
          isDense: true,
          items: options.map((option) {
            return DropdownMenuItem(
              value: option.id,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (option.icon != null) ...[
                    Icon(option.icon, size: 16),
                    const SizedBox(width: 8),
                  ],
                  Text(option.label, style: const TextStyle(fontSize: 14)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              onSortChanged(value);
            }
          },
        ),
      ),
    );
  }
}

/// Data class for sort options
class SortOption {
  final String id;
  final String label;
  final IconData? icon;

  const SortOption({
    required this.id,
    required this.label,
    this.icon,
  });
}
