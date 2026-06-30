import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateBasedOnRole(String role) {
    if (role == 'ADMIN') {
      context.go('/admin/dashboard');
    } else if (role == 'OWNER') {
      context.go('/owner/dashboard');
    } else {
      context.go('/customer/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    const themeColor = Color(0xFF39FF14);
    
    // Listen for auth state changes to trigger navigation after initialization
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (!next.isLoading) {
        if (next.isAuthenticated) {
          _navigateBasedOnRole(next.user!.role);
        } else {
          context.go('/login');
        }
      }
    });

    // Navigate immediately if already loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!authState.isLoading) {
        if (authState.isAuthenticated) {
          _navigateBasedOnRole(authState.user!.role);
        } else {
          context.go('/login');
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: themeColor.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: themeColor, width: 2),
              ),
              child: const Icon(
                Icons.sports_soccer,
                size: 80,
                color: themeColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'KICKOFF',
              style: GoogleFonts.outfit(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 12),
            const SpinKitThreeBounce(
              color: themeColor,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
