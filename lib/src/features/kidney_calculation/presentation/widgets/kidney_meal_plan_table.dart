// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\kidney_calculation\presentation\widgets\kidney_meal_plan_table.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_standard_food_model.dart';

/// Tabel bahan makanan standar sehari berdasarkan level diet ginjal.
///
/// Biasanya dibungkus [ExpansionTile] di halaman induk:
/// ```dart
/// ExpansionTile(
///   title: Text('Bahan Makanan Sehari'),
///   children: [
///     KidneyMealPlanTable(
///       mealPlan: _mealPlan!,
///       dietProteinGram: _result!.recommendedDiet,
///     ),
///   ],
/// )
/// ```
class KidneyMealPlanTable extends StatelessWidget {
  final List<KidneyStandardFoodItem> mealPlan;
  final int dietProteinGram;

  const KidneyMealPlanTable({
    super.key,
    required this.mealPlan,
    required this.dietProteinGram,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bahan Makanan Sehari (Diet Protein ${dietProteinGram}g)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const Divider(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            border: TableBorder.all(color: Colors.purple.shade100, width: 1),
            children: [
              // Header row
              const TableRow(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 196, 86, 216),
                ),
                children: [
                  _HeaderCell('Bahan'),
                  _HeaderCell('Berat (g)'),
                  _HeaderCell('URT'),
                ],
              ),
              // Data rows
              ...mealPlan.map(
                (item) => TableRow(
                  children: [
                    _DataCell(item.name),
                    _DataCell(item.weight.toString(), center: true),
                    _DataCell(item.urt),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Private helper widgets (hanya dipakai di file ini) ──────────────────────

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool center;
  const _DataCell(this.text, {this.center = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(text, textAlign: center ? TextAlign.center : TextAlign.start),
    );
  }
}
