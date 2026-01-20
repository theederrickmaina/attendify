import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:confetti/confetti.dart';
import '../utils/ui.dart';
import '../utils/api_service.dart';

/// Recognition Screen
/// ------------------
/// Real-time face detection; when a frame has a face, send to backend
/// /api/recognize to attempt matching and attendance logging.
class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  CameraController? _camera;
  late final FaceDetector _faceDetector;
  final _api = APIService();
  bool _busy = false;
  String? _result;
  Timer? _timer;
  bool _streaming = false;
  // Flag reserved for future stream-based filtering.
  // Currently unused; left for future continuous detection tuning.
  // bool _processingFrame = false;
  late ConfettiController _confetti;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(enableContours: true),
    );
    _confetti = ConfettiController(duration: const Duration(seconds: 2));
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final cam = cams.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );
    _camera = CameraController(
      cam,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _camera!.initialize();
    if (mounted) {
      setState(() {});
      _startImageStream();
    }
  }

  @override
  void dispose() {
    _camera?.dispose();
    _faceDetector.close();
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _startImageStream() {
    if (_camera == null || _streaming) return;
    _streaming = true;
    // Keep camera active; perform throttled still captures for detection.
    _camera!.startImageStream((_) {});
    _timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_busy) return;
      await _snapAndRecognize();
    });
  }

  // Stream frame conversion removed for cross-platform stability; using periodic stills instead.

  Future<void> _snapAndRecognize() async {
    if (_busy || !(_camera?.value.isInitialized ?? false)) return;
    setState(() {
      _busy = true;
    });
    // Some platforms require stopping stream before taking a picture.
    if (_camera!.value.isStreamingImages) {
      await _camera!.stopImageStream();
      _streaming = false;
    }
    final pic = await _camera!.takePicture();
    final bytes = await pic.readAsBytes();
    final image = InputImage.fromFilePath(pic.path);
    final faces = await _faceDetector.processImage(image);
    if (faces.isEmpty) {
      setState(() {
        _busy = false;
        _result = 'No face detected';
      });
      _startImageStream();
      return;
    }
    final b64 = base64Encode(bytes);
    final res = await _api.recognize(b64);
    setState(() {
      _busy = false;
      _result = res['attendance_logged'] == true
          ? 'Attendance logged ✓'
          : (res['matched'] == true
                ? 'Matched, but not in class time'
                : 'No match');
    });
    if (res['attendance_logged'] == true) {
      _confetti.play();
    }
    // Resume stream for further scans
    _startImageStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embuAppBar('Recognition'),
      body: EmbuBackground(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: _camera?.value.isInitialized == true
                      ? CameraPreview(_camera!)
                      : const Center(child: CircularProgressIndicator()),
                ),
                const SizedBox(height: 12),
                if (_result != null)
                  Text(
                    _result!,
                    style: const TextStyle(fontSize: 16, color: Colors.green),
                  ).animate().fadeIn().scale(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: ElevatedButton.icon(
                    onPressed: _busy ? null : _snapAndRecognize,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Scan & Log'),
                  ).animate().fadeIn().scale(),
                ),
              ],
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [Color(0xFF006400), Color(0xFF003366)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
