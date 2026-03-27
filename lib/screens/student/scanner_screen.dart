import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import 'borrow_request_screen.dart';

class ScannerScreen extends StatefulWidget {
  final String studentName;
  final String nim;
  final String kelas;

  const ScannerScreen({
    super.key,
    required this.studentName,
    required this.nim,
    required this.kelas,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final _supabase = Supabase.instance.client;
  final List<Map<String, dynamic>> _scannedItems = [];
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    
    for (final barcode in barcodes) {
      final code = barcode.rawValue;
      if (code != null) {
        setState(() => _isProcessing = true);
        await _handleScannedCode(code);
        break;
      }
    }
  }

  Future<void> _handleScannedCode(String code) async {
    try {
      // Check if already in scanned list
      if (_scannedItems.any((item) => item['id'] == code)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alat ini sudah ada di daftar scan!')),
        );
        setState(() => _isProcessing = false);
        return;
      }

      // Fetch equipment details
      final data = await _supabase
          .from('equipments')
          .select()
          .eq('id', code)
          .maybeSingle();

      if (data == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alat tidak ditemukan!'), backgroundColor: AppColors.statusOverdue),
          );
        }
      } else {
        if (mounted) {
          await _showEquipmentDetails(data);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusOverdue),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showEquipmentDetails(Map<String, dynamic> equipment) async {
    final bool? added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 24),
              if (equipment['image_url'] != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    equipment['image_url'],
                    width: double.infinity,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.primaryPink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.medical_services_outlined, color: AppColors.primaryPink, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(equipment['name'] ?? 'Alat Tanpa Nama', style: AppTextStyles.heading2),
                        Text(equipment['category'] ?? 'Kategori Umum', style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('FUNGSI / DESKRIPSI:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1, color: Colors.grey)),
              const SizedBox(height: 8),
              Text(
                equipment['description'] ?? 'Belum ada deskripsi fungsi untuk alat ini.',
                style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderLight)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Status Ketersediaan:', style: TextStyle(color: Colors.black54)),
                    Text(
                      equipment['available_quantity'] > 0 ? 'TERSEDIA (${equipment['available_quantity']})' : 'HABIS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: equipment['available_quantity'] > 0 ? AppColors.statusActive : AppColors.statusOverdue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: equipment['available_quantity'] > 0 ? () => Navigator.pop(context, true) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryPink,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('TAMBAH KE DAFTAR PINJAM', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('BATAL', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );

    if (added == true) {
      if (!mounted) return;
      setState(() {
        _scannedItems.add(equipment);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${equipment['name']} ditambahkan ke daftar.'),
          backgroundColor: AppColors.statusActive,
          duration: const Duration(seconds: 1),
        ),
      );
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
            onDetect: _onDetect,
          ),
          // Gradient Overlay for readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),
          ),
          // Scan Area Guide
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          // Top Bar
          Positioned(
            top: 40,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Text('Scan QR Alat Lab', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                  icon: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, state, child) {
                      final IconData icon = state.torchState == TorchState.on
                          ? Icons.flash_on
                          : Icons.flash_off;
                      return Icon(icon, color: state.torchState == TorchState.on ? Colors.yellow : Colors.white);
                    },
                  ),
                  onPressed: () => _controller.toggleTorch(),
                ),
              ],
            ),
          ),
          // Bottom Cart / Summary
          if (_scannedItems.isNotEmpty)
            Positioned(
              bottom: 40,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined, color: AppColors.primaryPink),
                        const SizedBox(width: 12),
                        Text('${_scannedItems.length} Alat Terpilih', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        InkWell(
                          onTap: () => setState(() => _scannedItems.clear()),
                          child: const Text('Reset', style: TextStyle(color: AppColors.statusOverdue, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _scannedItems.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                Text(_scannedItems[index]['name'], style: const TextStyle(fontSize: 10)),
                                const SizedBox(width: 4),
                                InkWell(
                                  onTap: () => setState(() => _scannedItems.removeAt(index)),
                                  child: const Icon(Icons.close, size: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BorrowRequestScreen(
                              items: _scannedItems,
                              studentName: widget.studentName,
                              nim: widget.nim,
                              kelas: widget.kelas,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryPink,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('LANJUT PINJAM', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          
          if (_isProcessing)
            const Center(child: CircularProgressIndicator(color: AppColors.primaryPink)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
