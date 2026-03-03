import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:camera/camera.dart';

/// Mobile implementation — uses image_picker for quick capture and camera package for live preview.
class CaptureService {
  static final _picker = ImagePicker();
  CameraController? _controller;

  static Future<String?> _xFileToDataUrl(XFile? file) async {
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }

  /// Pick an image from gallery → base64 data URL.
  static Future<String?> pickImageFromGallery() async {
    final f = await _picker.pickImage(
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 90);
    return _xFileToDataUrl(f);
  }

  /// Take a photo with the system camera → base64 data URL.
  static Future<String?> takePhoto() async {
    final f = await _picker.pickImage(
        source: ImageSource.camera, maxWidth: 800, maxHeight: 800, imageQuality: 90,
        preferredCameraDevice: CameraDevice.front);
    return _xFileToDataUrl(f);
  }

  /// Start the front camera for live preview.
  Future<bool> startLiveCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return false;
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns a CameraPreview widget for the live feed.
  Widget buildLivePreview({double? width, double? height}) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return SizedBox(
        width: width, height: height,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox(
      width: width, height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CameraPreview(_controller!),
      ),
    );
  }

  /// Capture a frame from the live camera → base64 data URL.
  Future<String?> captureLiveSnapshot() async {
    if (_controller == null || !_controller!.value.isInitialized) return null;
    try {
      final xFile = await _controller!.takePicture();
      return _xFileToDataUrl(xFile);
    } catch (_) {
      return null;
    }
  }

  bool get isLiveCameraActive => _controller?.value.isInitialized ?? false;

  void disposeLiveCamera() {
    _controller?.dispose();
    _controller = null;
  }
}
