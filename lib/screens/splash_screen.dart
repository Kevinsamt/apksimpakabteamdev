import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/custom_loader.dart';
import 'auth_gate.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Use a simple timer instead of video listener
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _navigateToDashboard();
      }
    });
  }

  void _navigateToDashboard() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AuthGate(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Using the lighter logo for splash
            Image.asset(
              'assets/images/logo16_9.png',
              width: 280,
            ),
            const SizedBox(height: 50),
            const CustomLoader(
              size: 80,
              message: 'Menyiapkan Alat...',
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
