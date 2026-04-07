import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class ActiveLoansList extends StatefulWidget {
  const ActiveLoansList({super.key});

  @override
  State<ActiveLoansList> createState() => _ActiveLoansListState();
}

class _ActiveLoansListState extends State<ActiveLoansList> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLoans();
  }

  Future<void> _fetchLoans() async {
    try {
      final data = await _supabase
          .from('loans')
          .select('''
            *,
            profiles(full_name),
            equipments(name, sku)
          ''')
          .order('borrow_date', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _loans = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    if (status == 'active' || status == 'approved') return AppColors.statusActive;
    if (status == 'pending') return AppColors.statusPending;
    if (status == 'overdue') return AppColors.statusOverdue;
    return AppColors.textSecondary;
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return '-';
    }
  }

  Future<void> _updateStatus(String id, String newStatus, String equipmentId) async {
    try {
      if (newStatus == 'returned') {
        final eqData = await _supabase.from('equipments').select('available_quantity').eq('id', equipmentId).single();
        int currentQty = eqData['available_quantity'] as int;
        currentQty += 1;
        await _supabase.from('equipments').update({'available_quantity': currentQty}).eq('id', equipmentId);
      }

      await _supabase.from('loans').update({'status': newStatus}).eq('id', id);
      _fetchLoans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Peminjaman telah selesai (Dikembalikan)'), backgroundColor: AppColors.statusActive),
        );
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.statusOverdue),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Active Loans',
                style: AppTextStyles.heading2,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/loans');
              },
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_isLoading)
          const Center(child: Padding(
            padding: EdgeInsets.all(24.0),
            child: CircularProgressIndicator(),
          ))
        else if (_loans.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
             child: Text('Belum ada peminjaman aktif.', style: TextStyle(color: AppColors.textSecondary)),
          ))
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _loans.length,
            separatorBuilder: (context, index) => const Divider(
              color: AppColors.borderLight,
              height: 24,
            ),
            itemBuilder: (context, index) {
              final loan = _loans[index];
              final borrowerName = loan['profiles']?['full_name'] ?? 'Bidan Unknown';
              final initial = borrowerName.toString().isNotEmpty ? borrowerName.toString()[0].toUpperCase() : '?';
              
              final ekipName = loan['equipments']?['name'] ?? 'Barang Dihapus';
              final ekipSku = loan['equipments']?['sku'] ?? '';
              final itemName = ekipSku.isNotEmpty ? '$ekipName (#$ekipSku)' : ekipName;
              
              final dateStr = _formatDate(loan['borrow_date']);
              final status = (loan['status'] ?? 'unknown').toString().toUpperCase();
              final statusColor = _getStatusColor(loan['status'] ?? '');

              return Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.lightPink,
                    child: Text(
                      initial,
                      style: const TextStyle(color: AppColors.primaryPink, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(borrowerName, style: AppTextStyles.bodyTextStrong, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(itemName, style: AppTextStyles.label, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(dateStr, style: AppTextStyles.bodyText, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                status,
                                style: AppTextStyles.label.copyWith(
                                  color: statusColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            if (loan['status'] == 'approved') ...[
                               const SizedBox(width: 8),
                               InkWell(
                                 onTap: () => _updateStatus(loan['id'], 'returned', loan['equipment_id']),
                                 child: Container(
                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                   decoration: BoxDecoration(
                                     color: AppColors.primaryPink,
                                     borderRadius: BorderRadius.circular(12),
                                   ),
                                   child: const Row(
                                     mainAxisSize: MainAxisSize.min,
                                     children: [
                                       Icon(Icons.check, size: 12, color: AppColors.surfaceWhite),
                                       SizedBox(width: 4),
                                       Text('Selesai', style: TextStyle(color: AppColors.surfaceWhite, fontSize: 10, fontWeight: FontWeight.bold)),
                                     ],
                                   ),
                                 ),
                               ),
                            ],
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }
}


