// test/features/disease_calculation/presentation/pages/kidney_unit_test.dart
//
// ══════════════════════════════════════════════════════════════════════════════
//  UNIT TEST — Kalkulasi & Logika Murni Ginjal
// ══════════════════════════════════════════════════════════════════════════════
//
//  Cara jalankan (hanya butuh terminal, TANPA emulator):
//    flutter test test/features/disease_calculation/presentation/pages/kidney_unit_test.dart
//
//  Cakupan:
//    [1] calculateAgeInYears — logika hitung usia dari tanggal lahir
//    [2] KidneyCalculator.classifyBMI — logika kategori status gizi IMT
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure-function class — mencerminkan logika bisnis untuk Ginjal
// ---------------------------------------------------------------------------
class KidneyCalculator {
  // Klasifikasi IMT
  static String classifyBMI(double bmi) {
    if (bmi < 18.5) return 'BB Kurang';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'BB Lebih';
    return 'Obesitas';
  }
}

// ---------------------------------------------------------------------------
// Helper — _calculateAgeInYears (logika murni)
// ---------------------------------------------------------------------------
int calculateAgeInYears(DateTime birthDate, DateTime now) {
  int age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}

// ===========================================================================
// MAIN
// ===========================================================================
void main() {
  // ─── [1] Usia ─────────────────────────────────────────────────────────────
  group('Unit Test [1]: _calculateAgeInYears', () {
    test('menghitung usia tepat untuk tanggal lahir yang sudah lewat ulang tahun', () {
      final now = DateTime(2025, 6, 15);
      final birthDate = DateTime(1995, 5, 10);
      expect(calculateAgeInYears(birthDate, now), 30);
    });

    test('mengurangi 1 tahun jika ulang tahun belum tiba di bulan/hari ini', () {
      final now = DateTime(2025, 3, 1);
      final birthDate = DateTime(2000, 12, 15);
      expect(calculateAgeInYears(birthDate, now), 24);
    });
  });

  // ─── [2] Klasifikasi IMT ──────────────────────────────────────────────────
  group('Unit Test [2]: IMT Display', () {
    test('kategori IMT "BB Kurang" untuk nilai 17.0', () {
      expect(KidneyCalculator.classifyBMI(17.0), 'BB Kurang');
    });

    test('kategori IMT "Normal" untuk nilai 22.0', () {
      expect(KidneyCalculator.classifyBMI(22.0), 'Normal');
    });

    test('kategori IMT "BB Lebih" untuk nilai 27.0', () {
      expect(KidneyCalculator.classifyBMI(27.0), 'BB Lebih');
    });

    test('kategori IMT "Obesitas" untuk nilai 31.0', () {
      expect(KidneyCalculator.classifyBMI(31.0), 'Obesitas');
    });
  });
}