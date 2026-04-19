import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_screen.dart';
import 'student/student_dashboard_screen.dart';
import 'dev/dev_dashboard_screen.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class RoleRouter extends StatefulWidget {
  const RoleRouter({super.key});

  @override
  State<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends State<RoleRouter> {
  final _supabase = Supabase.instance.client;
  String? _role;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User tidak ditemukan';

      // 🛡️ STEP 1: CEK OFFLINE DULU BIAR CEPET
      final cachedProfile = await StorageService.getProfile();
      if (cachedProfile['role'] != null && cachedProfile['id'] == userId) {
        if (mounted) {
          setState(() {
            _role = cachedProfile['role'];
            _isLoading = false;
          });
        }
      }

      // 🕵️‍♂️ STEP 2: CEK KE SUPABASE (PASTIKAN DATA VALID)
      final userProfile = await _supabase
          .from('profiles')
          .select('role, full_name')
          .eq('id', userId)
          .single();

      final String newRole = userProfile['role'] as String;
      final String newName = userProfile['full_name'] ?? 'User';

      // 💾 UPDATE LOKAL (OFFLINE)
      await StorageService.saveProfile(userId, newRole, newName);

      if (mounted) {
        setState(() {
          _role = newRole;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted && _role == null) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primaryPink),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Gagal memuat profil:\n$_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.statusOverdue),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                      _error = null;
                    });
                    _fetchUserRole();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_supabase.auth.currentUser?.email == 'dev@simpakab.com') {
      return const DevDashboardScreen();
    }

    if (_role == 'admin') {
      return const DashboardScreen();
    } else {
      // Default ke halaman student
      return const StudentDashboardScreen();
    }
  }
}


