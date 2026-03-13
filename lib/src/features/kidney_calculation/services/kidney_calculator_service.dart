// lib/src/features/kidney_calculation/services/kidney_calculator_service.dart

import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_diet_nutrition_model.dart';

/// Layanan kalkulasi kebutuhan protein dan BMR untuk diet ginjal kronis.
class KidneyCalculatorService {
  /// Menghitung BBI, kebutuhan protein, BMR, dan merekomendasikan level diet.
  ///
  /// - [height]        : Tinggi badan dalam cm.
  /// - [gender]        : 'Laki-laki' atau 'Perempuan'.
  /// - [age]           : Usia dalam tahun.
  /// - [isDialysis]    : `true` jika pasien menjalani hemodialisis.
  /// - [proteinFactor] : Wajib diisi jika [isDialysis] = `false` (pre-dialisis).
  KidneyDietResult calculate({
    required double height,
    required bool isDialysis,
    required String gender,
    required int age,
    double? proteinFactor,
  }) {
    final double idealBodyWeight = _calculateIdealBodyWeight(height, gender);

    // BMR dihitung berdasarkan usia dan jenis kelamin
    final double bmr;
    if (gender == 'Laki-laki') {
      bmr = (age < 60) ? idealBodyWeight * 35 : idealBodyWeight * 30;
    } else {
      bmr = (age < 60) ? idealBodyWeight * 30 : idealBodyWeight * 25;
    }

    // Kebutuhan protein
    final double proteinNeeds;
    if (isDialysis) {
      // Hemodialisis: 1.2 g/kg BBI (standar buku panduan)
      proteinNeeds = 1.2 * idealBodyWeight;
    } else {
      assert(proteinFactor != null,
          'proteinFactor harus diisi untuk pasien pre-dialisis.');
      proteinNeeds = proteinFactor! * idealBodyWeight;
    }

    final int recommendedDiet = _getRecommendedDiet(proteinNeeds, isDialysis);
    final KidneyDietNutrition? nutritionInfo = kidneyDietData[recommendedDiet];

    return KidneyDietResult(
      idealBodyWeight: idealBodyWeight,
      proteinNeeds: proteinNeeds,
      bmr: bmr,
      recommendedDiet: recommendedDiet,
      isDialysis: isDialysis,
      nutritionInfo: nutritionInfo,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Rumus Broca, dibedakan berdasarkan jenis kelamin dan tinggi badan.
  double _calculateIdealBodyWeight(double height, String gender) {
    if (gender == 'Laki-laki') {
      return height >= 160 ? (height - 100) * 0.9 : height - 100;
    } else {
      return height >= 150 ? (height - 100) * 0.9 : height - 100;
    }
  }

  /// Menemukan level diet (dalam gram protein) yang paling dekat dengan hasil hitung.
  int _getRecommendedDiet(double calculatedProtein, bool isDialysis) {
    final List<int> options = isDialysis ? [60, 65, 70] : [30, 35, 40];
    return options.reduce(
      (a, b) => (a - calculatedProtein).abs() < (b - calculatedProtein).abs() ? a : b,
    );
  }
}