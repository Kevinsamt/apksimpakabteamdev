import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class HeaderWidget extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  const HeaderWidget({super.key, this.onMenuPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Title
          Expanded(
            child: Row(
              children: [
                if (onMenuPressed != null)
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                    onPressed: onMenuPressed,
                    padding: const EdgeInsets.only(right: 16),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard', style: AppTextStyles.heading1, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        'Welcome back!',
                        style: AppTextStyles.bodyText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Right: Action Buttons
          Row(
            children: [
              // Logout Button
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.statusOverdue),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
              ),
              const SizedBox(width: 8),
              // Notifications
              IconButton(
                icon: const Icon(Icons.notifications_none, color: AppColors.textSecondary),
                onPressed: () {},
              ),
              const SizedBox(width: 16),
              // Scan QR Code Button
              MediaQuery.of(context).size.width >= 600
                  ? ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.surfaceWhite),
                      label: const Text('Scan QR Code'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: AppColors.surfaceWhite,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        textStyle: AppTextStyles.bodyTextStrong,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryPink),
                      onPressed: () {},
                    ),
              const SizedBox(width: 8),
            ],
          )
        ],
      ),
    );
  }
}

