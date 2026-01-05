// Quick test to verify timezone handling
// Run with: dart test_timezone.dart

void main() {
  print('=== Timezone Test ===\n');
  
  // Simulate creating attendance at 5:32 PM local time
  final localTime = DateTime(2026, 1, 6, 17, 32); // 5:32 PM
  print('1. Local time (what user selected): ${localTime}');
  print('   Hour: ${localTime.hour} (17 = 5 PM)');
  
  // Convert to UTC for sending to backend (what service does now)
  final utcTime = localTime.toUtc();
  print('\n2. Converted to UTC for backend: ${utcTime}');
  print('   ISO String: ${utcTime.toIso8601String()}');
  
  // Simulate backend storing and returning it (as ISO string)
  final backendResponse = utcTime.toIso8601String();
  print('\n3. Backend returns: $backendResponse');
  
  // Frontend receives and parses it (what model does with .toLocal())
  final parsedTime = DateTime.parse(backendResponse).toLocal();
  print('\n4. Frontend parses with .toLocal(): ${parsedTime}');
  print('   Hour: ${parsedTime.hour} (should be 17 = 5 PM)');
  
  // Verify it matches original
  print('\n5. Verification:');
  print('   Original hour: ${localTime.hour}');
  print('   Parsed hour: ${parsedTime.hour}');
  print('   Match: ${localTime.hour == parsedTime.hour ? "✅ PASS" : "❌ FAIL"}');
  
  // Show what was happening BEFORE the fix
  print('\n=== What happened BEFORE fix ===');
  final wrongParse = DateTime.parse(backendResponse); // WITHOUT .toLocal()
  print('DateTime.parse() without .toLocal(): ${wrongParse}');
  print('Hour: ${wrongParse.hour} (wrong! showed UTC time)');
  print('This is why 17:32 showed as ${wrongParse.hour}:32');
}
