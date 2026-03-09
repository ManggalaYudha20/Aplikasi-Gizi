import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class BmiCalculator {
  /// Pure function untuk menghitung nilai IMT
  /// Rumus: Berat Badan (kg) / (Tinggi Badan (m) * Tinggi Badan (m))
  static double computeBMI(double weightKg, double heightCm) {
    if (heightCm == 0) return 0.0; // Mencegah pembagian dengan nol
    final double heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Pure function untuk klasifikasi kategori IMT beserta warnanya
  static (String, Color) classifyBMI(double bmi) {
    if (bmi < 18.5) return ('Kurus', Colors.red);
    if (bmi < 25.0) return ('Normal', const Color(0xFF009444));
    if (bmi < 27.0) return ('Gemuk', Colors.orange);
    return ('Obesitas', Colors.red);
  }
}
void main() {
  group('Unit Test: Akurasi Perhitungan dan Kategori IMT', () {
    
    test('Perhitungan nilai IMT akurat', () {
      // BB: 65 kg, TB: 170 cm (1.7 m) -> 65 / (1.7 * 1.7) = 22.4913...
      final double bmi1 = BmiCalculator.computeBMI(65, 170);
      expect(bmi1, closeTo(22.49, 0.01));

      // BB: 85 kg, TB: 170 cm (1.7 m) -> 85 / 2.89 = 29.4117...
      final double bmi2 = BmiCalculator.computeBMI(85, 170);
      expect(bmi2, closeTo(29.41, 0.01));
    });

    test('Klasifikasi kategori IMT sesuai batas', () {
      // BMI < 18.5 -> Kurus
      expect(BmiCalculator.classifyBMI(18.4).$1, 'Kurus');
      expect(BmiCalculator.classifyBMI(18.4).$2, Colors.red);

      // 18.5 <= BMI < 25.0 -> Normal
      expect(BmiCalculator.classifyBMI(22.5).$1, 'Normal');
      expect(BmiCalculator.classifyBMI(22.5).$2, const Color(0xFF009444));

      // 25.0 <= BMI < 27.0 -> Gemuk
      expect(BmiCalculator.classifyBMI(26.5).$1, 'Gemuk');
      expect(BmiCalculator.classifyBMI(26.5).$2, Colors.orange);

      // BMI >= 27.0 -> Obesitas
      expect(BmiCalculator.classifyBMI(28.0).$1, 'Obesitas');
      expect(BmiCalculator.classifyBMI(28.0).$2, Colors.red);
    });
  });
}