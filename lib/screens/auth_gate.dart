import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'role_router.dart';
import '../theme/app_colors.dart';
import 'reset_password_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
    _authStateStream.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResetPasswordScreen()),
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.backgroundWhite,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primaryPink),
            ),
          );
        }
        final session = snapshot.data?.session;
        if (session != null) {
          final email = session.user.email ?? '';
          final provider = session.user.appMetadata['provider'];
          
          if (provider == 'google' && !email.endsWith('@students.satyaterrabhinneka.ac.id')) {
            // Log out user as the domain is unauthorized
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Supabase.instance.client.auth.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hanya email @students.satyaterrabhinneka.ac.id yang diizinkan.'),
                  backgroundColor: AppColors.statusOverdue,
                ),
              );
            });
            // Tampilkan kembali layar login secara sementara sambil menunggu proses signOut merespons stream.
            return const LoginScreen();
          }
          return const RoleRouter();
        }
        return const LoginScreen();
      },
    );
  }
}


