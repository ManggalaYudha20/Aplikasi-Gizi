// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\nutrition_calculation\services\schofield_calculator_service.dart

class SchofieldCalculatorService {
  /// Menghitung BMR menggunakan formula Schofield berdasarkan Berat Badan saja.
  ///
  /// [weightKg] : Berat badan dalam kilogram (kg)
  /// [ageInYears] : Usia anak dalam tahun (bisa desimal, misal 2.5 untuk 2 tahun 6 bulan)
  /// [isMale] : true jika Laki-laki, false jika Perempuan
  static const Map<String, double> activityFactors = {
    'Tanpa Faktor Aktivitas': 1.0,
    'Aktivitas Sangat Ringan': 1.1,
    'Aktivitas Ringan': 1.2,
    'Aktivitas Sedang': 1.3,
    'Aktivitas Berat': 1.4,
    'Aktivitas Sangat Berat': 1.5,
  };

  static const Map<String, double> stressFactors = {
    'Tanpa Faktor Stres': 1.0,
    'Stres Sangat Ringan': 1.1,
    'Stres Ringan': 1.2,
    'Stres Sedang': 1.3,
    'Stres Berat': 1.4,
    'Stres Sangat Berat': 1.5,
  };

  static double calculateWithWeightOnly({
    required double weightKg,
    required double ageInYears,
    required bool isMale,
  }) {
    if (ageInYears < 0 || ageInYears > 18) {
      throw ArgumentError(
        'Formula Schofield didesain untuk anak dan remaja usia 0-18 tahun.',
      );
    }

    if (isMale) {
      if (ageInYears < 3) {
        return (59.512 * weightKg) - 30.4;
      } else if (ageInYears >= 3 && ageInYears <= 10) {
        return (22.7 * weightKg) + 504.3;
      } else {
        // Usia 10 - 18 tahun
        return (17.5 * weightKg) + 651;
      }
    } else {
      // Perempuan
      if (ageInYears < 3) {
        return (58.317 * weightKg) - 31.1;
      } else if (ageInYears >= 3 && ageInYears <= 10) {
        return (22.706 * weightKg) + 485.9;
      } else {
        // Usia 10 - 18 tahun
        return (13.384 * weightKg) + 692.6;
      }
    }
  }

  /// Menghitung BMR menggunakan formula Schofield berdasarkan Berat Badan dan Tinggi Badan.
  ///
  /// [weightKg] : Berat badan dalam kilogram (kg)
  /// [heightCm] : Tinggi badan dalam centimeter (cm). Akan dikonversi menjadi meter di dalam fungsi.
  /// [ageInYears] : Usia anak dalam tahun
  /// [isMale] : true jika Laki-laki, false jika Perempuan
  static double calculateWithWeightAndHeight({
    required double weightKg,
    required double heightCm,
    required double ageInYears,
    required bool isMale,
  }) {
    if (ageInYears < 0 || ageInYears > 18) {
      throw ArgumentError(
        'Formula Schofield didesain untuk anak dan remaja usia 0-18 tahun.',
      );
    }

    // Mengubah tinggi dari cm ke meter karena koefisien formula Schofield menggunakan Meter (H)
    double heightM = heightCm / 100.0;

    if (isMale) {
      if (ageInYears < 3) {
        return (0.167 * weightKg) + (1517.4 * heightM) - 616.6;
      } else if (ageInYears >= 3 && ageInYears <= 10) {
        return (19.59 * weightKg) + (130.3 * heightM) + 414.9;
      } else {
        // Usia 10 - 18 tahun
        return (16.25 * weightKg) + (137.2 * heightM) + 515.5;
      }
    } else {
      // Perempuan
      if (ageInYears < 3) {
        return (16.252 * weightKg) + (1023.3 * heightM) - 413.5;
      } else if (ageInYears >= 3 && ageInYears <= 10) {
        return (16.969 * weightKg) + (161.8 * heightM) + 371.2;
      } else {
        // Usia 10 - 18 tahun
        return (8.365 * weightKg) + (465 * heightM) + 200.0;
      }
    }
  }
}
