import 'package:flutter_test/flutter_test.dart';
// Pastikan path import ini sesuai dengan project Anda
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/services/kidney_calculator_service.dart';

void main() {
  late KidneyCalculatorService service;

  setUp(() {
    service = KidneyCalculatorService();
  });

  group('KidneyCalculatorService White Box Testing', () {
    
    // TC1: Path 1 (Laki-laki, < 60 tahun, >= 160cm, Dialisis)
    test('TC1: Laki-laki, Umur < 60, Tinggi >= 160, Hemodialisis', () {
      final result = service.calculate(
        gender: 'Laki-laki',
        age: 45,
        height: 165.0,
        actualWeight: 60.0, // <-- TAMBAHKAN ACTUAL WEIGHT
        isDialysis: true,
      );

      // BBI = (165 - 100) * 0.9 = 58.5
      // BMR Laki-laki (<60) = 58.5 * 35 = 2047.5
      // Protein Dialisis = 1.2 * 60.0 (BBA) = 72.0
      // Rekomendasi Diet Dialisis = [60, 65, 70] -> Terdekat: 70

      expect(result.idealBodyWeight, 58.5);
      expect(result.bmr, 2047.5);
      expect(result.proteinNeeds, closeTo(72.0, 0.01)); // Berubah
      expect(result.recommendedDiet, 70);
      expect(result.isDialysis, true);
    });

    // TC2: Path 2 (Laki-laki, >= 60 tahun, < 160cm, Pre-dialisis)
    test('TC2: Laki-laki, Umur >= 60, Tinggi < 160, Pre-dialisis', () {
      final result = service.calculate(
        gender: 'Laki-laki',
        age: 65,
        height: 155.0, // Di bawah batas pengalian 0.9
        actualWeight: 50.0, // <-- TAMBAHKAN ACTUAL WEIGHT
        isDialysis: false,
        proteinFactor: 0.8,
      );

      // BBI = 155 - 100 = 55.0 (Tanpa dikali 0.9)
      // BMR Laki-laki (>=60) = 55.0 * 30 = 1650.0
      // Protein Pre-dialisis = 0.8 * 50.0 (BBA) = 40.0
      // Rekomendasi Diet Pre-dialisis = [30, 35, 40] -> Terdekat: 40

      expect(result.idealBodyWeight, 55.0);
      expect(result.bmr, 1650.0);
      expect(result.proteinNeeds, closeTo(40.0, 0.01)); // Berubah
      expect(result.recommendedDiet, 40);
      expect(result.isDialysis, false);
    });

    // TC3: Path 3 (Perempuan, < 60 tahun, >= 150cm, Dialisis)
    test('TC3: Perempuan, Umur < 60, Tinggi >= 150, Hemodialisis', () {
      final result = service.calculate(
        gender: 'Perempuan',
        age: 50,
        height: 155.0,
        actualWeight: 55.0, // <-- TAMBAHKAN ACTUAL WEIGHT
        isDialysis: true,
      );

      // BBI = (155 - 100) * 0.9 = 49.5
      // BMR Perempuan (<60) = 49.5 * 30 = 1485.0
      // Protein Dialisis = 1.2 * 55.0 (BBA) = 66.0
      // Rekomendasi Diet Dialisis = [60, 65, 70] -> Terdekat: 65

      expect(result.idealBodyWeight, 49.5);
      expect(result.bmr, 1485.0);
      expect(result.proteinNeeds, closeTo(66.0, 0.01)); // Berubah
      expect(result.recommendedDiet, 65); // Berubah karena terdekat dengan 66 adalah 65
    });

    // TC4: Path 4 (Perempuan, >= 60 tahun, < 150cm, Pre-dialisis)
    test('TC4: Perempuan, Umur >= 60, Tinggi < 150, Pre-dialisis', () {
      final result = service.calculate(
        gender: 'Perempuan',
        age: 70,
        height: 145.0, // Di bawah batas pengalian 0.9
        actualWeight: 45.0, // <-- TAMBAHKAN ACTUAL WEIGHT
        isDialysis: false,
        proteinFactor: 0.6,
      );

      // BBI = 145 - 100 = 45.0 (Tanpa dikali 0.9)
      // BMR Perempuan (>=60) = 45.0 * 25 = 1125.0
      // Protein Pre-dialisis = 0.6 * 45.0 (BBA) = 27.0
      // Rekomendasi Diet Pre-dialisis = [30, 35, 40] -> Terdekat: 30

      expect(result.idealBodyWeight, 45.0);
      expect(result.bmr, 1125.0);
      expect(result.proteinNeeds, closeTo(27.0, 0.01));
      expect(result.recommendedDiet, 30);
    });

    // TC5: Path 5 (Laki-laki, < 60 tahun, Pre-dialisis)
    test('TC5: Laki-laki, Umur < 60, Pre-dialisis, Validasi Kedekatan Diet', () {
      final result = service.calculate(
        gender: 'Laki-laki',
        age: 55,
        height: 170.0,
        actualWeight: 65.0, // <-- TAMBAHKAN ACTUAL WEIGHT
        isDialysis: false,
        proteinFactor: 0.6,
      );

      // BBI = (170 - 100) * 0.9 = 63.0
      // BMR Laki-laki (<60) = 63.0 * 35 = 2205.0
      // Protein Pre-dialisis = 0.6 * 65.0 (BBA) = 39.0
      // Rekomendasi Diet = [30, 35, 40] -> Terdekat dengan 39.0 adalah 40

      expect(result.idealBodyWeight, 63.0);
      expect(result.bmr, 2205.0);
      expect(result.proteinNeeds, closeTo(39.0, 0.01)); // Berubah
      expect(result.recommendedDiet, 40); 
    });
    
  });
}