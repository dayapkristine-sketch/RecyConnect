import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'providers/app_provider.dart';
import 'providers/post_store.dart';
import 'screens/auth/login_page.dart';
import 'screens/auth/loading_page.dart';
import 'theme/app_theme.dart';
import 'widgets/osm_map.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StartupApp());
}

class StartupApp extends StatefulWidget {
  const StartupApp({super.key});

  @override
  State<StartupApp> createState() => _StartupAppState();
}

class _StartupAppState extends State<StartupApp> {
  AppProvider? _appProvider;
  String? _startupError;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      // Map caching is optional and must not delay the first screen, especially
      // on web where a file-backed cache is not available.
      unawaited(initializeOfflineMapCache());
      final appProvider = AppProvider();
      await appProvider.loadTheme();
      if (mounted) setState(() => _appProvider = appProvider);
    } catch (error) {
      if (mounted) setState(() => _startupError = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = _appProvider;
    if (appProvider == null) {
      if (_startupError != null) {
        return _StartupErrorPage(
          message: _startupError!,
          onRetry: () => setState(() {
            _startupError = null;
            _initialize();
          }),
        );
      }
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RecyConnect',
        home: const LoadingPage(),
      );
    }
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: appProvider),
        ChangeNotifierProvider(create: (_) => PostStore()),
      ],
      child: const RecyConnectApp(),
    );
  }
}

class _StartupErrorPage extends StatelessWidget {
  const _StartupErrorPage({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RecyConnect',
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'Could not start RecyConnect',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecyConnectApp extends StatelessWidget {
  const RecyConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RecyConnect',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: app.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const LoginPage(),
    );
  }
}
