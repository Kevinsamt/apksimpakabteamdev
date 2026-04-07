import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/custom_loader.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/header.dart';
import '../../widgets/app_bottom_nav.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';


class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipments = [];
  bool _isLoading = true;

  final List<String> _categories = [
    'ALAT LOGAM METAL',
    'BARANG STANLESS DAN NON STANLESS',
    'BAHAN TENUN',
    'BAHAN HABIS PAKAI',
    'PHANTOM (P.)',
    'BARANG LABORATORIUM KOMPLEMENTE',
  ];
  String _selectedCategory = 'Semua Kategori';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEquipments();
  }

  Future<void> _fetchEquipments() async {
    setState(() => _isLoading = true);
    try {
      final data = await _supabase.from('equipments').select().order('created_at');
      setState(() {
        _equipments = List<Map<String, dynamic>>.from(data);
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat data: $error'), backgroundColor: AppColors.statusOverdue),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddEquipmentDialog() async {
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final goodQtyController = TextEditingController();
    final brokenQtyController = TextEditingController();
    final descriptionController = TextEditingController(); 
    String? selectedCategory = _categories.first;
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    bool isSubmitting = false;

    Future<void> pickImage(void Function(void Function()) setStateDialog) async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setStateDialog(() {
          selectedImage = image;
          selectedImageBytes = bytes;
        });
      }
    }


    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceWhite,
              title: Text('Tambah Alat/Barang', style: AppTextStyles.heading2),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Barang'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: skuController,
                      decoration: const InputDecoration(labelText: 'Kode/SKU (Opsional)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setStateDialog(() => selectedCategory = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: goodQtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Kondisi Bagus'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: brokenQtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Kondisi Rusak'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi / Fungsi Alat',
                        hintText: 'Jelaskan kegunaan alat ini...',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Image Picker UI
                    const Text('Foto Alat (Opsional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => pickImage(setStateDialog),
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: selectedImageBytes != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(selectedImageBytes!, width: double.infinity, height: 120, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      radius: 14,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                        onPressed: () => setStateDialog(() {
                                          selectedImage = null;
                                          selectedImageBytes = null;
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryPink, size: 32),
                                  const SizedBox(height: 4),
                                  const Text('Ketuk untuk pilih foto', style: TextStyle(fontSize: 10, color: AppColors.primaryPink)),
                                ],
                              ),
                      ),
                    ),

                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (nameController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Nama barang wajib diisi'), backgroundColor: AppColors.statusOverdue),
                       );
                       return;
                    }
                    setStateDialog(() => isSubmitting = true);
                    try {
                      final goodQty = int.tryParse(goodQtyController.text) ?? 0;
                      final brokenQty = int.tryParse(brokenQtyController.text) ?? 0;
                      final totalQty = goodQty + brokenQty;

                      String? imageUrl;
                      if (selectedImage != null && selectedImageBytes != null) {
                        final fileName = 'equip_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        await _supabase.storage.from('equipment_images').uploadBinary(
                          fileName,
                          selectedImageBytes!,
                          fileOptions: const FileOptions(contentType: 'image/jpeg'),
                        );
                        imageUrl = _supabase.storage.from('equipment_images').getPublicUrl(fileName);
                      }

                      await _supabase.from('equipments').insert({
                        'name': nameController.text.trim(),
                        'sku': skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                        'category': selectedCategory,
                        'good_condition': goodQty,
                        'broken_condition': brokenQty,
                        'total_quantity': totalQty,
                        'available_quantity': goodQty,
                        'description': descriptionController.text.trim(), 
                        'image_url': imageUrl,
                      });

                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (e) {
                      setStateDialog(() => isSubmitting = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusOverdue),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white),
                  child: isSubmitting 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan'),
                ),
              ],
            );
          }
        );
      }
    );
    
    if (result == true) {
      _fetchEquipments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang berhasil ditambahkan!'), backgroundColor: AppColors.statusActive),
      );
    }
  }

  Future<void> _deleteEquipment(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceWhite,
        title: Text('Hapus Barang', style: AppTextStyles.heading2),
        content: Text('Yakin ingin menghapus ${item['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusOverdue, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _supabase.from('equipments').delete().eq('id', item['id']);
      _fetchEquipments();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barang berhasil dihapus'), backgroundColor: AppColors.statusOverdue));
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusOverdue));
    }
  }

  Future<void> _showEditEquipmentDialog(Map<String, dynamic> item) async {
    final nameController = TextEditingController(text: item['name']);
    final skuController = TextEditingController(text: item['sku'] ?? '');
    final goodQtyController = TextEditingController(text: (item['good_condition'] ?? item['total_quantity']).toString());
    final brokenQtyController = TextEditingController(text: (item['broken_condition'] ?? 0).toString());
    final descriptionController = TextEditingController(text: item['description'] ?? ''); 
    String? selectedCategory = item['category'] ?? _categories.first;
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    bool isSubmitting = false;

    Future<void> pickImage(void Function(void Function()) setStateDialog) async {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setStateDialog(() {
          selectedImage = image;
          selectedImageBytes = bytes;
        });
      }
    }


    final result = await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: AppColors.surfaceWhite,
              title: Text('Edit Alat/Barang', style: AppTextStyles.heading2),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nama Barang'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: skuController,
                      decoration: const InputDecoration(labelText: 'Kode/SKU (Opsional)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: const InputDecoration(labelText: 'Kategori'),
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (val) => setStateDialog(() => selectedCategory = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: goodQtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Kondisi Bagus'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: brokenQtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Kondisi Rusak'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Deskripsi / Fungsi Alat',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Image Picker UI for Edit
                    const Text('Foto Alat (Biarkan jika tidak diubah)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => pickImage(setStateDialog),
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: selectedImageBytes != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(selectedImageBytes!, width: double.infinity, height: 120, fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 4,
                                    child: CircleAvatar(
                                      backgroundColor: Colors.black54,
                                      radius: 14,
                                      child: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                        onPressed: () => setStateDialog(() {
                                          selectedImage = null;
                                          selectedImageBytes = null;
                                        }),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : (item['image_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(item['image_url'], width: double.infinity, height: 120, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_a_photo_outlined, color: AppColors.primaryPink, size: 32),
                                      const SizedBox(height: 4),
                                      const Text('Ganti foto', style: TextStyle(fontSize: 10, color: AppColors.primaryPink)),
                                    ],
                                  )),
                      ),
                    ),

                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(context),
                  child: const Text('Batal', style: TextStyle(color: AppColors.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : () async {
                    if (nameController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Nama barang wajib diisi'), backgroundColor: AppColors.statusOverdue),
                       );
                       return;
                    }
                    setStateDialog(() => isSubmitting = true);
                    try {
                      final newGood = int.tryParse(goodQtyController.text) ?? 0;
                      final newBroken = int.tryParse(brokenQtyController.text) ?? 0;
                      final totalQty = newGood + newBroken;
                      
                      // Recalculate available based on diff in good condition
                      final diffGood = newGood - (item['good_condition'] ?? item['total_quantity'] as int);
                      final newAvail = (item['available_quantity'] as int) + diffGood;

                      String? imageUrl = item['image_url'];
                      if (selectedImage != null && selectedImageBytes != null) {
                        final fileName = 'equip_${DateTime.now().millisecondsSinceEpoch}.jpg';
                        await _supabase.storage.from('equipment_images').uploadBinary(
                          fileName,
                          selectedImageBytes!,
                          fileOptions: const FileOptions(contentType: 'image/jpeg'),
                        );
                        imageUrl = _supabase.storage.from('equipment_images').getPublicUrl(fileName);
                      }
                      
                      await _supabase.from('equipments').update({
                        'name': nameController.text.trim(),
                        'sku': skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                        'category': selectedCategory,
                        'good_condition': newGood,
                        'broken_condition': newBroken,
                        'total_quantity': totalQty,
                        'available_quantity': newAvail >= 0 ? newAvail : 0,
                        'description': descriptionController.text.trim(), 
                        'image_url': imageUrl,
                      }).eq('id', item['id']);

                      if (!context.mounted) return;
                      Navigator.pop(context, true);
                    } catch (e) {
                      setStateDialog(() => isSubmitting = false);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.statusOverdue),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white),
                  child: isSubmitting 
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan'),
                ),
              ],
            );
          }
        );
      }
    );
    
    if (result == true) {
      _fetchEquipments();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang berhasil diperbarui!'), backgroundColor: AppColors.statusActive),
      );
    }
  }

  Future<void> _showQrLabelDialog(Map<String, dynamic> item) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceWhite,
          title: Text('QR Label: ${item['name']}', style: AppTextStyles.heading2),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    children: [
                      Text('SIMPAKAB - LAB', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink, fontSize: 10)),
                      const SizedBox(height: 8),
                      QrImageView(
                        data: item['id'].toString(),
                        version: QrVersions.auto,
                        size: 180.0,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 10,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.yellow, Colors.black, Colors.yellow, Colors.black, Colors.yellow],
                            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            tileMode: TileMode.repeated,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Text removed
                      // Category removed
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Print label ini untuk ditempelkan pada alat fisik.', style: TextStyle(fontSize: 10, fontStyle: FontStyle.italic)),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
            ElevatedButton.icon(
              onPressed: () async {
                final pdf = pw.Document();
                pdf.addPage(
                  pw.Page(
                    pageFormat: PdfPageFormat.roll80,
                    build: (pw.Context context) {
                      return pw.Center(
                        child: pw.Column(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text('SIMPAKAB - LAB', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                            pw.BarcodeWidget(
                              data: item['id'].toString(),
                              barcode: pw.Barcode.qrCode(),
                              width: 60,
                              height: 60,
                            ),
                            pw.SizedBox(height: 4),
                            // PDF Text removed
                          ],
                        ),
                      );
                    },
                  ),
                );
                await Printing.layoutPdf(onLayout: (format) async => pdf.save());
              },
              icon: const Icon(Icons.print),
              label: const Text('Print Label'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      bottomNavigationBar: isDesktop ? null : const AppBottomNav(currentIndex: 1),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop) const Sidebar(currentRoute: '/equipment'),
          Expanded(
            child: Column(
              children: [
                const HeaderWidget(onMenuPressed: null),
                Expanded(
                  child: _isLoading
                      ? const CustomLoader(message: 'Memuat data alat...')
                      : RefreshIndicator(
                          onRefresh: _fetchEquipments,
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(child: Text('Equipment Inventory', style: AppTextStyles.heading1)),
                                        const SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          onPressed: _showAddEquipmentDialog,
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Add', style: TextStyle(fontSize: 12)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.statusActive,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            controller: _searchController,
                                            style: const TextStyle(fontSize: 12),
                                            decoration: InputDecoration(
                                              hintText: 'Cari alat...',
                                              prefixIcon: const Icon(Icons.search, color: AppColors.primaryPink, size: 16),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                                            ),
                                            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                          height: 48,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: AppColors.borderLight),
                                          ),
                                          child: DropdownButton<String>(
                                            value: _selectedCategory,
                                            underline: const SizedBox(),
                                            icon: const Icon(Icons.filter_list, size: 16, color: AppColors.primaryPink),
                                            items: ['Semua Kategori', ..._categories].map((c) => DropdownMenuItem(value: c, child: Text(c.split(' ').first, style: const TextStyle(fontSize: 11)))).toList(),
                                            onChanged: (val) => setState(() => _selectedCategory = val!),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceWhite,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.borderLight),
                                  ),
                                  child: _equipments.isEmpty
                                    ? const Center(child: Padding(
                                        padding: EdgeInsets.all(32.0),
                                        child: Text('Belum ada data barang.', style: TextStyle(color: AppColors.textSecondary)),
                                      ))
                                    : SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          headingTextStyle: AppTextStyles.bodyTextStrong,
                                          columns: const [
                                            DataColumn(label: Text('Kategori')),
                                            DataColumn(label: Text('Nama Alat')),
                                            DataColumn(label: Text('SKU')),
                                            DataColumn(label: Text('Bagus')),
                                            DataColumn(label: Text('Rusak')),
                                            DataColumn(label: Text('Total')),
                                            DataColumn(label: Text('Tersedia')),
                                            DataColumn(label: Text('Aksi')),
                                          ],
                                          rows: _equipments.where((item) {
                                            final name = item['name']?.toString().toLowerCase() ?? '';
                                            final sku = item['sku']?.toString().toLowerCase() ?? '';
                                            final cat = item['category'] ?? 'ALAT LOGAM METAL';
                                            
                                            final matchesSearch = name.contains(_searchQuery) || sku.contains(_searchQuery);
                                            final matchesCat = _selectedCategory == 'Semua Kategori' || cat == _selectedCategory;
                                            
                                            return matchesSearch && matchesCat;
                                          }).map((item) {
                                            return DataRow(cells: [
                                              DataCell(Text(item['category'] ?? 'LOGAM', style: AppTextStyles.label.copyWith(color: AppColors.primaryPink))),
                                              DataCell(Text(item['name'] ?? '', style: AppTextStyles.bodyText)),
                                              DataCell(Text(item['sku'] ?? '-', style: AppTextStyles.bodyText)),
                                              DataCell(Text((item['good_condition'] ?? item['total_quantity']).toString(), style: AppTextStyles.bodyText)),
                                              DataCell(Text((item['broken_condition'] ?? 0).toString(), style: AppTextStyles.bodyText)),
                                              DataCell(Text(item['total_quantity'].toString(), style: AppTextStyles.bodyText)),
                                              DataCell(Text(item['available_quantity'].toString(), style: AppTextStyles.bodyText.copyWith(
                                                color: (item['available_quantity'] ?? 0) > 0 ? AppColors.statusActive : AppColors.statusOverdue,
                                                fontWeight: FontWeight.bold,
                                              ))),
                                              DataCell(Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.qr_code, color: Colors.blueAccent, size: 20),
                                                    onPressed: () => _showQrLabelDialog(item),
                                                    tooltip: 'Generate QR Label',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: AppColors.primaryPink, size: 20),
                                                    onPressed: () => _showEditEquipmentDialog(item),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: AppColors.statusOverdue, size: 20),
                                                    onPressed: () => _deleteEquipment(item),
                                                  ),
                                                ],
                                              )),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}






