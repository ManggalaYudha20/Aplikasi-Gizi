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
    required String bloodSugar,
    required String bloodPressure,
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
    if (age > 40) {
      ageCorrection = bmr * 0.05;
      totalCalories -= ageCorrection;
    }

    double stressMetabolicCorrection = 0;
    if (hospitalizedStatus == 'Ya') {
      stressMetabolicCorrection = (stressMetabolic / 100) * bmr;
      totalCalories += stressMetabolicCorrection;
    }

    if (bloodSugar == 'Tidak terkendali') {
      totalCalories *= 0.9;
    }

    if (bloodPressure == 'Tinggi') {
      totalCalories *= 0.95;
    }

    final dietInfo = _getDietType(totalCalories);
    final foodGroupDiet = _getFoodGroupDiet(totalCalories);

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
}
