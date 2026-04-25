import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/screens/phone_login_screen.dart';
import 'features/auth/screens/otp_screen.dart';
import 'features/auth/screens/role_select_screen.dart';
import 'features/auth/screens/language_select_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/care_log/screens/care_log_list_screen.dart';
import 'features/care_log/screens/care_log_edit_screen.dart';
import 'features/sos/screens/sos_screen.dart';
import 'features/resource_map/screens/resource_map_screen.dart';
import 'features/medication/screens/medication_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/family/screens/family_view_screen.dart';
import 'features/navigation/screens/navigation_screen.dart';
import 'features/home/screens/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final user = FirebaseAuth.instance.currentUser;
      final isAuth = user != null;
      final isLoginRoute = state.matchedLocation.startsWith('/auth');

      if (!isAuth && !isLoginRoute) return '/auth/phone';
      if (isAuth && isLoginRoute) return '/home';
      return null;
    },
    routes: [
      // Auth flow
      GoRoute(
        path: '/auth/phone',
        builder: (ctx, _) => const PhoneLoginScreen(),
      ),
      GoRoute(
        path: '/auth/otp',
        builder: (ctx, state) {
          final phone = state.extra as String? ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/auth/role',
        builder: (ctx, _) => const RoleSelectScreen(),
      ),
      GoRoute(
        path: '/auth/language',
        builder: (ctx, _) => const LanguageSelectScreen(),
      ),

      // Main shell (bottom nav)
      ShellRoute(
        builder: (ctx, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (ctx, _) => const HomeScreen(),
          ),
          GoRoute(
            path: '/care-log',
            builder: (ctx, _) => const CareLogListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (ctx, state) {
                  final elderId = state.extra as String?;
                  return CareLogEditScreen(elderId: elderId);
                },
              ),
              GoRoute(
                path: ':logId',
                builder: (ctx, state) => CareLogEditScreen(
                  logId: state.pathParameters['logId'],
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/sos',
            builder: (ctx, _) => const SosScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (ctx, _) => const ResourceMapScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (ctx, _) => const ProfileScreen(),
          ),
        ],
      ),

      // Standalone routes
      GoRoute(
        path: '/navigation',
        builder: (ctx, _) => const NavigationScreen(),
      ),
      GoRoute(
        path: '/medication',
        builder: (ctx, _) => const MedicationScreen(),
      ),
      GoRoute(
        path: '/family-view',
        builder: (ctx, state) {
          final elderId = state.extra as String? ?? '';
          return FamilyViewScreen(elderId: elderId);
        },
      ),
    ],
    errorBuilder: (ctx, state) => Scaffold(
      body: Center(
        child: Text('頁面不存在：${state.error}'),
      ),
    ),
  );
});
