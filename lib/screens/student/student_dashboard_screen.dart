import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import 'student_profile_screen.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _supabase = Supabase.instance.client;
  String _studentName = 'Nama Mahasiswa';
  String _nim = '***';
  String _kelas = 'KB_A-SG';
  String? _avatarUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
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
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Header & Profile Section with Gradient
            Container(
              width: double.infinity,
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
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    children: [
                      // Logo and Toolbar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Left side: Logo
                          Row(
                            children: [
                              Image.asset('assets/images/logo.png', height: 40, errorBuilder: (c,e,s) => const Icon(Icons.favorite, color: Colors.white)),
                              const SizedBox(width: 8),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SIMPAKAB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                  Text('sistem informasi management\n& peminjaman alat kebidanan', 
                                    style: TextStyle(fontSize: 8, color: Colors.black54, height: 1.1),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // Right side: Icons
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                                onPressed: () {},
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => StudentProfileScreen(
                                      initialName: _studentName,
                                      initialNim: _nim,
                                      initialKelas: _kelas,
                                      initialAvatarUrl: _avatarUrl,
                                    )),
                                  );
                                  if (result == true) {
                                    _fetchProfile();
                                  }
                                },
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.black,
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Profile Info
                      Row(
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            
            // Active Loans Card
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
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text('Alat sedang di pinjam', style: TextStyle(fontSize: 14, color: Colors.black87)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

