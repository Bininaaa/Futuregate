import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFFFF8C00), size: 20),
              SizedBox(width: 8),
              Text(
                'Students by Level Diagram',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _calculateMaxY(values),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        switch (value.toInt()) {
                          case 0:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Bac', style: TextStyle(fontSize: 11)),
                            );
                          case 1:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Licence', style: TextStyle(fontSize: 11)),
                            );
                          case 2:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Master', style: TextStyle(fontSize: 11)),
                            );
                          case 3:
                            return const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text('Doctorat', style: TextStyle(fontSize: 11)),
                            );
                          default:
                            return const SizedBox.shrink();
                        }
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: bacCount.toDouble(),
                        width: 22,
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
                        width: 22,
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
                        width: 22,
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
                        width: 22,
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
  }

  double _calculateMaxY(List<double> values) {
    final max = values.reduce((a, b) => a > b ? a : b);
    return max < 5 ? 5 : max + 2;
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: Colors.deepPurple, size: 20),
              SizedBox(width: 8),
              Text(
                'Users Distribution Diagram',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 3,
                sections: [
                  PieChartSectionData(
                    color: Colors.blue,
                    value: students.toDouble(),
                    title: total == 0
                        ? '0%'
                        : '${((students / total) * 100).toStringAsFixed(0)}%',
                    radius: 58,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    color: Colors.teal,
                    value: companies.toDouble(),
                    title: total == 0
                        ? '0%'
                        : '${((companies / total) * 100).toStringAsFixed(0)}%',
                    radius: 58,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    color: const Color(0xFFFF8C00),
                    value: admins.toDouble(),
                    title: total == 0
                        ? '0%'
                        : '${((admins / total) * 100).toStringAsFixed(0)}%',
                    radius: 58,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
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
              _legendItem(const Color(0xFFFF8C00), 'Admins', admins),
            ],
          ),
        ],
      ),
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

  const MonthlyRegistrationsLineChart({
    super.key,
    required this.monthlyData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.show_chart, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Monthly Registrations Diagram',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D1B4E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: monthlyData.isEmpty ? 11 : (monthlyData.length - 1).toDouble(),
                minY: 0,
                maxY: _maxY(monthlyData),
                gridData: FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 30),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= monthlyData.length) {
                          return const SizedBox.shrink();
                        }
                        final item = monthlyData[index] as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            item['month'] ?? '',
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    spots: List.generate(
                      monthlyData.length,
                      (index) {
                        final item = monthlyData[index] as Map<String, dynamic>;
                        return FlSpot(
                          index.toDouble(),
                          (item['count'] ?? 0).toDouble(),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withValues(alpha: 0.10),
                    ),
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _maxY(List<dynamic> data) {
    double max = 5;
    for (final item in data) {
      if (item is Map<String, dynamic>) {
        final value = (item['count'] ?? 0).toDouble();
        if (value > max) {
          max = value;
        }
      }
    }
    return max + 2;
  }
}
