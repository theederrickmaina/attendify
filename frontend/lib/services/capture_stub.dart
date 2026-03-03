import 'package:flutter/material.dart';

/// Stub implementation — should never actually be used at runtime.
/// The conditional import in capture_service.dart selects the real one.
class CaptureService {
  static Future<String?> pickImageFromGallery() async => null;
  static Future<String?> takePhoto() async => null;

  Future<bool> startLiveCamera() async => false;
  Widget buildLivePreview({double? width, double? height}) => const SizedBox();
  Future<String?> captureLiveSnapshot() async => null;
  bool get isLiveCameraActive => false;
  void disposeLiveCamera() {}
}
