// Conditional export for platform-specific implementations
export 'web_download_stub.dart' if (dart.library.html) 'web_download_web.dart';
