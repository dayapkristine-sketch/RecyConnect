import 'package:application_recyconnect/main.dart';
import 'package:application_recyconnect/providers/app_provider.dart';
import 'package:application_recyconnect/widgets/theme_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('app starts without a login theme toggle', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const RecyConnectApp(),
      ),
    );

    expect(find.text('RecyConnect'), findsOneWidget);
    expect(find.byTooltip('Switch to light mode'), findsNothing);
    expect(find.byTooltip('Switch to dark mode'), findsNothing);
  });

  testWidgets('icon-only theme toggle does not show a text label', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MaterialApp(
          home: Scaffold(body: ThemeToggle(iconOnly: true)),
        ),
      ),
    );

    expect(find.byType(IconButton), findsOneWidget);
    expect(find.text('Light mode'), findsNothing);
  });

  testWidgets('labeled theme toggle shows its current action', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MaterialApp(home: Scaffold(body: ThemeToggle())),
      ),
    );

    expect(find.text('Light mode'), findsOneWidget);
    expect(find.byType(TextButton), findsOneWidget);
  });
}
