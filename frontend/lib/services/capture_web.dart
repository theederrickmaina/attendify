import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:universal_html/html.dart' as html;

/// Web implementation — uses universal_html for camera and file picker.
class CaptureService {
  html.VideoElement? _video;
  html.MediaStream? _stream;
  String? _viewId;

  /// Pick an image file from the browser file dialog → base64 data URL.
  static Future<String?> pickImageFromGallery() async {
    final completer = Completer<String?>();
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();
    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file == null) { completer.complete(null); return; }
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoad.listen((_) => completer.complete(reader.result as String?));
      reader.onError.listen((_) => completer.complete(null));
    });
    return completer.future;
  }

  /// On web desktop, "take photo" just opens the file picker (no native camera).
  static Future<String?> takePhoto() async => pickImageFromGallery();

  /// Start webcam via getUserMedia and register an HtmlElementView.
  Future<bool> startLiveCamera() async {
    try {
      _video = html.VideoElement()
        ..autoplay = true
        ..setAttribute('playsinline', 'true')
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '12px'
        ..style.transform = 'scaleX(-1)';

      _stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'user', 'width': 640, 'height': 480}
      });
      _video!.srcObject = _stream;

      _viewId = 'webcam-${DateTime.now().millisecondsSinceEpoch}';
      ui_web.platformViewRegistry.registerViewFactory(
          _viewId!, (int viewId) => _video!);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Returns an HtmlElementView showing the live webcam.
  Widget buildLivePreview({double? width, double? height}) {
    if (_viewId == null) return SizedBox(width: width, height: height);
    return SizedBox(
      width: width, height: height,
      child: HtmlElementView(viewType: _viewId!),
    );
  }

  /// Capture the current webcam frame via canvas → base64 data URL.
  Future<String?> captureLiveSnapshot() async {
    if (_video == null) return null;
    final canvas = html.CanvasElement(
      width: _video!.videoWidth > 0 ? _video!.videoWidth : 640,
      height: _video!.videoHeight > 0 ? _video!.videoHeight : 480,
    );
    final ctx = canvas.context2D;
    ctx.translate(canvas.width!, 0);
    ctx.scale(-1, 1);
    ctx.drawImage(_video!, 0, 0);
    return canvas.toDataUrl('image/jpeg', 0.92);
  }

  bool get isLiveCameraActive => _stream != null && _video != null;

  void disposeLiveCamera() {
    _stream?.getTracks().forEach((track) => track.stop());
    _stream = null;
    _video = null;
    _viewId = null;
  }
}
