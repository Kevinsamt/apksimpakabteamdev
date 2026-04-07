import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/custom_loader.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/header.dart';
import '../../widgets/app_bottom_nav.dart';
import '../student/formal_form_view.dart';
import '../../services/notification_service.dart';

class LoansScreen extends StatefulWidget {
  const LoansScreen({super.key});

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;
  bool _showHistory = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLoans() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase
          .from('loans')
          .select('''
            *,
            profiles(full_name, nim, kelas),
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
        final eqData = await _supabase.from('equipments').select('available_quantity').eq('id', equipmentId).single();
        int currentQty = eqData['available_quantity'] as int;
        if (newStatus == 'approved') {
          if (currentQty <= 0) throw 'Stok barang habis!';
          currentQty -= 1;
        } else if (newStatus == 'returned') {
          currentQty += 1;
        }
        await _supabase.from('equipments').update({'available_quantity': currentQty}).eq('id', equipmentId);
      }

      if (newStatus == 'returned') {
        await _supabase.from('loans').update({
          'status': newStatus,
          'return_date': DateTime.now().toIso8601String(),
        }).eq('id', id);
      } else {
        await _supabase.from('loans').update({'status': newStatus}).eq('id', id);
      }

      final loanData = await _supabase.from('loans').select('user_id, equipments(name)').eq('id', id).single();
      final studentId = loanData['user_id'];
      final equipName = loanData['equipments']['name'];

      String title = '';
      String message = '';
      if (newStatus == 'approved') {
        title = 'Peminjaman Disetujui';
        message = 'Peminjaman alat "$equipName" telah disetujui. Silakan ambil barang di laboratorium.';
      } else if (newStatus == 'rejected') {
        title = 'Peminjaman Ditolak';
        message = 'Maaf, permintaan pinjam "$equipName" ditolak oleh admin.';
      }

      if (title.isNotEmpty) {
        await NotificationService.addNotification(
          userId: studentId,
          title: title,
          message: message,
          role: 'student',
          type: 'loan_status',
        );
      }
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

  Widget _buildToggleButton(String label, bool isActive, VoidCallback onTap) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isActive ? AppColors.primaryPink : AppColors.surfaceWhite,
        foregroundColor: isActive ? Colors.white : AppColors.textPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isActive ? AppColors.primaryPink : AppColors.borderLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '-';
    }
  }

  String _parseFromNotes(String? notes, String key) {
    if (notes == null || notes.isEmpty) return '-';
    final parts = notes.split(', ');
    for (var part in parts) {
      if (part.trim().startsWith('$key:')) {
        return part.replaceFirst('$key:', '').trim();
      }
    }
    return '-';
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
    String tglPinjam = '-';
    String tglPraktik = '-';
    final String notes = loan['notes'] ?? '';
    if (notes.contains('Tgl Pinjam:')) {
      tglPinjam = _parseFromNotes(notes, 'Tgl Pinjam');
      tglPraktik = _parseFromNotes(notes, 'Tgl Praktik');
    }

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
            Text('Tanggal Pinjam: ${tglPinjam != '-' ? tglPinjam : _formatDate(loan['borrow_date'])}', style: AppTextStyles.bodyText),
            const SizedBox(height: 8),
            Text('Tanggal Praktik: $tglPraktik', style: AppTextStyles.bodyText),
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

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '-';
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
                      ? const CustomLoader(message: 'Memuat data peminjaman...')
                      : RefreshIndicator(
                          onRefresh: _fetchLoans,
                          color: AppColors.primaryPink,
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 16,
                                  runSpacing: 12,
                                  children: [
                                    Text(_showHistory ? 'History Peminjaman' : 'Active Loans & Approvals', style: AppTextStyles.heading1),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _buildToggleButton('Aktif', !_showHistory, () => setState(() => _showHistory = false)),
                                        const SizedBox(width: 8),
                                        _buildToggleButton('Riwayat', _showHistory, () => setState(() => _showHistory = true)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                // Search Bar
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceWhite,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: TextField(
                                    controller: _searchController,
                                    onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                                    decoration: const InputDecoration(
                                      hintText: 'Cari nama peminjam atau tanggal (contoh: Apr 07)...',
                                      hintStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                                      border: InputBorder.none,
                                      icon: Icon(Icons.search, color: AppColors.primaryPink),
                                    ),
                                  ),
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
                                  child: Builder(
                                    builder: (context) {
                                      final filteredLoans = _loans.where((loan) {
                                        final status = loan['status'] ?? 'pending';
                                        final borrowerName = (loan['profiles']?['full_name'] ?? '').toString().toLowerCase();
                                        final loanDate = _formatDate(loan['borrow_date']).toLowerCase();
                                        
                                        // Filter berdasarkan Tab (Aktif/Riwayat)
                                        final matchesTab = _showHistory ? status == 'returned' : status != 'returned';
                                        
                                        // Filter berdasarkan Search Query
                                        final matchesSearch = borrowerName.contains(_searchQuery) || loanDate.contains(_searchQuery);
                                        
                                        return matchesTab && matchesSearch;
                                      }).toList();
 
                                      if (filteredLoans.isEmpty) {
                                        return Center(child: Padding(
                                          padding: const EdgeInsets.all(32.0),
                                          child: Text(_searchQuery.isNotEmpty 
                                            ? 'Hasil pencarian "$_searchQuery" tidak ditemukan.' 
                                            : (_showHistory ? 'Belum ada riwayat pengembalian.' : 'Belum ada peminjaman aktif.'), 
                                            style: const TextStyle(color: AppColors.textSecondary)),
                                        ));
                                      }
 
                                      return SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                            headingTextStyle: AppTextStyles.bodyTextStrong,
                                            columns: [
                                              const DataColumn(label: Text('Nama Alat')),
                                              const DataColumn(label: Text('Peminjam')),
                                              const DataColumn(label: Text('Tgl Pinjam')),
                                              if (!_showHistory) const DataColumn(label: Text('Tgl Praktik')),
                                              if (!_showHistory) const DataColumn(label: Text('Jam Ambil')),
                                              if (_showHistory) const DataColumn(label: Text('Tgl Kembali')),
                                              if (_showHistory) const DataColumn(label: Text('Jam Kembali')),
                                              const DataColumn(label: Text('Status')),
                                              const DataColumn(label: Text('Aksi')),
                                            ],
                                            rows: filteredLoans.map((loan) {
                                              final status = loan['status'] ?? 'pending';
                                              final ekipName = loan['equipments']?['name'] ?? 'Barang Dihapus';
                                              var borrowerName = loan['profiles']?['full_name'];
                                              if (borrowerName == null || borrowerName.toString().trim().isEmpty) {
                                                borrowerName = '(Nama Belum Diset)';
                                              }
 
                                              return DataRow(cells: [
                                                DataCell(Text(ekipName, style: AppTextStyles.bodyText)),
                                                DataCell(Text(borrowerName, style: AppTextStyles.bodyText)),
                                                DataCell(Text(_formatDate(loan['borrow_date']), style: AppTextStyles.bodyText)),
                                                if (!_showHistory) DataCell(Text(_parseFromNotes(loan['notes'], 'Tgl Praktik'), style: AppTextStyles.bodyText)),
                                                if (!_showHistory) DataCell(Text(_parseFromNotes(loan['notes'], 'Pukul'), style: AppTextStyles.bodyText)),
                                                if (_showHistory) DataCell(Text(_formatDate(loan['return_date']), style: AppTextStyles.bodyText)),
                                                if (_showHistory) DataCell(Text(_formatTime(loan['return_date']), style: AppTextStyles.bodyText)),
                                                DataCell(
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(status).withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(color: _getStatusColor(status).withValues(alpha: 0.5)),
                                                    ),
                                                    child: Text(
                                                      status.toUpperCase(),
                                                      style: AppTextStyles.label.copyWith(color: _getStatusColor(status), fontWeight: FontWeight.w700, fontSize: 10),
                                                    ),
                                                  ),
                                                ),
                                                DataCell(
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      if (status == 'pending') ...[
                                                        TextButton(onPressed: () => _updateStatus(loan['id'], 'approved', loan['equipment_id']), child: const Text('Setujui', style: TextStyle(color: AppColors.statusActive))),
                                                        TextButton(onPressed: () => _updateStatus(loan['id'], 'rejected', loan['equipment_id']), child: const Text('Tolak', style: TextStyle(color: AppColors.statusOverdue))),
                                                      ] else if (status == 'approved') ...[
                                                        TextButton(onPressed: () => _updateStatus(loan['id'], 'returned', loan['equipment_id']), child: const Text('Dikembalikan', style: TextStyle(color: AppColors.textSecondary))),
                                                      ],
                                                      IconButton(tooltip: 'Detail', icon: const Icon(Icons.info_outline, color: AppColors.primaryPink, size: 20), onPressed: () => _showLoanDetails(loan)),
                                                      IconButton(
                                                        tooltip: 'Formulir Formal',
                                                        icon: const Icon(Icons.description_outlined, color: AppColors.primaryPink, size: 20),
                                                        onPressed: () {
                                                          Navigator.push(context, MaterialPageRoute(builder: (context) => FormalFormView(loanData: loan, studentName: loan['profiles']?['full_name'] ?? 'Unknown', nim: loan['profiles']?['nim'] ?? '-', kelas: loan['profiles']?['kelas'] ?? '-')));
                                                        },
                                                      ),
                                                      IconButton(tooltip: 'Hapus', icon: const Icon(Icons.delete_outline, color: AppColors.statusOverdue, size: 20), onPressed: () => _deleteLoan(loan)),
                                                    ],
                                                  ),
                                                ),
                                              ]);
                                            }).toList()),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
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
