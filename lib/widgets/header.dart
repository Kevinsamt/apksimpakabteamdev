import 'dart:ui';
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

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 85,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            border: Border(
              bottom: BorderSide(color: AppColors.primaryPink.withValues(alpha: 0.1), width: 1.5),
            ),
          ),
          child: Row(
            children: [
              // 🍔 Mobile Menu Button
              if (widget.onMenuPressed != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: Icon(Icons.menu_open_rounded, color: AppColors.primaryPink, size: 28),
                    onPressed: widget.onMenuPressed,
                  ),
                ),

              // 🏷️ Page Title Context
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Simpakab', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink)),
                    Text('Dashboard', style: AppTextStyles.heading1.copyWith(fontSize: 22)),
                  ],
                ),
              ),

              // 🚀 Right Side Actions
              Row(
                children: [
                  // 🔍 Search Bar (Visual Placeholder)
                  if (MediaQuery.of(context).size.width > 900)
                    Container(
                      width: 250,
                      height: 40,
                      margin: const EdgeInsets.only(right: 24),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: AppColors.surfacePink.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: AppColors.textMuted, size: 18),
                          const SizedBox(width: 8),
                          Text('Search tools...', style: AppTextStyles.label),
                        ],
                      ),
                    ),

                  // 🔔 Notifications with Modern Badge
                  StreamBuilder<int>(
                    stream: NotificationService.getUnreadCountStream(_userId, role: _role),
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      if (count > _lastNotificationCount) _playSound();
                      _lastNotificationCount = count;

                      return Row(
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surfacePink,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    count > 0 ? Icons.notifications_active : Icons.notifications_none_rounded, 
                                    color: count > 0 ? AppColors.primaryPink : AppColors.textSecondary,
                                    size: 24,
                                  ),
                                  onPressed: () => _showNotifications(context),
                                ),
                              ),
                              if (count > 0)
                                Positioned(
                                  right: -4,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.statusOverdue,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.statusOverdue.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          // 🚪 Tombol Logout Cepat
                          IconButton(
                            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted, size: 24),
                            onPressed: () async {
                              await _supabase.auth.signOut();
                              if (context.mounted) {
                                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(width: 16),

                  // 📸 Quick Scan Action
                  if (_role == 'admin')
                    InkWell(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ReturnScannerScreen())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.gradientStart, AppColors.gradientEnd],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: AppColors.premiumShadow,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
                            if (MediaQuery.of(context).size.width > 700) ...[
                              const SizedBox(width: 10),
                              Text('Scan Return', style: AppTextStyles.button),
                            ],
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // 🛡️ Biar bisa ditarik ke atas
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75, // 📏 Batasi tingginya 75% layar
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: AppTextStyles.heading2),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
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
                  if (notes.isEmpty) return const Center(child: Text('No notifications yet.'));
                  return ListView.builder(
                    itemCount: notes.length,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 40), // 🛡️ Jarak aman bawah
                    physics: const BouncingScrollPhysics(),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: note['is_read'] ? Colors.transparent : AppColors.surfacePink.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
                            child: Icon(Icons.notifications_active_outlined, color: AppColors.primaryPink),
                          ),
                          title: Text(note['title'], style: AppTextStyles.bodyTextStrong),
                          subtitle: Text(note['message'], style: AppTextStyles.bodyText),
                          trailing: note['is_read'] ? null : CircleAvatar(radius: 4, backgroundColor: AppColors.primaryPink),
                          onTap: () async {
                            await NotificationService.markAsRead(note['id']);
                            if (context.mounted) Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
