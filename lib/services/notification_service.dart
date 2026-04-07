import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final _supabase = Supabase.instance.client;

  // Mendapatkan notifikasi untuk user spesifik (atau admin)
  static Future<List<Map<String, dynamic>>> getNotifications(String? userId, {String? role}) async {
    try {
      var query = _supabase.from('notifications').select();
      
      if (role == 'admin') {
        // Notifikasi untuk admin (biasanya request pinjam baru)
        query = query.eq('role', 'admin');
      } else if (userId != null) {
        // Notifikasi untuk mahasiswa (biasanya status pinjaman di-acc/tolak)
        query = query.eq('user_id', userId).eq('role', 'student');
      } else {
        return [];
      }

      final data = await query.order('created_at', ascending: false).limit(20);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('Error getNotifications: $e');
      return [];
    }
  }

  // Menambahkan notifikasi baru
  static Future<void> addNotification({
    required String title,
    required String message,
    String? userId,
    String? role = 'student',
    String? type = 'general',
  }) async {
    try {
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'role': role,
        'type': type,
        'is_read': false,
      });
      debugPrint('Notifikasi berhasil dikirim: $title');
    } catch (e) {
      debugPrint('Gagal menambah notifikasi (DB Error): $e');
    }
  }

  // Menandai satu notifikasi sudah dibaca
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', notificationId);
    } catch (e) {
      debugPrint('Gagal update status baca: $e');
    }
  }

  // Menandai semua notifikasi user sudah dibaca
  static Future<void> markAllAsRead(String? userId, {String? role}) async {
    try {
      if (role == 'admin') {
        await _supabase.from('notifications').update({'is_read': true}).eq('role', 'admin');
      } else if (userId != null) {
        await _supabase.from('notifications').update({'is_read': true}).eq('user_id', userId).eq('role', 'student');
      }
    } catch (e) {
      debugPrint('Gagal update semua status baca: $e');
    }
  }

  // Mendapatkan jumlah notifikasi yang belum dibaca (Realtime Stream)
  static Stream<int> getUnreadCountStream(String? userId, {String? role}) {
    // STREAMING realtime dari supabase
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .map((data) {
          if (role == 'admin') {
            return data.where((d) => d['role'] == 'admin' && d['is_read'] == false).length;
          } else {
            return data.where((d) => d['user_id'] == userId && d['role'] == 'student' && d['is_read'] == false).length;
          }
        });
  }
}


