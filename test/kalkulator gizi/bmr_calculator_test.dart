import 'package:flutter_test/flutter_test.dart';

class BmrCalculator {
  static const String male           = 'Laki-laki';
  static const String female         = 'Perempuan';
  static const String formulaMifflin = 'Mifflin-St Jeor';
  static const String formulaHarris  = 'Harris-Benedict';

  /// Pure function untuk menghitung BMR
  static double computeBMR({
    required double weight,
    required double height,
    required int    age,
    required String gender,
    required String formula,
  }) {
    final bool isMale = gender == male;

    if (formula == formulaHarris) {
      return isMale
          ? 66.47 + (13.75 * weight) + (5.003 * height) - (6.755 * age)
          : 655.1 + (9.563 * weight) + (1.850 * height) - (4.676 * age);
    }
    
    // Default fallback to Mifflin-St Jeor
    return isMale
        ? (9.99 * weight) + (6.25 * height) - (4.92 * age) + 5
        : (9.99 * weight) + (6.25 * height) - (4.92 * age) - 161;
  }
}
void main() {
  group('Unit Test: Akurasi Perhitungan BMR', () {
    
    // Data dummy: BB 70 kg, TB 175 cm, Umur 25 tahun

    test('Formula Mifflin-St Jeor - Laki-laki', () {
      // (9.99 * 70) + (6.25 * 175) - (4.92 * 25) + 5
      // 699.3 + 1093.75 - 123 + 5 = 1675.05
      final double bmr = BmrCalculator.computeBMR(
        weight: 70, height: 175, age: 25, 
        gender: BmrCalculator.male, formula: BmrCalculator.formulaMifflin,
      );
      expect(bmr, closeTo(1675.05, 0.01));
    });

    test('Formula Mifflin-St Jeor - Perempuan', () {
      // (9.99 * 70) + (6.25 * 175) - (4.92 * 25) - 161
      // 699.3 + 1093.75 - 123 - 161 = 1509.05
      final double bmr = BmrCalculator.computeBMR(
        weight: 70, height: 175, age: 25, 
        gender: BmrCalculator.female, formula: BmrCalculator.formulaMifflin,
      );
      expect(bmr, closeTo(1509.05, 0.01));
    });

    test('Formula Harris-Benedict - Laki-laki', () {
      // 66.47 + (13.75 * 70) + (5.003 * 175) - (6.755 * 25)
      // 66.47 + 962.5 + 875.525 - 168.875 = 1735.62
      final double bmr = BmrCalculator.computeBMR(
        weight: 70, height: 175, age: 25, 
        gender: BmrCalculator.male, formula: BmrCalculator.formulaHarris,
      );
      expect(bmr, closeTo(1735.62, 0.01));
    });

    test('Formula Harris-Benedict - Perempuan', () {
      // 655.1 + (9.563 * 70) + (1.850 * 175) - (4.676 * 25)
      // 655.1 + 669.41 + 323.75 - 116.9 = 1531.36
      final double bmr = BmrCalculator.computeBMR(
        weight: 70, height: 175, age: 25, 
        gender: BmrCalculator.female, formula: BmrCalculator.formulaHarris,
      );
      expect(bmr, closeTo(1531.36, 0.01));
    });
  });
}