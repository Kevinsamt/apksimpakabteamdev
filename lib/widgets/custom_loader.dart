import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomLoader extends StatefulWidget {
  final double size;
  final String? message;

  const CustomLoader({
    super.key,
    this.size = 100,
    this.message,
  });

  @override
  State<CustomLoader> createState() => _CustomLoaderState();
}

class _CustomLoaderState extends State<CustomLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.8, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _animation,
            child: Container(
              width: widget.size,
              height: widget.size,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryPink.withValues(alpha: 0.2),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/midwifery_icon_loading.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.medical_services_outlined,
                    color: AppColors.primaryPink,
                    size: 40,
                  );
                },
              ),
            ),
          ),
          if (widget.message != null) ...[
            const SizedBox(height: 24),
            Text(
              widget.message!,
              style: TextStyle(
                color: AppColors.primaryPink.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 8),
            const SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                backgroundColor: AppColors.surfacePink,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryPink),
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
