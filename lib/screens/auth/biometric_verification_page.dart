import 'package:flutter/material.dart';

import '../../services/biometric_service.dart';

class BiometricVerificationPage extends StatefulWidget {
  const BiometricVerificationPage({super.key});

  @override
  State<BiometricVerificationPage> createState() =>
      _BiometricVerificationPageState();
}

class _BiometricVerificationPageState extends State<BiometricVerificationPage> {
  bool _busy = true;
  BiometricResult? _result;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _busy = true;
      _result = null;
    });
    final result = await BiometricService.authenticate();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = result;
    });
    if (result == BiometricResult.success) {
      Navigator.of(context).pop(true);
    }
  }

  void _continueWithPassword() {
    BiometricService.allowPasswordFallback();
    Navigator.of(context).pop(true);
  }

  String get _message => switch (_result) {
    BiometricResult.unavailable =>
      'Biometric authentication is not available on this device.',
    BiometricResult.notEnrolled =>
      'No fingerprint or other biometric is enrolled on this device.',
    BiometricResult.lockedOut =>
      'Biometrics are temporarily locked. Unlock your device and try again.',
    BiometricResult.cancelled => 'Biometric authentication was cancelled.',
    BiometricResult.failed => 'Biometric authentication failed. Try again.',
    BiometricResult.success => 'Authentication successful.',
    null => 'Verify your identity to continue.',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fingerprint,
                    size: 96,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Verify your identity',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Use your enrolled fingerprint or another device biometric for this session.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Text(_message, textAlign: TextAlign.center),
                  const SizedBox(height: 22),
                  if (_busy)
                    const CircularProgressIndicator()
                  else ...[
                    FilledButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Try biometrics again'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _continueWithPassword,
                      child: const Text('Continue with password login'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
