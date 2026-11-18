import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/app_provider.dart';
import '../../widgets/app_background.dart';
import '../../widgets/theme_toggle.dart';
import 'login_page.dart';

class VerifyEmailPage extends StatefulWidget {
  const VerifyEmailPage({super.key});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  bool _busy = false;

  Future<void> _resend() async {
    setState(() => _busy = true);
    final message = await context.read<AppProvider>().resendVerificationEmail();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? 'Verification email sent. Please check your inbox.',
        ),
      ),
    );
  }

  Future<void> _check() async {
    setState(() => _busy = true);
    final verified = await context.read<AppProvider>().checkEmailVerification();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!verified) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email is not verified yet.')),
      );
      return;
    }
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    context.read<AppProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? 'your email';
    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(
                right: 12,
                top: 8,
                child: ThemeToggle(iconOnly: true),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.mark_email_unread_outlined,
                            size: 70,
                            color: Color(0xFF4ADE80),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Verify your email',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'We sent a verification link to $email. Verify it before continuing to RecyConnect.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _busy ? null : _check,
                              child: const Text('I HAVE VERIFIED MY EMAIL'),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _busy ? null : _resend,
                              child: const Text('RESEND VERIFICATION EMAIL'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _busy ? null : _logout,
                            child: const Text('Log out'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
