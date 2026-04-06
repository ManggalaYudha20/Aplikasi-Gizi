// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\diabetes_calculation\presentation\widgets\dm_meal_plan_table.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/dm_meal_session_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/meal_distribution_model.dart';

// ---------------------------------------------------------------------------
// Semantic Key Constants — single source of truth untuk QA team.
// Didefinisikan di sini agar bisa dipakai oleh DmMealDistributionTable
// (mealRow) sekaligus diimpor di diabetes_calculation_page.dart (form keys).
// ---------------------------------------------------------------------------
class DmSemanticKeys {
  const DmSemanticKeys._();

  static const patientPicker = ValueKey('patientPicker');
  static const ageField = ValueKey('ageField');
  static const genderDropdown = ValueKey('genderDropdown');
  static const weightField = ValueKey('weightField');
  static const heightField = ValueKey('heightField');
  static const activityDropdown = ValueKey('activityDropdown');
  static const hospitalizedDropdown = ValueKey('hospitalizedDropdown');
  static const stressSlider = ValueKey('stressSlider');
  static const btnDownloadPdf = ValueKey('btnDownloadPdf');

  /// Key dinamis per baris distribusi waktu makan (e.g. 'mealRow_Pagi').
  static ValueKey mealRow(String mealName) =>
      ValueKey('mealRow_${mealName.replaceAll(' ', '_')}');
}

// ---------------------------------------------------------------------------
// DmMealDistributionTile
// ---------------------------------------------------------------------------

/// ExpansionTile yang membungkus [DmMealDistributionTable] beserta
/// judul dan dekorasi warna hijau.
class DmMealDistributionTile extends StatelessWidget {
  final DiabetesCalculationResult result;

  const DmMealDistributionTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final dist = result.dailyMealDistribution;
    final hPad = MediaQuery.sizeOf(context).width * 0.04;

    return ExpansionTile(
      title: Text('Pembagian Makanan\nSehari-hari (${dist.calorieLevel})'),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(hPad),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Pembagian Makanan Sehari-hari \n (${dist.calorieLevel})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const Divider(height: 24),
              DmMealDistributionTable(distribution: dist),
              const SizedBox(height: 8),
              const Text(
                'Keterangan : (P = Penukar) (S = Sekehendak) ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembagian makanan sehari tiap Standar Diet Diabetes Melitus dan Nilai Gizi (dalam satuan penukar II)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// DmMealDistributionTable
// ---------------------------------------------------------------------------

/// Tabel bergrid yang menampilkan distribusi bahan makanan setiap waktu makan.
/// Setiap baris grup diberi [Semantics] + [ValueKey] via [DmSemanticKeys.mealRow]
/// agar dapat diidentifikasi oleh QA / Katalon.
class DmMealDistributionTable extends StatelessWidget {
  final DailyMealDistribution distribution;

  const DmMealDistributionTable({super.key, required this.distribution});

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(double v) =>
      v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _buildRowGroup(
    String mealName,
    MealDistribution meal, {
    required Color color,
  }) {
    const cellStyle = TextStyle(fontSize: 12);
    const cellPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0);
    final List<Widget> foodRows = [];

    void addRow(String foodName, dynamic value) {
      foodRows.add(
        Container(
          padding: cellPadding,
          decoration: BoxDecoration(
            color: color,
            border: Border(
              top: BorderSide(color: Colors.grey.shade300, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(flex: 3, child: Text(foodName, style: cellStyle)),
              Expanded(
                flex: 2,
                child: Text(
                  value is String ? value : '${_fmt(value as double)} P',
                  textAlign: TextAlign.center,
                  style: cellStyle,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (meal.nasiP > 0) addRow('Nasi', meal.nasiP);
    if (meal.ikanP > 0) addRow('Ikan', meal.ikanP);
    if (meal.dagingP > 0) addRow('Daging', meal.dagingP);
    if (meal.tempeP > 0) addRow('Tempe', meal.tempeP);
    if (meal.sayuranA.isNotEmpty) addRow('Sayuran A', meal.sayuranA);
    if (meal.sayuranB > 0) addRow('Sayuran B', meal.sayuranB);
    if (meal.buah > 0) addRow('Buah', meal.buah);
    if (meal.susu > 0) addRow('Susu', meal.susu);
    if (meal.minyak > 0) addRow('Minyak', meal.minyak);

    if (foodRows.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: 'Baris distribusi makanan $mealName',
      container: true,
      child: IntrinsicHeight(
        key: DmSemanticKeys.mealRow(mealName),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Kolom waktu makan ──────────────────────────────────────────
            Container(
              width: 80,
              padding: cellPadding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: Text(
                mealName,
                textAlign: TextAlign.center,
                style: cellStyle,
              ),
            ),
            // ── Kolom bahan makanan & penukar ──────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: foodRows,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    const cellPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        children: [
          // Header baris
          Container(
            padding: cellPadding,
            color: Colors.green.shade100,
            child: const Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'Waktu',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Bahan Makanan',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Penukar',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          _buildRowGroup('Pagi', distribution.pagi, color: Colors.white),
          _buildRowGroup(
            'Pukul 10.00',
            distribution.snackPagi,
            color: Colors.grey.shade100,
          ),
          _buildRowGroup('Siang', distribution.siang, color: Colors.white),
          _buildRowGroup(
            'Pukul 16.00',
            distribution.snackSore,
            color: Colors.grey.shade100,
          ),
          _buildRowGroup('Malam', distribution.malam, color: Colors.white),
        ],
      ),
    );
  }
}
