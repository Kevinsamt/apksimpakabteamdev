import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'auth_gate.dart';
import '../theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Failsafe timer: IF video hangs during initialization and doesn't throw an error,
    // force navigate to dashboard after 5 seconds so the user isn't stuck forever.
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        _navigateToDashboard();
      }
    });

    _controller = VideoPlayerController.asset('assets/video/VideoLoadingScreenAplikasi.mp4')
      ..initialize().then((_) {
        // Ensure the first frame is shown after the video is initialized
        setState(() {});
        _controller.play();
        
        // Listen for when the video finishes
        _controller.addListener(() {
          if (_controller.value.position == _controller.value.duration) {
            _navigateToDashboard();
          }
        });
      }).catchError((error) {
        // If video fails to load (e.g. unsupported format on Windows without plugins), fallback to dashboard after a delay
        Future.delayed(const Duration(seconds: 3), () {
          _navigateToDashboard();
        });
      });
  }

  void _navigateToDashboard() {
    // Only navigate if the widget is still mounted
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Center(
        child: _controller.value.isInitialized
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                ),
              )
            // Show a simple loading spinner before the video is fully prepared
            : const CircularProgressIndicator(color: AppColors.primaryPink),
      ),
    );
  }
}
