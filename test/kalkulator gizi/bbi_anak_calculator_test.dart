import 'package:flutter_test/flutter_test.dart';

class BbiAnakCalculator {
  // Konstanta kategori untuk mencegah typo
  static const String cat0to11 = '0 - 11 Bulan';
  static const String cat1to6  = '1 - 6 Tahun';
  static const String cat7to12 = '7 - 12 Tahun';

  /// Pure function untuk menghitung BBI Anak
  static double computeBBI(double age, String category) {
    if (category == cat0to11)  return (age + 9) / 2;
    if (category == cat1to6)   return (2 * age) + 8;
    if (category == cat7to12)  return ((7 * age) - 5) / 2;
    return 0.0; // Fallback jika kategori tidak valid
  }
}

void main() {
  group('Unit Test: Akurasi Perhitungan BBI Anak', () {
    
    test('Kategori 0-11 Bulan: Menggunakan rumus (Usia + 9) / 2', () {
      // Usia 5 bulan -> (5 + 9) / 2 = 7.0
      expect(BbiAnakCalculator.computeBBI(5, BbiAnakCalculator.cat0to11), 7.0);
      
      // Boundary bawah: Usia 0 bulan -> (0 + 9) / 2 = 4.5
      expect(BbiAnakCalculator.computeBBI(0, BbiAnakCalculator.cat0to11), 4.5);
      
      // Boundary atas: Usia 11 bulan -> (11 + 9) / 2 = 10.0
      expect(BbiAnakCalculator.computeBBI(11, BbiAnakCalculator.cat0to11), 10.0);
    });

    test('Kategori 1-6 Tahun: Menggunakan rumus (2 * Usia) + 8', () {
      // Usia 4 tahun -> (2 * 4) + 8 = 16.0
      expect(BbiAnakCalculator.computeBBI(4, BbiAnakCalculator.cat1to6), 16.0);
      
      // Boundary bawah: Usia 1 tahun -> (2 * 1) + 8 = 10.0
      expect(BbiAnakCalculator.computeBBI(1, BbiAnakCalculator.cat1to6), 10.0);
      
      // Boundary atas: Usia 6 tahun -> (2 * 6) + 8 = 20.0
      expect(BbiAnakCalculator.computeBBI(6, BbiAnakCalculator.cat1to6), 20.0);
    });

    test('Kategori 7-12 Tahun: Menggunakan rumus ((7 * Usia) - 5) / 2', () {
      // Usia 10 tahun -> ((7 * 10) - 5) / 2 = 32.5
      expect(BbiAnakCalculator.computeBBI(10, BbiAnakCalculator.cat7to12), 32.5);
      
      // Boundary bawah: Usia 7 tahun -> ((49) - 5) / 2 = 22.0
      expect(BbiAnakCalculator.computeBBI(7, BbiAnakCalculator.cat7to12), 22.0);
      
      // Boundary atas: Usia 12 tahun -> ((84) - 5) / 2 = 39.5
      expect(BbiAnakCalculator.computeBBI(12, BbiAnakCalculator.cat7to12), 39.5);
    });

    test('Kategori tidak valid mengembalikan nilai 0.0', () {
      expect(BbiAnakCalculator.computeBBI(5, 'Kategori Asal'), 0.0);
    });
  });
}