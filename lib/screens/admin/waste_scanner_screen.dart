import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';

class WasteScannerScreen extends StatefulWidget {
  const WasteScannerScreen({super.key});

  @override
  State<WasteScannerScreen> createState() => _WasteScannerScreenState();
}

class _WasteScannerScreenState extends State<WasteScannerScreen> {
  final _supabase = Supabase.instance.client;
  bool _isScanning = true;

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() => _isScanning = false);
        _handleScan(barcode.rawValue!);
        break;
      }
    }
  }

  void _handleScan(String code) {
    // 💡 Contoh format QR: "WASTE-BIN-001|Infeksius"
    List<String> parts = code.split('|');
    String binId = parts[0];
    String type = parts.length > 1 ? parts[1] : 'Infeksius';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => _buildDisposalForm(binId, type),
    ).then((_) => setState(() => _isScanning = true));
  }

  Widget _buildDisposalForm(String binId, String type) {
    final weightController = TextEditingController();
    bool isSubmitting = false;

    return StatefulBuilder(
      builder: (context, setModalState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Input Pembuangan Limbah', style: AppTextStyles.heading2),
            const SizedBox(height: 8),
            Text('Bin ID: $binId • Jenis: $type', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink)),
            const SizedBox(height: 24),
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Berat Limbah (KG)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                prefixIcon: const Icon(Icons.scale_rounded),
                filled: true,
                fillColor: AppColors.surfacePink.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  if (weightController.text.isEmpty) return;
                  setModalState(() => isSubmitting = true);
                  try {
                    await _supabase.from('medical_waste').insert({
                      'type': type,
                      'weight': double.tryParse(weightController.text) ?? 0,
                      'officer_name': 'Admin (Scan)',
                      'bin_id': binId,
                    });
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limbah Berhasil Dicatat! ✅')));
                    }
                  } catch (e) {
                    setModalState(() => isSubmitting = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('KONFIRMASI PEMBUANGAN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Tong Limbah'), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          // 🛡️ Scanner Overlay
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primaryPink, width: 4),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Arahkan kamera ke QR Code di Tong Limbah',
                style: AppTextStyles.label.copyWith(color: Colors.white, backgroundColor: Colors.black54),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
