import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final String code;
  final String mentahOlahan;
  final String kelompokMakanan;
  final num portionGram;
  final num air;
  final num calories;
  final num protein;
  final num fat;
  final num karbohidrat;
  final num fiber;
  final num abu;
  final num kalsium;
  final num fosfor;
  final num besi;
  final num natrium;
  final num kalium;
  final num tembaga;
  final num seng;
  final num retinol;
  final num betaKaroten;
  final num karotenTotal;
  final num thiamin;
  final num riboflavin;
  final num niasin;
  final num vitaminC;
  final num bdd;
  FoodItem({
    this.id = '',
    required this.name,
    required this.code,
    required this.mentahOlahan,
    required this.kelompokMakanan,
    required this.portionGram,
    required this.air,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.karbohidrat,
    required this.fiber,
    required this.abu,
    required this.kalsium,
    required this.fosfor,
    required this.besi,
    required this.natrium,
    required this.kalium,
    required this.tembaga,
    required this.seng,
    required this.retinol,
    required this.betaKaroten,
    required this.karotenTotal,
    required this.thiamin,
    required this.riboflavin,
    required this.niasin,
    required this.vitaminC,
    required this.bdd,
  });

  // Method untuk mengubah objek menjadi format JSON yang siap diunggah ke Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'nama': name,
      'kode': code,
      'mentah_olahan': mentahOlahan,
      'kelompok_makanan': kelompokMakanan,
      'porsi_gram': portionGram,
      'air': air,
      'energi': calories,
      'protein': protein,
      'lemak': fat,
      'karbohidrat': karbohidrat,
      'serat': fiber,
      'abu': abu,
      'kalsium': kalsium,
      'fosfor': fosfor,
      'besi': besi,
      'natrium': natrium,
      'kalium': kalium,
      'tembaga': tembaga,
      'seng': seng,
      'retinol': retinol,
      'beta_karoten': betaKaroten,
      'karoten_total': karotenTotal,
      'thiamin': thiamin,
      'riboflavin': riboflavin,
      'niasin': niasin,
      'vitamin_c': vitaminC,
      'bdd': bdd,
    };
  }

  // Factory constructor untuk membuat instance FoodItem dari dokumen Firestore
  factory FoodItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FoodItem(
      id: doc.id,
      name: data['nama'] ?? '',
      code: data['kode'] ?? '',
      mentahOlahan: data['mentah_olahan'] ?? '',
      kelompokMakanan: data['kelompok_makanan'] ?? '',
      portionGram: data['porsi_gram'] ?? 0,
      air: data['air'] ?? 0,
      calories: data['energi'] ?? 0,
      protein: data['protein'] ?? 0,
      fat: data['lemak'] ?? 0,
      karbohidrat: data['karbohidrat'] ?? 0,
      fiber: data['serat'] ?? 0,
      abu: data['abu'] ?? 0,
      kalsium: data['kalsium'] ?? 0,
      fosfor: data['fosfor'] ?? 0,
      besi: data['besi'] ?? 0,
      natrium: data['natrium'] ?? 0,
      kalium: data['kalium'] ?? 0,
      tembaga: data['tembaga'] ?? 0,
      seng: data['seng'] ?? 0,
      retinol: data['retinol'] ?? 0,
      betaKaroten: data['beta_karoten'] ?? 0,
      karotenTotal: data['karoten_total'] ?? 0,
      thiamin: data['thiamin'] ?? 0,
      riboflavin: data['riboflavin'] ?? 0,
      niasin: data['niasin'] ?? 0,
      vitaminC: data['vitamin_c'] ?? 0,
      bdd: data['bdd'] ?? 0,
    );
  }

   // DIPERBARUI: Metode untuk mendapatkan semua nilai gizi per 100 gram
  Map<String, num> get nutritionPer100g {
    if (portionGram == 0) {
      return {
        'air': 0,
        'energi': 0,
        'protein': 0,
        'lemak': 0,
        'karbohidrat': 0,
        'serat': 0,
        'abu': 0,
        'kalsium': 0,
        'fosfor': 0,
        'besi': 0,
        'natrium': 0,
        'kalium': 0,
        'tembaga': 0,
        'seng': 0,
        'retinol': 0,
        'betaKaroten': 0,
        'karotenTotal': 0,
        'thiamin': 0,
        'riboflavin': 0,
        'niasin': 0,
        'vitaminC': 0,
        'bdd': 0,
      };
    }
    num ratio = 100 / portionGram;
    return {
      'air': air * ratio,
      'energi': calories * ratio,
      'protein': protein * ratio,
      'lemak': fat * ratio,
      'karbohidrat': karbohidrat * ratio,
      'serat': fiber * ratio,
      'abu': abu * ratio,
      'kalsium': kalsium * ratio,
      'fosfor': fosfor * ratio,
      'besi': besi * ratio,
      'natrium': natrium * ratio,
      'kalium': kalium * ratio,
      'tembaga': tembaga * ratio,
      'seng': seng * ratio,
      'retinol': retinol * ratio,
      'betaKaroten': betaKaroten * ratio,
      'karotenTotal': karotenTotal * ratio,
      'thiamin': thiamin * ratio,
      'riboflavin': riboflavin * ratio,
      'niasin': niasin * ratio,
      'vitaminC': vitaminC * ratio,
      'bdd': bdd * ratio,
    };
  }

  // DIPERBARUI: Getter untuk mendapatkan semua nilai gizi dalam satu map
  Map<String, num> get allNutrition {
    return {
      'air': air,
      'energi': calories,
      'protein': protein,
      'lemak': fat,
      'karbohidrat': karbohidrat,
      'serat': fiber,
      'abu': abu,
      'kalsium': kalsium,
      'fosfor': fosfor,
      'besi': besi,
      'natrium': natrium,
      'kalium': kalium,
      'tembaga': tembaga,
      'seng': seng,
      'retinol': retinol,
      'beta_karoten': betaKaroten,
      'karoten_total': karotenTotal,
      'thiamin': thiamin,
      'riboflavin': riboflavin,
      'niasin': niasin,
      'vitamin_c': vitaminC,
      'bdd': bdd,
    };
  }

  // DIPERBARUI: Metode untuk mendapatkan nilai gizi per gram tertentu
  Map<String, num> getNutritionPerGram(num grams) {
    if (portionGram == 0) {
      return allNutrition.map((key, value) => MapEntry(key, 0));
    }
    final ratio = grams / portionGram;
    return {
      'air': air * ratio,
      'energi': calories * ratio,
      'protein': protein * ratio,
      'lemak': fat * ratio,
      'karbohidrat': karbohidrat * ratio,
      'serat': fiber * ratio,
      'abu': abu * ratio,
      'kalsium': kalsium * ratio,
      'fosfor': fosfor * ratio,
      'besi': besi * ratio,
      'natrium': natrium * ratio,
      'kalium': kalium * ratio,
      'tembaga': tembaga * ratio,
      'seng': seng * ratio,
      'retinol': retinol * ratio,
      'betaKaroten': betaKaroten * ratio,
      'karotenTotal': karotenTotal * ratio,
      'thiamin': thiamin * ratio,
      'riboflavin': riboflavin * ratio,
      'niasin': niasin * ratio,
      'vitaminC': vitaminC * ratio,
      'bdd': bdd * ratio,
    };
  }


  // Method untuk mendapatkan nilai gizi yang signifikan (>0)
  Map<String, num> get significantNutrition {
    final all = allNutrition;
    return Map.fromEntries(
      all.entries.where((entry) => entry.value > 0)
    );
  }
}