import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../theme/app_colors.dart';

class EquipmentPage extends StatefulWidget {
  const EquipmentPage({super.key});

  @override
  State<EquipmentPage> createState() => _EquipmentPageState();
}

class _EquipmentPageState extends State<EquipmentPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipments = [];
  bool _isEquipLoading = true;

  final List<String> _categories = [
    'Semua',
    'ALAT LOGAM METAL',
    'BARANG STANLESS DAN NON STANLESS',
    'BAHAN TENUN',
    'BAHAN HABIS PAKAI',
    'PHANTOM (P.)',
    'BARANG LABORATORIUM KOMPLEMENTE',
  ];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchEquipments();
  }

  Future<void> _fetchEquipments() async {
    try {
      final data = await _supabase.from('equipments').select().gt('available_quantity', 0).order('name');
      if (mounted) {
        setState(() {
          _equipments = List<Map<String, dynamic>>.from(data);
          _isEquipLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching equipments: $e');
      if (mounted) setState(() => _isEquipLoading = false);
    }
  }

  Future<void> _borrowEquipment(Map<String, dynamic> equipment) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pinjam Alat'),
        content: Text('Apakah Anda yakin ingin meminjam ${equipment['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink),
            child: const Text('Pinjam'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase.from('loans').insert({
        'user_id': userId,
        'equipment_id': equipment['id'],
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan peminjaman berhasil dikirim!'), backgroundColor: AppColors.statusActive),
        );
        _fetchEquipments();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal meminjam: $e'), backgroundColor: AppColors.statusOverdue),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search & Filter Header
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Daftar Alat Peminjaman', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Cari alat atau bahan...',
                  prefixIcon: const Icon(Icons.search, color: AppColors.primaryPink),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        label: Text(cat, style: TextStyle(
                          fontSize: 9, 
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        )),
                        selected: isSelected,
                        onSelected: (selected) => setState(() => _selectedCategory = cat),
                        selectedColor: AppColors.primaryPink,
                        checkmarkColor: Colors.white,
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isSelected ? AppColors.primaryPink : AppColors.borderLight),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: _isEquipLoading
              ? const Center(child: CircularProgressIndicator())
              : _equipments.isEmpty
                  ? const Center(child: Text('Tidak ada alat tersedia.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _equipments.where((item) {
                        final name = item['name']?.toString().toLowerCase() ?? '';
                        final cat = item['category'] ?? 'ALAT LOGAM METAL';
                        final matchesSearch = name.contains(_searchQuery);
                        final matchesCat = _selectedCategory == 'Semua' || cat == _selectedCategory;
                        return matchesSearch && matchesCat;
                      }).length,
                      itemBuilder: (context, index) {
                        final filteredList = _equipments.where((item) {
                          final name = item['name']?.toString().toLowerCase() ?? '';
                          final cat = item['category'] ?? 'ALAT LOGAM METAL';
                          final matchesSearch = name.contains(_searchQuery);
                          final matchesCat = _selectedCategory == 'Semua' || cat == _selectedCategory;
                          return matchesSearch && matchesCat;
                        }).toList();
                        final equipment = filteredList[index];
                        final catName = equipment['category'] ?? 'LOGAM';
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderLight),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: AppColors.primaryPink.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.medical_services_outlined, color: AppColors.primaryPink),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(equipment['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(catName, style: const TextStyle(color: AppColors.primaryPink, fontSize: 8, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text('Tersedia: ${equipment['available_quantity']}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _borrowEquipment(equipment),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryPink.withValues(alpha: 0.1),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  minimumSize: const Size(60, 32),
                                ),
                                child: const Text('Pinjam', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}


