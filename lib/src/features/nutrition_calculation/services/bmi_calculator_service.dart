// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\nutrition_calculation\services\bmi_calculator_service.dart
//
// ─── ATURAN KETAT ───────────────────────────────────────────────────────────
// File ini adalah Pure Dart — DILARANG mengimpor 'package:flutter/material.dart'
// atau package Flutter apapun. Hanya menerima tipe data dasar dan mengembalikan
// hasil perhitungan berupa tipe data Dart murni.
// ────────────────────────────────────────────────────────────────────────────

/// Service untuk semua kalkulasi yang berkaitan dengan Indeks Massa Tubuh (IMT).
///
/// Semua method bersifat [static] karena service ini stateless — tidak menyimpan
/// state apapun, sehingga tidak perlu diinstansiasi.
class BmiCalculatorService {
  // Konstruktor private agar class ini tidak bisa diinstansiasi secara tidak sengaja.
  const BmiCalculatorService._();

  // ── KONSTANTA BATAS KLASIFIKASI ────────────────────────────────────────────

  /// Batas bawah IMT kategori Normal (standar WHO umum / Indonesia).
  static const double _kUnderweightLow = 17.0;
  static const double _kNormalLow = 18.5;

  /// Batas bawah IMT kategori Gemuk.
  static const double _kOverweightLow = 25.0;

  /// Batas bawah IMT kategori Obesitas.
  static const double _kObeseLow = 27.0;

  // ── NAMA KATEGORI ──────────────────────────────────────────────────────────

  static const String categoryKurusSekali = 'Kurus Sekali';
  static const String categoryKurus = 'Kurus';
  static const String categoryNormal = 'Normal';
  static const String categoryGemuk = 'Gemuk';
  static const String categoryObesitas = 'Obesitas';

  // ── KALKULASI UTAMA ────────────────────────────────────────────────────────

  /// Menghitung nilai IMT dari berat dan tinggi badan.
  ///
  /// [weightKg]   : Berat badan dalam kilogram.
  /// [heightCm]   : Tinggi badan dalam sentimeter.
  ///
  /// Rumus: BB (kg) / (TB (m))²
  ///
  /// Melempar [ArgumentError] jika input tidak valid (≤ 0).
  static double calculate({
    required double weightKg,
    required double heightCm,
  }) {
    if (weightKg <= 0) throw ArgumentError('Berat badan harus lebih dari 0.');
    if (heightCm <= 0) throw ArgumentError('Tinggi badan harus lebih dari 0.');

    final double heightM = heightCm / 100.0;
    return weightKg / (heightM * heightM);
  }

  // ── KLASIFIKASI ────────────────────────────────────────────────────────────

  /// Mengklasifikasikan nilai IMT ke dalam kategori status gizi.
  ///
  /// Menggunakan acuan Kemenkes RI / WHO Asia-Pasifik:
  /// - < 18.5  → Kurus
  /// - 18.5 – <25.0 → Normal
  /// - 25.0 – <27.0 → Gemuk
  /// - ≥ 27.0  → Obesitas
  ///
  /// Mengembalikan [BmiClassification] yang berisi nama kategori dan
  /// kode kategori terstandarisasi untuk keperluan logika downstream.
  static BmiClassification classify(double bmi) {
    if (bmi < _kUnderweightLow) return BmiClassification.kurusSekali;
    if (bmi < _kNormalLow) return BmiClassification.kurus;
    if (bmi < _kOverweightLow) return BmiClassification.normal;
    if (bmi < _kObeseLow) return BmiClassification.gemuk;
    return BmiClassification.obesitas;
  }

  /// Shortcut: hitung dan langsung kembalikan [BmiResult] lengkap.
  ///
  /// Cocok dipakai di `onPressed` tombol "Hitung" di UI page,
  /// sehingga page hanya butuh satu baris pemanggilan.
  static BmiResult calculateAndClassify({
    required double weightKg,
    required double heightCm,
  }) {
    final double bmi = calculate(weightKg: weightKg, heightCm: heightCm);
    final BmiClassification classification = classify(bmi);
    return BmiResult(value: bmi, classification: classification);
  }
}

// ── VALUE OBJECTS ─────────────────────────────────────────────────────────────

/// Enum kategori IMT.
///
/// Menggunakan enum agar UI dapat menggunakan switch-expression exhaustive
/// (compile-time safe) daripada membandingkan String literal yang rawan typo.
enum BmiClassification {
  kurusSekali,
  kurus,
  normal,
  gemuk,
  obesitas;

  /// Nama kategori dalam Bahasa Indonesia untuk ditampilkan di UI.
  String get label {
    switch (this) {
      case BmiClassification.kurusSekali:
        return BmiCalculatorService.categoryKurusSekali;
      case BmiClassification.kurus:
        return BmiCalculatorService.categoryKurus;
      case BmiClassification.normal:
        return BmiCalculatorService.categoryNormal;
      case BmiClassification.gemuk:
        return BmiCalculatorService.categoryGemuk;
      case BmiClassification.obesitas:
        return BmiCalculatorService.categoryObesitas;
    }
  }

  /// Apakah kategori ini dianggap "sehat" / normal?
  bool get isHealthy => this == BmiClassification.normal;
}

/// Hasil perhitungan IMT yang sudah dikemas bersama klasifikasinya.
///
/// Menggunakan class terpisah (bukan Map) agar type-safe dan self-documenting.
class BmiResult {
  final double bmi;
  final BmiClassification classification;

  const BmiResult({required double value, required this.classification})
    : bmi = value;

  /// Label kategori siap pakai untuk widget Text di UI.
  String get categoryLabel => classification.label;

  @override
  String toString() =>
      'BmiResult(bmi: ${bmi.toStringAsFixed(2)}, category: $categoryLabel)';
}
