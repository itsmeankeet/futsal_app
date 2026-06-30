import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/court.dart';

// Screens
import '../../screens/login_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/court_detail_screen.dart';
import '../../screens/my_bookings_screen.dart';
import '../../screens/owner/owner_dashboard_screen.dart';
import '../../screens/owner/register_futsal_screen.dart';
import '../../screens/owner/add_court_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/splash_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    
    // Customer routes
    GoRoute(
      path: '/customer/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/customer/court-detail',
      builder: (context, state) {
        final court = state.extra as FutsalCourt;
        return CourtDetailScreen(court: court);
      },
    ),
    GoRoute(
      path: '/customer/bookings',
      builder: (context, state) => const MyBookingsScreen(),
    ),

    // Owner routes
    GoRoute(
      path: '/owner/dashboard',
      builder: (context, state) => const OwnerDashboardScreen(),
    ),
    GoRoute(
      path: '/owner/register-futsal',
      builder: (context, state) => const RegisterFutsalScreen(),
    ),
    GoRoute(
      path: '/owner/add-court',
      builder: (context, state) => const AddCourtScreen(),
    ),

    // Admin routes
    GoRoute(
      path: '/admin/dashboard',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
