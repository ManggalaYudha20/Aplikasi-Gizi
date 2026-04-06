// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\statistics\presentation\widgets\stat_bar_chart_widget.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Pure chart widget – renders a [BarChart] from [dataMap] + [colors].
class StatBarChartWidget extends StatelessWidget {
  const StatBarChartWidget({
    super.key,
    required this.dataMap,
    required this.colors,
  });

  final Map<String, double> dataMap;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    if (dataMap.length == 1 && dataMap.keys.first == "Tidak ada data") {
      return const Center(child: Text("Data Kosong"));
    }

    double maxY = dataMap.values.fold(0, (prev, v) => v > prev ? v : prev);
    maxY = maxY + (maxY * 0.2);
    if (maxY == 0) maxY = 10;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.blueGrey,
            getTooltipItem: (group, _, rod, __) {
              final String label = dataMap.keys.elementAt(group.x.toInt());
              return BarTooltipItem(
                '$label\n',
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                children: [
                  TextSpan(
                    text: rod.toY.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.yellow,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= dataMap.length) {
                  return const SizedBox();
                }
                String text = dataMap.keys.elementAt(index);
                if (text.length > 5) text = "${text.substring(0, 6)}..";
                return SideTitleWidget(
                  meta: meta,
                  space: 4,
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value == value.toInt().toDouble()) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dataMap.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dataMap.values.elementAt(index),
                color: colors[index % colors.length],
                width: 20,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(6),
                  topRight: Radius.circular(6),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
