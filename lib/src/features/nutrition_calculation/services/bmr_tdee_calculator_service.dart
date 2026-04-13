// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\nutrition_calculation\services\bmr_tdee_calculator_service.dart
//
// ─── ATURAN KETAT ───────────────────────────────────────────────────────────
// File ini adalah Pure Dart — DILARANG mengimpor 'package:flutter/material.dart'
// atau package Flutter apapun.
// ────────────────────────────────────────────────────────────────────────────

/// Service untuk kalkulasi Basal Metabolic Rate (BMR) dan
/// Total Daily Energy Expenditure (TDEE).
///
/// Mencakup dua formula BMR yang umum digunakan secara klinis:
/// - Harris-Benedict (1919) — digunakan juga di TDEE page
/// - Mifflin-St Jeor (1990) — lebih akurat untuk populasi modern
class BmrTdeeCalculatorService {
  const BmrTdeeCalculatorService._();

  // ── FAKTOR AKTIVITAS ───────────────────────────────────────────────────────
  // Sumber: Ainsworth et al. / Panduan Gizi Klinnis
  // Dipindahkan dari _kActivityFactors di tdee_form_page.dart agar menjadi
  // Single Source of Truth yang bisa diakses service maupun UI.

  static const Map<String, double> activityFactors = {
    'Sangat Jarang': 1.2,
    'Aktivitas Ringan': 1.375,
    'Aktivitas Sedang': 1.55,
    'Aktivitas Berat': 1.725,
    'Sangat Aktif': 1.9,
  };

  // ── FAKTOR STRES ───────────────────────────────────────────────────────────
  // Dipindahkan dari _kStressFactors di tdee_form_page.dart.
  // Catatan: nilai faktor 'Demam' = 0.13 adalah MULTIPLIER PER °C delta suhu
  // (bukan faktor langsung seperti entri lainnya).

  static const String feverKey = 'Demam (per 1°C)';
  static const double feverMultiplierPerDegree = 0.13;
  static const double normalBodyTemperature = 37.0;

  static const Map<String, double> stressFactors = {
    'Normal': 1.00,
    feverKey: feverMultiplierPerDegree, // Lihat catatan di atas
    'Peritonitis': 1.35,
    'Cedera Jaringan Lunak Ringan': 1.14,
    'Cedera Jaringan Lunak Berat': 1.37,
    'Patah Tulang Multiple Ringan': 1.20,
    'Patah Tulang Multiple Berat': 1.35,
    'Sepsis Ringan': 1.40,
    'Sepsis Berat': 1.80,
    'Luka Bakar 0-20%': 1.25,
    'Luka Bakar 20-40%': 1.675,
    'Luka Bakar 40-100%': 1.95,
    'Puasa': 0.70,
    'Payah Gagal Jantung Ringan': 1.30,
    'Payah Gagal Jantung Berat': 1.50,
    'Kanker': 1.30,
  };

  // ── NAMA FORMULA ──────────────────────────────────────────────────────────

  static const String formulaMifflin = 'Mifflin-St Jeor';
  static const String formulaHarris = 'Harris-Benedict';

  // ── KONSTANTA GENDER ──────────────────────────────────────────────────────

  static const String genderMale = 'Laki-laki';
  static const String genderFemale = 'Perempuan';

  // ── FORMULA BMR ───────────────────────────────────────────────────────────

  /// Menghitung BMR menggunakan formula Harris-Benedict (1919).
  ///
  /// Digunakan oleh: [BmrFormPage] dan sebagai basis kalkulasi TDEE di [TdeeFormPage].
  ///
  /// Formula:
  ///   Laki-laki  : 66.47  + (13.75 × BB) + (5.003 × TB) − (6.755 × U)
  ///   Perempuan  : 655.1  + (9.563 × BB)  + (1.850 × TB) − (4.676 × U)
  ///
  /// [weightKg] : Berat badan dalam kilogram.
  /// [heightCm] : Tinggi badan dalam sentimeter.
  /// [ageYears] : Usia dalam tahun.
  /// [isMale]   : true = Laki-laki, false = Perempuan.
  static double calculateBmrHarrisBenedict({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required bool isMale,
  }) {
    _assertPositive(weightKg, 'weightKg');
    _assertPositive(heightCm, 'heightCm');
    _assertPositive(ageYears.toDouble(), 'ageYears');

    return isMale
        ? 66.47 + (13.75 * weightKg) + (5.003 * heightCm) - (6.755 * ageYears)
        : 655.1 + (9.563 * weightKg) + (1.850 * heightCm) - (4.676 * ageYears);
  }



  /// Menghitung BMR menggunakan formula Mifflin-St Jeor (1990).
  ///
  /// Dianggap lebih akurat untuk populasi modern.
  ///
  /// Formula:
  ///   Laki-laki  : (9.99 × BB) + (6.25 × TB) − (4.92 × U) + 5
  ///   Perempuan  : (9.99 × BB) + (6.25 × TB) − (4.92 × U) − 161
  static double calculateBmrMifflinStJeor({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required bool isMale,
  }) {
    _assertPositive(weightKg, 'weightKg');
    _assertPositive(heightCm, 'heightCm');
    _assertPositive(ageYears.toDouble(), 'ageYears');

    final double base =
        (9.99 * weightKg) + (6.25 * heightCm) - (4.92 * ageYears);
    return isMale ? base + 5 : base - 161;
  }

  /// Dispatcher: menghitung BMR berdasarkan nama formula.
  ///
  /// Digunakan oleh [BmrFormPage] yang memiliki dropdown pemilihan formula.
  /// Untuk TDEE, gunakan [calculateBmrForTdee] secara langsung.
  ///
  /// [formula] : Gunakan konstanta [formulaMifflin] atau [formulaHarris].
  static double calculateBmrByFormula({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required bool isMale,
    required String formula,
  }) {
    if (formula == formulaHarris) {
      return calculateBmrHarrisBenedict(
        weightKg: weightKg,
        heightCm: heightCm,
        ageYears: ageYears,
        isMale: isMale,
      );
    }
    // Default: Mifflin-St Jeor
    return calculateBmrMifflinStJeor(
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      isMale: isMale,
    );
  }

  // ── FORMULA TDEE ──────────────────────────────────────────────────────────

  /// Menghitung faktor stres.
  ///
  /// Kasus khusus "Demam": stres dihitung dari delta suhu terhadap suhu normal
  /// (37°C) dikalikan koefisien 0.13, lalu ditambahkan 1 sebagai basis.
  ///
  ///   Faktor Stres Demam = 1 + (Suhu - 37°C) × 0.13
  ///
  /// Untuk kondisi non-demam, nilai langsung diambil dari [stressFactors].
  ///
  /// [stressCondition]  : Nama kondisi stres. Gunakan kunci dari [stressFactors].
  /// [bodyTemperatureC] : Diperlukan hanya jika [stressCondition] == [feverKey].
  static double calculateStressFactor({
    required String stressCondition,
    double bodyTemperatureC = normalBodyTemperature,
  }) {
    if (stressCondition == feverKey) {
      final double delta = bodyTemperatureC - normalBodyTemperature;
      // Guard: suhu di bawah normal dianggap tidak demam → faktor = 1.0
      if (delta <= 0) return 1.0;
      return 1.0 + (delta * feverMultiplierPerDegree);
    }
    return stressFactors[stressCondition] ?? 1.0;
  }

  /// Menghitung TDEE lengkap beserta kebutuhan makronutrien.
  ///
  /// Langkah perhitungan:
  ///   1. Hitung BMR (Harris-Benedict Revised)
  ///   2. Hitung Faktor Stres
  ///   3. TDEE = BMR × Faktor Aktivitas × Faktor Stres
  ///   4. Karbohidrat = 60% TDEE / 4 kkal/g
  ///   5. Lemak       = 25% TDEE / 9 kkal/g
  ///   6. Protein     = 15% TDEE / 4 kkal/g
  ///
  /// Mengembalikan [TdeeResult] yang berisi semua nilai terkomputasi.
  static TdeeResult calculateTdee({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required bool isMale,
    required String activityCondition,
    required String stressCondition,
    double bodyTemperatureC = normalBodyTemperature,
  }) {
    final double bmr = calculateBmrHarrisBenedict(
      weightKg: weightKg,
      heightCm: heightCm,
      ageYears: ageYears,
      isMale: isMale,
    );

    final double activityFactor = activityFactors[activityCondition] ?? 1.0;

    final double stressFactor = calculateStressFactor(
      stressCondition: stressCondition,
      bodyTemperatureC: bodyTemperatureC,
    );

    final double tdee = bmr * activityFactor * stressFactor;

    // Distribusi Makronutrien (Pedoman Gizi Seimbang):
    //   Karbohidrat : 60% energi → 4 kkal/g
    //   Lemak       : 25% energi → 9 kkal/g
    //   Protein     : 15% energi → 4 kkal/g
    final double carbsGram = (tdee * 0.60) / 4.0;
    final double fatGram = (tdee * 0.25) / 9.0;
    final double proteinGram = (tdee * 0.15) / 4.0;

    return TdeeResult(
      bmr: bmr,
      tdee: tdee,
      carbsGram: carbsGram,
      fatGram: fatGram,
      proteinGram: proteinGram,
    );
  }

  // ── UTILITAS ──────────────────────────────────────────────────────────────

  /// Normalisasi string gender dari berbagai variasi penulisan ke nilai standar.
  ///
  /// Digunakan agar data pasien dari berbagai sumber (API, lokal DB) bisa
  /// langsung dikonversi ke nilai yang diterima oleh service ini.
  ///
  /// Contoh input yang dinormalisasi ke 'Laki-laki':
  ///   'laki-laki', 'Laki Laki', 'pria', 'l', 'L'
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

  /// Helper konversi string gender ke boolean [isMale].
  static bool isMaleFromString(String gender) => gender == genderMale;

  /// Menghitung usia dalam tahun penuh dari tanggal lahir ke tanggal sekarang.
  /// Pure function — tidak mengakses DateTime.now() secara langsung agar testable.
  ///
  /// [birthDate] : Tanggal lahir.
  /// [checkDate] : Tanggal pemeriksaan / referensi. Biasanya DateTime.now().
  static int calculateAgeInYears({
    required DateTime birthDate,
    required DateTime checkDate,
  }) {
    int age = checkDate.year - birthDate.year;
    final bool birthdayNotYetThisYear =
        checkDate.month < birthDate.month ||
        (checkDate.month == birthDate.month && checkDate.day < birthDate.day);
    if (birthdayNotYetThisYear) age--;
    return age < 0 ? 0 : age;
  }

  // ── PRIVATE GUARD ─────────────────────────────────────────────────────────

  static void _assertPositive(double value, String name) {
    if (value <= 0) {
      throw ArgumentError('$name harus lebih dari 0, diterima: $value');
    }
  }
}

// ── VALUE OBJECTS ─────────────────────────────────────────────────────────────

/// Hasil perhitungan TDEE lengkap beserta distribusi makronutrien.
class TdeeResult {
  /// Basal Metabolic Rate (kkal/hari).
  final double bmr;

  /// Total Daily Energy Expenditure (kkal/hari).
  final double tdee;

  /// Kebutuhan karbohidrat (gram/hari), 60% dari TDEE.
  final double carbsGram;

  /// Kebutuhan lemak (gram/hari), 25% dari TDEE.
  final double fatGram;

  /// Kebutuhan protein (gram/hari), 15% dari TDEE.
  final double proteinGram;

  const TdeeResult({
    required this.bmr,
    required this.tdee,
    required this.carbsGram,
    required this.fatGram,
    required this.proteinGram,
  });

  @override
  String toString() =>
      'TdeeResult(bmr: ${bmr.toStringAsFixed(2)}, '
      'tdee: ${tdee.toStringAsFixed(2)}, '
      'carbs: ${carbsGram.toStringAsFixed(2)}g, '
      'fat: ${fatGram.toStringAsFixed(2)}g, '
      'protein: ${proteinGram.toStringAsFixed(2)}g)';
}
