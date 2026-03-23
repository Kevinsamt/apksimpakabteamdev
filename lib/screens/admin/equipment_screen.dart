import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/app_colors.dart';
import '../../theme/text_styles.dart';
import '../../widgets/sidebar.dart';
import '../../widgets/header.dart';
import '../../widgets/app_bottom_nav.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipments = [];
  bool _isLoading = true;

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
    final qtyController = TextEditingController();
    bool isSubmitting = false;

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
                    const SizedBox(height: 8),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Jumlah Total'),
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
                    if (nameController.text.isEmpty || qtyController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Nama dan Jumlah wajib diisi'), backgroundColor: AppColors.statusOverdue),
                       );
                       return;
                    }
                    setStateDialog(() => isSubmitting = true);
                    try {
                      final qty = int.parse(qtyController.text);
                      await _supabase.from('equipments').insert({
                        'name': nameController.text.trim(),
                        'sku': skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                        'total_quantity': qty,
                        'available_quantity': qty,
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
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
    final qtyController = TextEditingController(text: item['total_quantity'].toString());
    bool isSubmitting = false;

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
                    const SizedBox(height: 8),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Jumlah Total'),
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
                    if (nameController.text.isEmpty || qtyController.text.isEmpty) {
                       ScaffoldMessenger.of(context).showSnackBar(
                         const SnackBar(content: Text('Nama dan Jumlah wajib diisi'), backgroundColor: AppColors.statusOverdue),
                       );
                       return;
                    }
                    setStateDialog(() => isSubmitting = true);
                    try {
                      final newQty = int.parse(qtyController.text);
                      final diff = newQty - (item['total_quantity'] as int);
                      final newAvail = (item['available_quantity'] as int) + diff;
                      
                      await _supabase.from('equipments').update({
                        'name': nameController.text.trim(),
                        'sku': skuController.text.trim().isEmpty ? null : skuController.text.trim(),
                        'total_quantity': newQty,
                        'available_quantity': newAvail >= 0 ? newAvail : 0,
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
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Top Update'),
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
                const HeaderWidget(
                  onMenuPressed: null,
                ),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryPink))
                      : SingleChildScrollView(
                          padding: EdgeInsets.all(isDesktop ? 24.0 : 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.spaceBetween,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 16,
                                runSpacing: 16,
                                children: [
                                  Text('Equipment Inventory', style: AppTextStyles.heading1),
                                  ElevatedButton.icon(
                                    onPressed: _showAddEquipmentDialog,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Equipment'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.statusActive,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                    ),
                                  )
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
                                            DataColumn(label: Text('Nama Alat')),
                                            DataColumn(label: Text('SKU')),
                                            DataColumn(label: Text('Total Stok')),
                                            DataColumn(label: Text('Tersedia')),
                                            DataColumn(label: Text('Aksi')),
                                          ],
                                          rows: _equipments.map((item) {
                                            return DataRow(cells: [
                                              DataCell(Text(item['name'] ?? '', style: AppTextStyles.bodyText)),
                                              DataCell(Text(item['sku'] ?? '-', style: AppTextStyles.bodyText)),
                                              DataCell(Text(item['total_quantity'].toString(), style: AppTextStyles.bodyText)),
                                              DataCell(Text(item['available_quantity'].toString(), style: AppTextStyles.bodyText.copyWith(
                                                color: item['available_quantity'] > 0 ? AppColors.statusActive : AppColors.statusOverdue,
                                                fontWeight: FontWeight.bold,
                                              ))),
                                              DataCell(Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
