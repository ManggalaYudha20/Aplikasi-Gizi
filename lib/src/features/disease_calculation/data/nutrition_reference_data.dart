// lib/src/features/disease_calculation/data/nutrition_reference_data.dart

/// Model standar untuk output Sistem Pakar (Diagnosa, Intervensi, Monitoring)
/// Digunakan agar UI (ExpertSystemResult) memiliki format data yang seragam.
class NutritionReferenceItem {
  final String code;       // Contoh: NI-5.8.3
  final String label;      // Contoh: Asupan karbohidrat berlebih
  final String definition; // Contoh: Konsumsi gula berlebih (bisa berisi kategori atau detail)

  const NutritionReferenceItem({
    required this.code,
    required this.label,
    required this.definition,
  });
}

// HAPUS class NutritionKnowledgeBase
// Data statis (diagnoses, interventions, monitoring) sudah dipindahkan ke:
// 1. diagnosis_terminology.dart
// 2. intervensi_data.dart
// 3. monitoring_data.dart
// Hal ini dilakukan agar tidak ada duplikasi data (Single Source of Truth).