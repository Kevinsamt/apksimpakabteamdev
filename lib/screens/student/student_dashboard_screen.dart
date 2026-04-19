import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/custom_loader.dart';
import '../../theme/app_colors.dart';
import 'student_profile_screen.dart';
import 'borrow_request_screen.dart';
import 'scanner_screen.dart';
import 'formal_form_view.dart';
import 'pages/history_page.dart';
import 'ai_assistant_screen.dart';
import '../../services/notification_service.dart';
import '../../theme/text_styles.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  final _supabase = Supabase.instance.client;
  String _studentName = 'Nama Mahasiswa';
  String _nim = '***';
  String _kelas = 'KB_A-SG';
  String? _avatarUrl;
  List<Map<String, dynamic>> _equipments = [];
  List<Map<String, dynamic>> _activeLoans = [];
  bool _isLoading = true;
  bool _isEquipLoading = true;
  bool _isLoansLoading = true;

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
  int _selectedIndex = 0;
  final List<Map<String, dynamic>> _cart = [];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
    _fetchEquipments();
    _fetchActiveLoans();
  }

  Future<void> _fetchProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        final data = await _supabase.from('profiles').select('full_name, nim, kelas, avatar_url').eq('id', userId).single();
        if (mounted) {
          setState(() {
            _studentName = data['full_name'] ?? 'Mahasiswa';
            if (data['nim'] != null) _nim = data['nim'];
            if (data['kelas'] != null) _kelas = data['kelas'];
            _avatarUrl = data['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchEquipments() async {
    try {
      if (mounted) setState(() => _isEquipLoading = true);
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

  Future<void> _fetchActiveLoans() async {
    try {
      if (mounted) setState(() => _isLoansLoading = true);
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;
      
      final data = await _supabase.from('loans')
          .select('*, equipments(name)')
          .eq('user_id', userId)
          .or('status.eq.pending,status.eq.approved')
          .order('borrow_date', ascending: false);
      
      if (mounted) {
        setState(() {
          _activeLoans = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error fetching active loans: $e');
    } finally {
      if (mounted) setState(() => _isLoansLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _fetchProfile(),
      _fetchEquipments(),
      _fetchActiveLoans(),
    ]);
  }

  void _updateQuantity(String equipmentId, int delta, int maxStock) {
    setState(() {
      final index = _cart.indexWhere((item) => item['id'] == equipmentId);
      if (index >= 0) {
        int newQty = (_cart[index]['quantity'] ?? 1) + delta;
        if (newQty > 0 && newQty <= maxStock) {
          _cart[index]['quantity'] = newQty;
        } else if (newQty <= 0) {
          _cart.removeAt(index);
        }
      }
    });
  }

  void _addToCart(Map<String, dynamic> equipment) {
    int maxStock = equipment['available_quantity'] ?? 1;
    final index = _cart.indexWhere((item) => item['id'] == equipment['id']);
    
    if (index >= 0) {
      if (_cart[index]['quantity'] < maxStock) {
        setState(() => _cart[index]['quantity']++);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Jumlah ${equipment['name']} bertambah jadi ${_cart[index]['quantity']}'), backgroundColor: AppColors.primaryPink, duration: const Duration(seconds: 1)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stok alat di laboratorium sudah maksimal'), backgroundColor: Colors.orange),
        );
      }
      return;
    }

    setState(() {
      _cart.add({...equipment, 'quantity': 1});
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${equipment['name']} ditambahkan ke daftar'),
        backgroundColor: AppColors.primaryPink,
        action: SnackBarAction(label: 'LIHAT', textColor: Colors.white, onPressed: () => setState(() => _selectedIndex = 2)),
      ),
    );
  }

  Future<void> _openFormalForm() async {
    if (_cart.isEmpty) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BorrowRequestScreen(
          items: List<Map<String, dynamic>>.from(_cart),
          studentName: _studentName,
          nim: _nim,
          kelas: _kelas,
        ),
      ),
    );

    if (result == true) {
      if (mounted) {
        setState(() {
          _cart.clear();
          _selectedIndex = 2; // Switch to "Peminjaman" tab
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permintaan peminjaman formal berhasil dikirim!'), backgroundColor: AppColors.statusActive),
        );
        _fetchActiveLoans();
      }
    }
  }

  Future<void> _showFeedbackDialog() async {
    final controller = TextEditingController();
    bool isSubmitting = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Lapor Keluhan / Saran 📝', style: TextStyle(fontWeight: FontWeight.bold)),
          content: TextField(
            controller: controller,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: 'Tuliskan keluhan atau saran Anda di sini...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: isSubmitting ? null : () async {
                if (controller.text.isEmpty) return;
                setStateDialog(() => isSubmitting = true);
                try {
                  await _supabase.from('feedback').insert({
                    'user_id': _supabase.auth.currentUser?.id,
                    'user_email': _supabase.auth.currentUser?.email,
                    'message': controller.text,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terima kasih! Laporan Anda sudah terkirim ke Developer. 🙏')));
                  }
                } catch (e) {
                  debugPrint('Error feedback: $e');
                  setStateDialog(() => isSubmitting = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white),
              child: isSubmitting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Kirim'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      body: SafeArea(
        child: _isLoading 
            ? const CustomLoader(message: 'Memuat data mahasiswa...')
            : _selectedIndex == 0 
                ? _buildHome() 
                : _selectedIndex == 1 
                    ? _buildAlat() 
                    : _selectedIndex == 2 
                        ? _buildPeminjaman() 
                        : _buildKembalian(),
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                  builder: (context) => SafeArea(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Butuh Bantuan? 🔱', style: AppTextStyles.heading2),
                          const SizedBox(height: 24),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.primaryPink.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.bolt_rounded, color: AppColors.primaryPink),
                            ),
                            title: const Text('Tanya AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Tanya seputar alat kebidanan'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const AiAssistantScreen()));
                            },
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                            ),
                            title: const Text('Lapor Keluhan / Saran', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: const Text('Kirim pesan ke Developer'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context);
                              _showFeedbackDialog();
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.primaryPink,
              child: const Icon(Icons.help_outline, color: Colors.white),
            )
          : (_selectedIndex == 1 && _cart.isNotEmpty
              ? FloatingActionButton.extended(
                  onPressed: () => setState(() => _selectedIndex = 2),
                  backgroundColor: AppColors.primaryPink,
                  icon: const Icon(Icons.shopping_basket_outlined, color: Colors.white),
                  label: Text('${_cart.length} Alat Terpilih', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              : null),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primaryPink,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.build_outlined), activeIcon: Icon(Icons.build), label: 'Alat'),
            BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), activeIcon: Icon(Icons.assignment), label: 'Peminjaman'),
            BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Kembalian'),
          ],
        ),
      ),
    );
  }

  Widget _buildHome() {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: AppColors.primaryPink,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.primaryPink,
                    AppColors.primaryPink.withValues(alpha: 0.1),
                    AppColors.backgroundWhite,
                  ],
                  stops: const [0.0, 0.6, 1.0],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Image.asset('assets/images/logo_student.png', height: 42, fit: BoxFit.contain, errorBuilder: (c,e,s) => const Icon(Icons.favorite, color: Colors.white)),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('SIMPAKAB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                                      Text('sistem informasi management\n& peminjaman alat kebidanan', 
                                        style: TextStyle(fontSize: 8, color: Colors.black54, height: 1.1),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              StreamBuilder<int>(
                                stream: NotificationService.getUnreadCountStream(_supabase.auth.currentUser?.id, role: 'student'),
                                builder: (context, snapshot) {
                                  final count = snapshot.data ?? 0;
                                  return Stack(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                                        onPressed: () {
                                          showModalBottomSheet(
                                            context: context,
                                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                                            builder: (context) => _buildNotificationSheet(),
                                          );
                                        },
                                      ),
                                      if (count > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                            child: Text(
                                              '$count',
                                              style: const TextStyle(color: AppColors.primaryPink, fontSize: 8, fontWeight: FontWeight.bold),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(width: 4),
                              GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => StudentProfileScreen(
                                      initialName: _studentName,
                                      initialNim: _nim,
                                      initialKelas: _kelas,
                                      initialAvatarUrl: _avatarUrl,
                                    )),
                                  );
                                  if (result == true) {
                                    _fetchProfile();
                                  }
                                },
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.black,
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
                              ]
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.black87,
                              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty ? NetworkImage(_avatarUrl!) : null,
                              child: _avatarUrl == null || _avatarUrl!.isEmpty ? const Icon(Icons.person, size: 50, color: Colors.white) : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Halo, Selamat Datang', style: TextStyle(fontSize: 14, color: Colors.black87)),
                                const SizedBox(height: 4),
                                _isLoading 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                    : Text(_studentName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black)),
                                const SizedBox(height: 4),
                                Text('(Nim :$_nim) Kelas: $_kelas', style: const TextStyle(fontSize: 12, color: Colors.black87)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ScannerScreen(
                              studentName: _studentName,
                              nim: _nim,
                              kelas: _kelas,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.primaryPink,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(color: AppColors.primaryPink.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_scanner, color: Colors.white, size: 24),
                            SizedBox(width: 12),
                            Text('SCAN QR ALAT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Peminjaman Aktif', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                    const SizedBox(height: 16),
                    if (_isLoansLoading)
                      const Center(child: CustomLoader(message: 'Memuat peminjaman aktif...'))
                    else if (_activeLoans.isEmpty)
                      Row(
                        children: [
                          Container(
                            width: 12, height: 4,
                            decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(child: Text('Belum ada peminjaman aktif', style: TextStyle(fontSize: 14, color: Colors.black54))),
                        ],
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _activeLoans.length,
                        itemBuilder: (context, index) {
                          final loan = _activeLoans[index];
                          final status = loan['status'] == 'pending' ? 'Menunggu' : 'Disetujui';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(color: loan['status'] == 'pending' ? AppColors.statusPending : AppColors.statusActive, shape: BoxShape.circle),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text('${loan['equipments']['name']} ($status)', style: const TextStyle(fontSize: 14, color: Colors.black87))),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildAlat() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.primaryPink, AppColors.primaryPink.withValues(alpha: 0.8)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  const Icon(Icons.build_circle_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Daftar Alat Peminjaman', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                  if (!_isEquipLoading) ...[
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)), child: Text('${_equipments.length} Item', style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchEquipments,
            color: AppColors.primaryPink,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Cari alat atau bahan...',
                              prefixIcon: const Icon(Icons.search, color: AppColors.primaryPink),
                              filled: true, fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.surfacePink, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primaryPink.withValues(alpha: 0.3))),
                          child: Row(
                            children: [
                              Text(_selectedCategory == 'Semua' ? 'Filter' : _selectedCategory.split(' ').first, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryPink)),
                              const Icon(Icons.keyboard_arrow_down, size: 16, color: AppColors.primaryPink),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final isSelected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: FilterChip(
                              label: Text(cat, style: TextStyle(fontSize: 10, color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                              selected: isSelected,
                              onSelected: (selected) => setState(() => _selectedCategory = cat),
                              selectedColor: AppColors.primaryPink,
                              checkmarkColor: Colors.white,
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? AppColors.primaryPink : AppColors.borderLight)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_isEquipLoading) const Center(child: CustomLoader(message: 'Memuat daftar alat...'))
                    else if (_equipments.isEmpty) const Center(child: Text('Tidak ada alat tersedia saat ini.'))
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _equipments.where((item) {
                          final name = item['name']?.toString().toLowerCase() ?? '';
                          final cat = item['category'] ?? 'ALAT LOGAM METAL';
                          return name.contains(_searchQuery) && (_selectedCategory == 'Semua' || cat == _selectedCategory);
                        }).length,
                        itemBuilder: (context, index) {
                          final filteredList = _equipments.where((item) {
                            final name = item['name']?.toString().toLowerCase() ?? '';
                            final cat = item['category'] ?? 'ALAT LOGAM METAL';
                            return name.contains(_searchQuery) && (_selectedCategory == 'Semua' || cat == _selectedCategory);
                          }).toList();
                          final equipment = filteredList[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderLight)),
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
                                      Text(equipment['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 2, overflow: TextOverflow.ellipsis),
                                      const SizedBox(height: 4),
                                      Text('${equipment['category'] ?? 'LOGAM'}', style: const TextStyle(color: AppColors.primaryPink, fontSize: 8, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text('Tersedia: ${equipment['available_quantity']}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Builder(
                                  builder: (context) {
                                    final cartItemIndex = _cart.indexWhere((c) => c['id'] == equipment['id']);
                                    if (cartItemIndex >= 0) {
                                      final qty = _cart[cartItemIndex]['quantity'] ?? 1;
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryPink, size: 22),
                                            onPressed: () => _updateQuantity(equipment['id'], -1, equipment['available_quantity'] ?? 1),
                                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, color: AppColors.primaryPink, size: 22),
                                            onPressed: () => _updateQuantity(equipment['id'], 1, equipment['available_quantity'] ?? 1),
                                            padding: EdgeInsets.zero, constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      );
                                    }
                                    return ElevatedButton(
                                      onPressed: () => _addToCart(equipment),
                                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), minimumSize: const Size(60, 36)),
                                      child: const Text('Pinjam', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                    );
                                  }
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPeminjaman() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [AppColors.primaryPink, AppColors.primaryPink.withValues(alpha: 0.8)])),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Row(
                children: [
                  const Icon(Icons.assignment_turned_in_outlined, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Alat Sedang Dipinjam', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchActiveLoans,
            color: AppColors.primaryPink,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_cart.isNotEmpty) ...[
                    const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 10), child: Text('DAFTAR PINJAM BARU', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryPink))),
                    ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: _cart.length,
                      itemBuilder: (context, index) {
                        final item = _cart[index];
                        return ListTile(
                          leading: const Icon(Icons.build_circle, color: AppColors.primaryPink),
                          title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${item['category'] ?? 'Alat'} • Jml: ${item['quantity']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(icon: const Icon(Icons.remove_circle_outline, size: 20), onPressed: () => _updateQuantity(item['id'], -1, item['available_quantity'] ?? 1)),
                              Text('${item['quantity']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.add_circle_outline, size: 20), onPressed: () => _updateQuantity(item['id'], 1, item['available_quantity'] ?? 1)),
                              const SizedBox(width: 8),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.grey), onPressed: () => setState(() => _cart.removeAt(index))),
                            ],
                          ),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton.icon(
                        onPressed: () => _openFormalForm(),
                        icon: const Icon(Icons.description_outlined), label: const Text('ISI FORMULIR PEMINJAMAN'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryPink, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ),
                    const Divider(thickness: 8, color: AppColors.surfacePink),
                  ],
                  const Padding(padding: EdgeInsets.fromLTRB(20, 20, 20, 10), child: Text('PINJAMAN SEBELUMNYA / AKTIF', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54))),
                  if (_isLoansLoading) const Center(child: CustomLoader(message: 'Memuat data peminjaman...'))
                  else if (_activeLoans.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40.0), child: Text('Tidak ada alat yang sedang dipinjam.')))
                  else
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columnSpacing: 20, headingRowColor: WidgetStateProperty.all(AppColors.surfacePink),
                        columns: const [
                          DataColumn(label: Text('No', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Nama Alat', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('NIM', style: TextStyle(fontWeight: FontWeight.bold))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                        rows: _activeLoans.asMap().entries.map((entry) {
                          final index = entry.key; final loan = entry.value; final equipmentName = loan['equipments'] != null ? loan['equipments']['name'] : 'Unknown';
                          final rawStatus = loan['status']; Color statusColor = AppColors.statusPending; String statusText = 'PENDING';
                          if (rawStatus == 'approved') { statusColor = AppColors.statusActive; statusText = 'AKTIF'; }
                          else if (rawStatus == 'rejected') { statusColor = AppColors.statusOverdue; statusText = 'DITOLAK'; }
                          return DataRow(cells: [
                            DataCell(Text('${index + 1}.')),
                            DataCell(SizedBox(width: 150, child: Text(equipmentName, maxLines: 2, overflow: TextOverflow.ellipsis))),
                            DataCell(Text(_nim)),
                            DataCell(Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)), child: Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10))),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.description_outlined, color: AppColors.primaryPink, size: 18),
                                  onPressed: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => FormalFormView(loanData: loan, studentName: _studentName, nim: _nim, kelas: _kelas)));
                                  },
                                ),
                              ],
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKembalian() {
    return HistoryPage(
      studentName: _studentName,
      nim: _nim,
      kelas: _kelas,
    );
  }

  Widget _buildNotificationSheet() {
    final userId = _supabase.auth.currentUser?.id;
    return SingleChildScrollView(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Notifikasi', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await NotificationService.markAllAsRead(userId, role: 'student');
                      if (!mounted) return;
                      navigator.pop();
                    },
                    child: const Text('Tandai semua dibaca'),
                  ),
                ],
              ),
            ),
            const Divider(),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: NotificationService.getNotifications(userId, role: 'student'),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
                final notes = snapshot.data!;
                if (notes.isEmpty) return const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Tidak ada notifikasi.')));
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: notes.length,
                  itemBuilder: (context, index) {
                    final note = notes[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: note['is_read'] ? Colors.grey[200] : AppColors.primaryPink.withValues(alpha: 0.1),
                        child: Icon(Icons.notifications, color: note['is_read'] ? Colors.grey : AppColors.primaryPink, size: 20),
                      ),
                      title: Text(note['title'], style: TextStyle(fontWeight: note['is_read'] ? FontWeight.normal : FontWeight.bold, fontSize: 13)),
                      subtitle: Text(note['message'], style: const TextStyle(fontSize: 11)),
                      onTap: () async {
                        final navigator = Navigator.of(context);
                        await NotificationService.markAsRead(note['id']);
                        if (!mounted) return;
                        navigator.pop();
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
