import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/nav_helper.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _period = 'Weekly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        leading: const AppBackButton(fallback: '/dashboard'),
        actions: [
          DropdownButton<String>(
            value: _period,
            underline: const SizedBox(),
            style: AppTextStyles.body.copyWith(color: AppColors.primary),
            items: ['Daily', 'Weekly', 'Monthly'].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (v) => setState(() => _period = v ?? 'Weekly'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary cards
            Row(children: [
              _SummaryCard(title: 'Revenue', value: '₹42,850', change: '+12%', isUp: true),
              const SizedBox(width: 8),
              _SummaryCard(title: 'Bookings', value: '142', change: '+8%', isUp: true),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _SummaryCard(title: 'Avg Wait', value: '14 min', change: '-3 min', isUp: true),
              const SizedBox(width: 8),
              _SummaryCard(title: 'Rating', value: '4.8 ⭐', change: '+0.2', isUp: true),
            ]),
            const SizedBox(height: 20),
            // Revenue chart
            Text('Revenue Trend', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Container(
              height: 200,
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.e2),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.border, strokeWidth: 0.5)),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text('₹${(v / 1000).toInt()}k', style: const TextStyle(fontSize: 9, color: AppColors.textHint)), reservedSize: 36)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(['M', 'T', 'W', 'T', 'F', 'S', 'S'][v.toInt() % 7], style: const TextStyle(fontSize: 9, color: AppColors.textHint)), reservedSize: 20)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [const FlSpot(0, 3200), const FlSpot(1, 5100), const FlSpot(2, 4800), const FlSpot(3, 6200), const FlSpot(4, 5800), const FlSpot(5, 7100), const FlSpot(6, 6400)],
                      isCurved: true,
                      gradient: const LinearGradient(colors: [AppColors.primaryLight, AppColors.primary]),
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.primary.withValues(alpha: 0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Bookings by Service', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Container(
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.e2),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(value: 45, color: AppColors.primary, radius: 55, title: '45%', titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                          PieChartSectionData(value: 28, color: AppColors.tealSuccess, radius: 55, title: '28%', titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                          PieChartSectionData(value: 15, color: AppColors.amberWarning, radius: 55, title: '15%', titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                          PieChartSectionData(value: 12, color: AppColors.primaryLight, radius: 55, title: '12%', titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                        sectionsSpace: 2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LegendItem(color: AppColors.primary, label: 'Consultation', value: '45%'),
                      _LegendItem(color: AppColors.tealSuccess, label: 'Blood Test', value: '28%'),
                      _LegendItem(color: AppColors.amberWarning, label: 'ECG', value: '15%'),
                      _LegendItem(color: AppColors.primaryLight, label: 'Others', value: '12%'),
                    ],
                  )),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Busy times
            Text('Busiest Times', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            Container(
              height: 140,
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppShadows.e2),
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, _) => Text(['9', '10', '11', '12', '1', '2', '3', '4'][v.toInt()], style: const TextStyle(fontSize: 9, color: AppColors.textHint)), reservedSize: 16)),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [8, 12, 15, 7, 9, 14, 11, 6].asMap().entries.map((e) => BarChartGroupData(x: e.key, barRods: [BarChartRodData(toY: e.value.toDouble(), gradient: AppGradients.primary, width: 16, borderRadius: const BorderRadius.vertical(top: Radius.circular(4)))])).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Top customers
            Text('Top Customers', style: AppTextStyles.h3),
            const SizedBox(height: 12),
            ...List.generate(3, (i) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppShadows.e1),
              child: Row(children: [
                CircleAvatar(radius: 20, backgroundColor: [AppColors.primary, AppColors.tealSuccess, AppColors.amberWarning][i].withValues(alpha: 0.15), child: Text(['RK', 'PS', 'AS'][i], style: TextStyle(color: [AppColors.primary, AppColors.tealSuccess, AppColors.amberWarning][i], fontWeight: FontWeight.w700, fontSize: 12))),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(['Ravi Kumar', 'Priya Singh', 'Amit Sharma'][i], style: AppTextStyles.h4),
                  Text(['8 visits', '6 visits', '5 visits'][i], style: AppTextStyles.caption),
                ])),
                Text(['₹2,832', '₹2,124', '₹1,770'][i], style: AppTextStyles.h4.copyWith(color: AppColors.primary)),
              ]),
            )),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String change;
  final bool isUp;
  const _SummaryCard({required this.title, required this.value, required this.change, required this.isUp});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppShadows.e1),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.caption),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.h2),
        const SizedBox(height: 4),
        Row(children: [
          Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: AppColors.tealSuccess),
          Text(' $change', style: TextStyle(color: AppColors.tealSuccess, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ]),
    ));
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendItem({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }
}
