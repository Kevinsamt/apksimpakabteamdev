import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/header.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/custom_loader.dart';

class DevDashboardScreen extends StatefulWidget {
  const DevDashboardScreen({super.key});

  @override
  State<DevDashboardScreen> createState() => _DevDashboardScreenState();
}

class _DevDashboardScreenState extends State<DevDashboardScreen> {
  final _supabase = Supabase.instance.client;
  final _broadcastController = TextEditingController();
  final _titleController = TextEditingController();
  bool _isSending = false;
  List<Map<String, dynamic>> _feedbacks = [];
  bool _isLoadingFeedback = true;

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    try {
      final data = await _supabase.from('feedback').select().order('created_at', ascending: false);
      setState(() { _feedbacks = List<Map<String, dynamic>>.from(data); _isLoadingFeedback = false; });
    } catch (e) {
      debugPrint('Error fetch feedback: $e');
      setState(() => _isLoadingFeedback = false);
    }
  }

  Future<void> _sendBroadcast() async {
    if (_broadcastController.text.isEmpty || _titleController.text.isEmpty) return;
    setState(() => _isSending = true);
    
    try {
      // Kita kirim pengumuman ke tabel updates/notifications
      await _supabase.from('app_updates').insert({
        'title': _titleController.text,
        'message': _broadcastController.text,
        'created_at': DateTime.now().toIso8601String(),
        'sender': 'Developer',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update berhasil disiarkan ke semua user! 🚀')));
        _titleController.clear();
        _broadcastController.clear();
      }
    } catch (e) {
      debugPrint('Error broadcast: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1000;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: Row(
          children: [
            if (isDesktop) const Sidebar(currentRoute: '/dev_dashboard'),
            Expanded(
              child: Column(
                children: [
                  const HeaderWidget(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeSection(),
                          const SizedBox(height: 32),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 2, child: _buildBroadcastPanel()),
                              const SizedBox(width: 24),
                              Expanded(flex: 3, child: _buildFeedbackPanel()),
                            ],
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
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pusat Komando Developer 🔱', style: AppTextStyles.heading1),
        Text('Pantau kelancaran aplikasi dan siarkan update terbaru.', style: AppTextStyles.bodyText),
      ],
    );
  }

  Widget _buildBroadcastPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Siarkan Update 📣', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: 'Judul Update (e.g. Versi 1.4.5 Rilis!)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _broadcastController,
            maxLines: 4,
            decoration: InputDecoration(labelText: 'Pesan untuk Mahasiswa & Admin', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendBroadcast,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white),
              child: _isSending ? const CircularProgressIndicator(color: Colors.white) : const Text('SIARKAN SEKARANG'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackPanel() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Keluh Kesah Mahasiswa 💬', style: AppTextStyles.heading2),
          const SizedBox(height: 16),
          if (_isLoadingFeedback) const Center(child: CustomLoader())
          else if (_feedbacks.isEmpty) const Center(child: Text('Belum ada laporan dari user.'))
          else ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _feedbacks.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final item = _feedbacks[index];
              return ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.surfacePink, child: const Icon(Icons.person, color: AppColors.primaryPink)),
                title: Text(item['user_email'] ?? 'User Anonim', style: AppTextStyles.bodyTextStrong),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['message'] ?? '', style: AppTextStyles.bodyText),
                    Text(item['created_at'].toString().split('T')[0], style: AppTextStyles.label),
                  ],
                ),
                isThreeLine: true,
              );
            },
          ),
        ],
      ),
    );
  }
}
