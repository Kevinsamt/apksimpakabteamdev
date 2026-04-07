import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';

class InventoryChart extends StatefulWidget {
  const InventoryChart({super.key});

  @override
  State<InventoryChart> createState() => _InventoryChartState();
}

class _InventoryChartState extends State<InventoryChart> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _equipments = [];
  bool _isLoading = true;
  double _maxY = 10;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _supabase.from('equipments').select().limit(5).order('total_quantity', ascending: false);
      double maxVal = 0;
      for (var item in data) {
        if ((item['total_quantity'] as int).toDouble() > maxVal) {
          maxVal = (item['total_quantity'] as int).toDouble();
        }
      }
      if (mounted) {
        setState(() {
          _equipments = List<Map<String, dynamic>>.from(data);
          _maxY = maxVal > 10 ? maxVal + 10 : 20;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
                 'Equipment Inventory',
                 style: AppTextStyles.heading2,
                 maxLines: 1,
                 overflow: TextOverflow.ellipsis,
               ),
             ),
             const Icon(Icons.more_horiz, color: AppColors.textSecondary),
           ],
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 250,
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator())
            : _equipments.isEmpty
                ? const Center(child: Text('Belum ada barang'))
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _maxY,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: getTitles,
                            reservedSize: 38,
                          ),
                        ),
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _buildBarGroups(),
                      gridData: const FlGridData(show: false),
                    ),
                  ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final colors = [
      AppColors.primaryPink,
      AppColors.statusActive,
      AppColors.statusPending,
      AppColors.statusOverdue,
      AppColors.lightPink
    ];
    
    List<BarChartGroupData> groups = [];
    for (int i = 0; i < _equipments.length; i++) {
      groups.add(
        makeGroupData(i, (_equipments[i]['total_quantity'] as int).toDouble(), colors[i % colors.length]),
      );
    }
    return groups;
  }

  Widget getTitles(double value, TitleMeta meta) {
    var style = AppTextStyles.label;
    int index = value.toInt();
    String name = '';
    if (index >= 0 && index < _equipments.length) {
      name = _equipments[index]['name'];
      if (name.length > 8) name = '${name.substring(0, 7)}...';
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      space: 16,
      child: Text(name, style: style),
    );
  }

  BarChartGroupData makeGroupData(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 48,
          borderRadius: BorderRadius.circular(8),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxY,
            color: AppColors.lightPink.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}



