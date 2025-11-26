// Stub for path_provider on web - prevents compilation errors
// This file is only used on web where path_provider is not available

class Directory {
  final String path = '';
}

Future<Directory> getApplicationDocumentsDirectory() async {
  throw UnsupportedError('path_provider is not supported on web');
}
