// lib/src/features/nutrition_calculation/services/bbi_calculator_service.dart
//
// ─── ATURAN KETAT ───────────────────────────────────────────────────────────
// File ini adalah Pure Dart — DILARANG mengimpor 'package:flutter/material.dart'
// atau package Flutter apapun.
// ────────────────────────────────────────────────────────────────────────────

/// Service untuk kalkulasi Berat Badan Ideal (BBI).
///
/// Mencakup dua jenis kalkulasi:
/// 1. **BBI Dewasa** (usia > 12 tahun) — Formula Broca yang dimodifikasi.
/// 2. **BBI Anak**  (usia 0–12 tahun) — Formula berdasarkan kelompok usia.
class BbiCalculatorService {
  const BbiCalculatorService._();

  // ── KONSTANTA KATEGORI USIA ANAK ──────────────────────────────────────────

  /// Label kategori usia untuk anak 0–11 bulan.
  static const String categoryMonths0to11 = '0 - 11 Bulan';

  /// Label kategori usia untuk anak 1–6 tahun.
  static const String categoryYears1to6   = '1 - 6 Tahun';

  /// Label kategori usia untuk anak 7–12 tahun.
  static const String categoryYears7to12  = '7 - 12 Tahun';

  /// Semua pilihan kategori usia anak, urut sesuai tampilan dropdown UI.
  static const List<String> ageCategories = [
    categoryMonths0to11,
    categoryYears1to6,
    categoryYears7to12,
  ];

  // ── KONSTANTA GENDER ──────────────────────────────────────────────────────

  static const String genderMale   = 'Laki-laki';
  static const String genderFemale = 'Perempuan';

  // ── FORMULA BBI DEWASA (Usia > 12 Tahun) ─────────────────────────────────

  /// Menghitung Berat Badan Ideal dewasa dengan Formula Broca yang dimodifikasi.
  ///
  /// Formula:
  ///   Laki-laki   : (TB - 100) × 90%  = (TB - 100) × 0.90
  ///   Perempuan   : (TB - 100) × 85%  = (TB - 100) × 0.85
  ///
  /// [heightCm] : Tinggi badan dalam sentimeter.
  /// [isMale]   : true = Laki-laki, false = Perempuan.
  ///
  /// Melempar [ArgumentError] jika [heightCm] ≤ 0.
  static double calculateAdult({
    required double heightCm,
    required bool   isMale,
  }) {
    if (heightCm <= 0) {
      throw ArgumentError('heightCm harus lebih dari 0, diterima: $heightCm');
    }

    final double base = heightCm - 100.0;

    // Menentukan apakah menggunakan persamaan (a) berdasarkan gender dan tinggi badan
    final bool useFormulaA = (isMale && heightCm >= 160.0) || (!isMale && heightCm >= 150.0);

    if (useFormulaA) {
      // Persamaan (a): (TB - 100) dikurangi 10% (sama dengan dikali 0.90)
      return base * 0.90; 
    } else {
      // Persamaan (b): (TB - 100) tanpa pengurangan 10%
      return base; 
    }
  }

  // ── FORMULA BBI ANAK (Usia 0–12 Tahun) ───────────────────────────────────

  /// Menghitung Berat Badan Ideal anak berdasarkan kategori usia.
  ///
  /// Formula per kategori:
  ///   0–11 Bulan  : (Usia bulan + 9) / 2
  ///   1–6 Tahun   : (2 × Usia tahun) + 8
  ///   7–12 Tahun  : ((7 × Usia tahun) − 5) / 2
  ///
  /// [ageValue]  : Nilai usia (bulan atau tahun, sesuai kategori).
  /// [category]  : Gunakan salah satu konstanta [categoryMonths0to11],
  ///               [categoryYears1to6], atau [categoryYears7to12].
  ///
  /// Mengembalikan 0 jika kategori tidak dikenali.
  static double calculateChild({
    required double ageValue,
    required String category,
  }) {
    if (category == categoryMonths0to11) return (ageValue + 9.0) / 2.0;
    if (category == categoryYears1to6)   return (2.0 * ageValue) + 8.0;
    if (category == categoryYears7to12)  return ((7.0 * ageValue) - 5.0) / 2.0;
    return 0.0;
  }

  // ── UTILITAS PEMILIHAN KATEGORI USIA ─────────────────────────────────────

  /// Menentukan kategori usia anak secara otomatis dari komponen usia.
  ///
  /// Digunakan saat data pasien diisi otomatis dari PatientPicker,
  /// sehingga page tidak perlu memuat logika penentuan kategori ini.
  ///
  /// Mengembalikan null jika usia di luar rentang anak (0–12 tahun).
  ///
  /// [ageYears]  : Usia dalam tahun penuh.
  /// [ageMonths] : Total usia dalam bulan (untuk anak < 1 tahun).
  static String? detectAgeCategory({
    required int ageYears,
    required int totalAgeMonths,
  }) {
    if (totalAgeMonths < 12)              return categoryMonths0to11;
    if (ageYears >= 1 && ageYears <= 6)   return categoryYears1to6;
    if (ageYears >= 7 && ageYears <= 12)  return categoryYears7to12;
    return null; // Usia di luar rentang anak
  }

  /// Menghitung komponen usia (tahun & total bulan) dari tanggal lahir.
  ///
  /// Mengembalikan record Dart 3: (ageYears, totalAgeMonths).
  /// Pure function — [checkDate] di-inject agar testable tanpa DateTime.now().
  ///
  /// Contoh penggunaan:
  /// ```dart
  /// final (years, months) = BbiCalculatorService.calculateAgeComponents(
  ///   birthDate: patientDob,
  ///   checkDate: DateTime.now(),
  /// );
  /// ```
  static (int years, int totalMonths) calculateAgeComponents({
    required DateTime birthDate,
    required DateTime checkDate,
  }) {
    int years  = checkDate.year - birthDate.year;
    int months = (checkDate.year - birthDate.year) * 12 +
                 (checkDate.month - birthDate.month);

    // Koreksi jika hari belum mencapai hari ulang tahun bulan ini
    if (checkDate.day < birthDate.day) {
      months--;
      if (checkDate.month <= birthDate.month) years--;
    }

    return (years < 0 ? 0 : years, months < 0 ? 0 : months);
  }

  // ── DESKRIPSI FORMULA (untuk result card) ─────────────────────────────────

  /// Mengembalikan deskripsi formula yang digunakan untuk kategori anak tertentu.
  ///
  /// Digunakan oleh UI result card agar tidak ada string formula yang tersimpan
  /// di dalam widget.
  static String getChildFormulaDescription(String category) {
    switch (category) {
      case categoryMonths0to11: return 'Rumus: (Usia bulan + 9) / 2';
      case categoryYears1to6:   return 'Rumus: (2 × Usia tahun) + 8';
      case categoryYears7to12:  return 'Rumus: ((7 × Usia tahun) − 5) / 2';
      default:                  return 'Berat Badan Ideal Anak';
    }
  }

  // ── UTILITAS GENDER ───────────────────────────────────────────────────────

  /// Normalisasi string gender dari berbagai variasi penulisan ke nilai standar.
  ///
  /// Nilai yang dinormalisasi ke [genderMale]: 'laki-laki', 'pria', 'l', 'L'.
  static String normalizeGender(String raw) {
    final String lower = raw.toLowerCase();
    if (lower.contains('laki') || lower.contains('pria') || lower == 'l') {
      return genderMale;
    }
    if (lower.contains('perempuan') ||
        lower.contains('wanita') ||
        lower == 'p') {
      return genderFemale;
    }
    return raw;
  }

  /// Konversi string gender ke boolean [isMale].
  static bool isMaleFromString(String gender) => gender == genderMale;
}