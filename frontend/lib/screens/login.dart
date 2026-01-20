import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/ui.dart';
import '../utils/api_service.dart';

/// Login Screen
/// ------------
/// Username/password authentication, stores JWT locally.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onLoggedIn});
  final void Function() onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = APIService();
  final _usernameCtrl = TextEditingController(text: 'admin_lecturer1');
  final _passwordCtrl = TextEditingController(text: 'adminpasshash1');
  bool _loading = false;
  String? _error;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _api.login(_usernameCtrl.text.trim(), _passwordCtrl.text);
    setState(() => _loading = false);
    if (res['access_token'] != null) {
      widget.onLoggedIn();
    } else {
      setState(() => _error = res['error']?.toString() ?? 'Login failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: embuAppBar('Attendify Login'),
      body: EmbuBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: NeumoCard(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Attendify Login',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Username required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordCtrl,
                      decoration: const InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Password required' : null,
                    ),
                    const SizedBox(height: 20),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ).animate().fadeIn(),
                    const SizedBox(height: 10),
                    _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : NeumoButton(
                            onPressed: _submit,
                            child: const Text('Login'),
                          ).animate().fadeIn().scale(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
