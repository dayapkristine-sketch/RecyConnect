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

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Keep the branded startup screen visible briefly without delaying any
    // Firebase work beyond what is necessary.
    final minimumLoadingTime = Future<void>.delayed(const Duration(seconds: 2));
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await initializeOfflineMapCache();
    final appProvider = AppProvider();
    await appProvider.loadTheme();
    await minimumLoadingTime;
    if (mounted) setState(() => _appProvider = appProvider);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = _appProvider;
    if (appProvider == null) {
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
