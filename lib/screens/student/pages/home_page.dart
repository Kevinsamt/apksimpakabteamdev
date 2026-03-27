import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import '../scanner_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  String _studentName = 'Nama Mahasiswa';
  String _nim = '***';
  String _kelas = 'KB_A-SG';
  String? _avatarUrl;
  List<Map<String, dynamic>> _activeLoans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchActiveLoans();
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final data = await _supabase.from('profiles').select('full_name, nim, kelas, avatar_url').eq('id', userId).single();
        if (mounted) {
          setState(() {
            _studentName = data['full_name'] ?? 'Mahasiswa';
            if (data['nim'] != null) _nim = data['nim'];
            if (data['kelas'] != null) _kelas = data['kelas'];
            _avatarUrl = data['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: \$e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchActiveLoans() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final data = await _supabase.from('loans')
          .select('*, equipments(name)')
          .eq('user_id', userId)
          .or('status.eq.pending,status.eq.approved')
          .order('borrow_date', ascending: false);
      
      if (mounted) {
        setState(() {
          _activeLoans = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error fetching active loans: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Section Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20, bottom: 40, left: 24, right: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primaryPink,
                  AppColors.primaryPink.withValues(alpha: 0.1),
                  AppColors.backgroundWhite,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
                    ]
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.black87,
                    backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty ? NetworkImage(_avatarUrl!) : null,
                    child: _avatarUrl == null || _avatarUrl!.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Halo, Selamat Datang', style: TextStyle(fontSize: 14, color: Colors.black87)),
                      const SizedBox(height: 4),
                      _isLoading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                      const SizedBox(height: 4),
                      Text('(Nim :$_nim) Kelas: $_kelas', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ScannerScreen(
                            studentName: _studentName,
                            nim: _nim,
                            kelas: _kelas,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.qr_code_scanner, color: Colors.white, size: 32),
                          SizedBox(height: 8),
                          Text('SCAN QR ALAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: AppColors.primaryPink, size: 32),
                        SizedBox(height: 8),
                        Text('DAFTAR ALAT', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Peminjaman Aktif Summary Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Peminjaman Aktif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 16),
                  if (_activeLoans.isEmpty)
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Belum ada peminjaman aktif', style: TextStyle(fontSize: 14, color: Colors.black54)),
                        ),
                      ],
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _activeLoans.length,
                      itemBuilder: (context, index) {
                        final loan = _activeLoans[index];
                        final status = loan['status'] == 'pending' ? 'Menunggu' : 'Disetujui';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: loan['status'] == 'pending' ? AppColors.statusPending : AppColors.statusActive,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${loan['equipments']['name']} ($status)',
                                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
