import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_colors.dart';

class StudentProfileScreen extends StatefulWidget {
  final String initialName;
  final String initialNim;
  final String initialKelas;
  final String? initialAvatarUrl;

  const StudentProfileScreen({
    super.key,
    required this.initialName,
    required this.initialNim,
    required this.initialKelas,
    this.initialAvatarUrl,
  });

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _supabase = Supabase.instance.client;
  late TextEditingController _nameController;
  late TextEditingController _nimController;
  late TextEditingController _kelasController;
  String? _avatarUrlStr;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _nimController = TextEditingController(text: widget.initialNim == '***' ? '' : widget.initialNim);
    _kelasController = TextEditingController(text: widget.initialKelas == 'KB_A-SG' ? '' : widget.initialKelas);
    _avatarUrlStr = widget.initialAvatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nimController.dispose();
    _kelasController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      if (mounted) {
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
        });
      }
    }
  }

  ImageProvider? _getAvatarImage() {
    if (_selectedImageBytes != null) {
      return MemoryImage(_selectedImageBytes!);
    } else if (_avatarUrlStr != null && _avatarUrlStr!.isNotEmpty) {
      return NetworkImage(_avatarUrlStr!);
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama lengkap wajib diisi'), backgroundColor: AppColors.statusOverdue));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = _supabase.auth.currentUser!.id;
      
      String? updatedAvatarUrl = _avatarUrlStr;
      
      // Upload new image if selected
      if (_selectedImage != null && _selectedImageBytes != null) {
        final bytes = _selectedImageBytes!;
        final fileExtension = _selectedImage!.name.split('.').last;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
        final filePath = '$userId/$fileName';
        
        await _supabase.storage.from('avatars').uploadBinary(
          filePath,
          bytes,
          fileOptions: FileOptions(contentType: 'image/$fileExtension'),
        );
        
        updatedAvatarUrl = _supabase.storage.from('avatars').getPublicUrl(filePath);
      }

      await _supabase.from('profiles').update({
        'full_name': _nameController.text.trim(),
        'nim': _nimController.text.trim().isEmpty ? null : _nimController.text.trim(),
        'kelas': _kelasController.text.trim().isEmpty ? null : _kelasController.text.trim(),
        if (updatedAvatarUrl != null) 'avatar_url': updatedAvatarUrl,
      }).eq('id', userId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil berhasil diperbarui!'), backgroundColor: AppColors.statusActive));
      
      // Kembalikan nilai true ke dashboard agar me-refresh data
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan profil: $e'), backgroundColor: AppColors.statusOverdue));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _logout() async {
    await _supabase.auth.signOut();
    // Navigate will be handled by AuthGate automatically watching user auth stream
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Profil Saya', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black87),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Avatar Preview
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
                      ]
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
                      backgroundImage: _getAvatarImage(),
                      child: _getAvatarImage() == null ? const Icon(Icons.person, size: 60, color: AppColors.primaryPink) : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryPink,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Form Fields
            _buildTextField('Nama Lengkap', _nameController, Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField('NIM Mahasiswa', _nimController, Icons.badge_outlined),
            const SizedBox(height: 16),
            _buildTextField('Kelas', _kelasController, Icons.school_outlined),
            
            const SizedBox(height: 40),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting 
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('SIMPAN PERUBAHAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),

            const SizedBox(height: 24),
            
            // Logout Button
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: AppColors.statusOverdue),
              label: const Text('Keluar (Logout)', style: TextStyle(color: AppColors.statusOverdue, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isUrl = false}) {
    return TextField(
      controller: controller,
      onChanged: isUrl ? (v) => setState(() {}) : null, // Update UI for image preview
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.borderLight), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppColors.primaryPink), borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
