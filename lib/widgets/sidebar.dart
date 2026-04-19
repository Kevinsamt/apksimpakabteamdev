import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class Sidebar extends StatelessWidget {
  final String currentRoute;
  const Sidebar({super.key, this.currentRoute = '/dashboard'});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280, // Slightly wider for better breathing space
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        border: const Border(
          right: BorderSide(color: Color(0xFFF3E5F5), width: 1.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✨ Logo Area (More Polished)
          Container(
            padding: const EdgeInsets.fromLTRB(28, 48, 28, 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: AppColors.premiumShadow,
                  ),
                  child: Image.asset(
                    'assets/images/logo_student.png',
                    height: 28,
                    errorBuilder: (c, e, s) => const Icon(Icons.monitor_heart, color: Colors.white, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SIMPAKAB', style: AppTextStyles.heading2.copyWith(fontSize: 18)),
                      Text('Admin Dashboard', style: AppTextStyles.label.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // 🚀 Navigation Items (Premium Styling)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionHeader('MAIN MENU'),
                _buildNavItem(context, icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, title: 'Dashboard', route: '/dashboard'),
                _buildNavItem(context, icon: Icons.inventory_2_outlined, activeIcon: Icons.inventory_2, title: 'Inventory', route: '/equipment'),
                _buildSectionHeader('OPERATIONS'),
                _buildNavItem(context, icon: Icons.assignment_return_outlined, activeIcon: Icons.assignment_return, title: 'Active Loans', route: '/loans'),
                _buildNavItem(context, icon: Icons.delete_sweep_outlined, activeIcon: Icons.delete_sweep, title: 'Medical Waste', route: '/waste'),
                _buildNavItem(context, icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner, title: 'Scan Tools', route: '/scan'),
                _buildSectionHeader('MANAGEMENT'),
                _buildNavItem(context, icon: Icons.people_outline, activeIcon: Icons.people, title: 'Midwives', route: '/users'),
                _buildNavItem(context, icon: Icons.analytics_outlined, activeIcon: Icons.analytics, title: 'Reports', route: '/reports'),
                
                // 🔱 Secret Dev Menu
                if (Supabase.instance.client.auth.currentUser?.email == 'dev@simpakab.com') ...[
                  _buildSectionHeader('DEVELOPER'),
                  _buildNavItem(context, icon: Icons.admin_panel_settings_outlined, activeIcon: Icons.admin_panel_settings, title: 'Dev Hub', route: '/dev_dashboard'),
                ],
              ],
            ),
          ),
          
          // 👤 Bottom Profile (Premium Card)
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.surfacePink.withValues(alpha: 0.5),
              border: const Border(top: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryPink, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, color: AppColors.primaryPink, size: 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Admin Klinik', style: AppTextStyles.bodyTextStrong),
                      Text('Coordinator', style: AppTextStyles.label),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.logout, color: AppColors.textMuted, size: 20),
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 24, 12, 8),
      child: Text(title, style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
    );
  }

  Widget _buildNavItem(BuildContext context, {
    required IconData icon, 
    required IconData activeIcon,
    required String title, 
    required String route
  }) {
    final isActive = currentRoute == route;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        gradient: isActive ? const LinearGradient(
          colors: [AppColors.gradientStart, AppColors.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isActive ? AppColors.premiumShadow : null,
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? Colors.white : AppColors.textSecondary,
          size: 22,
        ),
        title: Text(
          title,
          style: AppTextStyles.bodyTextStrong.copyWith(
            color: isActive ? Colors.white : AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
        onTap: () {
          if (!isActive) Navigator.pushReplacementNamed(context, route);
        },
      ),
    );
  }
}
