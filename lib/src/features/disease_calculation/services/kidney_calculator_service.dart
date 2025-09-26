// lib/src/features/disease_calculation/services/kidney_calculator_service.dart

class KidneyDietNutrition {
  final int energi;
  final int protein;
  final int lemak;
  final int karbohidrat;
  final int kalsium;
  final double zatBesi;
  final int fosfor;
  final int vitaminA;
  final double tiamin;
  final int vitaminC;
  final int natrium;
  final int kalium;

  KidneyDietNutrition({
    required this.energi,
    required this.protein,
    required this.lemak,
    required this.karbohidrat,
    required this.kalsium,
    required this.zatBesi,
    required this.fosfor,
    required this.vitaminA,
    required this.tiamin,
    required this.vitaminC,
    required this.natrium,
    required this.kalium,
  });
}

/// Kelas untuk menampung hasil kalkulasi diet ginjal.
class KidneyDietResult {
  final double idealBodyWeight;
  final double proteinNeeds;
  final double bmr;
  final int recommendedDiet;
  final bool isDialysis;
  final KidneyDietNutrition? nutritionInfo;

  KidneyDietResult({
    required this.idealBodyWeight,
    required this.proteinNeeds,
    required this.bmr,
    required this.recommendedDiet,
    required this.isDialysis,
    this.nutritionInfo,
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
    double? proteinFactor,
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
      assert(proteinFactor != null,
          'Protein factor must be provided for non-dialysis patients.');
      proteinNeeds = proteinFactor! * idealBodyWeight;
    }

    // Langkah 3: Tentukan kategori diet terdekat dari hasil perhitungan.
    final int recommendedDiet = _getRecommendedDiet(proteinNeeds, isDialysis);
    final KidneyDietNutrition? nutritionInfo = _kidneyDietData[recommendedDiet];

    // Kembalikan hasil dalam bentuk objek KidneyDietResult.
    return KidneyDietResult(
      idealBodyWeight: idealBodyWeight,
      proteinNeeds: proteinNeeds,
      bmr: bmr,
      recommendedDiet: recommendedDiet,
      isDialysis: isDialysis,
      nutritionInfo: nutritionInfo,
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

final Map<int, KidneyDietNutrition> _kidneyDietData = {
  // Data dari gambar pertama
  30: KidneyDietNutrition(
    energi: 1798,
    protein: 30,
    lemak: 63,
    karbohidrat: 160,
    kalsium: 190,
    kalium: 1219,
    fosfor: 452,
    natrium: 157,
    zatBesi: 4.3,
    vitaminA: 0, // Nilai default, tidak ada di gambar pertama
    tiamin: 0,   // Nilai default
    vitaminC: 0,   // Nilai default
  ),
  35: KidneyDietNutrition(
    energi: 1873,
    protein: 35,
    lemak: 61,
    karbohidrat: 117,
    kalsium: 190,
    kalium: 1099,
    fosfor: 452,
    natrium: 156,
    zatBesi: 4.3,
    vitaminA: 0,
    tiamin: 0,
    vitaminC: 0,
  ),
  40: KidneyDietNutrition(
    energi: 2085,
    protein: 41,
    lemak: 63,
    karbohidrat: 161,
    kalsium: 190,
    kalium: 1219,
    fosfor: 452,
    natrium: 157,
    zatBesi: 4.3,
    vitaminA: 0,
    tiamin: 0,
    vitaminC: 0,
  ),
  // Data dari gambar kedua
  60: KidneyDietNutrition(
    energi: 2000,
    protein: 62,
    lemak: 67,
    karbohidrat: 290,
    kalsium: 547,
    zatBesi: 21.5,
    fosfor: 917,
    vitaminA: 38630,
    tiamin: 0.8,
    vitaminC: 254,
    natrium: 400,
    kalium: 2156,
  ),
  65: KidneyDietNutrition(
    energi: 2040,
    protein: 67,
    lemak: 68,
    karbohidrat: 293,
    kalsium: 579,
    zatBesi: 24,
    fosfor: 957,
    vitaminA: 38643,
    tiamin: 0.8,
    vitaminC: 254,
    natrium: 400,
    kalium: 2156,
  ),
  70: KidneyDietNutrition(
    energi: 2130,
    protein: 72,
    lemak: 72,
    karbohidrat: 301,
    kalsium: 583,
    zatBesi: 24.8,
    fosfor: 1013,
    vitaminA: 38652,
    tiamin: 0.8,
    vitaminC: 423,
    natrium: 400,
    kalium: 2288,
  ),
};