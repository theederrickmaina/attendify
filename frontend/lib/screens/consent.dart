import 'package:flutter/material.dart';
import '../utils/api_service.dart';
import '../utils/secure_store.dart';

/// Consent Screen
/// --------------
/// Displays informed consent and requires acceptance before app use.
class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.onAccepted});
  final void Function() onAccepted;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agree = false;
  bool _submitting = false;
  final _store = SecureStore();
  final _api = APIService();

  Future<void> _submit() async {
    if (!_agree) return;
    setState(() => _submitting = true);
    await _store.setConsentAccepted(true);
    try {
      await _api.updateConsent(true);
    } catch (_) {}
    setState(() => _submitting = false);
    widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Protection Consent')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informed Consent',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'This application processes biometric data (facial images/embeddings) for automated attendance. '
              'By continuing, you confirm informed consent under Kenya\'s Data Protection Act, and acknowledge data '
              'is encrypted in transit and at rest. You may withdraw consent at any time.',
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              value: _agree,
              title: const Text('I have read and consent to biometric processing.'),
              onChanged: (v) => setState(() => _agree = v ?? false),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitting || !_agree ? null : _submit,
              child: _submitting
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Accept and Continue'),
            ),
          ],
        ),
      ),
    );
  }
}

