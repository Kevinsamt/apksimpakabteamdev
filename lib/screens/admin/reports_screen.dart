import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/header.dart';
import '../../widgets/app_bottom_nav.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _supabase = Supabase.instance.client;
  int totalEquipments = 0;
  int activeLoansCount = 0;
  int overdueLoansCount = 0;
  int availableEquipments = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      // Fetch Equipments Info
      final equipments = await _supabase.from('equipments').select();
      int totalQty = 0;
      int availableQty = 0;
      for (var eq in equipments) {
        totalQty += (eq['total_quantity'] as int);
        availableQty += (eq['available_quantity'] as int);
      }

      // Fetch Loans Info
      final loans = await _supabase.from('loans').select();
      int active = 0;
      int overdue = 0;
      for (var loan in loans) {
         if (loan['status'] == 'approved' || loan['status'] == 'active') {
             active++;
         } else if (loan['status'] == 'overdue') {
             overdue++;
         }
      }

      if (mounted) {
        setState(() {
          totalEquipments = totalQty;
          availableEquipments = availableQty;
          activeLoansCount = active;
          overdueLoansCount = overdue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 24,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Flexible(
                  child: Text(
                    value,
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.primaryPink,
                      fontSize: 20,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: isDesktop ? null : const AppBottomNav(currentIndex: 4),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const Sidebar(currentRoute: '/reports'),
          Expanded(
            child: Column(
              children: [
                const HeaderWidget(
                  onMenuPressed: null,
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  Text('Reports & Analytics', style: AppTextStyles.heading1),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                         const SnackBar(content: Text('Fitur Ekspor PDF sedang dalam pengembangan!'))
                                      );
                                    },
                                    icon: const Icon(Icons.download),
                                    label: const Text('Export to PDF'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primaryPink,
                                      foregroundColor: AppColors.surfaceWhite,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    ),
                                  )
                                ],
                              ),
                              const SizedBox(height: 24),
                              GridView.count(
                                crossAxisCount: isDesktop ? 4 : 2,
                                childAspectRatio: isDesktop ? 2.2 : 1.5,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: [
                                  _buildStatCard('Total Inventaris', totalEquipments.toString(), AppColors.statusPending, Icons.inventory),
                                  _buildStatCard('Alat Tersedia', availableEquipments.toString(), AppColors.statusActive, Icons.check_circle_outline),
                                  _buildStatCard('Pinjaman Aktif', activeLoansCount.toString(), AppColors.lightPink, Icons.card_travel),
                                  _buildStatCard('Pinjaman Terlambat', overdueLoansCount.toString(), AppColors.statusOverdue, Icons.warning_amber),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ringkasan Laporan Bulan Ini', style: AppTextStyles.heading2),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Aplikasi saat ini menunjukkan pemanfaatan peralatan yang sangat baik. Semua peralatan yang tercatat masih bisa didistribusikan ke mahasiswa kebidanan (Bidan) dengan baik. Laporan bulanan detail akan digenerasi di akhir bulan.',
                                      style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
