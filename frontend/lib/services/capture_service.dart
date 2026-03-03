// Platform-aware capture service.
// Automatically selects the right implementation at compile time.
export 'capture_stub.dart'
    if (dart.library.html) 'capture_web.dart'
    if (dart.library.io) 'capture_mobile.dart';
