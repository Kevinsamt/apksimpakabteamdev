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
      case 0:
        route = '/dashboard';
        break;
      case 1:
        route = '/equipment';
        break;
      case 2:
        route = '/loans';
        break;
      case 3:
        route = '/users';
        break;
      case 4:
        route = '/reports';
        break;
    }
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryPink.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) => _onItemTapped(context, index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surfaceWhite,
          elevation: 0,
          selectedItemColor: AppColors.primaryPink,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
          unselectedLabelStyle: AppTextStyles.label.copyWith(fontSize: 10),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Beranda',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'Alat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_return),
          label: 'Pinjaman',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Bidan',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Laporan',
        ),
      ],
        ),
      ),
    );
  }
}
