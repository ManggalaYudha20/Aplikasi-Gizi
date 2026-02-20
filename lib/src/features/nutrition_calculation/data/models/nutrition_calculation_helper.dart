// lib\src\features\nutrition_calculation\data\models\nutrition_calculation_helper.dart

import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';

class NutritionCalculationHelper {
  
  static int calculateAgeInMonths(DateTime birthDate, DateTime checkDate) {
    final difference = checkDate.difference(birthDate);
    final days = difference.inDays;
    return (days / 30.44).round(); // Rata-rata hari per bulan
  }

   static Map<String, dynamic> calculateIMTU5To18({
    required int ageYears,
    required int ageMonthsRemainder, // Sisa bulan setelah dikurangi tahun penuh (0–11)
    required double bmi,
    required String gender,
  }) {
    final String ageKey = '$ageYears-$ageMonthsRemainder';
    final bool isMale = gender.toLowerCase().contains('laki') ||
        gender.toLowerCase().contains('pria') ||
        gender.toLowerCase() == 'l';

    final List<double>? ref = isMale
        ? NutritionStatusData.imtUBoys5To18[ageKey]
        : NutritionStatusData.imtUGirls5To18[ageKey];

    if (ref == null) {
      return {
        'zScore': null,
        'category': 'Data referensi tidak tersedia',
        'bmi': bmi,
      };
    }

    try {
      final double median = ref[3];
      final double sdPos = ref[4] - median; // Selisih median ke +1 SD
      final double sdNeg = median - ref[2]; // Selisih -1 SD ke median
      final double sd = bmi >= median ? sdPos : sdNeg;
      final double zScore = (bmi - median) / sd;

      return {
        'zScore': zScore,
        'category': _getIMTU5To18Category(zScore),
        'bmi': bmi,
      };
    } catch (_) {
      return {
        'zScore': null,
        'category': 'Error perhitungan',
        'bmi': bmi,
      };
    }
  }

  // Kategori IMT/U khusus anak 5–18 tahun (WHO 2007)
  static String _getIMTU5To18Category(double zScore) {
    if (zScore < -3) return 'Gizi buruk';
    if (zScore < -2) return 'Gizi kurang';
    if (zScore <= 1) return 'Gizi baik';
    if (zScore <= 2) return 'Gizi lebih';
    return 'Obesitas (obese)';
  }

  static Map<String, dynamic> calculateAll(
      {required DateTime birthDate,
      required DateTime checkDate,
      required double weight,
      required double height,
      required String gender}) {
    
    final int ageInMonths = calculateAgeInMonths(birthDate, checkDate);
    final double bmi = weight / ((height / 100) * (height / 100));

    return {
      'bbPerU': _calculateWeightForAge(ageInMonths, weight, gender),
      'tbPerU': _calculateHeightForAge(ageInMonths, height, gender),
      'bbPerTB': _calculateWeightForHeight(height, weight, gender),
      'imtPerU': _calculateBMIForAge(ageInMonths, bmi, gender),
      'ageInMonths': ageInMonths,
      'bmi': bmi,
    };
  }

  // --- LOGIKA INTERNAL (Diambil dari nutrition_status_form_page.dart) ---

  static Map<String, dynamic> _calculateWeightForAge(int age, double weight, String gender) {
    final referenceData = gender == 'Laki-laki' ? NutritionStatusData.bbUBoys : NutritionStatusData.bbUGirls;
    if (!referenceData.containsKey(age)) return {'zScore': null, 'category': 'Data tidak tersedia'};
    
    final percentiles = referenceData[age]!;
    final median = percentiles[3];
    final sd = percentiles[4] - median; // Menggunakan +1 SD sebagai acuan deviasi
    final zScore = (weight - median) / sd;

    return {'zScore': zScore, 'category': _getWeightForAgeCategory(zScore)};
  }

  static Map<String, dynamic> _calculateHeightForAge(int age, double height, String gender) {
    final referenceData = gender == 'Laki-laki' ? NutritionStatusData.pbTbUBoys : NutritionStatusData.pbTbUGirls;
    if (!referenceData.containsKey(age)) return {'zScore': null, 'category': 'Data tidak tersedia'};

    final percentiles = referenceData[age]!;
    final median = percentiles[3];
    final sd = percentiles[4] - median;
    final zScore = (height - median) / sd;

    return {'zScore': zScore, 'category': _getHeightForAgeCategory(zScore)};
  }

  static Map<String, dynamic> _calculateWeightForHeight(double height, double weight, String gender) {
    final referenceData = gender == 'Laki-laki' ? NutritionStatusData.bbPbTbUBoys : NutritionStatusData.bbPbTbUGirls;
    
    // Mencari tinggi badan terdekat (interpolasi sederhana)
    double closestHeight = referenceData.keys.first;
    double minDifference = (height - closestHeight).abs();
    for (final h in referenceData.keys) {
      final difference = (height - h).abs();
      if (difference < minDifference) {
        minDifference = difference;
        closestHeight = h;
      }
    }
    
    if (minDifference > 2.0) return {'zScore': null, 'category': 'Data tidak tersedia'}; // Toleransi 2cm

    final percentiles = referenceData[closestHeight]!;
    final median = percentiles[3];
    final sd = percentiles[4] - median;
    final zScore = (weight - median) / sd;

    return {'zScore': zScore, 'category': _getWeightForHeightCategory(zScore)};
  }

  static Map<String, dynamic> _calculateBMIForAge(int age, double bmi, String gender) {
    final referenceData = gender == 'Laki-laki' ? NutritionStatusData.imtUBoys : NutritionStatusData.imtUGirls;
    if (!referenceData.containsKey(age)) return {'zScore': null, 'category': 'Data tidak tersedia'};

    final percentiles = referenceData[age]!;
    final median = percentiles[3];
    final sd = percentiles[4] - median;
    final zScore = (bmi - median) / sd;

    return {'zScore': zScore, 'category': _getBMIForAgeCategory(zScore)};
  }

  // --- Interpretasi Kategori ---
  static String _getWeightForAgeCategory(double zScore) {
    if (zScore < -3) return 'Sangat kurang (severely underweight)';
    if (zScore < -2) return 'Kurang (underweight)';
    if (zScore <= 1) return 'Normal';
    return 'Risiko Berat badan lebih';
  }

  static String _getHeightForAgeCategory(double zScore) {
    if (zScore < -3) return 'Sangat pendek (severely stunted)';
    if (zScore < -2) return 'Pendek (stunted)';
    if (zScore <= 3) return 'Normal';
    return 'Tinggi';
  }

  static String _getWeightForHeightCategory(double zScore) {
    if (zScore < -3) return 'Gizi buruk';
    if (zScore < -2) return 'Gizi kurang';
    if (zScore <= 1) return 'Gizi baik';
    if (zScore <= 2) return 'Berisiko gizi lebih';
    if (zScore <= 3) return 'Gizi lebih';
    return 'Obesitas';
  }

  static String _getBMIForAgeCategory(double zScore) {
    return _getWeightForHeightCategory(zScore); // Kategorinya mirip
  }

  // --- FUNGSI PUBLIK BARU (Pindahan dari detail page) ---
  static String? determineHeightCategory(double? zScore) {
    if (zScore == null) return null;
    if (zScore < -3) return 'Sangat Pendek (severely stunted)';
    if (zScore < -2) return 'Pendek (stunted)';
    if (zScore <= 3) return 'Normal';
    return 'Tinggi';
  }
}