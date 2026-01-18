// lib/src/features/disease_calculation/application/services/diabetes_calculator_service.dart

// KELAS BARU: Untuk menyimpan informasi lengkap tentang jenis diet
class DietInfo {
  final String name;
  final double protein;
  final double fat;
  final double carbohydrate;

  DietInfo({
    required this.name,
    required this.protein,
    required this.fat,
    required this.carbohydrate,
  });
}

// KELAS BARU: Untuk standar diet golongan bahan makanan
class FoodGroupDiet {
  final String calorieLevel;
  final double nasiP;
  final double ikanP;
  final double dagingP;
  final String sayuranA;
  final double sayuranB;
  final double buah;
  final double susu;
  final double minyak;
  final double tempeP;

  FoodGroupDiet({
    required this.calorieLevel,
    required this.nasiP,
    required this.ikanP,
    required this.dagingP,
    required this.sayuranA,
    required this.sayuranB,
    required this.buah,
    required this.susu,
    required this.minyak,
    required this.tempeP,
  });
}

// KELAS BARU: Untuk menyimpan data per waktu makan (SUDAH DIPERBAIKI)
class MealDistribution {
  final double nasiP;
  final double ikanP;
  final double dagingP;
  final String sayuranA; // DIUBAH: dari double ke String
  final double sayuranB;
  final double buah;
  final double susu;
  final double tempeP;
  final double minyak;

  MealDistribution({
    this.nasiP = 0,
    this.ikanP = 0,
    this.dagingP = 0,
    this.sayuranA = '', // DIUBAH: default value ke string kosong
    this.sayuranB = 0,
    this.buah = 0,
    this.susu = 0,
    this.tempeP = 0,
    this.minyak = 0,
  });
}

// KELAS BARU: Untuk menyimpan pembagian makanan sepanjang hari
class DailyMealDistribution {
  final String calorieLevel;
  final MealDistribution pagi;
  final MealDistribution snackPagi;
  final MealDistribution siang;
  final MealDistribution snackSore;
  final MealDistribution malam;

  DailyMealDistribution({
    required this.calorieLevel,
    required this.pagi,
    required this.snackPagi,
    required this.siang,
    required this.snackSore,
    required this.malam,
  });
}

class DiabetesCalculationResult {
  final double bbIdeal;
  final double bmr;
  final double totalCalories;
  final double ageCorrection;
  final double activityCorrection;
  final double weightCorrection;
  final String bmiCategory;
  final DietInfo dietInfo;
  final FoodGroupDiet foodGroupDiet;
  final DailyMealDistribution dailyMealDistribution;

  DiabetesCalculationResult({
    required this.bbIdeal,
    required this.bmr,
    required this.totalCalories,
    required this.ageCorrection,
    required this.activityCorrection,
    required this.weightCorrection,
    required this.bmiCategory,
    required this.dietInfo,
    required this.foodGroupDiet,
    required this.dailyMealDistribution,
  });
}

class DiabetesCalculatorService {
  DiabetesCalculationResult calculate({
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activity,
    required String hospitalizedStatus,
    required double stressMetabolic,
    //required String bloodSugar,
    //required String bloodPressure,
  }) {
    final bbIdeal = _calculateBBIdeal(height, gender);
    final bmiCategory = _calculateBMICategory(weight, height);
    final bmr = (gender == 'Laki-laki') ? bbIdeal * 30 : bbIdeal * 25;

    double activityFactor = 0;
    switch (activity) {
      case 'Bed rest':
        activityFactor = 0.1;
        break;
      case 'Ringan':
        activityFactor = 0.2;
        break;
      case 'Sedang':
        activityFactor = 0.3;
        break;
      case 'Berat':
        activityFactor = 0.4;
        break;
    }

    final activityCorrection = activityFactor * bmr;
    final weightCorrection = _calculateWeightCorrection(bmiCategory, bmr);

    double totalCalories = bmr + activityCorrection + weightCorrection;

    double ageCorrection = 0;

    // Cek umur diatas atau sama dengan 70 tahun (20%)
    if (age >= 70) {
      ageCorrection = bmr * 0.20;
    } 
    // Cek umur 60 - 69 tahun (10%)
    else if (age >= 60) {
      ageCorrection = bmr * 0.10;
    } 
    // Cek umur 40 - 59 tahun (5%)
    else if (age >= 40) {
      ageCorrection = bmr * 0.05;
    }
    
    totalCalories -= ageCorrection;

    double stressMetabolicCorrection = 0;
    if (hospitalizedStatus == 'Ya') {
      stressMetabolicCorrection = (stressMetabolic / 100) * bmr;
      totalCalories += stressMetabolicCorrection;
    }

    /*if (bloodSugar == 'Tidak terkendali') {
      totalCalories *= 0.9;
    }

    if (bloodPressure == 'Tinggi') {
      totalCalories *= 0.95;
    }*/

    final dietInfo = _getDietType(totalCalories);
    final foodGroupDiet = _getFoodGroupDiet(totalCalories);
    final dailyMealDistribution = _getDailyMealDistribution(totalCalories);

    return DiabetesCalculationResult(
      bbIdeal: bbIdeal,
      bmr: bmr,
      totalCalories: totalCalories,
      ageCorrection: ageCorrection,
      activityCorrection: activityCorrection,
      weightCorrection: weightCorrection,
      bmiCategory: bmiCategory,
      dietInfo: dietInfo,
      foodGroupDiet: foodGroupDiet,
      dailyMealDistribution: dailyMealDistribution,
    );
  }

  double _calculateBBIdeal(double height, String gender) {
    double bbIdeal;

    if (gender == 'Laki-laki') {
      if (height >= 160) {
        bbIdeal = (height - 100) * 0.9; // (TB-100)-10%
      } else {
        bbIdeal = height - 100; // (TB-100)
      }
    } else {
      // Perempuan
      if (height >= 150) {
        bbIdeal = (height - 100) * 0.9; // (TB-100)-10%
      } else {
        bbIdeal = height - 100; // (TB-100)
      }
    }

    return bbIdeal;
  }

  String _calculateBMICategory(double weight, double height) {
    double bmi = weight / ((height / 100) * (height / 100));
    if (bmi < 18.5) {
      return 'Kurang';
    } else if (bmi >= 18.5 && bmi < 23) {
      return 'Normal';
    } else if (bmi >= 23 && bmi < 25) {
      return 'Lebih';
    } else {
      return 'Gemuk';
    }
  }

  double _calculateWeightCorrection(String bmiCategory, double bmr) {
    if (bmiCategory == 'Normal') {
      return 0;
    }

    switch (bmiCategory) {
      case 'Gemuk':
        return -0.2 * bmr; // (-) 20%
      case 'Lebih':
        return -0.1 * bmr; // (-) 10%
      case 'Kurang':
        return 0.2 * bmr; // (+) 20%
      default:
        return 0;
    }
  }

  // DIUBAH: Fungsi ini sekarang mengembalikan objek DietInfo
  DietInfo _getDietType(double totalCalories) {
    if (totalCalories < 1200) {
      return DietInfo(
        name: 'Diet I (1100 kkal)',
        protein: 43,
        fat: 30,
        carbohydrate: 172,
      );
    }
    if (totalCalories < 1400) {
      return DietInfo(
        name: 'Diet II (1300 kkal)',
        protein: 45,
        fat: 35,
        carbohydrate: 192,
      );
    }
    if (totalCalories < 1600) {
      return DietInfo(
        name: 'Diet III (1500 kkal)',
        protein: 51.5,
        fat: 36.5,
        carbohydrate: 235,
      );
    }
    if (totalCalories < 1800) {
      return DietInfo(
        name: 'Diet IV (1700 kkal)',
        protein: 55.5,
        fat: 36.5,
        carbohydrate: 275,
      );
    }
    if (totalCalories < 2000) {
      return DietInfo(
        name: 'Diet V (1900 kkal)',
        protein: 60,
        fat: 48,
        carbohydrate: 299,
      );
    }
    if (totalCalories < 2200) {
      return DietInfo(
        name: 'Diet VI (2100 kkal)',
        protein: 62,
        fat: 53,
        carbohydrate: 319,
      );
    }
    if (totalCalories < 2400) {
      return DietInfo(
        name: 'Diet VII (2300 kkal)',
        protein: 73,
        fat: 59,
        carbohydrate: 369,
      );
    }
    return DietInfo(
      name: 'Diet VIII (2500 kkal)',
      protein: 80,
      fat: 62,
      carbohydrate: 396,
    );
  }

  FoodGroupDiet _getFoodGroupDiet(double totalCalories) {
    if (totalCalories < 1200) {
      return FoodGroupDiet(
        calorieLevel: '1100 kkal',
        nasiP: 2.5,
        ikanP: 2,
        dagingP: 1,
        tempeP: 2,
        sayuranA: 'S',
        sayuranB: 2,
        buah: 4,
        susu: 0,
        minyak: 3,
      );
    }
    if (totalCalories < 1400) {
      return FoodGroupDiet(
        calorieLevel: '1300 kkal',
        nasiP: 3,
        ikanP: 2,
        dagingP: 1,
        tempeP: 2,
        sayuranA: 'S',
        sayuranB: 2,
        buah: 4,
        susu: 0,
        minyak: 4,
      );
    }
    if (totalCalories < 1600) {
      return FoodGroupDiet(
        calorieLevel: '1500 kkal',
        nasiP: 4,
        ikanP: 2,
        dagingP: 1,
        tempeP: 2.5,
        sayuranA: 'S',
        sayuranB: 2,
        buah: 4,
        susu: 0,
        minyak: 4,
      );
    }
    if (totalCalories < 1800) {
      return FoodGroupDiet(
        calorieLevel: '1700 kkal',
        nasiP: 5,
        ikanP: 2,
        dagingP: 1,
        tempeP: 2.5,
        sayuranA: 'S',
        sayuranB: 2,
        buah: 4,
        susu: 0,
        minyak: 4,
      );
    }
    if (totalCalories < 2000) {
      return FoodGroupDiet(
        calorieLevel: '1900 kkal',
        nasiP: 5.5,
        ikanP: 2,
        dagingP: 1,
        tempeP: 3,
        sayuranA: 'S',
        sayuranB: 2,
        buah: 4,
        susu: 0,
        minyak: 6,
      );
    }
    if (totalCalories < 2200) {
      return FoodGroupDiet(
        calorieLevel: '2100 kkal',
        nasiP: 6,
        ikanP: 2,
        dagingP: 1,
        tempeP: 3,
        sayuranA: 'S',
        sayuranB: 2,
        buah: 4,
        susu: 0,
        minyak: 7,
      );
    }
    if (totalCalories < 2400) {
      return FoodGroupDiet(
        calorieLevel: '2300 kkal',
        nasiP: 7,
        ikanP: 2,
        dagingP: 1,
        tempeP: 3,
        sayuranA: 'S',
        sayuranB: 2,
        buah: 4,
        susu: 1,
        minyak: 7,
      );
    }
    return FoodGroupDiet(
      calorieLevel: '2500 kkal',
      nasiP: 7.5,
      ikanP: 2,
      dagingP: 1,
      tempeP: 5,
      sayuranA: 'S',
      sayuranB: 2,
      buah: 4,
      susu: 1,
      minyak: 7,
    );
  }

   // FUNGSI INI DIUBAH TOTAL DENGAN DATA YANG BENAR
  DailyMealDistribution _getDailyMealDistribution(double totalCalories) {
    if (totalCalories < 1200) { // 1100 kkal
      return DailyMealDistribution(
        calorieLevel: '1100 kkal',
        pagi: MealDistribution(nasiP: 0.5, ikanP: 1, sayuranA: 'S', minyak: 1),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 1, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
      );
    }
    if (totalCalories < 1400) { // 1300 kkal
      return DailyMealDistribution(
        calorieLevel: '1300 kkal',
        pagi: MealDistribution(nasiP: 1, ikanP: 1, sayuranA: 'S', minyak: 1),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 1, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
      );
    }
    if (totalCalories < 1600) { // 1500 kkal
      return DailyMealDistribution(
        calorieLevel: '1500 kkal',
        pagi: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 0.5, sayuranA: 'S', minyak: 1),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 2, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
      );
    }
    if (totalCalories < 1800) { // 1700 kkal
      return DailyMealDistribution(
        calorieLevel: '1700 kkal',
        pagi: MealDistribution(nasiP: 1, ikanP: 1, tempeP: 0.5, sayuranA: 'S', minyak: 1),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 2, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 2, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 1),
      );
    }
    if (totalCalories < 2000) { // 1900 kkal
      return DailyMealDistribution(
        calorieLevel: '1900 kkal',
        pagi: MealDistribution(nasiP: 1.5, ikanP: 1, tempeP: 1, sayuranA: 'S', minyak: 2),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 2, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 2, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
      );
    }
    if (totalCalories < 2200) { // 2100 kkal
      return DailyMealDistribution(
        calorieLevel: '2100 kkal',
        pagi: MealDistribution(nasiP: 1.5, ikanP: 1, tempeP: 1, sayuranA: 'S', minyak: 2),
        snackPagi: MealDistribution(buah: 1),
        siang: MealDistribution(nasiP: 2.5, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 3),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 2, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
      );
    }
    if (totalCalories < 2400) { // 2300 kkal
      return DailyMealDistribution(
        calorieLevel: '2300 kkal',
        pagi: MealDistribution(nasiP: 1.5, ikanP: 1, tempeP: 1, sayuranA: 'S', minyak: 2),
        snackPagi: MealDistribution(buah: 1, susu: 1),
        siang: MealDistribution(nasiP: 3, dagingP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah:1, minyak: 3),
        snackSore: MealDistribution(buah: 1),
        malam: MealDistribution(nasiP: 2.5, ikanP: 1, tempeP: 1, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
      );
    }
    // Default to 2500 kkal
    return DailyMealDistribution(
      calorieLevel: '2500 kkal',
      pagi: MealDistribution(nasiP: 2, ikanP: 1, tempeP: 1, sayuranA: 'S', minyak: 2),
      snackPagi: MealDistribution(buah: 1, susu: 1),
      siang: MealDistribution(nasiP: 3, dagingP: 1, tempeP: 2, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 3),
      snackSore: MealDistribution(buah: 1),
      malam: MealDistribution(nasiP: 2.5, ikanP: 1, tempeP: 2, sayuranA: 'S', sayuranB: 1, buah: 1, minyak: 2),
    );
  }

}
