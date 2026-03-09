import 'package:flutter_test/flutter_test.dart';
class TdeeCalculator {
  /// Menghitung BMR menggunakan rumus Harris-Benedict
  static double computeBMR(double weight, double height, int age, String gender) {
    if (weight <= 0 || height <= 0 || age <= 0) return 0.0;
    
    if (gender == 'Laki-laki') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  /// Menghitung faktor stress khusus untuk kondisi Demam (> 37°C)
  static double computeStressFactorFever(double temperature) {
    return temperature > 37 ? 1.0 + (0.13 * (temperature - 37)) : 1.0;
  }

  /// Menghitung Total Daily Energy Expenditure (TDEE)
  static double computeTDEE(double bmr, double activityFactor, double stressFactor) {
    return bmr * activityFactor * stressFactor;
  }

  /// Menghitung distribusi Makronutrien (Karbohidrat 60%, Lemak 25%, Protein 15%)
  static Map<String, double> computeMacros(double tdee) {
    return {
      'carbs': (tdee * 0.60) / 4.0,  // 4 kkal per gram
      'fat': (tdee * 0.25) / 9.0,    // 9 kkal per gram
      'protein': (tdee * 0.15) / 4.0, // 4 kkal per gram
    };
  }
}void main() {
  group('Unit Test: Akurasi Perhitungan TDEE dan Makronutrien', () {
    
    test('Kalkulasi BMR Pria (Harris-Benedict)', () {
      // Skenario: Laki-laki, BB 70kg, TB 170cm, Umur 25
      // Rumus: 88.362 + (13.397*70) + (4.799*170) - (5.677*25)
      // Hasil = 88.362 + 937.79 + 815.83 - 141.925 = 1700.057
      final double bmr = TdeeCalculator.computeBMR(70, 170, 25, 'Laki-laki');
      expect(bmr, closeTo(1700.06, 0.01));
    });

    test('Kalkulasi BMR Wanita (Harris-Benedict)', () {
      // Skenario: Perempuan, BB 60kg, TB 160cm, Umur 30
      // Rumus: 447.593 + (9.247*60) + (3.098*160) - (4.330*30)
      // Hasil = 447.593 + 554.82 + 495.68 - 129.9 = 1368.193
      final double bmr = TdeeCalculator.computeBMR(60, 160, 30, 'Perempuan');
      expect(bmr, closeTo(1368.19, 0.01));
    });

    test('Faktor Stress Khusus Demam', () {
      // Skenario: Suhu 38°C -> naik 1°C dari batas 37°C
      // Penggali = 1.0 + (0.13 * 1) = 1.13
      final double stress = TdeeCalculator.computeStressFactorFever(38.0);
      expect(stress, 1.13);
    });

    test('Distribusi Gram Makronutrien dari TDEE', () {
      // Skenario: Kebutuhan total 2000 kkal/hari
      final macros = TdeeCalculator.computeMacros(2000);
      
      // Karbo (60% dari 2000) = 1200 kkal / 4 = 300 gram
      expect(macros['carbs'], 300.0);
      
      // Lemak (25% dari 2000) = 500 kkal / 9 = 55.55... gram
      expect(macros['fat'], closeTo(55.55, 0.01));
      
      // Protein (15% dari 2000) = 300 kkal / 4 = 75 gram
      expect(macros['protein'], 75.0);
    });
  });
}