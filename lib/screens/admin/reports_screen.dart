import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/pdf_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/header.dart';
import '../../widgets/app_bottom_nav.dart';
import '../../widgets/custom_loader.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _supabase = Supabase.instance.client;
  int totalEquipments = 0;
  int availableEquipments = 0;
  int brokenEquipmentsCount = 0;
  int activeLoansCount = 0;
  int overdueLoansCount = 0;
  List<Map<String, dynamic>> _brokenList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final equipments = await _supabase.from('equipments').select();
      int totalQty = 0;
      int availableQty = 0;
      int brokenQty = 0;
      List<Map<String, dynamic>> brokenItems = [];

      for (var eq in equipments) {
        totalQty += (eq['total_quantity'] as int);
        availableQty += (eq['available_quantity'] as int);
        int itemBroken = (eq['broken_condition'] as int? ?? 0);
        brokenQty += itemBroken;
        if (itemBroken > 0) brokenItems.add(eq);
      }

      final loans = await _supabase.from('loans').select();
      int active = 0;
      int overdue = 0;
      for (var loan in loans) {
        if (loan['status'] == 'approved' || loan['status'] == 'active') active++;
        else if (loan['status'] == 'overdue') overdue++;
      }

      if (mounted) {
        setState(() {
          totalEquipments = totalQty;
          availableEquipments = availableQty;
          brokenEquipmentsCount = brokenQty;
          _brokenList = brokenItems;
          activeLoansCount = active;
          overdueLoansCount = overdue;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

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
                const HeaderWidget(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CustomLoader())
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isDesktop ? 32 : 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildHeaderSection(context),
                              const SizedBox(height: 32),
                              _buildStatCardsGrid(isDesktop),
                              const SizedBox(height: 32),
                              _buildBrokenListSection(),
                              const SizedBox(height: 32),
                              _buildSummaryAnalytics(),
                              const SizedBox(height: 100),
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

  Widget _buildHeaderSection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports & Analytics 📊', style: AppTextStyles.heading1),
            Text('Ringkasan statistik laboratorium kebidanan.', style: AppTextStyles.bodyText),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => PdfService.generateReportsPdf(
            context: context,
            totalEquipments: totalEquipments,
            availableEquipments: availableEquipments,
            activeLoans: activeLoansCount,
            overdueLoans: overdueLoansCount,
            summaryText: 'Laporan per tanggal ${DateTime.now().toLocal()}. Kondisi alat terpantau ${brokenEquipmentsCount > 0 ? 'butuh perhatian' : 'sangat baik'}.',
          ),
          icon: const Icon(Icons.picture_as_pdf_rounded),
          label: const Text('Export PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCardsGrid(bool isDesktop) {
    return GridView.count(
      crossAxisCount: isDesktop ? 4 : 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Alat', totalEquipments.toString(), Icons.inventory_2_rounded, AppColors.primaryPink),
        _buildStatCard('Alat Siap', availableEquipments.toString(), Icons.check_circle_rounded, AppColors.statusActive),
        _buildStatCard('Rusak', brokenEquipmentsCount.toString(), Icons.report_gmailerrorred_rounded, AppColors.statusOverdue),
        _buildStatCard('Aktif Pinjam', activeLoansCount.toString(), Icons.assignment_rounded, AppColors.textSecondary),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.label.copyWith(fontSize: 11)),
              Icon(icon, color: color.withValues(alpha: 0.6), size: 18),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.heading1.copyWith(fontSize: 24, color: color)),
        ],
      ),
    );
  }

  Widget _buildBrokenListSection() {
    return Container(
      width: double.infinity,
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
            children: [
              const Icon(Icons.warning_rounded, color: AppColors.statusOverdue, size: 24),
              const SizedBox(width: 12),
              Text('Alat Butuh Perhatian', style: AppTextStyles.heading2),
            ],
          ),
          const SizedBox(height: 20),
          if (_brokenList.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Semua alat dalam kondisi prima! ✨')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _brokenList.length,
              separatorBuilder: (c, i) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = _brokenList[index];
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.statusOverdue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.handyman_rounded, color: AppColors.statusOverdue, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['name'], style: AppTextStyles.bodyTextStrong),
                          Text('Kategori: ${item['category']}', style: AppTextStyles.label.copyWith(fontSize: 10)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.statusOverdue, borderRadius: BorderRadius.circular(10)),
                      child: Text('${item['broken_condition']} Unit', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryAnalytics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primaryPink, AppColors.primaryPink.withValues(alpha: 0.8)]),
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.premiumShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Analisis AI Singkat 🤖', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 12),
          Text(
            brokenEquipmentsCount > 0 
                ? 'Sistem mendeteksi adanya $brokenEquipmentsCount alat rusak. Disarankan untuk segera melakukan stok opname atau pengadaan baru agar praktikum tidak terhambat.'
                : 'Performa laboratorium saat ini dalam kondisi optimal. Tingkat ketersediaan alat mencapai ${(availableEquipments/totalEquipments*100).toStringAsFixed(1)}%. Pertahankan kondisi ini!',
            style: const TextStyle(color: Colors.white, height: 1.6, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
