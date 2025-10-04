import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final AuthService _authService = AuthService();
  String _status = 'Ready to test';
  bool _isLoading = false;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
    });

    try {
      // Test login with sample credentials
      final loginRequest = LoginRequest(username: 'test', password: 'test123');

      final response = await _authService.login(loginRequest);

      setState(() {
        _status =
            'Connection successful! Logged in as: ${response.user.username}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Connection failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Connection Test')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Connection Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Base URL: http://localhost:5000/api',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Status: $_status',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _testConnection,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Test Connection'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Setup Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Make sure your backend server is running on port 5000',
                    ),
                    const Text(
                      '2. If testing on Android emulator, use: http://10.0.2.2:5000/api',
                    ),
                    const Text(
                      '3. If testing on physical device, use your computer\'s IP address',
                    ),
                    const Text(
                      '4. Make sure CORS is properly configured in your backend',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
