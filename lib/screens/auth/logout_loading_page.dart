import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';
import '../../services/firebase_service.dart';
import 'loading_page.dart';
import 'login_page.dart';

class LogoutLoadingPage extends StatefulWidget {
  const LogoutLoadingPage({super.key});

  @override
  State<LogoutLoadingPage> createState() => _LogoutLoadingPageState();
}

class _LogoutLoadingPageState extends State<LogoutLoadingPage> {
  @override
  void initState() {
    super.initState();
    _signOut();
  }

  Future<void> _signOut() async {
    final minimumLoadingTime = Future<void>.delayed(const Duration(seconds: 2));
    await FirebaseService.signOut();
    await minimumLoadingTime;
    if (!mounted) return;
    context.read<AppProvider>().logout();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingPage(
      message: 'Signing you out securely...',
      icon: Icons.logout_rounded,
    );
  }
}
