import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_calculation_helper.dart';

void main() {
  group('Unit Test: Akurasi Z-Score Status Gizi Balita (0-60 Bulan)', () {
    
    test('Skenario Bayi Laki-laki Baru Lahir (0 Bulan) - Tumbuh Kembang Median (Normal)', () {
      // Skenario: Bayi lahir hari ini dan diukur hari ini (Usia = 0 bulan)
      // Menggunakan data Median (nilai tengah) dari Kemenkes untuk 0 bulan:
      // BB Median = 3.3 kg, TB Median = 49.9 cm
      final results = NutritionCalculationHelper.calculateAll(
        birthDate: DateTime(2023, 1, 1),
        checkDate: DateTime(2023, 1, 1), 
        weight: 3.3, 
        height: 49.9, 
        gender: 'Laki-laki',
      );

      // Verifikasi Perhitungan Usia
      expect(results['ageInMonths'], 0);

      // Verifikasi Z-Score BB/U (Harus ≈ 0 karena menggunakan berat Median)
      final bbU = results['bbPerU']['zScore'] as double;
      expect(bbU, closeTo(0.0, 0.05));
      expect(results['bbPerU']['category'], 'Normal');

      // Verifikasi Z-Score TB/U
      final tbU = results['tbPerU']['zScore'] as double;
      expect(tbU, closeTo(0.0, 0.05));
      expect(results['tbPerU']['category'], 'Normal');

      // Verifikasi Z-Score BB/TB (Tinggi terdekat di tabel adalah 50.0 cm yang median BB-nya 3.3 kg)
      final bbTb = results['bbPerTB']['zScore'] as double;
      expect(bbTb, closeTo(0.0, 0.05));
      expect(results['bbPerTB']['category'], 'Gizi baik');
    });

    test('Skenario Balita Perempuan 12 Bulan - Risiko Gizi Kurang', () {
      // Skenario: Balita perempuan tepat 1 Tahun (12 Bulan)
      // Data Median Perempuan 12 Bln: BB = 8.9 kg, TB = 74.0 cm
      // Kita gunakan BB = 7.0 kg (di bawah -2 SD yaitu 7.0) dan TB = 70.0 cm
      final results = NutritionCalculationHelper.calculateAll(
        birthDate: DateTime(2022, 1, 1),
        checkDate: DateTime(2023, 1, 1), // Tepat 1 tahun kemudian
        weight: 7.0, 
        height: 70.0, 
        gender: 'Perempuan',
      );

      expect(results['ageInMonths'], 12);

      // Verifikasi Z-Score BB/U (Harus berada di zona Gizi Kurang / Underweight)
      final bbU = results['bbPerU']['zScore'] as double;
      expect(bbU, lessThan(-1.0)); // Pasti bernilai negatif karena di bawah median
      expect(results['bbPerU']['category'], contains('Kurang'));
    });
  });
}