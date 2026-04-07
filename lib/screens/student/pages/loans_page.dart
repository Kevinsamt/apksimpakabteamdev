import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../theme/app_colors.dart';

class LoansPage extends StatefulWidget {
  const LoansPage({super.key});

  @override
  State<LoansPage> createState() => _LoansPageState();
}

class _LoansPageState extends State<LoansPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activeLoans = [];
  final Set<String> _selectedLoanIds = {};
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
          .or('status.eq.pending,status.eq.active,status.eq.approved')
          .order('borrow_date', ascending: false);
      
      if (mounted) {
        setState(() {
          _activeLoans = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showQRDialog() {
    if (_selectedLoanIds.isEmpty) return;
    final now = DateTime.now();
    final timeBlock = (now.millisecondsSinceEpoch / (30 * 60 * 1000)).floor();
    final payload = {
      'type': 'return',
      'ids': _selectedLoanIds.toList(),
      'token': timeBlock,
    };
    final qrData = jsonEncode(payload);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Pengembalian', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tunjukkan ke Admin Lab', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 20),
            SizedBox(
              width: 180, height: 180,
              child: QrImageView(data: qrData, version: QrVersions.auto, size: 180.0, eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.primaryPink)),
            ),
            const SizedBox(height: 20),
            Text('Item dipilih: ${_selectedLoanIds.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('TUTUP'))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text('PINJAMAN AKTIF', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          ),
          Expanded(
            child: _isLoading ? const Center(child: CircularProgressIndicator()) : _activeLoans.isEmpty
              ? const Center(child: Text('Kosong.'))
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    columns: const [
                      DataColumn(label: Text('Pilih')),
                      DataColumn(label: Text('Alat')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: _activeLoans.map((loan) {
                      final name = loan['equipments']?['name'] ?? 'Unknown';
                      final status = loan['status'] ?? 'pending';
                      final isSelectable = status == 'active' || status == 'approved';
                      final isSelected = _selectedLoanIds.contains(loan['id']);
                      return DataRow(cells: [
                        DataCell(isSelectable ? Checkbox(value: isSelected, activeColor: AppColors.primaryPink, onChanged: (v) {
                          setState(() { if (v!) _selectedLoanIds.add(loan['id']); else _selectedLoanIds.remove(loan['id']); });
                        }) : const Icon(Icons.lock_outline, size: 16, color: Colors.grey)),
                        DataCell(SizedBox(width: 150, child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis))),
                        DataCell(Text(status.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                      ]);
                    }).toList(),
                  ),
                ),
          ),
          if (_selectedLoanIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: ElevatedButton(
                onPressed: _showQRDialog,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50)),
                child: const Text('DAPATKAN QR PENGEMBALIAN'),
              ),
            ),
        ],
      ),
    );
  }
}
