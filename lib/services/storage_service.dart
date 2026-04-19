import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyUserId = 'user_id';
  static const String _keyRole = 'user_role';
  static const String _keyFullName = 'full_name';

  // SIMPAN PROFIL
  static Future<void> saveProfile(String id, String role, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, id);
    await prefs.setString(_keyRole, role);
    await prefs.setString(_keyFullName, name);
  }

  // AMBIL PROFIL
  static Future<Map<String, String?>> getProfile() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'id': prefs.getString(_keyUserId),
      'role': prefs.getString(_keyRole),
      'name': prefs.getString(_keyFullName),
    };
  }

  // HAPUS DATA (Kalau Logout)
  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
