import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'nav.dart';
import 'services/theme_provider.dart';

/// Main entry point for the application
///
/// This sets up:
/// - Provider state management (ThemeProvider)
/// - go_router navigation
/// - Material 3 theming with light/dark modes
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  _warmUpFonts();
  runApp(const MyApp());
}

/// Starts loading the fonts the first screens use straight away, so text
/// doesn't re-layout (and stutter) mid-animation when a font arrives late.
void _warmUpFonts() {
  unawaited(
    GoogleFonts.pendingFonts([
      GoogleFonts.outfit(fontWeight: FontWeight.w600),
      GoogleFonts.outfit(fontWeight: FontWeight.w700),
      GoogleFonts.inter(),
      GoogleFonts.inter(fontWeight: FontWeight.w500),
      GoogleFonts.inter(fontWeight: FontWeight.w600),
      GoogleFonts.inter(fontWeight: FontWeight.w700),
      GoogleFonts.jetBrainsMono(fontWeight: FontWeight.w700),
    ]).catchError((_) => <void>[]),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider wraps the app to provide state to all widgets
    // As you extend the app, use MultiProvider to wrap the app
    // and provide state to all widgets
    // Example:
    // return MultiProvider(
    //   providers: [
    //     ChangeNotifierProvider(create: (_) => ExampleProvider()),
    //   ],
    //   child: MaterialApp.router(
    //     title: 'Dreamflow Starter',
    //     debugShowCheckedModeBanner: false,
    //     routerConfig: AppRouter.router,
    //   ),
    // );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp.router(
            title: 'SmartTaxi',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeProvider.themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
