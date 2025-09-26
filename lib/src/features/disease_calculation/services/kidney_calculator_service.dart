// lib/src/features/disease_calculation/services/kidney_calculator_service.dart

/// Kelas untuk menampung hasil kalkulasi diet ginjal.
class KidneyDietResult {
  final double idealBodyWeight;
  final double proteinNeeds;
  final double bmr;
  final int recommendedDiet;
  final bool isDialysis;

  KidneyDietResult({
    required this.idealBodyWeight,
    required this.proteinNeeds,
    required this.bmr,
    required this.recommendedDiet,
    required this.isDialysis,
  });
}

/// Kelas layanan untuk logika kalkulasi diet ginjal.
class KidneyCalculatorService {
  /// Menghitung BBI, kebutuhan protein, dan rekomendasi diet.
  ///
  /// [height]: Tinggi badan dalam cm.
  /// [isDialysis]: Status apakah pasien menjalani cuci darah (hemodialisis).
  /// [gender]: Jenis kelamin pasien (Laki-laki/Perempuan)
  KidneyDietResult calculate({
    required double height,
    required bool isDialysis,
    required String gender,
    required int age,
  }) {
    // Langkah 1: Hitung Berat Badan Ideal (BBI) menggunakan rumus Broca.
    final double idealBodyWeight = _calculateIdealBodyWeight(height, gender);

    // Langkah 2: Hitung BMR berdasarkan usia dan jenis kelamin.
    final double bmr;
    if (gender == 'Laki-laki') {
      bmr = (age < 60) ? idealBodyWeight * 35 : idealBodyWeight * 30;
    } else {
      bmr = (age < 60) ? idealBodyWeight * 30 : idealBodyWeight * 25;
    }

    // Langkah 2: Tentukan kebutuhan protein berdasarkan status dialisis.
    final double proteinNeeds;
    if (isDialysis) {
      // Untuk pasien hemodialisis (HD), kebutuhan protein lebih tinggi.
      // Sesuai buku panduan: 1.2 g/kg BBI.
      proteinNeeds = 1.2 * idealBodyWeight;
    } else {
      // Untuk pasien pre-dialisis (belum cuci darah), kebutuhan protein akan diisi melalui form input.
      proteinNeeds = 0.6 * idealBodyWeight;
    }

    // Langkah 3: Tentukan kategori diet terdekat dari hasil perhitungan.
    final int recommendedDiet = _getRecommendedDiet(proteinNeeds, isDialysis);

    // Kembalikan hasil dalam bentuk objek KidneyDietResult.
    return KidneyDietResult(
      idealBodyWeight: idealBodyWeight,
      proteinNeeds: proteinNeeds,
      bmr: bmr,
      recommendedDiet: recommendedDiet,
      isDialysis: isDialysis,
    );
  }

  /// Menghitung Berat Badan Ideal (BBI) dengan rumus Broca, differentiated by gender.
  /// BBI = (Tinggi Badan (cm) - 100) - 10% (for tall individuals)
  /// BBI = (Tinggi Badan (cm) - 100) (for short individuals)
  double _calculateIdealBodyWeight(double height, String gender) {
    double idealBodyWeight;

    if (gender == 'Laki-laki') {
      if (height >= 160) {
        idealBodyWeight = (height - 100) * 0.9; // (TB-100)-10%
      } else {
        idealBodyWeight = height - 100; // (TB-100)
      }
    } else {
      // Perempuan
      if (height >= 150) {
        idealBodyWeight = (height - 100) * 0.9; // (TB-100)-10%
      } else {
        idealBodyWeight = height - 100; // (TB-100)
      }
    }

    return idealBodyWeight;
  }

  /// Menemukan nilai diet terdekat dari daftar yang tersedia.
  int _getRecommendedDiet(double calculatedProtein, bool isDialysis) {
    final List<int> dietOptions = isDialysis ? [60, 65, 70] : [30, 35, 40];

    // Temukan diet yang selisihnya paling kecil dengan kebutuhan protein hasil hitung.
    return dietOptions.reduce(
        (a, b) => (a - calculatedProtein).abs() < (b - calculatedProtein).abs() ? a : b);
  }
}