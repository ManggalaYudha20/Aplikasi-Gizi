// test/features/disease_calculation/presentation/pages/diabetes_unit_test.dart
//
// ══════════════════════════════════════════════════════════════════════════════
//  UNIT TEST — Kalkulasi & Logika Murni Diabetes
// ══════════════════════════════════════════════════════════════════════════════
//
//  Cara jalankan (hanya butuh terminal, TANPA emulator):
//    flutter test test/features/disease_calculation/presentation/pages/diabetes_unit_test.dart
//
//  Cakupan:
//    [1] DiabetesCalculator.computeBMR          — formula Harris-Benedict
//    [2] DiabetesCalculator.computeIdealWeight   — Broca correction
//    [3] DiabetesCalculator.classifyBMI          — kategori IMT
//    [4] DiabetesCalculator.applyAgeCorrection   — koreksi energi lansia
//    [5] DiabetesCalculator.applyStressCorrection— faktor stress metabolik
//    [6] DiabetesCalculator.applyActivityFactor  — faktor aktivitas fisik
//    [7] _calculateAgeInYears                    — hitung usia dari tanggal lahir
//    [8] normalizeGender                         — normalisasi string gender
//    [9] formatNumber                            — format bilangan bulat vs desimal
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Pure-function class — mencerminkan logika bisnis di DiabetesCalculationPage
// ---------------------------------------------------------------------------
class DiabetesCalculator {
  // [1] BMR Harris-Benedict
  // Laki-laki : 66.5 + (13.7 × BB) + (5.0 × TB) − (6.8 × usia)
  // Perempuan : 655  + (9.6  × BB) + (1.8 × TB) − (4.7 × usia)
  static double computeBMR({
    required String gender,
    required double weightKg,
    required double heightCm,
    required int ageYears,
  }) {
    if (gender == 'Laki-laki') {
      return 66.5 + (13.7 * weightKg) + (5.0 * heightCm) - (6.8 * ageYears);
    } else {
      return 655.0 + (9.6 * weightKg) + (1.8 * heightCm) - (4.7 * ageYears);
    }
  }

  // [2] BB Ideal — Broca (height in cm)
  // Laki-laki : (TB - 100) - ((TB - 100) * 10%)
  // Perempuan : (TB - 100) - ((TB - 100) * 15%)
  static double computeIdealWeight({
    required String gender,
    required double heightCm,
  }) {
    final base = heightCm - 100;
    if (gender == 'Laki-laki') return base - (base * 0.10);
    return base - (base * 0.15);
  }

  // [3] Klasifikasi IMT (Asia-Pasifik / Indonesia)
  static String classifyBMI(double bmi) {
    if (bmi < 18.5) return 'Kurus';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 27.0) return 'Gemuk';
    return 'Obesitas';
  }

  // [4] Koreksi usia (setelah 40 tahun, kurangi 5% per dekade)
  // Usia 40–59 : −5%,  60–69 : −10%,  ≥70 : −15%
  static double applyAgeCorrection(double totalEnergy, int ageYears) {
    if (ageYears >= 70) return totalEnergy * 0.85;
    if (ageYears >= 60) return totalEnergy * 0.90;
    if (ageYears >= 40) return totalEnergy * 0.95;
    return totalEnergy;
  }

  // [5] Faktor stress metabolik (hanya saat rawat inap)
  // stressPct: 0–50 (integer percent)
  static double applyStressCorrection(double energy, int stressPct) {
    return energy * (1 + stressPct / 100);
  }

  // [6] Faktor aktivitas
  static double applyActivityFactor(double bmr, String activityLevel) {
    const factors = {
      'Bed rest': 1.2,
      'Ringan': 1.3,
      'Sedang': 1.5,
      'Berat': 1.75,
    };
    return bmr * (factors[activityLevel] ?? 1.0);
  }
}

// ---------------------------------------------------------------------------
// Helper — _calculateAgeInYears (logika murni, tidak bergantung widget)
// ---------------------------------------------------------------------------
int calculateAgeInYears(DateTime birthDate, DateTime now) {
  int age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}

// ---------------------------------------------------------------------------
// Helper — normalizeGender (logika murni)
// ---------------------------------------------------------------------------
String normalizeGender(String gender) {
  final lower = gender.toLowerCase();
  if (lower.contains('laki') || lower.contains('pria') || lower == 'l') {
    return 'Laki-laki';
  } else if (lower.contains('perempuan') ||
      lower.contains('wanita') ||
      lower == 'p') {
    return 'Perempuan';
  }
  return gender;
}

// ---------------------------------------------------------------------------
// Helper — formatNumber (logika murni)
// ---------------------------------------------------------------------------
String formatNumber(double value) =>
    value == value.toInt() ? value.toInt().toString() : value.toStringAsFixed(1);

// ===========================================================================
// MAIN
// ===========================================================================
void main() {
  // ─── [1] BMR ──────────────────────────────────────────────────────────────
  group('Unit Test [1]: Perhitungan BMR (Harris-Benedict)', () {
    test('Laki-laki, 45 th, 70 kg, 168 cm → ≈ 1 559.5 kkal', () {
      // 66.5 + (13.7×70) + (5.0×168) − (6.8×45)
      // = 66.5 + 959 + 840 − 306 = 1559.5
      final bmr = DiabetesCalculator.computeBMR(
        gender: 'Laki-laki',
        weightKg: 70,
        heightCm: 168,
        ageYears: 45,
      );
      expect(bmr, closeTo(1559.5, 0.5));
    });

    test('Perempuan, 35 th, 55 kg, 160 cm → ≈ 1 306.5 kkal', () {
      // 655 + (9.6×55) + (1.8×160) − (4.7×35)
      // = 655 + 528 + 288 − 164.5 = 1306.5
      final bmr = DiabetesCalculator.computeBMR(
        gender: 'Perempuan',
        weightKg: 55,
        heightCm: 160,
        ageYears: 35,
      );
      expect(bmr, closeTo(1306.5, 0.5));
    });
  });

  // ─── [2] BB Ideal ─────────────────────────────────────────────────────────
  group('Unit Test [2]: Berat Badan Ideal (Broca)', () {
    test('Laki-laki TB 168 cm → BB ideal ≈ 61.2 kg', () {
      final ideal = DiabetesCalculator.computeIdealWeight(
        gender: 'Laki-laki',
        heightCm: 168,
      );
      expect(ideal, closeTo(61.2, 0.1));
    });

    test('Perempuan TB 160 cm → BB ideal ≈ 51.0 kg', () {
      final ideal = DiabetesCalculator.computeIdealWeight(
        gender: 'Perempuan',
        heightCm: 160,
      );
      expect(ideal, closeTo(51.0, 0.1));
    });
  });

  // ─── [3] Klasifikasi IMT ──────────────────────────────────────────────────
  group('Unit Test [3]: Klasifikasi Kategori IMT', () {
    test('IMT 17.0 → Kurus', () => expect(DiabetesCalculator.classifyBMI(17.0), 'Kurus'));
    test('IMT 18.5 → Normal', () => expect(DiabetesCalculator.classifyBMI(18.5), 'Normal'));
    test('IMT 24.9 → Normal', () => expect(DiabetesCalculator.classifyBMI(24.9), 'Normal'));
    test('IMT 25.0 → Gemuk', () => expect(DiabetesCalculator.classifyBMI(25.0), 'Gemuk'));
    test('IMT 26.9 → Gemuk', () => expect(DiabetesCalculator.classifyBMI(26.9), 'Gemuk'));
    test('IMT 27.0 → Obesitas', () => expect(DiabetesCalculator.classifyBMI(27.0), 'Obesitas'));
    test('IMT 35.0 → Obesitas', () => expect(DiabetesCalculator.classifyBMI(35.0), 'Obesitas'));
  });

  // ─── [4] Koreksi Usia ─────────────────────────────────────────────────────
  group('Unit Test [4]: Koreksi Energi Berdasarkan Usia', () {
    test('Usia 35 th → tidak ada koreksi (100%)', () {
      expect(DiabetesCalculator.applyAgeCorrection(2000, 35), 2000.0);
    });
    test('Usia 40 th → dikurangi 5% → 1 900 kkal', () {
      expect(DiabetesCalculator.applyAgeCorrection(2000, 40), closeTo(1900, 0.1));
    });
    test('Usia 60 th → dikurangi 10% → 1 800 kkal', () {
      expect(DiabetesCalculator.applyAgeCorrection(2000, 60), closeTo(1800, 0.1));
    });
    test('Usia 70 th → dikurangi 15% → 1 700 kkal', () {
      expect(DiabetesCalculator.applyAgeCorrection(2000, 70), closeTo(1700, 0.1));
    });
  });

  // ─── [5] Koreksi Stress Metabolik ─────────────────────────────────────────
  group('Unit Test [5]: Koreksi Stress Metabolik', () {
    test('Stress 0% → energi tetap sama', () {
      expect(DiabetesCalculator.applyStressCorrection(2000, 0), 2000.0);
    });
    test('Stress 20% → 2000 × 1.20 = 2 400 kkal', () {
      expect(DiabetesCalculator.applyStressCorrection(2000, 20), closeTo(2400, 0.1));
    });
    test('Stress 50% → 2000 × 1.50 = 3 000 kkal', () {
      expect(DiabetesCalculator.applyStressCorrection(2000, 50), closeTo(3000, 0.1));
    });
  });

  // ─── [6] Faktor Aktivitas ─────────────────────────────────────────────────
  group('Unit Test [6]: Faktor Aktivitas Fisik', () {
    test('Bed rest → BMR × 1.2', () {
      expect(DiabetesCalculator.applyActivityFactor(1000, 'Bed rest'), closeTo(1200, 0.1));
    });
    test('Ringan → BMR × 1.3', () {
      expect(DiabetesCalculator.applyActivityFactor(1000, 'Ringan'), closeTo(1300, 0.1));
    });
    test('Sedang → BMR × 1.5', () {
      expect(DiabetesCalculator.applyActivityFactor(1000, 'Sedang'), closeTo(1500, 0.1));
    });
    test('Berat → BMR × 1.75', () {
      expect(DiabetesCalculator.applyActivityFactor(1000, 'Berat'), closeTo(1750, 0.1));
    });
  });

  // ─── [7] _calculateAgeInYears ─────────────────────────────────────────────
  group('Unit Test [7]: Perhitungan Usia dari Tanggal Lahir', () {
    test('Usia tepat 30 th (ulang tahun sudah lewat)', () {
      final now = DateTime(2025, 6, 15);
      final birth = DateTime(1995, 5, 10);
      expect(calculateAgeInYears(birth, now), 30);
    });

    test('Kurangi 1 jika ulang tahun belum tiba bulan ini', () {
      final now = DateTime(2025, 3, 1);
      final birth = DateTime(2000, 12, 15);
      expect(calculateAgeInYears(birth, now), 24);
    });

    test('Usia 0 untuk bayi yang baru lahir hari ini', () {
      final now = DateTime(2025, 6, 15);
      expect(calculateAgeInYears(now, now), 0);
    });
  });

  // ─── [8] normalizeGender ──────────────────────────────────────────────────
  group('Unit Test [8]: Normalisasi Jenis Kelamin', () {
    test('"laki-laki" → "Laki-laki"', () => expect(normalizeGender('laki-laki'), 'Laki-laki'));
    test('"pria"     → "Laki-laki"', () => expect(normalizeGender('pria'), 'Laki-laki'));
    test('"L"        → "Laki-laki"', () => expect(normalizeGender('L'), 'Laki-laki'));
    test('"perempuan"→ "Perempuan"', () => expect(normalizeGender('perempuan'), 'Perempuan'));
    test('"wanita"   → "Perempuan"', () => expect(normalizeGender('wanita'), 'Perempuan'));
    test('"P"        → "Perempuan"', () => expect(normalizeGender('P'), 'Perempuan'));
    test('nilai tidak dikenal dikembalikan apa adanya',
        () => expect(normalizeGender('other'), 'other'));
  });

  // ─── [9] formatNumber ─────────────────────────────────────────────────────
  group('Unit Test [9]: Format Angka', () {
    test('3.0  → "3"',   () => expect(formatNumber(3.0), '3'));
    test('1.5  → "1.5"', () => expect(formatNumber(1.5), '1.5'));
    test('2.75 → "2.8"', () => expect(formatNumber(2.75), '2.8'));
    test('0.0  → "0"',   () => expect(formatNumber(0.0), '0'));
    test('-1.0 → "-1"',  () => expect(formatNumber(-1.0), '-1'));
  });
}