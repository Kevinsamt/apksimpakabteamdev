import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/text_styles.dart';
import '../../../widgets/custom_loader.dart';
import '../scanner_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  String _studentName = 'Mahasiswa';
  String _nim = '***';
  String _kelas = '-';
  String? _avatarUrl;
  List<Map<String, dynamic>> _activeLoans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchProfile(),
      _fetchActiveLoans(),
    ]);
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final data = await _supabase.from('profiles').select('full_name, nim, kelas, avatar_url').eq('id', userId).single();
        if (mounted) {
          setState(() {
            _studentName = data['full_name'] ?? 'Mahasiswa';
            _nim = data['nim'] ?? '***';
            _kelas = data['kelas'] ?? '-';
            _avatarUrl = data['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error Profile: $e');
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
      if (mounted) setState(() => _activeLoans = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error Loans: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CustomLoader(message: 'Mempersiapkan Lab...'));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPremiumHeader(),
          const SizedBox(height: 24),
          _buildInfoBanner(),
          const SizedBox(height: 32),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildActiveLoansSection(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.primaryPink, AppColors.darkPink]),
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(50)),
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Halo, Mahasiswa Hebat! 👋', style: AppTextStyles.label.copyWith(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(_studentName, style: AppTextStyles.heading2.copyWith(color: Colors.white, fontSize: 22)),
                const SizedBox(height: 2),
                Text('$_nim • $_kelas', style: AppTextStyles.label.copyWith(color: Colors.white60)),
              ],
            ),
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_active_outlined, color: Colors.white, size: 28)),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2)),
      child: CircleAvatar(
        radius: 35,
        backgroundColor: Colors.white,
        child: CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.surfacePink,
          backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
          child: _avatarUrl == null ? const Icon(Icons.person_rounded, size: 30, color: AppColors.primaryPink) : null,
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.cardShadow),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppColors.statusActive.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.info_outline_rounded, color: AppColors.statusActive)),
            const SizedBox(width: 16),
            const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Info Laboratorium', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), Text('Lab buka jam 08:00 - 16:00 WIB. Pastikan alat steril sebelum dikembalikan.', style: TextStyle(fontSize: 11, color: Colors.grey))])),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Menu Cepat', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildBigButton(title: 'SCAN QR ALAT', icon: Icons.qr_code_scanner_rounded, isPrimary: true, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScannerScreen(studentName: _studentName, nim: _nim, kelas: _kelas)))),
              const SizedBox(width: 16),
              _buildBigButton(title: 'LIHAT DAFTAR', icon: Icons.inventory_2_rounded, isPrimary: false, onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBigButton({required String title, required IconData icon, required bool isPrimary, required VoidCallback onTap}) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 30),
          decoration: BoxDecoration(
            color: isPrimary ? null : Colors.white,
            gradient: isPrimary ? const LinearGradient(colors: [AppColors.gradientStart, AppColors.gradientEnd]) : null,
            borderRadius: BorderRadius.circular(24),
            border: isPrimary ? null : Border.all(color: AppColors.borderLight, width: 1.5),
            boxShadow: isPrimary ? AppColors.premiumShadow : AppColors.cardShadow,
          ),
          child: Column(children: [Icon(icon, color: isPrimary ? Colors.white : AppColors.primaryPink, size: 40), const SizedBox(height: 12), Text(title, style: AppTextStyles.button.copyWith(color: isPrimary ? Colors.white : AppColors.textPrimary, fontSize: 12))]),
        ),
      ),
    );
  }

  Widget _buildActiveLoansSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: AppColors.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Peminjaman Aktif', style: AppTextStyles.heading2), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: AppColors.surfacePink, borderRadius: BorderRadius.circular(10)), child: Text('${_activeLoans.length}', style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold, fontSize: 12)))]),
            const SizedBox(height: 24),
            if (_activeLoans.isEmpty) const Center(child: Text('Belum ada peminjaman aktif.'))
            else ..._activeLoans.map((loan) => _buildLoanItem(loan)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanItem(Map<String, dynamic> loan) {
    bool isPending = loan['status'] == 'pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.backgroundWhite, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderLight.withValues(alpha: 0.5))),
      child: Row(children: [CircleAvatar(backgroundColor: (isPending ? AppColors.statusPending : AppColors.statusActive).withValues(alpha: 0.15), radius: 5), const SizedBox(width: 14), Expanded(child: Text(loan['equipments']['name'], style: AppTextStyles.bodyTextStrong)), Text(isPending ? 'Menunggu' : 'Disetujui', style: AppTextStyles.label.copyWith(color: isPending ? AppColors.statusPending : AppColors.statusActive, fontSize: 10, fontWeight: FontWeight.bold))]),
    );
  }
}
