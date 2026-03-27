import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activeLoans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchActiveLoans();
  }

  Future<void> _fetchActiveLoans() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final data = await _supabase.from('loans')
          .select('*, equipments(name), profiles(nim)')
          .eq('user_id', userId)
          .or('status.eq.pending,status.eq.approved')
          .order('borrow_date', ascending: false);
      
      if (mounted) {
        setState(() {
          _activeLoans = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching active loans: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(20.0),
          child: Text('ALAT SEDANG DIPINJAM', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _activeLoans.isEmpty
                  ? const Center(child: Text('Tidak ada alat yang sedang dipinjam.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columnSpacing: 20,
                          headingRowColor: WidgetStateProperty.all(AppColors.surfacePink),
                          columns: const [
                            DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Nama Alat', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('NIM', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _activeLoans.asMap().entries.map((entry) {
                            final index = entry.key;
                            final loan = entry.value;
                            final equipmentName = loan['equipments'] != null ? loan['equipments']['name'] : 'Unknown';
                            final nim = loan['profiles'] != null ? loan['profiles']['nim'] : '***';
                            final rawStatus = loan['status'];
                            
                            Color statusColor = AppColors.statusPending;
                            String statusText = 'PENDING';
                            
                            if (rawStatus == 'approved') {
                              statusColor = AppColors.statusActive;
                              statusText = 'AKTIF';
                            } else if (rawStatus == 'rejected') {
                              statusColor = AppColors.statusOverdue;
                              statusText = 'DITOLAK';
                            }

                            return DataRow(cells: [
                              DataCell(Text('${index + 1}.')),
                              DataCell(SizedBox(width: 150, child: Text(equipmentName, maxLines: 2, overflow: TextOverflow.ellipsis))),
                              DataCell(Text(nim)),
                              DataCell(Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
        ),
      ],
    );
  }
}
