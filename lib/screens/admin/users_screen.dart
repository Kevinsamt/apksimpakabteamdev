import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/header.dart';
import '../../widgets/app_bottom_nav.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfiles();
  }

  Future<void> _fetchProfiles() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('profiles').select().order('created_at');
      if (mounted) {
        setState(() {
          _profiles = List<Map<String, dynamic>>.from(data);
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

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text('Hapus Pengguna', style: AppTextStyles.heading2),
        content: Text('Yakin ingin menghapus profil ${user['full_name'] ?? 'ini'}?\n(Akan gagal jika pengguna memiliki riwayat pinjaman aktif)'),
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
      await _supabase.from('profiles').delete().eq('id', user['id']);
      _fetchProfiles();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pengguna berhasil dihapus'), backgroundColor: AppColors.statusActive));
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusOverdue));
      }
    }
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    final nameController = TextEditingController(text: user['full_name']);
    String selectedRole = user['role'] ?? 'student';
    bool isSubmitting = false;

    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceWhite,
              title: Text('Edit Pengguna', style: AppTextStyles.heading2),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedRole,
                      items: ['admin', 'student'].map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase()))).toList(),
                      onChanged: (val) { if (val != null) setStateDialog(() => selectedRole = val); },
                      decoration: const InputDecoration(labelText: 'Peran (Role)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (nameController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Nama wajib diisi'), backgroundColor: AppColors.statusOverdue),
                       );
                       return;
                    }
                    setStateDialog(() => isSubmitting = true);
                    try {
                      await _supabase.from('profiles').update({
                        'full_name': nameController.text.trim(),
                        'role': selectedRole,
                      }).eq('id', user['id']);
                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (e) {
                      setStateDialog(() => isSubmitting = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusOverdue),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white),
                  child: isSubmitting 
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan'),
                ),
              ],
            );
          }
        );
      }
    );
    
    if (result == true) {
      _fetchProfiles();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil diperbarui!'), backgroundColor: AppColors.statusActive),
      );
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '-';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: isDesktop ? null : const AppBottomNav(currentIndex: 3),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const Sidebar(currentRoute: '/users'),
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
                              Text('Midwives Directory', style: AppTextStyles.heading1),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceWhite,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.borderLight),
                                ),
                                child: _profiles.isEmpty
                                  ? const Center(child: Padding(
                                      padding: EdgeInsets.all(32.0),
                                      child: Text('Belum ada pengguna terdaftar.', style: TextStyle(color: AppColors.textSecondary)),
                                    ))
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                          headingTextStyle: AppTextStyles.bodyTextStrong,
                                          columns: const [
                                            DataColumn(label: Text('Nama Lengkap / Identitas')),
                                            DataColumn(label: Text('Peran (Role)')),
                                            DataColumn(label: Text('Tanggal Bergabung')),
                                            DataColumn(label: Text('Aksi')),
                                          ],
                                          rows: _profiles.map((user) {
                                            final role = user['role'] ?? 'student';
                                            final name = (user['full_name'] == null || user['full_name'].toString().trim().isEmpty) 
                                                ? '(Nama Belum Diset)' 
                                                : user['full_name'];
                                                
                                            return DataRow(cells: [
                                              DataCell(Text(name, style: AppTextStyles.bodyText)),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: role == 'admin' ? AppColors.statusOverdue.withValues(alpha: 0.1) : AppColors.lightPink,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    role.toString().toUpperCase(),
                                                    style: AppTextStyles.label.copyWith(
                                                      color: role == 'admin' ? AppColors.statusOverdue : AppColors.primaryPink,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(Text(_formatDate(user['created_at']), style: AppTextStyles.bodyText)),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Lihat Riwayat',
                                                      icon: const Icon(Icons.history, color: AppColors.lightPink, size: 20),
                                                      onPressed: () {},
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Edit Profil',
                                                      icon: const Icon(Icons.edit, color: AppColors.primaryPink, size: 20),
                                                      onPressed: () => _showEditUserDialog(user),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Hapus Profil',
                                                      icon: const Icon(Icons.delete, color: AppColors.statusOverdue, size: 20),
                                                      onPressed: () => _deleteUser(user),
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


