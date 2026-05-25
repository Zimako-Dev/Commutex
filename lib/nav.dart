import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smarttaxi/pages/onboarding_page.dart';
import 'package:smarttaxi/pages/auth_page.dart';
import 'package:smarttaxi/pages/ai_chat_page.dart';
import 'package:smarttaxi/pages/saved_page.dart';
import 'pages/home_page.dart';
import 'pages/calculator_page.dart';
import 'pages/trip_planner_page.dart';
import 'pages/result_page.dart';
import 'pages/settings_page.dart';
import 'data/models.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OnboardingPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AuthPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: HomePage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.calculator,
        name: 'calculator',
        builder: (context, state) => const CalculatorPage(),
      ),
      GoRoute(
        path: AppRoutes.tripPlanner,
        name: 'tripPlanner',
        builder: (context, state) => const TripPlannerPage(),
      ),
      GoRoute(
        path: AppRoutes.results,
        name: 'results',
        builder: (context, state) {
          final result = state.extra as TripResult;
          return ResultPage(result: result);
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.saved,
        name: 'saved',
        builder: (context, state) => const SavedPage(),
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        name: 'aiChat',
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const AiChatPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            );
          },
        ),
      ),
    ],
  );
}

class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String home = '/';
  static const String calculator = '/calculator';
  static const String tripPlanner = '/planner';
  static const String results = '/results';
  static const String settings = '/settings';
  static const String aiChat = '/ai-chat';
  static const String saved = '/saved';
}
