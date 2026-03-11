// test/features/food_database/food_nutrition_calculation_test.dart
//
// Pengujian unit untuk:
//   1. FoodItem model  — nutritionPer100g, getNutritionPerGram,
//                        allNutrition, significantNutrition
//   2. NutritionCalculatorService — validate + calculate
//
// Jalankan dengan:
//   flutter test test/features/food_database/food_nutrition_calculation_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

/// Enum untuk merepresentasikan hasil validasi input takaran.
enum PortionValidationResult {
  valid,
  emptyInput,
  invalidNumber,
  zeroOrNegative,
  zeroBasePortion,
}

/// Service untuk menghitung nilai gizi berdasarkan takaran yang dimasukkan pengguna.
class NutritionCalculatorService {
  /// Memvalidasi teks input takaran (gram) sebelum kalkulasi.
  ///
  /// Mengembalikan [PortionValidationResult.valid] jika input valid,
  /// atau nilai enum yang sesuai jika ada kesalahan.
  static PortionValidationResult validatePortionInput({
    required String portionText,
    required num basePortion,
  }) {
    if (portionText.trim().isEmpty) {
      return PortionValidationResult.emptyInput;
    }

    final num? parsed = num.tryParse(portionText);
    if (parsed == null) {
      return PortionValidationResult.invalidNumber;
    }

    if (parsed <= 0) {
      return PortionValidationResult.zeroOrNegative;
    }

    if (basePortion == 0) {
      return PortionValidationResult.zeroBasePortion;
    }

    return PortionValidationResult.valid;
  }

  /// Menghitung nilai gizi untuk takaran [portionGram] gram
  /// berdasarkan data [foodItem].
  ///
  /// Mengembalikan [Map<String, num>] yang berisi setiap nutrisi yang telah
  /// diskalakan sesuai takaran yang diminta.
  ///
  /// Melempar [ArgumentError] jika [portionGram] <= 0
  /// atau jika [foodItem.portionGram] == 0.
  static Map<String, num> calculate({
    required FoodItem foodItem,
    required num portionGram,
  }) {
    if (portionGram <= 0) {
      throw ArgumentError('portionGram harus lebih dari 0, dapat: $portionGram');
    }
    if (foodItem.portionGram == 0) {
      throw ArgumentError('portionGram pada FoodItem tidak boleh 0.');
    }

    final num ratio = portionGram / foodItem.portionGram;

    return {
      'air': foodItem.air * ratio,
      'energi': foodItem.calories * ratio,
      'protein': foodItem.protein * ratio,
      'lemak': foodItem.fat * ratio,
      'karbohidrat': foodItem.karbohidrat * ratio,
      'serat': foodItem.fiber * ratio,
      'abu': foodItem.abu * ratio,
      'kalsium': foodItem.kalsium * ratio,
      'fosfor': foodItem.fosfor * ratio,
      'besi': foodItem.besi * ratio,
      'natrium': foodItem.natrium * ratio,
      'kalium': foodItem.kalium * ratio,
      'tembaga': foodItem.tembaga * ratio,
      'seng': foodItem.seng * ratio,
      'retinol': foodItem.retinol * ratio,
      'betaKaroten': foodItem.betaKaroten * ratio,
      'karotenTotal': foodItem.karotenTotal * ratio,
      'thiamin': foodItem.thiamin * ratio,
      'riboflavin': foodItem.riboflavin * ratio,
      'niasin': foodItem.niasin * ratio,
      'vitaminC': foodItem.vitaminC * ratio,
    };
  }
}





// ---------------------------------------------------------------------------
// Helper: FoodItem fixture
// ---------------------------------------------------------------------------

/// Membuat FoodItem contoh dengan porsi dasar 100 g agar rasio = 1 sehingga
/// hasil kalkulasi mudah diverifikasi secara manual.
FoodItem _makeFoodItem100g() => FoodItem(
      id: 'test-001',
      name: 'Nasi Putih',
      code: 'NP-001',
      mentahOlahan: 'Olahan',
      kelompokMakanan: 'Serealia',
      portionGram: 100,
      air: 60.0,
      calories: 175.0,
      protein: 3.5,
      fat: 0.3,
      karbohidrat: 40.6,
      fiber: 0.2,
      abu: 0.3,
      kalsium: 5.0,
      fosfor: 60.0,
      besi: 0.5,
      natrium: 5.0,
      kalium: 55.0,
      tembaga: 0.1,
      seng: 0.6,
      retinol: 0.0,
      betaKaroten: 0.0,
      karotenTotal: 0.0,
      thiamin: 0.02,
      riboflavin: 0.01,
      niasin: 1.4,
      vitaminC: 0.0,
      bdd: 100.0,
    );

/// FoodItem dengan porsi dasar 200 g (rasio = 0,5 untuk 100 g).
FoodItem _makeFoodItem200g() => FoodItem(
      id: 'test-002',
      name: 'Ayam Goreng',
      code: 'AG-001',
      mentahOlahan: 'Olahan',
      kelompokMakanan: 'Daging',
      portionGram: 200,
      air: 50.0,
      calories: 290.0,
      protein: 28.0,
      fat: 16.0,
      karbohidrat: 10.0,
      fiber: 0.0,
      abu: 2.0,
      kalsium: 14.0,
      fosfor: 180.0,
      besi: 1.5,
      natrium: 70.0,
      kalium: 300.0,
      tembaga: 0.08,
      seng: 1.8,
      retinol: 12.0,
      betaKaroten: 0.0,
      karotenTotal: 0.0,
      thiamin: 0.08,
      riboflavin: 0.16,
      niasin: 6.0,
      vitaminC: 0.0,
      bdd: 82.0,
    );

/// FoodItem dengan portionGram = 0 (edge-case).
FoodItem _makeFoodItemZeroPortion() => FoodItem(
      id: 'test-003',
      name: 'Makanan Tak Diketahui',
      code: 'MTD-001',
      mentahOlahan: 'Mentah',
      kelompokMakanan: 'Lainnya',
      portionGram: 0,
      air: 0,
      calories: 0,
      protein: 0,
      fat: 0,
      karbohidrat: 0,
      fiber: 0,
      abu: 0,
      kalsium: 0,
      fosfor: 0,
      besi: 0,
      natrium: 0,
      kalium: 0,
      tembaga: 0,
      seng: 0,
      retinol: 0,
      betaKaroten: 0,
      karotenTotal: 0,
      thiamin: 0,
      riboflavin: 0,
      niasin: 0,
      vitaminC: 0,
      bdd: 0,
    );

// ---------------------------------------------------------------------------
// Matcher toleransi floating point
// ---------------------------------------------------------------------------
Matcher closeTo(num value, [double delta = 1e-9]) =>
    inInclusiveRange(value - delta, value + delta);

// ---------------------------------------------------------------------------
// 1. FoodItem — allNutrition
// ---------------------------------------------------------------------------
void main() {
  group('FoodItem.allNutrition', () {
    late FoodItem food;

    setUp(() => food = _makeFoodItem100g());

    test('mengembalikan map dengan 22 kunci', () {
      expect(food.allNutrition.length, equals(22));
    });

    test('nilai energi sesuai dengan field calories', () {
      expect(food.allNutrition['energi'], equals(food.calories));
    });

    test('semua kunci wajib ada', () {
      final keys = [
        'air', 'energi', 'protein', 'lemak', 'karbohidrat', 'serat', 'abu',
        'kalsium', 'fosfor', 'besi', 'natrium', 'kalium', 'tembaga', 'seng',
        'retinol', 'beta_karoten', 'karoten_total', 'thiamin', 'riboflavin',
        'niasin', 'vitamin_c', 'bdd',
      ];
      for (final key in keys) {
        expect(food.allNutrition.containsKey(key), isTrue,
            reason: 'Kunci "$key" tidak ditemukan di allNutrition');
      }
    });

    test('nilai tidak berubah (immutable snapshot)', () {
      final n1 = food.allNutrition;
      final n2 = food.allNutrition;
      expect(n1['protein'], equals(n2['protein']));
    });
  });

  // -------------------------------------------------------------------------
  // 2. FoodItem — nutritionPer100g
  // -------------------------------------------------------------------------
  group('FoodItem.nutritionPer100g', () {
    group('porsi dasar 100 g — rasio = 1, nilai harus sama', () {
      late FoodItem food;
      setUp(() => food = _makeFoodItem100g());

      test('energi per 100 g == energi asli', () {
        expect(food.nutritionPer100g['energi'], closeTo(175.0));
      });

      test('protein per 100 g == protein asli', () {
        expect(food.nutritionPer100g['protein'], closeTo(3.5));
      });

      test('lemak per 100 g == lemak asli', () {
        expect(food.nutritionPer100g['lemak'], closeTo(0.3));
      });

      test('karbohidrat per 100 g == karbohidrat asli', () {
        expect(food.nutritionPer100g['karbohidrat'], closeTo(40.6));
      });

      test('air per 100 g == air asli', () {
        expect(food.nutritionPer100g['air'], closeTo(60.0));
      });
    });

    group('porsi dasar 200 g — rasio = 0.5', () {
      late FoodItem food;
      setUp(() => food = _makeFoodItem200g());

      test('energi per 100 g == 290 / 2 = 145', () {
        expect(food.nutritionPer100g['energi'], closeTo(145.0));
      });

      test('protein per 100 g == 28 / 2 = 14', () {
        expect(food.nutritionPer100g['protein'], closeTo(14.0));
      });

      test('kalsium per 100 g == 14 / 2 = 7', () {
        expect(food.nutritionPer100g['kalsium'], closeTo(7.0));
      });

      test('bdd per 100 g == 82 / 2 = 41', () {
        expect(food.nutritionPer100g['bdd'], closeTo(41.0));
      });
    });

    group('porsi dasar 0 g — semua nilai harus 0 (guard division-by-zero)', () {
      late FoodItem food;
      setUp(() => food = _makeFoodItemZeroPortion());

      test('energi per 100 g == 0', () {
        expect(food.nutritionPer100g['energi'], equals(0));
      });

      test('protein per 100 g == 0', () {
        expect(food.nutritionPer100g['protein'], equals(0));
      });

      test('semua nilai == 0', () {
        food.nutritionPer100g.forEach((key, value) {
          expect(value, equals(0),
              reason: 'Nilai "$key" seharusnya 0 saat portionGram = 0');
        });
      });

      test('mengembalikan map 21 kunci (tidak crash)', () {
        expect(food.nutritionPer100g.length, equals(21));
      });
    });
  });

  // -------------------------------------------------------------------------
  // 3. FoodItem — getNutritionPerGram
  // -------------------------------------------------------------------------
  group('FoodItem.getNutritionPerGram', () {
    late FoodItem food100;
    late FoodItem food200;

    setUp(() {
      food100 = _makeFoodItem100g();
      food200 = _makeFoodItem200g();
    });

    test('porsi dasar 100 g, input 100 g → rasio 1, energi = 175', () {
      final result = food100.getNutritionPerGram(100);
      expect(result['energi'], closeTo(175.0));
    });

    test('porsi dasar 100 g, input 200 g → rasio 2, energi = 350', () {
      final result = food100.getNutritionPerGram(200);
      expect(result['energi'], closeTo(350.0));
    });

    test('porsi dasar 100 g, input 50 g → rasio 0.5, protein = 1.75', () {
      final result = food100.getNutritionPerGram(50);
      expect(result['protein'], closeTo(1.75));
    });

    test('porsi dasar 100 g, input 150 g → karbohidrat = 60.9', () {
      final result = food100.getNutritionPerGram(150);
      expect(result['karbohidrat'], closeTo(60.9));
    });

    test('porsi dasar 200 g, input 100 g → rasio 0.5, energi = 145', () {
      final result = food200.getNutritionPerGram(100);
      expect(result['energi'], closeTo(145.0));
    });

    test('porsi dasar 200 g, input 250 g → rasio 1.25, protein = 35', () {
      final result = food200.getNutritionPerGram(250);
      expect(result['protein'], closeTo(35.0));
    });

    test('porsi dasar 200 g, input 1 g → natrium = 0.35', () {
      final result = food200.getNutritionPerGram(1);
      expect(result['natrium'], closeTo(0.35));
    });

    test('input sangat kecil (0.1 g) tidak crash dan mendekati 0', () {
      final result = food100.getNutritionPerGram(0.1);
      expect(result['energi'], closeTo(0.175));
    });

    test('input sangat besar (10000 g) tidak crash', () {
      final result = food100.getNutritionPerGram(10000);
      expect(result['energi'], closeTo(17500.0));
    });

    group('portionGram dasar = 0 → semua nilai harus 0', () {
      late FoodItem foodZero;
      setUp(() => foodZero = _makeFoodItemZeroPortion());

      test('semua nilai 0 saat basePortion = 0', () {
        final result = foodZero.getNutritionPerGram(200);
        result.forEach((key, value) {
          expect(value, equals(0),
              reason: '"$key" seharusnya 0 saat portionGram dasar = 0');
        });
      });
    });
  });

  // -------------------------------------------------------------------------
  // 4. FoodItem — significantNutrition
  // -------------------------------------------------------------------------
  group('FoodItem.significantNutrition', () {
    test('hanya mengembalikan nutrisi dengan nilai > 0', () {
      final food = _makeFoodItem100g();
      final sig = food.significantNutrition;
      sig.forEach((key, value) {
        expect(value, greaterThan(0),
            reason: '"$key" dengan nilai $value seharusnya tidak ada');
      });
    });

    test('nutrisi bernilai 0 (retinol, betaKaroten, vitaminC) tidak masuk', () {
      final food = _makeFoodItem100g();
      final sig = food.significantNutrition;
      expect(sig.containsKey('retinol'), isFalse);
      expect(sig.containsKey('beta_karoten'), isFalse);
      expect(sig.containsKey('vitamin_c'), isFalse);
    });

    test('energi, protein, lemak harus masuk (> 0)', () {
      final food = _makeFoodItem100g();
      final sig = food.significantNutrition;
      expect(sig.containsKey('energi'), isTrue);
      expect(sig.containsKey('protein'), isTrue);
      expect(sig.containsKey('lemak'), isTrue);
    });

    test('makanan dengan semua nilai 0 → map kosong', () {
      final food = _makeFoodItemZeroPortion();
      expect(food.significantNutrition.isEmpty, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // 5. NutritionCalculatorService — validatePortionInput
  // -------------------------------------------------------------------------
  group('NutritionCalculatorService.validatePortionInput', () {
    const num basePortion = 100;

    test('input valid "150" → valid', () {
      expect(
        NutritionCalculatorService.validatePortionInput(
          portionText: '150',
          basePortion: basePortion,
        ),
        equals(PortionValidationResult.valid),
      );
    });

    test('input desimal "75.5" → valid', () {
      expect(
        NutritionCalculatorService.validatePortionInput(
          portionText: '75.5',
          basePortion: basePortion,
        ),
        equals(PortionValidationResult.valid),
      );
    });

    test('input kosong "" → emptyInput', () {
      expect(
        NutritionCalculatorService.validatePortionInput(
          portionText: '',
          basePortion: basePortion,
        ),
        equals(PortionValidationResult.emptyInput),
      );
    });

    test('input hanya spasi "   " → emptyInput', () {
      expect(
        NutritionCalculatorService.validatePortionInput(
          portionText: '   ',
          basePortion: basePortion,
        ),
        equals(PortionValidationResult.emptyInput),
      );
    });

    test('input bukan angka "abc" → invalidNumber', () {
      expect(
        NutritionCalculatorService.validatePortionInput(
          portionText: 'abc',
          basePortion: basePortion,
        ),
        equals(PortionValidationResult.invalidNumber),
      );
    });

    test('input dengan karakter campuran "12abc" → invalidNumber', () {
      expect(
        NutritionCalculatorService.validatePortionInput(
          portionText: '12abc',
          basePortion: basePortion,
        ),
        equals(PortionValidationResult.invalidNumber),
      );
    });

    test('input negatif "-50" → zeroOrNegative', () {
      expect(
        NutritionCalculatorService.validatePortionInput(
          portionText: '-50',
          basePortion: basePortion,
        ),
        equals(PortionValidationResult.zeroOrNegative),
      );
    });

    test('input nol "0" → zeroOrNegative', () {
      expect(
        NutritionCalculatorService.validatePortionInput(
          portionText: '0',
          basePortion: basePortion,
        ),
        equals(PortionValidationResult.zeroOrNegative),
      );
    });

    test('input valid tapi basePortion = 0 → zeroBasePortion', () {
      expect(
        NutritionCalculatorService.validatePortionInput(
          portionText: '100',
          basePortion: 0,
        ),
        equals(PortionValidationResult.zeroBasePortion),
      );
    });
  });

  // -------------------------------------------------------------------------
  // 6. NutritionCalculatorService — calculate
  // -------------------------------------------------------------------------
  group('NutritionCalculatorService.calculate', () {
    late FoodItem food100;
    late FoodItem food200;

    setUp(() {
      food100 = _makeFoodItem100g();
      food200 = _makeFoodItem200g();
    });

    // --- Kalkulasi normal ---

    test('100g dari porsi 100g → energi = 175', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 100,
      );
      expect(result['energi'], closeTo(175.0));
    });

    test('200g dari porsi 100g → energi = 350', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 200,
      );
      expect(result['energi'], closeTo(350.0));
    });

    test('50g dari porsi 100g → protein = 1.75', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 50,
      );
      expect(result['protein'], closeTo(1.75));
    });

    test('75g dari porsi 100g → lemak = 0.225', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 75,
      );
      expect(result['lemak'], closeTo(0.225));
    });

    test('250g dari porsi 200g → energi = 362.5', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food200,
        portionGram: 250,
      );
      expect(result['energi'], closeTo(362.5));
    });

    test('100g dari porsi 200g → kalsium = 7.0', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food200,
        portionGram: 100,
      );
      expect(result['kalsium'], closeTo(7.0));
    });

    // --- Hasil map harus memiliki 21 kunci (tanpa bdd) ---
    test('hasil memiliki tepat 21 kunci nutrisi', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 100,
      );
      expect(result.length, equals(21));
    });

    // --- Konsistensi: sama dengan getNutritionPerGram pada model ---
    test('hasil sama dengan FoodItem.getNutritionPerGram untuk 50g', () {
      final fromService = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 50,
      );
      final fromModel = food100.getNutritionPerGram(50);

      // Bandingkan kunci yang ada di service (21 kunci)
      fromService.forEach((key, serviceValue) {
        expect(
          fromModel[key],
          isNotNull,
          reason: 'Kunci "$key" tidak ada di getNutritionPerGram',
        );
        expect(
          fromModel[key],
          closeTo(serviceValue),
          reason: 'Nilai "$key" tidak konsisten antara service dan model',
        );
      });
    });

    // --- Mineral mikro ---
    test('100g dari porsi 100g → besi = 0.5', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 100,
      );
      expect(result['besi'], closeTo(0.5));
    });

    test('100g dari porsi 100g → natrium = 5.0', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 100,
      );
      expect(result['natrium'], closeTo(5.0));
    });

    test('100g dari porsi 100g → thiamin = 0.02', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 100,
      );
      expect(result['thiamin'], closeTo(0.02));
    });

    test('100g dari porsi 200g → retinol = 6.0 (12 / 2)', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food200,
        portionGram: 100,
      );
      expect(result['retinol'], closeTo(6.0));
    });

    // --- Guard: portionGram <= 0 melempar ArgumentError ---
    test('portionGram = 0 → ArgumentError', () {
      expect(
        () => NutritionCalculatorService.calculate(
          foodItem: food100,
          portionGram: 0,
        ),
        throwsArgumentError,
      );
    });

    test('portionGram negatif → ArgumentError', () {
      expect(
        () => NutritionCalculatorService.calculate(
          foodItem: food100,
          portionGram: -10,
        ),
        throwsArgumentError,
      );
    });

    test('foodItem.portionGram = 0 → ArgumentError', () {
      final foodZero = _makeFoodItemZeroPortion();
      expect(
        () => NutritionCalculatorService.calculate(
          foodItem: foodZero,
          portionGram: 100,
        ),
        throwsArgumentError,
      );
    });

    // --- Nilai kecil (presisi desimal) ---
    test('0.5g dari porsi 100g → niasin = 0.007', () {
      final result = NutritionCalculatorService.calculate(
        foodItem: food100,
        portionGram: 0.5,
      );
      expect(result['niasin'], closeTo(0.007));
    });
  });

  // -------------------------------------------------------------------------
  // 7. Integrasi: alur lengkap validasi → kalkulasi
  // -------------------------------------------------------------------------
  group('Integrasi: validatePortionInput → calculate', () {
    late FoodItem food;
    setUp(() => food = _makeFoodItem100g());

    test('skenario happy path: input "150" → protein = 5.25', () {
      const portionText = '150';

      final validation = NutritionCalculatorService.validatePortionInput(
        portionText: portionText,
        basePortion: food.portionGram,
      );
      expect(validation, equals(PortionValidationResult.valid));

      final portionGram = num.parse(portionText);
      final result = NutritionCalculatorService.calculate(
        foodItem: food,
        portionGram: portionGram,
      );
      expect(result['protein'], closeTo(5.25));
    });

    test('skenario gagal: input kosong → tidak sampai kalkulasi', () {
      final validation = NutritionCalculatorService.validatePortionInput(
        portionText: '',
        basePortion: food.portionGram,
      );
      expect(validation, isNot(equals(PortionValidationResult.valid)));
    });

    test('skenario gagal: foodItem.portionGram = 0 → tidak sampai kalkulasi', () {
      final foodZero = _makeFoodItemZeroPortion();
      final validation = NutritionCalculatorService.validatePortionInput(
        portionText: '100',
        basePortion: foodZero.portionGram,
      );
      expect(validation, equals(PortionValidationResult.zeroBasePortion));
    });

    test('skenario input "300" → air = 180', () {
      const portionText = '300';

      final validation = NutritionCalculatorService.validatePortionInput(
        portionText: portionText,
        basePortion: food.portionGram,
      );
      expect(validation, equals(PortionValidationResult.valid));

      final result = NutritionCalculatorService.calculate(
        foodItem: food,
        portionGram: num.parse(portionText),
      );
      expect(result['air'], closeTo(180.0));
    });
  });
}