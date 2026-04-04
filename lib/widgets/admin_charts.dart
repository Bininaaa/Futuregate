import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../utils/admin_palette.dart';

class UsersByLevelBarChart extends StatelessWidget {
  final int bacCount;
  final int licenceCount;
  final int masterCount;
  final int doctoratCount;

  const UsersByLevelBarChart({
    super.key,
    required this.bacCount,
    required this.licenceCount,
    required this.masterCount,
    required this.doctoratCount,
  });

  @override
  Widget build(BuildContext context) {
    final values = [
      bacCount.toDouble(),
      licenceCount.toDouble(),
      masterCount.toDouble(),
      doctoratCount.toDouble(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AdminPalette.border.withValues(alpha: 0.92),
            ),
            boxShadow: AdminPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.bar_chart, color: AdminPalette.accent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Students by Level',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AdminPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: isCompact ? 220 : 240,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _calculateMaxY(values),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: isCompact ? 24 : 30,
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _barLabel(value.toInt(), isCompact: isCompact),
                              style: TextStyle(fontSize: isCompact ? 10 : 11),
                            ),
                          ),
                        ),
                      ),
                    ),
                    barGroups: [
                      BarChartGroupData(
                        x: 0,
                        barRods: [
                          BarChartRodData(
                            toY: bacCount.toDouble(),
                            width: isCompact ? 18 : 22,
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.orange,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 1,
                        barRods: [
                          BarChartRodData(
                            toY: licenceCount.toDouble(),
                            width: isCompact ? 18 : 22,
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.indigo,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 2,
                        barRods: [
                          BarChartRodData(
                            toY: masterCount.toDouble(),
                            width: isCompact ? 18 : 22,
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      BarChartGroupData(
                        x: 3,
                        barRods: [
                          BarChartRodData(
                            toY: doctoratCount.toDouble(),
                            width: isCompact ? 18 : 22,
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _calculateMaxY(List<double> values) {
    final max = values.reduce((a, b) => a > b ? a : b);
    return max < 5 ? 5 : max + 2;
  }

  String _barLabel(int index, {required bool isCompact}) {
    switch (index) {
      case 0:
        return 'Bac';
      case 1:
        return isCompact ? 'Lic.' : 'Licence';
      case 2:
        return 'Master';
      case 3:
        return isCompact ? 'PhD' : 'Doctorat';
      default:
        return '';
    }
  }
}

class UsersRolePieChart extends StatelessWidget {
  final int students;
  final int companies;
  final int admins;

  const UsersRolePieChart({
    super.key,
    required this.students,
    required this.companies,
    required this.admins,
  });

  @override
  Widget build(BuildContext context) {
    final total = students + companies + admins;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AdminPalette.border.withValues(alpha: 0.92),
            ),
            boxShadow: AdminPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.pie_chart, color: AdminPalette.activity, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Users Distribution',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AdminPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: isCompact ? 220 : 240,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: isCompact ? 36 : 42,
                    sectionsSpace: 3,
                    sections: [
                      PieChartSectionData(
                        color: Colors.blue,
                        value: students.toDouble(),
                        title: total == 0
                            ? '0%'
                            : '${((students / total) * 100).toStringAsFixed(0)}%',
                        radius: isCompact ? 52 : 58,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.teal,
                        value: companies.toDouble(),
                        title: total == 0
                            ? '0%'
                            : '${((companies / total) * 100).toStringAsFixed(0)}%',
                        radius: isCompact ? 52 : 58,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PieChartSectionData(
                        color: AdminPalette.accent,
                        value: admins.toDouble(),
                        title: total == 0
                            ? '0%'
                            : '${((admins / total) * 100).toStringAsFixed(0)}%',
                        radius: isCompact ? 52 : 58,
                        titleStyle: TextStyle(
                          color: Colors.white,
                          fontSize: isCompact ? 11 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _legendItem(Colors.blue, 'Students', students),
                  _legendItem(Colors.teal, 'Companies', companies),
                  _legendItem(AdminPalette.accent, 'Admins', admins),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendItem(Color color, String label, int value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: 6),
        Text('$label: $value'),
      ],
    );
  }
}

class MonthlyRegistrationsLineChart extends StatelessWidget {
  final List<dynamic> monthlyData;

  const MonthlyRegistrationsLineChart({super.key, required this.monthlyData});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final maxY = _maxY(monthlyData);
        final yInterval = _leftAxisInterval(maxY);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminPalette.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AdminPalette.border.withValues(alpha: 0.92),
            ),
            boxShadow: AdminPalette.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart, color: AdminPalette.success, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Monthly Registrations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AdminPalette.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: isCompact ? 240 : 260,
                child: LineChart(
                  LineChartData(
                    minX: 0,
                    maxX: monthlyData.isEmpty
                        ? 11
                        : (monthlyData.length - 1).toDouble(),
                    minY: 0,
                    maxY: maxY,
                    clipData: const FlClipData.all(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: yInterval,
                    ),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: isCompact ? 34 : 40,
                          interval: yInterval,
                          getTitlesWidget: (value, meta) {
                            if (value < 0 || value > maxY) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Text(
                                value.toInt().toString(),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: isCompact ? 10 : 11,
                                  color: AdminPalette.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: isCompact ? 28 : 32,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index < 0 || index >= monthlyData.length) {
                              return const SizedBox.shrink();
                            }
                            if (isCompact && index.isOdd) {
                              return const SizedBox.shrink();
                            }

                            final item =
                                monthlyData[index] as Map<String, dynamic>;
                            final month = '${item['month'] ?? ''}';
                            final label = isCompact && month.length > 3
                                ? month.substring(0, 3)
                                : month;

                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                label,
                                style: TextStyle(fontSize: isCompact ? 9 : 10),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        isCurved: true,
                        curveSmoothness: 0.18,
                        preventCurveOverShooting: true,
                        preventCurveOvershootingThreshold: 4,
                        color: AdminPalette.success,
                        barWidth: 3,
                        spots: List.generate(monthlyData.length, (index) {
                          final item =
                              monthlyData[index] as Map<String, dynamic>;
                          return FlSpot(
                            index.toDouble(),
                            (item['count'] ?? 0).toDouble(),
                          );
                        }),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AdminPalette.success.withValues(alpha: 0.10),
                        ),
                        dotData: FlDotData(show: !isCompact),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _maxY(List<dynamic> data) {
    double max = 0;
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final value = (item['count'] ?? 0).toDouble();
        if (value > max) {
          max = value;
        }
      }
    }

    if (max <= 5) {
      return 5;
    }

    final interval = _leftAxisInterval(max);
    return (max / interval).ceil() * interval;
  }

  double _leftAxisInterval(double max) {
    if (max <= 5) {
      return 1;
    }
    if (max <= 12) {
      return 2;
    }
    if (max <= 30) {
      return 5;
    }
    if (max <= 60) {
      return 10;
    }
    if (max <= 120) {
      return 20;
    }
    return 50;
  }
}
