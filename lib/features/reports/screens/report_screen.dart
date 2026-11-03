import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/icon_helper.dart';
import '../providers/report_providers.dart';

class ReportScreen extends ConsumerStatefulWidget {
  const ReportScreen({super.key});

  @override
  ConsumerState<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends ConsumerState<ReportScreen> {
  int _touchedSectionIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final periodIndex = ref.watch(reportPeriodIndexProvider);
    final sharesAsync = ref.watch(reportCategorySharesProvider);
    final trendAsync = ref.watch(reportDailyTrendProvider);
    final comparisonAsync = ref.watch(reportMonthComparisonProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Keuangan'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Period Switcher (Minggu / Bulan / Tahun)
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevatedDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            child: Row(
              children: [
                _buildPeriodTab('Minggu Ini', 0, periodIndex),
                _buildPeriodTab('Bulan Ini', 1, periodIndex),
                _buildPeriodTab('Tahun Ini', 2, periodIndex),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Donut Chart: 5 Kategori Terbesar + Lainnya (§6.5)
          Text(
            'Pengeluaran per Kategori',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          sharesAsync.when(
            data: (shares) {
              if (shares.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Belum ada pengeluaran pada periode ini',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                );
              }

              final total = shares.fold<int>(0, (sum, s) => sum + s.totalAmount);

              final colorPalette = [
                const Color(0xFF059669), // Emerald
                const Color(0xFF0284C7), // Sky blue
                const Color(0xFFF97316), // Orange
                const Color(0xFF8B5CF6), // Violet
                const Color(0xFFEC4899), // Pink
                const Color(0xFF9CA3AF), // Gray for Lainnya
              ];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 200,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedSectionIndex = -1;
                                        return;
                                      }
                                      _touchedSectionIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                sectionsSpace: 2,
                                centerSpaceRadius: 60,
                                sections: List.generate(shares.length, (i) {
                                  final isTouched = i == _touchedSectionIndex;
                                  final fontSize = isTouched ? 15.0 : 12.0;
                                  final radius = isTouched ? 36.0 : 30.0;
                                  final share = shares[i];
                                  final color = colorPalette[i % colorPalette.length];

                                  return PieChartSectionData(
                                    color: color,
                                    value: share.percentage * 100,
                                    title: '${(share.percentage * 100).toStringAsFixed(0)}%',
                                    radius: radius,
                                    titleStyle: TextStyle(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('Total', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  CurrencyFormatter.formatCompact(total),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Legend list
                      ...List.generate(shares.length, (i) {
                        final share = shares[i];
                        final color = colorPalette[i % colorPalette.length];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  share.categoryName,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                '${(share.percentage * 100).toStringAsFixed(1)}% • ${CurrencyFormatter.format(share.totalAmount)}',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 20),

          // Bar Chart: Tren 7 Hari Terakhir
          Text(
            'Tren Pengeluaran Harian',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          trendAsync.when(
            data: (trend) {
              if (trend.isEmpty) return const SizedBox.shrink();

              int maxExp = 0;
              for (final t in trend) {
                if (t.expenseAmount > maxExp) maxExp = t.expenseAmount;
              }

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        maxY: (maxExp * 1.2).clamp(100000.0, double.infinity),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              final item = trend[group.x.toInt()];
                              return BarTooltipItem(
                                '${item.label}\n${CurrencyFormatter.format(item.expenseAmount)}',
                                const TextStyle(color: Colors.white, fontSize: 12),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, meta) {
                                final idx = val.toInt();
                                if (idx >= 0 && idx < trend.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      trend[idx].label,
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(trend.length, (i) {
                          final item = trend[i];
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: item.expenseAmount.toDouble(),
                                color: AppColors.expenseLight,
                                width: 18,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 20),

          // Month-over-Month Comparison Table (§6.5)
          Text(
            'Perbandingan Bulan Ini vs Bulan Lalu',
            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          comparisonAsync.when(
            data: (comparisons) {
              if (comparisons.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Belum ada data pembanding antar bulan',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                );
              }

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comparisons.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = comparisons[i];
                    final isIncreased = item.difference > 0;
                    final isSame = item.difference == 0;

                    return ListTile(
                      leading: Icon(IconHelper.getIcon(item.categoryIcon), size: 20),
                      title: Text(
                        item.categoryName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Lalu: ${CurrencyFormatter.format(item.previousAmount)}',
                        style: const TextStyle(fontSize: 11),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(item.currentAmount),
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSame
                                    ? LucideIcons.minus
                                    : (isIncreased ? LucideIcons.trendingUp : LucideIcons.trendingDown),
                                size: 12,
                                color: isSame
                                    ? Colors.grey
                                    : (isIncreased ? AppColors.expenseLight : AppColors.incomeLight),
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${isIncreased ? '+' : ''}${item.percentageChange.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSame
                                      ? Colors.grey
                                      : (isIncreased ? AppColors.expenseLight : AppColors.incomeLight),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Error: $e'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, int index, int current) {
    final isSelected = index == current;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(reportPeriodIndexProvider.notifier).setPeriod(index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primaryLight : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.grey,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
