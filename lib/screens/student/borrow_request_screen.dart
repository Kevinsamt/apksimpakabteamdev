import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class BorrowRequestScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final String studentName;
  final String nim;
  final String kelas;

  const BorrowRequestScreen({
    super.key,
    required this.items,
    required this.studentName,
    required this.nim,
    required this.kelas,
  });

  @override
  State<BorrowRequestScreen> createState() => _BorrowRequestScreenState();
}

class _BorrowRequestScreenState extends State<BorrowRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _semesterController = TextEditingController();
  final _mataKuliahController = TextEditingController();
  final _dosenController = TextEditingController();
  final _pukulController = TextEditingController();
  DateTime _borrowDate = DateTime.now();
  DateTime _practiceDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _semesterController.dispose();
    _mataKuliahController.dispose();
    _dosenController.dispose();
    _pukulController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;

    try {
      final String formalNotes = 'Semester: ${_semesterController.text}, '
          'MK: ${_mataKuliahController.text}, '
          'Dosen: ${_dosenController.text}, '
          'Pukul: ${_pukulController.text}, '
          'Tgl Pinjam: ${_borrowDate.toIso8601String().split('T')[0]}, '
          'Tgl Praktik: ${_practiceDate.toIso8601String().split('T')[0]}';

      // Create entries for each item
      for (var item in widget.items) {
        await supabase.from('loans').insert({
          'user_id': userId,
          'equipment_id': item['id'],
          'status': 'pending',
          'borrow_date': _borrowDate.toIso8601String(),
          'notes': formalNotes,
        });
      }

      if (mounted) {
        Navigator.pop(context, true); // Success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengirim permintaan: $e'), backgroundColor: AppColors.statusOverdue),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Formulir Peminjaman Formal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPink,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('INFORMASI MAHASISWA'),
              _buildInfoRow('Nama', widget.studentName),
              _buildInfoRow('NIM', widget.nim),
              _buildInfoRow('Kelas', widget.kelas),
              const SizedBox(height: 24),
              
              _buildSectionHeader('DETAIL PERKULIAHAN'),
              _buildTextField(_semesterController, 'Semester', Icons.school_outlined, 'Masukkan semester (contoh: 4)'),
              _buildTextField(_mataKuliahController, 'Mata Kuliah', Icons.book_outlined, 'Contoh: Askeb Kehamilan'),
              _buildTextField(_dosenController, 'Dosen Pengampu', Icons.person_outline, 'Nama dosen lengkap'),
              
              const SizedBox(height: 24),
              _buildSectionHeader('WAKTU PEMINJAMAN'),
              _buildDatePicker(
                label: 'Tanggal Pinjam',
                selectedDate: _borrowDate,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _borrowDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 7)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (date != null) setState(() => _borrowDate = date);
                },
              ),
              _buildDatePicker(
                label: 'Tanggal Praktik',
                selectedDate: _practiceDate,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _practiceDate,
                    firstDate: _borrowDate,
                    lastDate: _borrowDate.add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setState(() {
                      _practiceDate = date;
                    });
                  }
                },
              ),
              _buildTextField(_pukulController, 'Pukul Peminjaman (Ambil Barang)', Icons.access_time, 'Contoh: 08:00 WIB'),
              
              const SizedBox(height: 24),
              _buildSectionHeader('DAFTAR ALAT (${widget.items.length})'),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: widget.items.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = widget.items[index];
                    return ListTile(
                      title: Text(item['name']),
                      subtitle: Text(item['category'] ?? ''),
                      leading: Text('${index + 1}.'),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('KIRIM PERMINTAAN PEMINJAMAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 20),
              const Text(
                '*Dengan mengirim formulir ini, Anda bertanggung jawab penuh atas alat yang dipinjam.',
                style: TextStyle(fontSize: 11, color: Colors.black54, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink, fontSize: 13, letterSpacing: 1.1)),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: Colors.black54))),
          const Text(': ', style: TextStyle(color: Colors.black54)),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime selectedDate, VoidCallback? onTap, bool isReturn = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(isReturn ? Icons.assignment_return_outlined : Icons.calendar_today, color: AppColors.primaryPink),
      title: Text('$label: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
      trailing: onTap != null 
        ? TextButton(onPressed: onTap, child: const Text('UBAH', style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)))
        : null,
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryPink),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        validator: (val) => val == null || val.isEmpty ? '$label tidak boleh kosong' : null,
      ),
    );
  }
}
