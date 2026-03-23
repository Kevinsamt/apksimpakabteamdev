import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/header.dart';
import '../../widgets/app_bottom_nav.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('loans')
          .select('''
            *,
            profiles(full_name),
            equipments(name, sku)
          ''')
          .order('borrow_date', ascending: false);
      if (mounted) {
        setState(() {
          _loans = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $error'), backgroundColor: AppColors.statusOverdue),
        );
      }
    }
  }

  Future<void> _updateStatus(String id, String newStatus, String equipmentId) async {
    try {
      if (newStatus == 'approved' || newStatus == 'returned') {
        // Fetch current equipment
        final eqData = await _supabase.from('equipments').select('available_quantity').eq('id', equipmentId).single();
        int currentQty = eqData['available_quantity'] as int;

        if (newStatus == 'approved') {
          if (currentQty <= 0) {
             throw 'Stok barang habis!';
          }
          currentQty -= 1;
        } else if (newStatus == 'returned') {
          currentQty += 1;
        }

        // Update equipment stock
        await _supabase.from('equipments').update({'available_quantity': currentQty}).eq('id', equipmentId);
      }

      await _supabase.from('loans').update({'status': newStatus}).eq('id', id);
      _fetchLoans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status berhasil diubah ke "$newStatus"'), backgroundColor: AppColors.statusActive),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Gagal mengubah status: $e'), backgroundColor: AppColors.statusOverdue),
        );
      }
    }
  }

  Future<void> _deleteLoan(Map<String, dynamic> loan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text('Hapus Data Pinjaman', style: AppTextStyles.heading2),
        content: const Text('Yakin ingin menghapus riwayat peminjaman ini secara permanen?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusOverdue, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabase.from('loans').delete().eq('id', loan['id']);
      _fetchLoans();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data pinjaman berhasil dihapus'), backgroundColor: AppColors.statusActive));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusOverdue));
      }
    }
  }

  void _showLoanDetails(Map<String, dynamic> loan) {
    final borrowerName = loan['profiles']?['full_name'] ?? 'Unknown';
    final equipName = loan['equipments']?['name'] ?? 'Unknown';
    final sku = loan['equipments']?['sku'] ?? '-';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text('Detail Peminjaman', style: AppTextStyles.heading2),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Peminjam: $borrowerName', style: AppTextStyles.bodyTextStrong),
            const SizedBox(height: 8),
            Text('Barang: $equipName (SKU: $sku)', style: AppTextStyles.bodyText),
            const SizedBox(height: 8),
            Text('Tanggal Pinjam: ${_formatDate(loan['borrow_date'])}', style: AppTextStyles.bodyText),
            const SizedBox(height: 8),
            Text('Tanggal Kembali: ${loan['return_date'] != null ? _formatDate(loan['return_date']) : 'Belum/Tidak Terjadwal'}', style: AppTextStyles.bodyText),
            const SizedBox(height: 8),
            Text('Status: ${loan['status'].toString().toUpperCase()}', style: AppTextStyles.bodyText.copyWith(color: _getStatusColor(loan['status'] ?? ''))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup', style: TextStyle(color: AppColors.primaryPink))),
        ],
      ),
    );
  }

  // --- UI Helpers ---
  Color _getStatusColor(String status) {
    if (status == 'active' || status == 'approved') return AppColors.statusActive;
    if (status == 'pending') return AppColors.statusPending;
    if (status == 'overdue') return AppColors.statusOverdue;
    if (status == 'returned') return AppColors.textSecondary;
    return AppColors.textPrimary;
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: isDesktop ? null : const AppBottomNav(currentIndex: 2),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const Sidebar(currentRoute: '/loans'),
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
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Active Loans & Approvals', style: AppTextStyles.heading1),
                                  // Nanti bisa ditambahkan tombol "Manual Loan" jika admin mau input sendiri
                                ],
                              ),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: _loans.isEmpty
                                  ? const Center(child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Text('Belum ada peminjaman alat.', style: TextStyle(color: AppColors.textSecondary)),
                                    ))
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                          headingTextStyle: AppTextStyles.bodyTextStrong,
                                          columns: const [
                                            DataColumn(label: Text('Nama Alat')),
                                            DataColumn(label: Text('Peminjam')),
                                            DataColumn(label: Text('Tgl Pinjam')),
                                            DataColumn(label: Text('Status')),
                                            DataColumn(label: Text('Aksi')),
                                          ],
                                          rows: _loans.map((loan) {
                                            final status = loan['status'] ?? 'pending';
                                            final ekipName = loan['equipments']?['name'] ?? 'Barang Dihapus';
                                            
                                            // Fallback for borrower name
                                            var borrowerName = loan['profiles']?['full_name'];
                                            if (borrowerName == null || borrowerName.toString().trim().isEmpty) {
                                              borrowerName = '(Nama Belum Diset)';
                                            }

                                            return DataRow(cells: [
                                              DataCell(Text(ekipName, style: AppTextStyles.bodyText)),
                                              DataCell(Text(borrowerName, style: AppTextStyles.bodyText)),
                                              DataCell(Text(_formatDate(loan['borrow_date']), style: AppTextStyles.bodyText)),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: _getStatusColor(status).withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.5)),
                                                  ),
                                                  child: Text(
                                                    status.toString().toUpperCase(),
                                                    style: AppTextStyles.label.copyWith(
                                                      color: _getStatusColor(status),
                                                      fontWeight: FontWeight.w700,
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    if (status == 'pending') ...[
                                                      TextButton(
                                                        onPressed: () => _updateStatus(loan['id'], 'approved', loan['equipment_id']),
                                                        child: const Text('Setujui', style: TextStyle(color: AppColors.statusActive)),
                                                      ),
                                                      TextButton(
                                                        onPressed: () => _updateStatus(loan['id'], 'rejected', loan['equipment_id']),
                                                        child: const Text('Tolak', style: TextStyle(color: AppColors.statusOverdue)),
                                                      ),
                                                    ] else if (status == 'approved') ...[
                                                      TextButton(
                                                        onPressed: () => _updateStatus(loan['id'], 'returned', loan['equipment_id']),
                                                        child: const Text('Dikembalikan', style: TextStyle(color: AppColors.textSecondary)),
                                                      ),
                                                    ],
                                                    IconButton(
                                                      tooltip: 'Lihat Detail',
                                                      icon: const Icon(Icons.info_outline, color: AppColors.primaryPink, size: 20),
                                                      onPressed: () => _showLoanDetails(loan),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Hapus Riwayat',
                                                      icon: const Icon(Icons.delete, color: AppColors.statusOverdue, size: 20),
                                                      onPressed: () => _deleteLoan(loan),
                                                    ),
                                                  ],
                                                )
                                              ),
                                            ]);
                                          }).toList(),
                                      ),
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
