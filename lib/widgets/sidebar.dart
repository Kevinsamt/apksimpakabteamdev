import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;
  const Sidebar({super.key, this.currentRoute = '/dashboard'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: AppColors.surfaceWhite,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Image.asset(
                  'assets/images/logo_student.png',
                  height: 40,
                  errorBuilder: (c,e,s) => const Icon(Icons.monitor_heart, color: Colors.white),
                ),
          ),
          const Divider(color: AppColors.borderLight, height: 1),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                _buildNavItem(context, icon: Icons.dashboard, title: 'Dashboard', route: '/dashboard'),
                _buildNavItem(context, icon: Icons.inventory_2, title: 'Equipment Inventory', route: '/equipment'),
                _buildNavItem(context, icon: Icons.assignment_return, title: 'Active Loans', route: '/loans'),
                _buildNavItem(context, icon: Icons.qr_code_scanner, title: 'Scan Tools', route: '/scan'),
                _buildNavItem(context, icon: Icons.people, title: 'Midwives Directory', route: '/users'),
                _buildNavItem(context, icon: Icons.analytics, title: 'Reports', route: '/reports'),
              ],
            ),
          ),
          
          // Bottom Info
          const Divider(color: AppColors.borderLight, height: 1),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.lightPink,
                  child: Icon(Icons.person, color: AppColors.primaryPink),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Klinik',
                        style: AppTextStyles.bodyTextStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Bidan Coordinator',
                        style: AppTextStyles.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, {required IconData icon, required String title, required String route}) {
    final isActive = currentRoute == route;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? AppColors.lightPink : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppColors.primaryPink : AppColors.textSecondary,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyTextStrong.copyWith(
            color: isActive ? AppColors.primaryPink : AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        onTap: () {
          if (!isActive) {
            Navigator.pushReplacementNamed(context, route);
          }
        },
      ),
    );
  }
}
