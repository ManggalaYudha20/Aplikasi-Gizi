// lib/src/features/kidney_calculation/presentation/widgets/kidney_result_card.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_diet_nutrition_model.dart';

/// Warna hijau utama modul Diet Ginjal Kronis.
const kKidneyGreen = Color.fromARGB(255, 0, 148, 68);

/// Kartu ringkasan hasil perhitungan BBI, IMT, BMR, dan rekomendasi diet ginjal.
///
/// Gunakan:
/// ```dart
/// KidneyResultCard(
///   result: _result!,
///   currentWeight: double.parse(_currentWeightController.text),
///   proteinFactorLabel: _proteinFactorController.text,
/// )
/// ```
class KidneyResultCard extends StatelessWidget {
  final KidneyDietResult result;

  /// Berat badan aktual pasien (dari form input).
  final double currentWeight;

  /// Tinggi badan pasien dalam cm (untuk hitung IMT).
  final double heightCm;

  /// Label faktor protein dari dropdown, mis. '0.6 (Rendah)'.
  final String proteinFactorLabel;

  /// GlobalKey yang digunakan halaman induk untuk auto-scroll ke kartu ini.
  final Key? cardKey;

  const KidneyResultCard({
    super.key,
    required this.result,
    required this.currentWeight,
    required this.heightCm,
    required this.proteinFactorLabel,
    this.cardKey,
  });

  // ── IMT calculation ─────────────────────────────────────────────────────────
  (double imt, String status) _imtInfo() {
    final heightM = heightCm / 100;
    if (currentWeight <= 0 || heightM <= 0) return (0, '-');
    final imt = currentWeight / (heightM * heightM);
    final status = imt < 18.5
        ? 'BB Kurang'
        : imt < 25
            ? 'Normal'
            : imt < 30
                ? 'BB Lebih'
                : 'Obesitas';
    return (imt, status);
  }

  @override
  Widget build(BuildContext context) {
    final proteinFactorValue = proteinFactorLabel.split(' ')[0];
    final (imt, nutritionalStatus) = _imtInfo();

    final recommendationText = result.isDialysis
        ? 'Diet Hemodialisis (HD)\nProtein ${result.recommendedDiet} gram'
        : 'Diet Protein Rendah ${result.recommendedDiet} gram';

    final factorExplanationText = result.isDialysis
        ? '*Pasien hemodialisis membutuhkan asupan protein lebih tinggi (1.2 g/kg BBI).'
        : '*Pasien pre-dialisis membutuhkan asupan protein lebih rendah '
          '(${proteinFactorValue}g/kg BBI) untuk memperlambat laju penyakit.';

    return Container(
      key: cardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kKidneyGreen.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kKidneyGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hasil Perhitungan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: kKidneyGreen,
            ),
          ),
          const Divider(height: 24),
          _row('Berat Badan Ideal (BBI)',
              '${result.idealBodyWeight.toStringAsFixed(1)} kg', 'result_bbi'),
          _row('Berat Badan Aktual',
              '${currentWeight.toStringAsFixed(1)} kg', 'result_bb_aktual'),
          _row('Indeks Massa Tubuh (IMT)',
              '${imt.toStringAsFixed(1)} ($nutritionalStatus)', 'result_imt'),
          if (result.bmr > 0)
            _row('BMR', '${result.bmr.toStringAsFixed(1)} kkal/hari', 'result_bmr'),
          _row('Kebutuhan Protein Harian',
              '${result.proteinNeeds.toStringAsFixed(1)} gram', 'result_protein_needs'),
          const SizedBox(height: 16),
          const Text(
            'Rekomendasi Diet:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            key: const ValueKey('result_recommendation_box'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kKidneyGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              recommendationText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            factorExplanationText,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Baris label–nilai dengan ValueKey untuk QA / Katalon.
  Widget _row(String label, String value, String keySuffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            key: ValueKey('value_$keySuffix'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}