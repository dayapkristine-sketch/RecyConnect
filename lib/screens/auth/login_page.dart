import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/post_store.dart';
import '../../services/firebase_service.dart';
import '../../widgets/app_background.dart';
import 'register_page.dart';
import 'biometric_verification_page.dart';
import '../admin/admin_dashboard.dart';
import '../dashboards/role_dashboard.dart';
import '../dashboards/household_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _hidePassword = true;
  bool _showVerificationNotice = false;
  bool _checkingVerification = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final app = context.read<AppProvider>();
    final message = await app.loginWithFirebase(_username.text, _password.text);
    if (!mounted) return;
    if (app.emailVerificationRequired) {
      setState(() => _showVerificationNotice = true);
      return;
    }
    setState(() => _showVerificationNotice = false);
    if (message != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    final user = app.currentUser!;
    await context.read<PostStore>().loadForCurrentUser();
    if (!mounted) return;
    final biometricVerified = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BiometricVerificationPage()),
    );
    if (!mounted) return;
    if (biometricVerified != true) {
      await FirebaseService.signOut();
      if (!mounted) return;
      app.logout();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identity verification was cancelled.')),
      );
      return;
    }
    if (user.role == UserRole.admin) {
      final loadError = await app.loadUsersFromFirebase();
      if (!mounted) return;
      if (loadError != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(loadError)));
      }
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) {
          if (user.role == UserRole.admin) {
            return const AdminDashboard();
          } else if (user.role == UserRole.household) {
            return const HouseholdDashboard();
          } else {
            return const RoleDashboard();
          }
        },
      ),
    );
  }

  Future<void> _resendVerification() async {
    final app = context.read<AppProvider>();
    final message = await app.resendVerificationEmail();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ?? 'Verification email sent. Please check your Gmail inbox.',
        ),
      ),
    );
  }

  Future<void> _checkVerification() async {
    setState(() => _checkingVerification = true);
    final app = context.read<AppProvider>();
    final verified = await app.checkEmailVerification();
    if (!mounted) return;
    setState(() => _checkingVerification = false);
    if (verified) {
      await FirebaseService.signOut();
      if (!mounted) return;
      app.logout();
      setState(() {
        _showVerificationNotice = false;
        _username.clear();
        _password.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email verified. Please log in again.')),
      );
    }
  }

  void _forgotPassword() {
    final controller = TextEditingController(text: _username.text);
    final app = context.read<AppProvider>();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Forgot password?'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email address',
            prefixIcon: Icon(Icons.email_outlined),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final result = await app.forgotPasswordWithFirebase(
                controller.text,
              );
              if (!mounted || !dialogContext.mounted) return;
              Navigator.pop(dialogContext);
              if (result != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(result)));
              }
            },
            child: const Text('Send reset link'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppBackground(
        assetPath: 'assets/images/green_envi.jpg',
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.recycling_rounded,
                          size: 76,
                          color: Color(0xFF4ADE80),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'RecyConnect',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Connecting communities for a greener tomorrow',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 30),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.32),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white38),
                          ),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Welcome back!',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 25,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Log in to continue to your account.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 24),
                                _field(
                                  controller: _username,
                                  label: 'Email address',
                                  icon: Icons.email_outlined,
                                  validator: (v) =>
                                      v == null || !v.contains('@')
                                      ? 'Enter the email address used to register'
                                      : null,
                                  keyboard: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 16),
                                _field(
                                  controller: _password,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscure: _hidePassword,
                                  suffix: IconButton(
                                    onPressed: () => setState(
                                      () => _hidePassword = !_hidePassword,
                                    ),
                                    icon: Icon(
                                      _hidePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  validator: (v) => v == null || v.isEmpty
                                      ? 'Enter your password'
                                      : null,
                                ),
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _forgotPassword,
                                    child: const Text('Forgot password?'),
                                  ),
                                ),
                                SizedBox(
                                  height: 52,
                                  child: FilledButton(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF4ADE80),
                                      foregroundColor: const Color(0xFF102B1A),
                                    ),
                                    onPressed: _login,
                                    child: const Text(
                                      'LOG IN',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                if (_showVerificationNotice) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.orangeAccent,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        const Text(
                                          'Email not yet verified. Check your Gmail inbox, then try again.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          alignment: WrapAlignment.center,
                                          children: [
                                            TextButton(
                                              onPressed: _resendVerification,
                                              child: const Text('Resend email'),
                                            ),
                                            TextButton(
                                              onPressed: _checkingVerification
                                                  ? null
                                                  : _checkVerification,
                                              child: Text(
                                                _checkingVerification
                                                    ? 'Checking...'
                                                    : 'I verified it',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    const Text(
                                      "Don't have an account?",
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      ),
                                      child: const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          color: Color(0xFF4ADE80),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'RECYCLE  •  RECONNECT  •  REBUILD',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscure = false,
    Widget? suffix,
    TextInputType? keyboard,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      validator: validator,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: const Color(0xFF4ADE80)),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.20),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(13)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFF4ADE80), width: 1.5),
        ),
      ),
    );
  }
}
