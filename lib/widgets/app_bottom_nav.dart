import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  
  const AppBottomNav({super.key, required this.currentIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == currentIndex) return;

    String route = '/dashboard';
    switch (index) {
      case 0: route = '/dashboard'; break;
      case 1: route = '/equipment'; break;
      case 2: route = '/loans'; break;
      case 3: route = '/users'; break;
      case 4: route = '/reports'; break;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      decoration: BoxDecoration(
        color: Colors.transparent, // Backgroundnya bening biar Floating
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryPink.withValues(alpha: 0.15),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: AppColors.primaryPink.withValues(alpha: 0.05), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(context, 0, Icons.dashboard_outlined, Icons.dashboard, 'Beranda'),
            _buildNavItem(context, 1, Icons.inventory_2_outlined, Icons.inventory_2, 'Alat'),
            _buildNavItem(context, 2, Icons.assignment_return_outlined, Icons.assignment_return, 'Pinjaman'),
            _buildNavItem(context, 3, Icons.people_outline, Icons.people, 'Bidan'),
            _buildNavItem(context, 4, Icons.analytics_outlined, Icons.analytics, 'Laporan'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, int index, IconData icon, IconData activeIcon, String label) {
    final isActive = currentIndex == index;
    return InkWell(
      onTap: () => _onItemTapped(context, index),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryPink.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? AppColors.primaryPink : AppColors.textMuted,
              size: 24,
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.primaryPink,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
