import 'package:flutter_test/flutter_test.dart';
// Pastikan path import ini sesuai dengan struktur folder Anda
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/services/diabetes_calculator_service.dart';

void main() {
  late DiabetesCalculatorService service;

  setUp(() {
    service = DiabetesCalculatorService();
  });

  group('DiabetesCalculatorService White Box Testing', () {
    // TC1: Laki-laki, Bed rest, umur 30, rawat Tidak
    test('TC1: Laki-laki, Bed rest, Umur < 40, Tidak dirawat', () {
      final result = service.calculate(
        age: 30,
        weight: 60.0,
        height: 165.0,
        gender: 'Laki-laki',
        activity: 'Bed rest',
        hospitalizedStatus: 'Tidak',
        stressMetabolic: 0.0,
      );

      // BBI Laki-laki (165 >= 160) = (165 - 100) * 0.9 = 58.5
      // BMR Laki-laki = 58.5 * 30 = 1755
      // Koreksi Aktivitas = 1755 * 0.1 = 175.5
      // Koreksi Umur = 0 (karena < 40)
      
      expect(result.bbIdeal, 58.5);
      expect(result.bmr, 1755.0);
      expect(result.activityCorrection, 175.5);
      expect(result.ageCorrection, 0.0);
    });

    // TC2: Perempuan, Ringan, umur 45, rawat Ya
    test('TC2: Perempuan, Ringan, Umur >= 40, Dirawat dengan stress 10', () {
      final result = service.calculate(
        age: 45,
        weight: 55.0,
        height: 155.0,
        gender: 'Perempuan',
        activity: 'Ringan',
        hospitalizedStatus: 'Ya',
        stressMetabolic: 10.0, // 10%
      );

      // BBI Perempuan (155 >= 150) = (155 - 100) * 0.9 = 49.5
      // BMR Perempuan = 49.5 * 25 = 1237.5
      // Koreksi Aktivitas (Ringan) = 1237.5 * 0.2 = 247.5
      // Koreksi Umur (>= 40) = 1237.5 * 0.05 = 61.875
      
      expect(result.bmr, 1237.5);
      expect(result.activityCorrection, 247.5);
      expect(result.ageCorrection, 61.875);
    });

    // TC3: Laki-laki, Sedang, umur 65, rawat Tidak
    test('TC3: Laki-laki, Sedang, Umur >= 60, Tidak dirawat', () {
      final result = service.calculate(
        age: 65,
        weight: 70.0,
        height: 170.0,
        gender: 'Laki-laki',
        activity: 'Sedang',
        hospitalizedStatus: 'Tidak',
        stressMetabolic: 0.0,
      );

      // Koreksi Aktivitas (Sedang) = BMR * 0.3
      // Koreksi Umur (>= 60) = BMR * 0.10
      expect(result.ageCorrection, result.bmr * 0.10);
      expect(result.activityCorrection, result.bmr * 0.3);
    });

    // TC4: Perempuan, Berat, umur 75, rawat Ya
    test('TC4: Perempuan, Berat, Umur >= 70, Dirawat', () {
      final result = service.calculate(
        age: 75,
        weight: 50.0,
        height: 150.0,
        gender: 'Perempuan',
        activity: 'Berat',
        hospitalizedStatus: 'Ya',
        stressMetabolic: 20.0,
      );

      // Koreksi Aktivitas (Berat) = BMR * 0.4
      // Koreksi Umur (>= 70) = BMR * 0.20
      expect(result.ageCorrection, result.bmr * 0.20);
      expect(result.activityCorrection, result.bmr * 0.4);
    });

    // TC5: Uji default fallback aktivitas (Tidak ada di case)
    test('TC5: Laki-laki, Aktivitas Tidak Dikenal, Umur 30, Tidak dirawat', () {
      final result = service.calculate(
        age: 30,
        weight: 60.0,
        height: 165.0,
        gender: 'Laki-laki',
        activity: 'Tidak Ada', // Tidak masuk case switch manapun
        hospitalizedStatus: 'Tidak',
        stressMetabolic: 0.0,
      );

      // Jika tidak masuk case manapun, activityFactor harusnya tetap 0
      expect(result.activityCorrection, 0.0);
    });
    
    // TC6: Perempuan, Bed rest, umur 65, rawat Tidak.
    // Tambahan: Uji kategori BMI "Kurang" (< 18.5)
    test('TC6: Perempuan, Bed rest, Umur >= 60, Tidak dirawat, BMI Kurang', () {
      final result = service.calculate(
        age: 65,
        weight: 45.0,
        height: 160.0,
        gender: 'Perempuan',
        activity: 'Bed rest',
        hospitalizedStatus: 'Tidak',
        stressMetabolic: 0.0,
      );

      // BMI = 45 / (1.6 * 1.6) = 17.57 (Kurang)
      // BBI Perempuan (160 >= 150) = (160 - 100) * 0.9 = 54.0
      // BMR Perempuan = 54.0 * 25 = 1350.0
      // Koreksi Umur (>= 60) = 1350 * 0.10 = 135.0
      // Koreksi Aktivitas (Bed rest) = 1350 * 0.1 = 135.0
      // Koreksi Berat Badan (Kurang) = 1350 * 0.2 = 270.0

      expect(result.bmiCategory, 'Kurang');
      expect(result.bbIdeal, 54.0);
      expect(result.bmr, 1350.0);
      expect(result.ageCorrection, 135.0);
      expect(result.activityCorrection, 135.0);
      expect(result.weightCorrection, 270.0);
    });

    // TC7: Laki-laki, Ringan, umur 75, rawat Tidak.
    // Tambahan: Uji kategori BMI "Gemuk" (>= 25)
    test('TC7: Laki-laki, Ringan, Umur >= 70, Tidak dirawat, BMI Gemuk', () {
      final result = service.calculate(
        age: 75,
        weight: 80.0,
        height: 165.0,
        gender: 'Laki-laki',
        activity: 'Ringan',
        hospitalizedStatus: 'Tidak',
        stressMetabolic: 0.0,
      );

      // BMI = 80 / (1.65 * 1.65) = 29.38 (Gemuk)
      // BBI Laki-laki (165 >= 160) = (165 - 100) * 0.9 = 58.5
      // BMR Laki-laki = 58.5 * 30 = 1755.0
      // Koreksi Umur (>= 70) = 1755 * 0.20 = 351.0
      // Koreksi Aktivitas (Ringan) = 1755 * 0.2 = 351.0
      // Koreksi Berat Badan (Gemuk) = 1755 * (-0.2) = -351.0

      expect(result.bmiCategory, 'Gemuk');
      expect(result.bbIdeal, 58.5);
      expect(result.ageCorrection, 351.0);
      expect(result.activityCorrection, 351.0);
      expect(result.weightCorrection, -351.0);
    });

    // TC8: Perempuan, Sedang, umur 30, rawat Ya.
    // Tambahan: Uji kategori BMI "Lebih" (23 <= BMI < 25)
    test('TC8: Perempuan, Sedang, Umur < 40, Dirawat, BMI Lebih', () {
      final result = service.calculate(
        age: 30,
        weight: 62.0,
        height: 160.0,
        gender: 'Perempuan',
        activity: 'Sedang',
        hospitalizedStatus: 'Ya',
        stressMetabolic: 15.0, // Stress 15%
      );

      // BMI = 62 / (1.6 * 1.6) = 24.21 (Lebih)
      // BMR Perempuan (BBI: 54.0) = 54.0 * 25 = 1350.0
      // Koreksi Umur (< 40) = 0.0
      // Koreksi Aktivitas (Sedang) = 1350 * 0.3 = 405.0
      // Koreksi Berat Badan (Lebih) = 1350 * (-0.1) = -135.0

      expect(result.bmiCategory, 'Lebih');
      expect(result.ageCorrection, 0.0);
      expect(result.activityCorrection, 405.0);
      expect(result.weightCorrection, -135.0);
    });

    // TC9: Laki-laki, Berat, umur 45, rawat Tidak.
    // Tambahan: Uji Tinggi Badan Laki-laki < 160 cm untuk cabang (height - 100)
    test('TC9: Laki-laki, Berat, Umur >= 40, Tidak dirawat, Tinggi < 160', () {
      final result = service.calculate(
        age: 45,
        weight: 50.0,
        height: 155.0, // Tinggi di bawah 160 cm untuk Laki-laki
        gender: 'Laki-laki',
        activity: 'Berat',
        hospitalizedStatus: 'Tidak',
        stressMetabolic: 0.0,
      );

      // BBI Laki-laki (155 < 160) = (155 - 100) = 55.0  (Tidak dikali 0.9)
      // BMR Laki-laki = 55.0 * 30 = 1650.0
      // BMI = 50 / (1.55 * 1.55) = 20.81 (Normal)
      // Koreksi Berat Badan (Normal) = 0.0
      // Koreksi Aktivitas (Berat) = 1650 * 0.4 = 660.0
      // Koreksi Umur (>= 40) = 1650 * 0.05 = 82.5

      expect(result.bbIdeal, 55.0);
      expect(result.bmiCategory, 'Normal');
      expect(result.weightCorrection, 0.0);
      expect(result.activityCorrection, 660.0);
      expect(result.ageCorrection, 82.5);
    });

    // TC10: Perempuan, Bed rest, umur 75, rawat Ya.
    // Tambahan: Uji Tinggi Badan Perempuan < 150 cm untuk cabang (height - 100)
    test('TC10: Perempuan, Bed rest, Umur >= 70, Dirawat, Tinggi < 150', () {
      final result = service.calculate(
        age: 75,
        weight: 45.0,
        height: 145.0, // Tinggi di bawah 150 cm untuk Perempuan
        gender: 'Perempuan',
        activity: 'Bed rest',
        hospitalizedStatus: 'Ya',
        stressMetabolic: 10.0,
      );

      // BBI Perempuan (145 < 150) = (145 - 100) = 45.0 (Tidak dikali 0.9)
      // BMR Perempuan = 45.0 * 25 = 1125.0
      // Koreksi Aktivitas (Bed rest) = 1125 * 0.1 = 112.5
      // Koreksi Umur (>= 70) = 1125 * 0.20 = 225.0
      // Total metabolisme stress = 1125 * 0.10 (Jika ini tidak di-expose di model, asersi BMR cukup)

      expect(result.bbIdeal, 45.0);
      expect(result.bmr, 1125.0);
      expect(result.activityCorrection, 112.5);
      expect(result.ageCorrection, 225.0);
    });
  });
}