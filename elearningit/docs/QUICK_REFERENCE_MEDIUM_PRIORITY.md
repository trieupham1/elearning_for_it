# Medium Priority Features - Quick Reference

## 🎨 Animations

### Animated Buttons
```dart
// Standard button with press animation
AnimatedButton(
  onPressed: () => save(),
  text: 'Save',
  icon: Icons.save,
)

// Async button with auto-loading
AnimatedButton(
  onPressedAsync: () async => await submit(),
  text: 'Submit',
)
```

### Animated Lists
```dart
// Replace ListView.builder with:
AnimatedListView(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemCard(items[index]),
)

// Or use extension for one-off animations:
MyWidget().animateOnPageLoad()
```

---

## 🔍 Search & Filters

### Search Bar
```dart
// Advanced search with filters
AdvancedSearchBar(
  onSearch: (query, filters) => search(query, filters),
  filters: ['All', 'Active', 'Completed'],
  sortOptions: ['Name', 'Date'],
)

// Simple search
SimpleSearchBar(
  onSearch: (query) => search(query),
)
```

### Filters
```dart
// Full filter panel
FilterPanel(
  onFiltersChanged: (filters) => apply(filters),
  availableFilters: {
    'status': ['All', 'Active', 'Completed'],
    'type': ['Course', 'Assignment'],
  },
)

// Quick filter chips
QuickFilters(
  filters: [
    QuickFilter(id: 'all', label: 'All', count: 45),
    QuickFilter(id: 'active', label: 'Active', count: 12),
  ],
  selectedFilter: 'all',
  onFilterSelected: (id) => filter(id),
)
```

---

## 🌙 Dark Mode

### Theme Provider
```dart
// Get theme provider
final theme = Provider.of<ThemeProvider>(context);

// Set theme
theme.setTheme('light');   // Light mode
theme.setTheme('dark');    // Dark mode
theme.setTheme('system');  // Follow system (NEW!)

// Toggle
theme.toggleTheme();       // Light <-> Dark
theme.cycleThemeMode();    // Light -> Dark -> System

// Check status
bool isDark = theme.isDarkMode;
ThemeMode mode = theme.effectiveThemeMode;
```

---

## 🖼️ Optimized Images

### Basic Usage
```dart
// Standard image
OptimizedImage(
  imageUrl: url,
  width: 300,
  height: 200,
)

// Avatar
OptimizedAvatar(
  imageUrl: user.avatar,
  radius: 24,
  fallbackText: user.name,
)

// Thumbnail
ThumbnailImage(
  imageUrl: thumb,
  size: 64,
)

// Extension methods
url.toOptimizedImage(width: 300, height: 200)
url.toAvatar(radius: 24)
url.toThumbnail(size: 64)
```

---

## 📡 Connectivity

### Service
```dart
final monitor = ConnectivityMonitor();
await monitor.initialize();

// Check status
if (monitor.isConnected) { ... }
if (monitor.isWiFi) { ... }
if (monitor.isMobile) { ... }

// Listen to changes
monitor.onConnectivityChanged.listen((isConnected) {
  // Handle connection change
});
```

### Widgets
```dart
// Banner (wrap your app)
ConnectivityBanner(
  child: MyApp(),
)

// Builder
ConnectivityBuilder(
  builder: (context, isConnected) {
    return isConnected ? OnlineView() : OfflineView();
  },
)
```

---

## 📝 Migration Checklist

### Replace These:
- [ ] `ListView.builder` → `AnimatedListView`
- [ ] `ElevatedButton` → `AnimatedButton`
- [ ] `Image.network` → `OptimizedImage`
- [ ] `CircleAvatar + NetworkImage` → `OptimizedAvatar`
- [ ] Theme switch → Add 'system' option

### Add These:
- [ ] `AdvancedSearchBar` to list screens
- [ ] `FilterPanel` to course/assignment lists
- [ ] `ConnectivityBanner` to app root
- [ ] `.animateOnPageLoad()` to static content

---

## 🎯 Common Patterns

### Filtered List with Search
```dart
Column(
  children: [
    AdvancedSearchBar(
      onSearch: (q, f) => setState(() { /* update filters */ }),
      filters: ['All', 'Active', 'Completed'],
    ),
    Expanded(
      child: AnimatedListView(
        itemCount: filteredItems.length,
        itemBuilder: (context, index) => ItemCard(filteredItems[index]),
      ),
    ),
  ],
)
```

### Form with Animated Button
```dart
Form(
  child: Column(
    children: [
      TextField(...),
      TextField(...),
      AnimatedButton(
        onPressedAsync: () async => await submitForm(),
        text: 'Submit',
        icon: Icons.send,
      ),
    ],
  ),
)
```

### Optimized Image Card
```dart
Card(
  child: Column(
    children: [
      OptimizedImage(
        imageUrl: item.imageUrl,
        width: double.infinity,
        height: 200,
      ),
      Padding(
        padding: EdgeInsets.all(16),
        child: Text(item.title),
      ),
    ],
  ),
)
```

---

## 💡 Pro Tips

1. **Always** use `OptimizedImage` for network images
2. **Always** debounce search inputs (built into `AdvancedSearchBar`)
3. Use `AnimatedListView` for lists with 10+ items
4. Set theme to 'system' by default for better UX
5. Check connectivity before large downloads
6. Use `ThumbnailImage` for small previews
7. Add `borderRadius` to images for modern look
8. Use `AnimatedButton` for all form submissions

---

## 🐛 Troubleshooting

**Q: Animations feel laggy**  
A: Reduce `duration` or use `AnimationStyle.fade` instead of `fadeSlide`

**Q: Images loading slowly**  
A: Set appropriate `memCacheWidth` (default is good for most cases)

**Q: Search firing too often**  
A: Increase `debounceDuration` (default 500ms)

**Q: Theme not following system**  
A: Make sure to call `updateSystemBrightness()` in main app widget

**Q: Connectivity not detecting changes**  
A: Call `await monitor.initialize()` before using

---

## 📚 Full Documentation
See `MEDIUM_PRIORITY_IMPLEMENTATION.md` for complete guide
