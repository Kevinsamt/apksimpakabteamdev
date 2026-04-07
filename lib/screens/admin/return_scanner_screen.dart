import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';

class ReturnScannerScreen extends StatefulWidget {
  const ReturnScannerScreen({super.key});

  @override
  State<ReturnScannerScreen> createState() => _ReturnScannerScreenState();
}

class _ReturnScannerScreenState extends State<ReturnScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _supabase = Supabase.instance.client;
  bool _isProcessing = false;

  void _processScan(String code) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    
    _controller.stop(); // Hentikan kamera dulu

    try {
      final data = jsonDecode(code);
      if (data['type'] != 'return') throw Exception('QR Bukan untuk Pengembalian');
      
      final List<dynamic> loanIds = data['ids'];
      
      // Ambil detail barang dari DB
      final response = await _supabase.from('loans')
          .select('*, equipments(name), profiles(student_name, nim)')
          .inFilter('id', loanIds);
      
      final loans = List<Map<String, dynamic>>.from(response);
      
      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (context) => Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('KONFIRMASI PENGEMBALIAN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Divider(height: 32),
              ...loans.map((l) => ListTile(
                title: Text(l['equipments']?['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Peminjam: ${l['profiles']?['student_name'] ?? '***'}'),
                leading: const Icon(Icons.inventory_2, color: AppColors.primaryPink),
              )),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _confirmReturn(loanIds),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryPink,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('ACC PENGEMBALIAN SEKARANG', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('BATAL', style: TextStyle(color: Colors.grey))),
            ],
          ),
        ),
      ).then((_) {
        setState(() => _isProcessing = false);
        _controller.start(); // Mulai kamera lagi kalau ditutup
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
      setState(() => _isProcessing = false);
      _controller.start();
    }
  }

  Future<void> _confirmReturn(List<dynamic> loanIds) async {
    try {
      showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
      
      for (var id in loanIds) {
        // 1. Update status pinjaman
        await _supabase.from('loans').update({'status': 'returned', 'return_date': DateTime.now().toIso8601String()}).eq('id', id);
        
        // 2. Ambil equipment_id & quantity buat balikin stok
        final loan = await _supabase.from('loans').select('equipment_id, quantity').eq('id', id).single();
        final equipId = loan['equipment_id'];
        final qty = loan['quantity'];

        // 3. Tambah stok di equipment
        final equip = await _supabase.from('equipments').select('quantity').eq('id', equipId).single();
        final newStock = (equip['quantity'] ?? 0) + qty;
        await _supabase.from('equipments').update({'quantity': newStock}).eq('id', equipId);
      }

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading
      Navigator.pop(context); // Tutup bottom sheet
      
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Berhasil! Alat Terlah Dikembalikan.'), backgroundColor: Colors.green));
      Navigator.pop(context); // Tutup scanner screen
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  _processScan(barcode.rawValue!);
                  break;
                }
              }
            },
          ),
          // Overlay UI
          Positioned(
            top: 60, left: 20,
            child: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ),
          Center(
            child: Container(
              width: 250, height: 250,
              decoration: BoxDecoration(border: Border.all(color: AppColors.primaryPink, width: 4), borderRadius: BorderRadius.circular(20)),
            ),
          ),
          const Positioned(
            bottom: 100, left: 0, right: 0,
            child: Text('Scan QR Pengembalian Mahasiswa', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
