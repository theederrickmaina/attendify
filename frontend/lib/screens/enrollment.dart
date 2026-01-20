import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import '../utils/api_service.dart';
import '../utils/ui.dart';

/// Enrollment Screen
/// -----------------
/// Captures student details and facial image, detects faces locally,
/// and sends the base64 image to backend /api/enroll with consent.
class EnrollmentScreen extends StatefulWidget {
  const EnrollmentScreen({super.key});

  @override
  State<EnrollmentScreen> createState() => _EnrollmentScreenState();
}

class _EnrollmentScreenState extends State<EnrollmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = APIService();

  final _nameCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _courseCtrl = TextEditingController(text: 'IT');
  final _yearCtrl = TextEditingController(text: '1');
  final _semCtrl = TextEditingController(text: '1');
  bool _consent = false;
  CameraController? _camera;
  late final FaceDetector _faceDetector;
  bool _processing = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(enableContours: true),
    );
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
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _camera?.dispose();
    _faceDetector.close();
    super.dispose();
  }

  Future<void> _captureAndEnroll() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_consent) {
      setState(() => _message = 'Consent is required to enroll');
      return;
    }
    if (!(_camera?.value.isInitialized ?? false)) {
      setState(() => _message = 'Camera not ready');
      return;
    }
    setState(() {
      _processing = true;
      _message = null;
    });
    final file = await _camera!.takePicture();
    final bytes = await file.readAsBytes();
    final image = InputImage.fromFilePath(file.path);
    final faces = await _faceDetector.processImage(image);
    if (faces.isEmpty) {
      setState(() {
        _processing = false;
        _message = 'No face detected. Please try again.';
      });
      return;
    }
    final b64 = base64Encode(bytes);
    final res = await _api.enroll({
      'name': _nameCtrl.text.trim(),
      'reg_no': _regCtrl.text.trim(),
      'course': _courseCtrl.text.trim(),
      'year': int.tryParse(_yearCtrl.text) ?? 1,
      'semester': int.tryParse(_semCtrl.text) ?? 1,
      'facial_image_base64': b64,
      'consent': true,
      'username': _regCtrl.text.trim(),
      'password': 'changeme',
    });
    setState(() {
      _processing = false;
      _message =
          res['message']?.toString() ??
          res['error']?.toString() ??
          'Unknown response';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embuAppBar('Enrollment'),
      body: EmbuBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _regCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Registration No',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                    TextFormField(
                      controller: _courseCtrl,
                      decoration: const InputDecoration(labelText: 'Course'),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _yearCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Year',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _semCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Semester',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: const Text(
                        'I consent to biometric processing for attendance.',
                      ),
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v ?? false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 240,
                child: _camera?.value.isInitialized == true
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CameraPreview(_camera!),
                      )
                    : const Center(child: CircularProgressIndicator()),
              ).animate().fadeIn(),
              const SizedBox(height: 16),
              ElevatedButton(
                    onPressed: _processing ? null : _captureAndEnroll,
                    style: ElevatedButton.styleFrom(
                      elevation: 12,
                      shadowColor: Colors.black54,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    child: _processing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Enrollment'),
                  )
                  .animate()
                  .fadeIn()
                  .scale()
                  .shake(hz: 2, duration: 600.ms)
                  .then(delay: 200.ms)
                  .saturate(),
              if (_message != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _message!,
                    style: const TextStyle(color: Colors.blue),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
