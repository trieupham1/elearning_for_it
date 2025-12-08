// providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../services/settings_service.dart';
import '../config/theme.dart';
import '../utils/logger_service.dart';

class ThemeProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  String _themeMode = 'system'; // 'light', 'dark', or 'system'
  bool _isSaving = false;
  bool _isInitialized = false;
  Brightness? _systemBrightness;

  String get themeMode => _themeMode;
  bool get isSaving => _isSaving;
  bool get isInitialized => _isInitialized;
  
  /// Get the effective theme mode considering system settings
  ThemeMode get effectiveThemeMode {
    if (_themeMode == 'system') {
      return ThemeMode.system;
    } else if (_themeMode == 'dark') {
      return ThemeMode.dark;
    } else {
      return ThemeMode.light;
    }
  }
  
  /// Check if dark mode is currently active
  bool get isDarkMode {
    if (_themeMode == 'dark') return true;
    if (_themeMode == 'light') return false;
    // System mode - check platform brightness
    return _systemBrightness == Brightness.dark;
  }

  ThemeData get themeData {
    if (_themeMode == 'dark') {
      return _buildDarkTheme();
    }
    return AppTheme.lightTheme; // Use the original light theme
  }

  ThemeData _buildDarkTheme() {
    // Dark blue color - much darker than default blue
    const darkBlue = Color(0xFF1565C0); // Dark blue instead of bright blue
    const veryDarkBlue = Color(0xFF0D47A1); // Even darker blue for accents
    
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      primaryColor: darkBlue,
      scaffoldBackgroundColor: const Color(0xFF121212), // Pure dark background
      colorScheme: const ColorScheme.dark(
        primary: darkBlue,
        secondary: veryDarkBlue,
        surface: Color(0xFF1E1E1E), // Dark gray for cards
        background: Color(0xFF121212), // Black background
        onPrimary: Colors.white, // White text on primary color
        onSurface: Colors.white, // White text on surfaces
        onBackground: Colors.white, // White text on background
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E), // Dark gray AppBar
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E), // Dark gray cards
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkBlue, // Dark blue buttons
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
        titleLarge: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        fillColor: Color(0xFF1E1E1E), // Dark input fields
        filled: true,
        border: OutlineInputBorder(),
        labelStyle: TextStyle(color: Colors.white70),
        hintStyle: TextStyle(color: Colors.white38),
      ),
    );
  }

  /// Update system brightness (call this from main app widget)
  void updateSystemBrightness(Brightness brightness) {
    if (_systemBrightness != brightness) {
      _systemBrightness = brightness;
      if (_themeMode == 'system') {
        notifyListeners(); // Update UI when system theme changes
      }
    }
  }
  
  /// Detect system theme preference
  void detectSystemTheme() {
    try {
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      _systemBrightness = brightness;
      LoggerService.info('Detected system brightness: $brightness');
    } catch (e) {
      LoggerService.error('Error detecting system theme', e);
      _systemBrightness = Brightness.light;
    }
  }

  // Load theme from backend on app startup
  Future<void> loadTheme() async {
    detectSystemTheme(); // Always detect system theme first
    
    try {
      final settings = await _settingsService.getSettings();
      _themeMode = settings.theme;
      
      // Validate theme mode
      if (!['light', 'dark', 'system'].contains(_themeMode)) {
        LoggerService.warning('Invalid theme mode: $_themeMode, defaulting to system');
        _themeMode = 'system';
      }
      
      _isInitialized = true;
      notifyListeners();
      LoggerService.info('Theme loaded: $_themeMode');
    } catch (e) {
      LoggerService.info('Error loading theme (user may not be logged in): $e');
      // Use default system theme if user isn't logged in or settings can't be loaded
      _themeMode = 'system';
      _isInitialized = true;
      notifyListeners();
    }
  }

  // Set theme and save to backend
  Future<void> setTheme(String newTheme) async {
    if (_themeMode == newTheme || _isSaving) return;
    
    // Validate theme mode
    if (!['light', 'dark', 'system'].contains(newTheme)) {
      LoggerService.warning('Invalid theme mode: $newTheme');
      return;
    }

    // Update UI immediately for better UX
    final oldTheme = _themeMode;
    _themeMode = newTheme;
    notifyListeners();
    LoggerService.info('Theme changed: $oldTheme -> $newTheme');

    // Save to backend
    _isSaving = true;
    notifyListeners();

    try {
      final currentSettings = await _settingsService.getSettings();
      final updatedSettings = currentSettings.copyWith(theme: newTheme);
      await _settingsService.updateSettings(updatedSettings);
      LoggerService.info('Theme saved to backend successfully');
    } catch (e) {
      LoggerService.error('Error saving theme', e);
      // Theme is already updated locally, so user sees the change even if save fails
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }
  
  /// Toggle between light and dark mode (skips system)
  Future<void> toggleTheme() async {
    final newTheme = _themeMode == 'dark' ? 'light' : 'dark';
    await setTheme(newTheme);
  }
  
  /// Cycle through all theme modes: light -> dark -> system -> light
  Future<void> cycleThemeMode() async {
    String newTheme;
    switch (_themeMode) {
      case 'light':
        newTheme = 'dark';
        break;
      case 'dark':
        newTheme = 'system';
        break;
      case 'system':
      default:
        newTheme = 'light';
        break;
    }
    await setTheme(newTheme);
  }
}
