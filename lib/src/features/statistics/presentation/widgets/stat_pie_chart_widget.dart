// lib/src/features/statistics/presentation/widgets/stat_pie_chart_widget.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Pure chart widget – renders a [PieChart] from [dataMap] + [colors].
///
/// Touch state is managed externally so that the parent can sync the same
/// [touchedIndex] with the legend list.
class StatPieChartWidget extends StatelessWidget {
  const StatPieChartWidget({
    super.key,
    required this.dataMap,
    required this.colors,
    required this.touchedIndex,
    required this.onTouch,
  });

  final Map<String, double> dataMap;
  final List<Color> colors;

  /// Index of the currently-touched pie slice, or `-1` when nothing is touched.
  final int touchedIndex;

  /// Called with the newly-touched index (or `-1` on release).
  final ValueChanged<int> onTouch;

  @override
  Widget build(BuildContext context) {
    final double total =
        dataMap.values.fold(0, (prev, item) => prev + item);

    if (total == 0 ||
        (dataMap.length == 1 && dataMap.keys.first == "Tidak ada data")) {
      return const Center(child: Text("Data Kosong"));
    }

    return PieChart(
      PieChartData(
        pieTouchData: PieTouchData(
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              onTouch(-1);
              return;
            }
            onTouch(pieTouchResponse.touchedSection!.touchedSectionIndex);
          },
        ),
        borderData: FlBorderData(show: false),
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        sections: List.generate(dataMap.length, (i) {
          final bool isTouched = i == touchedIndex;
          final double value = dataMap.values.elementAt(i);
          final String percentage =
              total > 0 ? (value / total * 100).toStringAsFixed(1) : "0";

          return PieChartSectionData(
            color: colors[i % colors.length],
            value: value,
            title: '$percentage%',
            radius: isTouched ? 110.0 : 100.0,
            titleStyle: TextStyle(
              fontSize: isTouched ? 20.0 : 14.0,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          );
        }),
      ),
    );
  }
}