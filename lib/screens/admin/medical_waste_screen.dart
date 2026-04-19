import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/header.dart';
import '../../widgets/custom_loader.dart';
import 'waste_scanner_screen.dart';

class MedicalWasteScreen extends StatefulWidget {
  const MedicalWasteScreen({super.key});

  @override
  State<MedicalWasteScreen> createState() => _MedicalWasteScreenState();
}

class _MedicalWasteScreenState extends State<MedicalWasteScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _wasteData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchWasteData();
  }

  Future<void> _fetchWasteData() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('medical_waste').select().order('created_at');
      if (mounted) {
        setState(() {
          _wasteData = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const Sidebar(currentRoute: '/waste'),
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
                            _buildTitleSection(),
                            const SizedBox(height: 32),
                            _buildSummaryCards(),
                            const SizedBox(height: 32),
                            _buildWasteTable(),
                          ],
                        ),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddWasteDialog(context),
        backgroundColor: AppColors.primaryPink,
        icon: const Icon(Icons.add_circle_outline, color: Colors.white),
        label: Text('Catat Limbah', style: AppTextStyles.button),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pengelolaan Limbah Medis 🩹', style: AppTextStyles.heading1),
            Text('Pantau dan catat pembuangan limbah infeksius.', style: AppTextStyles.bodyText),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WasteScannerScreen())),
          icon: const Icon(Icons.qr_code_scanner, size: 18),
          label: const Text('Scan QR Tong'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildStatCard('Total Limbah', '${_wasteData.length} KG', Icons.delete_forever, AppColors.primaryPink),
        const SizedBox(width: 20),
        _buildStatCard('Bulan Ini', '12 KG', Icons.calendar_today, AppColors.statusPending),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.label),
                Text(value, style: AppTextStyles.heading2),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWasteTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppColors.cardShadow,
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Riwayat Pembuangan', style: AppTextStyles.heading2),
          const SizedBox(height: 20),
          if (_wasteData.isEmpty)
             const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Belum ada riwayat pembuangan.')))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _wasteData.length,
              separatorBuilder: (context, index) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final item = _wasteData[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfacePink,
                    child: Icon(Icons.medication_liquid_sharp, color: AppColors.primaryPink),
                  ),
                  title: Text(item['type'] ?? 'Infeksius', style: AppTextStyles.bodyTextStrong),
                  subtitle: Text('Petugas: ${item['officer_name'] ?? 'Admin'} • ${item['weight']} KG', style: AppTextStyles.bodyText),
                  trailing: Text(item['created_at'].toString().split('T')[0], style: AppTextStyles.label),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showAddWasteDialog(BuildContext context) {
    final weightController = TextEditingController();
    final officerController = TextEditingController();
    String? selectedType = 'Infeksius';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Catat Pembuangan Limbah', style: AppTextStyles.heading2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: _inputDecoration('Jenis Limbah'),
                  items: ['Infeksius', 'Benda Tajam', 'Kimiawi', 'Radioaktif'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setStateDialog(() => selectedType = v),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration('Berat Limbah (KG)'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: officerController,
                  decoration: _inputDecoration('Nama Petugas'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (weightController.text.isEmpty) return;
                setStateDialog(() => isSubmitting = true);
                try {
                  await _supabase.from('medical_waste').insert({
                    'type': selectedType,
                    'weight': double.tryParse(weightController.text) ?? 0,
                    'officer_name': officerController.text,
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    _fetchWasteData();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limbah berhasil dicatat!')));
                  }
                } catch (e) {
                  debugPrint('Error: $e');
                  setStateDialog(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white),
              child: isSubmitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
    );
  }
}
