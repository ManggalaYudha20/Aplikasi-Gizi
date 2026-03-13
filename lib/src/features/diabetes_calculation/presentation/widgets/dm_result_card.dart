// lib/src/features/diabetes_calculation/presentation/widgets/dm_result_card.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/dm_meal_session_model.dart';

/// Warna hijau utama modul Diabetes Melitus.
const kDmGreen = Color.fromARGB(255, 0, 148, 68);

/// Kartu ringkasan hasil total kebutuhan energi pasien diabetes.
///
/// Gunakan:
/// ```dart
/// DmResultCard(
///   result: _result!,
///   isHospitalized: _hospitalizedStatusController.text == 'Ya',
///   stressMetabolic: _stressMetabolic,
/// )
/// ```
class DmResultCard extends StatelessWidget {
  final DiabetesCalculationResult result;

  /// `true` jika pasien berstatus rawat inap (menampilkan baris koreksi stress metabolik).
  final bool isHospitalized;

  /// Nilai slider stress metabolik dalam persen (10–40).
  final double stressMetabolic;

  const DmResultCard({
    super.key,
    required this.result,
    required this.isHospitalized,
    required this.stressMetabolic,
  });

  @override
  Widget build(BuildContext context) {
    final hPad = MediaQuery.sizeOf(context).width * 0.04;

    return Container(
      padding: EdgeInsets.all(hPad),
      decoration: BoxDecoration(
        color: kDmGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: const Border.fromBorderSide(BorderSide(color: kDmGreen)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Hasil Total Kebutuhan Energi',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kDmGreen,
              ),
            ),
          ),
          const Divider(height: 24),
          const SizedBox(height: 8),
          _row('BB Ideal', '${result.bbIdeal.round()} kg'),
          _row('BMR', '${result.bmr.round()} kkal/hari'),
          _row('Kategori IMT', result.bmiCategory),
          _row('Koreksi Aktivitas', '+${result.activityCorrection.round()} kkal/hari'),
          if (result.ageCorrection > 0)
            _row('Koreksi Usia', '-${result.ageCorrection.round()} kkal/hari'),
          if (result.weightCorrection != 0)
            _row(
              'Koreksi Berat Badan',
              '${result.weightCorrection > 0 ? '+' : ''}${result.weightCorrection.round()} kkal/hari',
            ),
          if (isHospitalized)
            _row(
              'Koreksi Stress Metabolik',
              '+${((stressMetabolic / 100) * result.bmr).round()} kkal/hari',
            ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Total Kalori: ${result.totalCalories.round()} kkal/hari',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Total kebutuhan energi digunakan untuk mengetahui jenis diet Diabetes Melitus',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  /// Baris label–nilai yang dipakai berulang di dalam kartu.
  Widget _row(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}