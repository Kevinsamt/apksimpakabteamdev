import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/inventory_chart.dart';
import '../widgets/active_loans_list.dart';
import '../widgets/app_bottom_nav.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: isDesktop ? null : const AppBottomNav(currentIndex: 0),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const Sidebar(),
          
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  const HeaderWidget(onMenuPressed: null),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        isDesktop ? 32 : 16, 
                        isDesktop ? 32 : 16, 
                        isDesktop ? 32 : 16, 
                        80
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✨ Welcome Header
                          Text('Halo, Admin! 👋', style: AppTextStyles.heading1),
                          Text('Berikut adalah ringkasan inventaris Anda hari ini.', style: AppTextStyles.bodyText),
                          const SizedBox(height: 32),

                          // 💎 Summary Cards Row
                          LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 700 ? 2 : 1);
                              return GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 2.2,
                                children: [
                                  _buildSummaryCard(
                                    context,
                                    title: 'Total Barang',
                                    value: '124',
                                    icon: Icons.inventory_2_rounded,
                                    color: AppColors.primaryPink,
                                    trend: '+5%',
                                  ),
                                  _buildSummaryCard(
                                    context,
                                    title: 'Barang Rusak',
                                    value: '12',
                                    icon: Icons.personal_injury_rounded,
                                    color: AppColors.statusOverdue,
                                    trend: '-2%',
                                  ),
                                  _buildSummaryCard(
                                    context,
                                    title: 'Peminjaman Aktif',
                                    value: '45',
                                    icon: Icons.shopping_bag_rounded,
                                    color: AppColors.statusActive,
                                    trend: '+12%',
                                  ),
                                  _buildSummaryCard(
                                    context,
                                    title: 'Limbah Medis',
                                    value: '12 KG',
                                    icon: Icons.delete_sweep_rounded,
                                    color: AppColors.statusPending,
                                    trend: 'Monitor',
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 32),

                          // 🚀 Main Insights Area
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildContentBlock(
                                    title: 'Statistik Stok',
                                    child: const InventoryChart(),
                                  ),
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  flex: 3,
                                  child: _buildContentBlock(
                                    title: 'Aktivitas Peminjaman',
                                    child: const ActiveLoansList(),
                                  ),
                                )
                              ],
                            )
                          else ...[
                            _buildContentBlock(
                              title: 'Statistik Stok',
                              child: const InventoryChart(),
                            ),
                            const SizedBox(height: 24),
                            _buildContentBlock(
                              title: 'Aktivitas Peminjaman',
                              child: const ActiveLoansList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
        border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: AppTextStyles.label),
                Row(
                  children: [
                    Text(value, style: AppTextStyles.heading2.copyWith(fontSize: 24)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(trend, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBlock({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.heading2),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz)),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
