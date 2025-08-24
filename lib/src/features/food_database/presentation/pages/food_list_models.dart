import 'package:cloud_firestore/cloud_firestore.dart';

class FoodItem {
  final String id;
  final String name;
  final String code;
  final num portionGram;
  final num calories;
  final num protein;
  final num fat;
  final num fiber;
  FoodItem({
    required this.id,
    required this.name,
    required this.code,
    required this.portionGram,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.fiber,
  });

  // Factory constructor untuk membuat instance FoodItem dari dokumen Firestore
  factory FoodItem.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return FoodItem(
      id: doc.id,
      name: data['nama'] ?? '',
      code: data['kode'] ?? '',
      portionGram: data['porsi_gram'] ?? 0,
      calories: data['kalori'] ?? 0,
      protein: data['protein'] ?? 0,
      fat: data['lemak'] ?? 0,
      fiber: data['serat'] ?? 0,
    );
  }

  // Method untuk mendapatkan nilai gizi per 100 gram
  Map<String, num> get nutritionPer100g {
    return {
      'kalori': (calories / portionGram) * 100,
      'protein': (protein / portionGram) * 100,
      'lemak': (fat / portionGram) * 100,
      'serat': (fiber / portionGram) * 100,
    };
  }

  // Getter untuk mendapatkan semua nilai gizi dalam satu map
  Map<String, num> get allNutrition {
    return {
      'kalori': calories,
      'protein': protein,
      'lemak': fat,
      'serat': fiber,
    };
  }

  // Method untuk mendapatkan nilai gizi per gram tertentu
  Map<String, num> getNutritionPerGram(num grams) {
    final ratio = grams / portionGram;
    return {
      'kalori': calories * ratio,
      'protein': protein * ratio,
      'lemak': fat * ratio,
      'serat': fiber * ratio,
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