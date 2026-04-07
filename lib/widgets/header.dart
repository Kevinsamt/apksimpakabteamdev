import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/notification_service.dart';
import 'package:audioplayers/audioplayers.dart';
import '../screens/admin/return_scanner_screen.dart';

class HeaderWidget extends StatefulWidget {
  final VoidCallback? onMenuPressed;
  const HeaderWidget({super.key, this.onMenuPressed});

  @override
  State<HeaderWidget> createState() => _HeaderWidgetState();
}

class _HeaderWidgetState extends State<HeaderWidget> {
  final _supabase = Supabase.instance.client;
  String? _role;
  String? _userId;
  int _lastNotificationCount = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
  }

  Future<void> _fetchUserInfo() async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      _userId = user.id;
      final profile = await _supabase.from('profiles').select('role').eq('id', user.id).single();
      if (mounted) {
        setState(() {
          _role = profile['role'];
        });
      }
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Notifikasi', style: AppTextStyles.heading2),
                    TextButton(
                      onPressed: () async {
                        await NotificationService.markAllAsRead(_userId, role: _role);
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Tandai semua dibaca'),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: NotificationService.getNotifications(_userId, role: _role),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final notes = snapshot.data!;
                    if (notes.isEmpty) return const Center(child: Text('Tidak ada notifikasi.'));

                    return ListView.builder(
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: note['is_read'] ? Colors.grey[200] : AppColors.primaryPink.withValues(alpha: 0.1),
                            child: Icon(
                              note['type'] == 'loan_request' ? Icons.add_shopping_cart : Icons.notifications,
                              color: note['is_read'] ? Colors.grey : AppColors.primaryPink,
                              size: 20,
                            ),
                          ),
                          title: Text(note['title'], style: TextStyle(fontWeight: note['is_read'] ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                          subtitle: Text(note['message'], style: const TextStyle(fontSize: 11)),
                          trailing: note['is_read'] ? null : const CircleAvatar(radius: 4, backgroundColor: AppColors.primaryPink),
                          onTap: () async {
                            await NotificationService.markAsRead(note['id']);
                            if (context.mounted) Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _playSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/notifsimpakab.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReturnScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(bottom: BorderSide(color: AppColors.borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Title
          Expanded(
            child: Row(
              children: [
                if (widget.onMenuPressed != null)
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                    onPressed: widget.onMenuPressed,
                    padding: const EdgeInsets.only(right: 16),
                  ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard', style: AppTextStyles.heading1, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(
                        'SIMPAKAB - Lab Management',
                        style: AppTextStyles.bodyText.copyWith(fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Right: Action Buttons
          Row(
            children: [
              // Logout Button
              IconButton(
                icon: const Icon(Icons.logout, color: AppColors.statusOverdue, size: 20),
                onPressed: () async {
                  await _supabase.auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  }
                },
              ),
              const SizedBox(width: 8),
              // Notifications Bell with Badge
              StreamBuilder<int>(
                stream: NotificationService.getUnreadCountStream(_userId, role: _role),
                builder: (context, snapshot) {
                  final count = snapshot.data ?? 0;
                  
                  // BUNYIKAN SUARA: Jika jumlah notif baru bertambah (misal dari 2 jadi 3)
                  if (count > _lastNotificationCount) {
                    _playSound();
                  }
                  _lastNotificationCount = count;

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_none, color: AppColors.textSecondary),
                        onPressed: () => _showNotifications(context),
                      ),
                      if (count > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: AppColors.primaryPink, shape: BoxShape.circle),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '$count',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(width: 16),
              // Scan QR Button (Enabled)
              if (_role == 'admin') 
                MediaQuery.of(context).size.width >= 600
                    ? ElevatedButton.icon(
                        onPressed: _openScanner,
                        icon: const Icon(Icons.qr_code_scanner, color: AppColors.surfaceWhite, size: 18),
                        label: const Text('Scan Pengembalian', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: AppColors.surfaceWhite,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.qr_code_scanner, color: Colors.black87),
                        onPressed: _openScanner,
                      ),
            ],
          )
        ],
      ),
    );
  }
}




