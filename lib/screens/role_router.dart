import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_screen.dart';
import 'student/student_dashboard_screen.dart';
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

      final userProfile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', userId)
          .single();

      if (mounted) {
        setState(() {
          _role = userProfile['role'] as String?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
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
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryPink),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.backgroundWhite,
        body: Center(
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
      );
    }

    if (_role == 'admin') {
      return const DashboardScreen();
    } else {
      // Default ke halaman student
      return const StudentDashboardScreen();
    }
  }
}
