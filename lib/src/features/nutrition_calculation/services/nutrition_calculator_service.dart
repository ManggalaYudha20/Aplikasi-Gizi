// lib/src/features/nutrition_calculation/services/nutrition_calculator_service.dart
//
// ─── ATURAN KETAT ───────────────────────────────────────────────────────────
// File ini adalah Pure Dart — DILARANG mengimpor 'package:flutter/material.dart'
// atau package Flutter apapun.
// ────────────────────────────────────────────────────────────────────────────
//
// RIWAYAT PERUBAHAN:
// - Sebelumnya : lib/src/features/nutrition_calculation/data/models/nutrition_calculation_helper.dart
// - Sekarang   : lib/src/features/nutrition_calculation/services/nutrition_calculator_service.dart
//
// Perubahan dari versi helper:
// 1. Class direname dari NutritionCalculationHelper → NutritionCalculatorService
// 2. Semua method internal (_calculateWeightForAge, dll) dipreservasi utuh
// 3. Ditambahkan value object NutritionStatusResult & NutritionAllResult
//    untuk menggantikan Map<String, dynamic> yang tidak type-safe
// 4. Ditambahkan method calculateIMTUFromRawInputs sebagai entry-point
//    tunggal untuk halaman IMT/U
// ────────────────────────────────────────────────────────────────────────────

import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';

/// Service utama untuk kalkulasi status gizi berbasis tabel Z-Score WHO.
///
/// Mencakup:
/// - Status Gizi (BB/U, TB/U, BB/TB, IMT/U) untuk usia 0–60 bulan
/// - IMT/U untuk usia 5–18 tahun
class NutritionCalculatorService {
  const NutritionCalculatorService._();

  // ── KONSTANTA GENDER ──────────────────────────────────────────────────────

  static const String genderMale   = 'Laki-laki';
  static const String genderFemale = 'Perempuan';

  // ── KALKULASI USIA ────────────────────────────────────────────────────────

  /// Menghitung usia dalam bulan dari tanggal lahir ke tanggal pemeriksaan.
  ///
  /// Menggunakan rata-rata 30.44 hari/bulan (365.25 / 12) sesuai konvensi WHO.
  static int calculateAgeInMonths({
    required DateTime birthDate,
    required DateTime checkDate,
  }) {
    final int days = checkDate.difference(birthDate).inDays;
    return (days / 30.44).round();
  }

  // ── KALKULASI STATUS GIZI (0–60 BULAN) ───────────────────────────────────

  /// Menghitung seluruh indikator status gizi sekaligus untuk usia 0–60 bulan.
  ///
  /// Mengembalikan [NutritionAllResult] yang berisi semua indikator:
  /// BB/U, TB/U, BB/TB, dan IMT/U.
  static NutritionAllResult calculateAll({
    required DateTime birthDate,
    required DateTime checkDate,
    required double   weightKg,
    required double   heightCm,
    required String   gender,
  }) {
    final int ageInMonths = calculateAgeInMonths(
      birthDate: birthDate,
      checkDate: checkDate,
    );
    final double bmi = weightKg / ((heightCm / 100.0) * (heightCm / 100.0));

    return NutritionAllResult(
      ageInMonths: ageInMonths,
      bmi: bmi,
      weightForAge: _calculateWeightForAge(ageInMonths, weightKg, gender),
      heightForAge: _calculateHeightForAge(ageInMonths, heightCm, gender),
      weightForHeight: _calculateWeightForHeight(heightCm, weightKg, gender),
      bmiForAge: _calculateBMIForAge(ageInMonths, bmi, gender),
    );
  }

  // ── KALKULASI IMT/U (5–18 TAHUN) ─────────────────────────────────────────

  /// Menghitung Z-Score IMT/U untuk anak usia 5–18 tahun.
  ///
  /// Entry-point untuk [IMTUFormPage]. Menerima input mentah dari form UI,
  /// menghitung BMI, lalu melakukan lookup ke tabel referensi WHO 2007.
  ///
  /// [ageYears]         : Tahun penuh usia anak.
  /// [ageMonthsRemainder] : Sisa bulan setelah dikurangi tahun penuh (0–11).
  /// [weightKg]         : Berat badan dalam kilogram.
  /// [heightCm]         : Tinggi badan dalam sentimeter.
  /// [gender]           : Gunakan [genderMale] atau [genderFemale].
  static ImtuResult calculateIMTUFromRawInputs({
    required int    ageYears,
    required int    ageMonthsRemainder,
    required double weightKg,
    required double heightCm,
    required String gender,
  }) {
    final double bmi = weightKg / ((heightCm / 100.0) * (heightCm / 100.0));
    return calculateIMTU5To18(
      ageYears: ageYears,
      ageMonthsRemainder: ageMonthsRemainder,
      bmi: bmi,
      gender: gender,
    );
  }

  /// Menghitung Z-Score IMT/U dari nilai BMI yang sudah diketahui.
  ///
  /// Dipindahkan dari [NutritionCalculationHelper.calculateIMTU5To18].
  /// Logika perhitungan Z-Score dipreservasi 100% tanpa perubahan.
  static ImtuResult calculateIMTU5To18({
    required int    ageYears,
    required int    ageMonthsRemainder,
    required double bmi,
    required String gender,
  }) {
    final String ageKey = '$ageYears-$ageMonthsRemainder';
    final bool isMale = gender == genderMale;

    final List<double>? ref = isMale
        ? NutritionStatusData.imtUBoys5To18[ageKey]
        : NutritionStatusData.imtUGirls5To18[ageKey];

    if (ref == null) {
      return ImtuResult(
        ageKey: ageKey,
        bmi: bmi,
        zScore: null,
        category: 'Data referensi tidak tersedia untuk usia ini',
      );
    }

    try {
      final double median = ref[3];
      // Menggunakan SD asimetris (sesuai metode LMS WHO):
      //   Jika BMI ≥ median, gunakan selisih ke +1 SD sebagai SD
      //   Jika BMI <  median, gunakan selisih dari -1 SD ke median sebagai SD
      final double sdPos  = ref[4] - median;
      final double sdNeg  = median - ref[2];
      final double sd     = bmi >= median ? sdPos : sdNeg;
      final double zScore = (bmi - median) / sd;

      return ImtuResult(
        ageKey: ageKey,
        bmi: bmi,
        zScore: zScore,
        category: _getIMTU5To18Category(zScore),
      );
    } catch (_) {
      return ImtuResult(
        ageKey: ageKey,
        bmi: bmi,
        zScore: null,
        category: 'Error perhitungan',
      );
    }
  }

  // ── LOGIKA INTERNAL — STATUS GIZI 0–60 BULAN ─────────────────────────────
  // Semua method di bawah ini dipreservasi dari nutrition_calculation_helper.dart
  // dengan perubahan minimal: return type diganti ke value object terstandarisasi.

  static NutritionStatusResult _calculateWeightForAge(
      int age, double weight, String gender) {
    final referenceData = gender == genderMale
        ? NutritionStatusData.bbUBoys
        : NutritionStatusData.bbUGirls;

    if (!referenceData.containsKey(age)) {
      return const NutritionStatusResult(zScore: null, category: 'Data tidak tersedia');
    }

    final percentiles = referenceData[age]!;
    final double median  = percentiles[3];
    final double sd      = percentiles[4] - median;
    final double zScore  = (weight - median) / sd;

    return NutritionStatusResult(
      zScore: zScore,
      category: _getWeightForAgeCategory(zScore),
    );
  }

  static NutritionStatusResult _calculateHeightForAge(
      int age, double height, String gender) {
    final referenceData = gender == genderMale
        ? NutritionStatusData.pbTbUBoys
        : NutritionStatusData.pbTbUGirls;

    if (!referenceData.containsKey(age)) {
      return const NutritionStatusResult(zScore: null, category: 'Data tidak tersedia');
    }

    final percentiles = referenceData[age]!;
    final double median = percentiles[3];
    final double sd     = percentiles[4] - median;
    final double zScore = (height - median) / sd;

    return NutritionStatusResult(
      zScore: zScore,
      category: _getHeightForAgeCategory(zScore),
    );
  }

  static NutritionStatusResult _calculateWeightForHeight(
      double height, double weight, String gender) {
    final referenceData = gender == genderMale
        ? NutritionStatusData.bbPbTbUBoys
        : NutritionStatusData.bbPbTbUGirls;

    // Mencari kunci tinggi badan terdekat (interpolasi sederhana)
    double closestHeight  = referenceData.keys.first;
    double minDifference  = (height - closestHeight).abs();

    for (final h in referenceData.keys) {
      final double diff = (height - h).abs();
      if (diff < minDifference) {
        minDifference = diff;
        closestHeight = h;
      }
    }

    // Toleransi 2 cm — di luar itu dianggap data tidak tersedia
    if (minDifference > 2.0) {
      return const NutritionStatusResult(zScore: null, category: 'Data tidak tersedia');
    }

    final percentiles = referenceData[closestHeight]!;
    final double median = percentiles[3];
    final double sd     = percentiles[4] - median;
    final double zScore = (weight - median) / sd;

    return NutritionStatusResult(
      zScore: zScore,
      category: _getWeightForHeightCategory(zScore),
    );
  }

  static NutritionStatusResult _calculateBMIForAge(
      int age, double bmi, String gender) {
    final referenceData = gender == genderMale
        ? NutritionStatusData.imtUBoys
        : NutritionStatusData.imtUGirls;

    if (!referenceData.containsKey(age)) {
      return const NutritionStatusResult(zScore: null, category: 'Data tidak tersedia');
    }

    final percentiles = referenceData[age]!;
    final double median = percentiles[3];
    final double sd     = percentiles[4] - median;
    final double zScore = (bmi - median) / sd;

    return NutritionStatusResult(
      zScore: zScore,
      category: _getWeightForHeightCategory(zScore), // Kategori IMT/U sama dengan BB/TB
    );
  }

  // ── INTERPRETASI KATEGORI Z-SCORE ─────────────────────────────────────────

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

  static String _getIMTU5To18Category(double zScore) {
    if (zScore < -3) return 'Gizi buruk';
    if (zScore < -2) return 'Gizi kurang';
    if (zScore <= 1) return 'Gizi baik';
    if (zScore <= 2) return 'Gizi lebih';
    return 'Obesitas (obese)';
  }

  // ── FUNGSI PUBLIK TAMBAHAN ────────────────────────────────────────────────

  /// Menentukan kategori tinggi badan dari nilai z-score TB/U.
  ///
  /// Dipreservasi dari method [determineHeightCategory] di helper lama.
  /// Null-safe: mengembalikan null jika input null.
  static String? determineHeightCategory(double? zScore) {
    if (zScore == null) return null;
    if (zScore < -3) return 'Sangat Pendek (severely stunted)';
    if (zScore < -2) return 'Pendek (stunted)';
    if (zScore <= 3) return 'Normal';
    return 'Tinggi';
  }
}

// ── VALUE OBJECTS ─────────────────────────────────────────────────────────────

/// Hasil kalkulasi satu indikator status gizi (z-score + kategori).
///
/// Menggantikan Map String, dynamic yang digunakan di helper lama
/// agar type-safe dan IDE-friendly (auto-complete, null-safety).
class NutritionStatusResult {
  final double? zScore;
  final String  category;

  const NutritionStatusResult({
    required this.zScore,
    required this.category,
  });

  /// Apakah data referensi tersedia untuk usia/tinggi ini?
  bool get hasData => zScore != null;

  @override
  String toString() =>
      'NutritionStatusResult(zScore: ${zScore?.toStringAsFixed(2)}, category: $category)';
}

/// Hasil kalkulasi lengkap semua indikator status gizi (0–60 bulan).
class NutritionAllResult {
  final int    ageInMonths;
  final double bmi;
  final NutritionStatusResult weightForAge;    // BB/U
  final NutritionStatusResult heightForAge;    // TB/U
  final NutritionStatusResult weightForHeight; // BB/TB
  final NutritionStatusResult bmiForAge;       // IMT/U

  const NutritionAllResult({
    required this.ageInMonths,
    required this.bmi,
    required this.weightForAge,
    required this.heightForAge,
    required this.weightForHeight,
    required this.bmiForAge,
  });
}

/// Hasil kalkulasi IMT/U untuk usia 5–18 tahun.
class ImtuResult {
  /// Kunci usia yang digunakan untuk lookup tabel referensi (format: 'tahun-bulan').
  final String  ageKey;
  final double  bmi;
  final double? zScore;
  final String  category;

  const ImtuResult({
    required this.ageKey,
    required this.bmi,
    required this.zScore,
    required this.category,
  });

  /// Apakah perhitungan berhasil (data referensi ditemukan)?
  bool get isValid => zScore != null;

  @override
  String toString() =>
      'ImtuResult(ageKey: $ageKey, bmi: ${bmi.toStringAsFixed(2)}, '
      'zScore: ${zScore?.toStringAsFixed(2)}, category: $category)';
}