import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../services/notification_service.dart';

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
  String _selectedSemester = '1'; // Default
  final _mataKuliahController = TextEditingController();
  final _dosenController = TextEditingController();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _borrowDate = DateTime.now();
  DateTime _practiceDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _mataKuliahController.dispose();
    _dosenController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final supabase = Supabase.instance.client;
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) return;
    final navigator = Navigator.of(context);

    try {
      final String formalNotes = 'Semester: $_selectedSemester, '
          'MK: ${_mataKuliahController.text}, '
          'Dosen: ${_dosenController.text}, '
          'Pukul: ${_selectedTime.format(context)}, '
          'Tgl Pinjam: ${_borrowDate.toIso8601String().split('T')[0]}, '
          'Tgl Praktik: ${_practiceDate.toIso8601String().split('T')[0]}';

      for (var item in widget.items) {
        await supabase.from('loans').insert({
          'user_id': userId,
          'equipment_id': item['id'],
          'status': 'pending',
          'borrow_date': _borrowDate.toIso8601String(),
          'notes': formalNotes,
          'quantity': item['quantity'] ?? 1,
        });
      }

      await NotificationService.addNotification(
        title: 'Permintaan Pinjam Baru',
        message: '${widget.studentName} mengajukan peminjaman untuk ${widget.items.length} alat.',
        role: 'admin',
        type: 'loan_request',
      );
      
      if (!mounted) return;
      navigator.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusOverdue),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: const Text('Formulir Peminjaman Formal', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryPink,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('INFORMASI MAHASISWA'),
              _buildInfoCard(),
              const SizedBox(height: 24),
              
              _buildSectionHeader('DETAIL PERKULIAHAN'),
              _buildSemesterSelector(),
              const SizedBox(height: 16),
              _buildTextField(_mataKuliahController, 'Mata Kuliah', Icons.book_outlined, 'Contoh: Askeb Kehamilan'),
              _buildTextField(_dosenController, 'Dosen Pengampu', Icons.person_outline, 'Nama dosen lengkap'),
              
              const SizedBox(height: 24),
              _buildSectionHeader('WAKTU & TANGGAL'),
              _buildDatePicker(
                label: 'Tanggal Pinjam',
                selectedDate: _borrowDate,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _borrowDate,
                    firstDate: DateTime.now(), // 🛡️ Tanggal Lewat DIMATIKAN!
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
                  if (date != null) setState(() => _practiceDate = date);
                },
              ),
              _buildTimePicker(),
              
              const SizedBox(height: 24),
              _buildSectionHeader('DAFTAR ALAT (${widget.items.length})'),
              _buildItemsList(),
              
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  shadowColor: AppColors.primaryPink.withValues(alpha: 0.3),
                ),
                child: _isSubmitting 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('KIRIM PERMINTAAN PEMINJAMAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(title, style: AppTextStyles.label.copyWith(color: AppColors.primaryPink, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        children: [
          _buildInfoRow('Nama', widget.studentName),
          const Divider(height: 16),
          _buildInfoRow('NIM', widget.nim),
          const Divider(height: 16),
          _buildInfoRow('Kelas', widget.kelas),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12))),
        Expanded(child: Text(value, style: AppTextStyles.bodyTextStrong)),
      ],
    );
  }

  Widget _buildSemesterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Semester', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 8,
            itemBuilder: (context, index) {
              final sem = (index + 1).toString();
              final isSelected = _selectedSemester == sem;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('Semester $sem'),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedSemester = sem);
                  },
                  selectedColor: AppColors.primaryPink,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: isSelected ? AppColors.primaryPink : AppColors.borderLight),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfacePink, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.access_time, color: AppColors.primaryPink),
      ),
      title: const Text('Waktu Ambil Alat', style: TextStyle(fontSize: 14)),
      subtitle: Text(_selectedTime.format(context), style: AppTextStyles.bodyTextStrong),
      trailing: TextButton(
        onPressed: () async {
          final time = await showTimePicker(context: context, initialTime: _selectedTime);
          if (time != null) setState(() => _selectedTime = time);
        },
        child: const Text('PILIH JAM', style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDatePicker({required String label, required DateTime selectedDate, VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.surfacePink, borderRadius: BorderRadius.circular(8)),
        child: const Icon(Icons.calendar_today, color: AppColors.primaryPink),
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}', style: AppTextStyles.bodyTextStrong),
      trailing: TextButton(
        onPressed: onTap,
        child: const Text('UBAH TGL', style: TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        style: AppTextStyles.bodyTextStrong,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          hintText: hint,
          prefixIcon: Icon(icon, color: AppColors.primaryPink, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primaryPink, width: 2)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (val) => val == null || val.isEmpty ? '$label harus diisi' : null,
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: widget.items.length,
        separatorBuilder: (c, i) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = widget.items[index];
          return ListTile(
            title: Text(item['name'], style: AppTextStyles.bodyTextStrong),
            subtitle: Text(item['category'] ?? '', style: const TextStyle(fontSize: 11)),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: AppColors.surfacePink, borderRadius: BorderRadius.circular(12)),
              child: Text('${item['quantity']} Unit', style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          );
        },
      ),
    );
  }
}
