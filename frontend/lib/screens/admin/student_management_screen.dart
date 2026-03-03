import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/theme.dart';
import '../../services/api_service.dart';
import '../../services/capture_service.dart';

class StudentManagementScreen extends StatefulWidget {
  final ApiService api;
  const StudentManagementScreen({super.key, required this.api});

  @override
  State<StudentManagementScreen> createState() => _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  List<dynamic> _students = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await widget.api.getStudents(
        q: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      );
      if (r['_ok'] == true) _students = r['students'] ?? [];
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search students...', prefixIcon: Icon(Icons.search)),
                  onSubmitted: (_) => _load(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: _load,
                icon: const Icon(Icons.refresh, color: AttendifyTheme.accent),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AttendifyTheme.primary))
              : _students.isEmpty
              ? const Center(child: Text('No students found',
                  style: TextStyle(color: AttendifyTheme.textSecondary)))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _students.length,
                  itemBuilder: (ctx, i) => _studentTile(_students[i]),
                ),
        ),
      ],
    );
  }

  Widget _studentTile(Map<String, dynamic> s) {
    final hasFace = s['has_face'] == true;
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: hasFace
                ? AttendifyTheme.success.withValues(alpha: 0.15)
                : AttendifyTheme.warning.withValues(alpha: 0.15),
            child: Icon(
              hasFace ? Icons.face : Icons.face_retouching_off,
              color: hasFace ? AttendifyTheme.success : AttendifyTheme.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s['name'] ?? '', style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text('${s['registration_number']}  ·  ${s['course_code'] ?? ''}  ·  Y${s['year']}S${s['semester']}',
                    style: GoogleFonts.spaceGrotesk(fontSize: 12, color: AttendifyTheme.textSecondary)),
              ],
            ),
          ),
          if (!hasFace)
            TextButton.icon(
              onPressed: () => _showEnrollDialog(s),
              icon: const Icon(Icons.add_a_photo, size: 16),
              label: const Text('Enroll Face'),
              style: TextButton.styleFrom(foregroundColor: AttendifyTheme.accent),
            ),
          if (hasFace)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AttendifyTheme.success.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('ENROLLED',
                  style: GoogleFonts.spaceGrotesk(fontSize: 11, fontWeight: FontWeight.w600,
                      color: AttendifyTheme.success)),
            ),
        ],
      ),
    );
  }

  void _showEnrollDialog(Map<String, dynamic> student) {
    showDialog(
      context: context,
      builder: (ctx) => _EnrollFaceDialog(
        api: widget.api,
        studentId: student['id'],
        studentName: student['name'] ?? '',
        onSuccess: _load,
      ),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }
}

class _EnrollFaceDialog extends StatefulWidget {
  final ApiService api;
  final int studentId;
  final String studentName;
  final VoidCallback onSuccess;

  const _EnrollFaceDialog({required this.api, required this.studentId,
    required this.studentName, required this.onSuccess});

  @override
  State<_EnrollFaceDialog> createState() => _EnrollFaceDialogState();
}

class _EnrollFaceDialogState extends State<_EnrollFaceDialog> {
  bool _uploading = false;
  bool _cameraActive = false;
  String? _error;
  String? _successMsg;
  CaptureService? _camera;

  Future<void> _pickFile() async {
    setState(() => _error = null);
    try {
      final dataUrl = await CaptureService.pickImageFromGallery();
      if (dataUrl == null || !mounted) return;
      _upload(dataUrl);
    } catch (e) {
      setState(() => _error = 'File selection failed: $e');
    }
  }

  Future<void> _startCamera() async {
    setState(() { _error = null; _cameraActive = false; });
    try {
      _camera = CaptureService();
      final ok = await _camera!.startLiveCamera();
      if (!ok) throw Exception('Camera init failed');
      if (mounted) setState(() => _cameraActive = true);
    } catch (e) {
      setState(() => _error = 'Camera access denied or unavailable.\nTry uploading a file instead.');
    }
  }

  Future<void> _captureAndUpload() async {
    if (_camera == null) return;
    final dataUrl = await _camera!.captureLiveSnapshot();
    if (dataUrl == null) {
      setState(() => _error = 'Failed to capture frame');
      return;
    }
    _stopCamera();
    _upload(dataUrl);
  }

  void _stopCamera() {
    _camera?.disposeLiveCamera();
    _camera = null;
    if (mounted) setState(() => _cameraActive = false);
  }

  Future<void> _upload(String imageData) async {
    setState(() { _uploading = true; _error = null; });
    try {
      final r = await widget.api.enrollFace(widget.studentId, imageData);
      if (!mounted) return;
      if (r['_ok'] == true) {
        setState(() => _successMsg = 'Face enrolled successfully!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Face enrolled successfully!')));
      } else {
        setState(() => _error = r['message'] ?? r['error'] ?? 'Enrollment failed');
      }
    } catch (e) {
      setState(() => _error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Enroll Face — ${widget.studentName}'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_successMsg != null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AttendifyTheme.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.check_circle, color: AttendifyTheme.success, size: 48),
                  const SizedBox(height: 12),
                  Text(_successMsg!, style: const TextStyle(color: AttendifyTheme.success, fontWeight: FontWeight.w600)),
                ]),
              ),
            ] else if (_cameraActive && _camera != null) ...[
              // Live camera preview
              Container(
                height: 320,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AttendifyTheme.accent, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: _camera!.buildLivePreview(height: 320),
              ),
              const SizedBox(height: 12),
              const Text('Position the face clearly in frame, then capture.',
                  style: TextStyle(color: AttendifyTheme.textSecondary, fontSize: 13)),
            ] else if (!_uploading) ...[
              const Text('Choose how to capture the student\'s face photo:',
                  style: TextStyle(color: AttendifyTheme.textSecondary, fontSize: 14)),
              const SizedBox(height: 20),
              // Two option cards
              Row(children: [
                Expanded(child: _optionCard(
                  icon: Icons.camera_alt,
                  label: 'Webcam Capture',
                  desc: 'Use your camera to take a photo',
                  color: AttendifyTheme.accent,
                  onTap: _startCamera,
                )),
                const SizedBox(width: 12),
                Expanded(child: _optionCard(
                  icon: Icons.upload_file,
                  label: 'Upload File',
                  desc: 'Select an image from your device',
                  color: AttendifyTheme.primary,
                  onTap: _pickFile,
                )),
              ]),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AttendifyTheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const Icon(Icons.error_outline, color: AttendifyTheme.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: const TextStyle(color: AttendifyTheme.error, fontSize: 13))),
                ]),
              ),
            ],
            if (_uploading)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  CircularProgressIndicator(color: AttendifyTheme.primary),
                  SizedBox(height: 12),
                  Text('Processing face data...', style: TextStyle(color: AttendifyTheme.textSecondary, fontSize: 13)),
                ]),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () { _stopCamera(); Navigator.pop(context); },
          child: const Text('Cancel'),
        ),
        if (_cameraActive && !_uploading)
          ElevatedButton.icon(
            onPressed: _captureAndUpload,
            icon: const Icon(Icons.camera, size: 18),
            label: const Text('Capture Photo'),
          ),
      ],
    );
  }

  Widget _optionCard({
    required IconData icon, required String label, required String desc,
    required Color color, required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          const SizedBox(height: 4),
          Text(desc, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AttendifyTheme.textSecondary)),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _camera?.disposeLiveCamera();
    super.dispose();
  }
}
