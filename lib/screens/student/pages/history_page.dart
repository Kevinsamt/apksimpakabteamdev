import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';
import '../formal_form_view.dart';

class HistoryPage extends StatefulWidget {
  final String studentName;
  final String nim;
  final String kelas;

  const HistoryPage({
    super.key,
    required this.studentName,
    required this.nim,
    required this.kelas,
  });

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final data = await _supabase.from('loans')
          .select('*, equipments(name)')
          .eq('user_id', userId)
          .eq('status', 'returned')
          .order('borrow_date', ascending: false);
      
      if (mounted) {
        setState(() {
          _history = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr == '-') return '-';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('RIWAYAT PENGEMBALIAN', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _history.isEmpty
                  ? const Center(child: Text('Belum ada riwayat pengembalian.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final loan = _history[index];
                        final eqName = loan['equipments'] != null ? loan['equipments']['name'] : 'Unknown';
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: AppColors.borderLight),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                                  backgroundColor: AppColors.surfacePink.withValues(alpha: 0.1),
                                  child: const Icon(Icons.history, color: AppColors.primaryPink),
                            ),
                            title: Text(eqName, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text('Kembali: ${_formatDateTime(loan['return_date'])}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.description_outlined, color: AppColors.primaryPink),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FormalFormView(
                                      loanData: loan,
                                      studentName: widget.studentName,
                                      nim: widget.nim,
                                      kelas: widget.kelas,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
