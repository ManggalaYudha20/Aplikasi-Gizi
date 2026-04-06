// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\expert_system\data\models\knowledge_base_model.dart

class DiseaseGuideline {
  final String diseaseId;
  final String diseaseName;
  final List<String> forbiddenFoods;
  final Map<String, List<String>> conditionalForbiddenFoods;

  DiseaseGuideline({
    required this.diseaseId,
    required this.diseaseName,
    required this.forbiddenFoods,
    this.conditionalForbiddenFoods = const {},
  });
}

class MealItemRule {
  final String categoryLabel;
  final dynamic portion;
  final double? weightGrams; // Tambahan baru
  final String? urt;

  MealItemRule({
    required this.categoryLabel,
    required this.portion,
    this.weightGrams,
    this.urt,
  });
}

/// Model untuk Aturan Distribusi Porsi (Berdasarkan Target Kalori)
class DietDistributionRule {
  final double targetCalories;
  final Map<String, List<MealItemRule>> distribution;

  DietDistributionRule({
    required this.targetCalories,
    required this.distribution,
  });
}
