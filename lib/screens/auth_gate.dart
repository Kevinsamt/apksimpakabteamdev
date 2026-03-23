import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'role_router.dart';
import '../theme/app_colors.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
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
