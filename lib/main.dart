import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'utils/constants.dart';
import 'screens/dashboard_screen.dart';
import 'screens/admin/equipment_screen.dart';
import 'screens/admin/loans_screen.dart';
import 'screens/admin/users_screen.dart';
import 'screens/admin/reports_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SIMPAKAB Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundWhite,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryPink,
          primary: AppColors.primaryPink,
          secondary: AppColors.statusActive,
          surface: AppColors.surfaceWhite,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/equipment': (context) => const EquipmentScreen(),
        '/loans': (context) => const LoansScreen(),
        '/users': (context) => const UsersScreen(),
        '/reports': (context) => const ReportsScreen(),
      },
    );
  }
}

