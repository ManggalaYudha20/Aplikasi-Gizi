import 'package:flutter_test/flutter_test.dart';

class BbiCalculator {
  static const String male = 'Laki-laki';
  static const String female = 'Perempuan';

  /// Pure function untuk menghitung BBI Dewasa (Rumus Broca modifikasi)
  /// Laki-laki : (TB - 100) * 0.90
  /// Perempuan : (TB - 100) * 0.85
  static double computeBBI(double heightCm, String gender) {
    final double base = heightCm - 100;
    return gender == male ? base * 0.90 : base * 0.85;
  }
}

void main() {
  group('Unit Test: Akurasi Perhitungan BBI Dewasa', () {
    
    test('Perhitungan BBI Laki-laki: (TB - 100) * 90%', () {
      // Tinggi 170 cm -> (170 - 100) * 0.90 = 63.0
      expect(BbiCalculator.computeBBI(170, BbiCalculator.male), 63.0);
      
      // Tinggi 180 cm -> (180 - 100) * 0.90 = 72.0
      expect(BbiCalculator.computeBBI(180, BbiCalculator.male), 72.0);
    });

    test('Perhitungan BBI Perempuan: (TB - 100) * 85%', () {
      // Tinggi 160 cm -> (160 - 100) * 0.85 = 51.0
      expect(BbiCalculator.computeBBI(160, BbiCalculator.female), 51.0);
      
      // Tinggi 150 cm -> (150 - 100) * 0.85 = 42.5
      expect(BbiCalculator.computeBBI(150, BbiCalculator.female), 42.5);
    });

    test('Kembalikan nilai default fallback jika gender tidak dikenali (menggunakan pengali 85%)', () {
      // Secara default fungsi di atas akan masuk ke fallback * 0.85 jika string tidak "Laki-laki"
      expect(BbiCalculator.computeBBI(160, 'Tidak Diketahui'), 51.0);
    });
  });
}