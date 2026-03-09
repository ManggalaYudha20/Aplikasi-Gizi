import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_calculation_helper.dart';

void main() {
  group('Unit Test: Akurasi Z-Score IMT/U (5-18 Tahun)', () {
    
    test('Laki-laki, 5 Tahun 1 Bulan - Gizi Baik', () {
      // Skenario: BB 20 kg, TB 110 cm (1.1 m) -> BMI = 20 / 1.21 = 16.5289...
      // Tabel Boys '5-1' -> Median = 15.3, +1 SD = 16.6 -> (SD+ = 1.3)
      // Z-Score = (16.5289 - 15.3) / 1.3 = 0.9453...
      final result = NutritionCalculationHelper.calculateIMTU5To18(
        ageYears: 5, 
        ageMonthsRemainder: 1, 
        bmi: 16.5289, 
        gender: 'Laki-laki',
      );

      expect(result['zScore'], closeTo(0.945, 0.001));
      expect(result['category'], 'Gizi baik');
    });

    test('Perempuan, 6 Tahun 0 Bulan - Gizi Kurang', () {
      // Skenario: BB 17.28 kg, TB 120 cm (1.2 m) -> BMI = 17.28 / 1.44 = 12.0
      // Tabel Girls '6-0' -> Median = 15.3, -1 SD = 13.9 -> (SD- = 1.4)
      // Z-Score = (12.0 - 15.3) / 1.4 = -2.357...
      final result = NutritionCalculationHelper.calculateIMTU5To18(
        ageYears: 6, 
        ageMonthsRemainder: 0, 
        bmi: 12.0, 
        gender: 'Perempuan',
      );

      expect(result['zScore'], closeTo(-2.357, 0.001));
      expect(result['category'], 'Gizi kurang');
    });

    test('Kembalikan error jika data referensi usia di luar rentang (misal 4 tahun)', () {
      final result = NutritionCalculationHelper.calculateIMTU5To18(
        ageYears: 4, 
        ageMonthsRemainder: 0, 
        bmi: 15.0, 
        gender: 'Laki-laki',
      );

      expect(result['zScore'], isNull);
      expect(result['category'], 'Data referensi tidak tersedia');
    });
  });
}