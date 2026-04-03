// lib\src\features\diabetes_calculation\services\expert_system_engine.dart

import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/diabetes_knowledge_base.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_knowledge_base.dart';
// --- Data Structures ---

/// Representasi Fakta Input dari sistem kalkulator sebelumnya
class PatientFact {
  final String diseaseId;
  final double calculatedCalories;
  final double? calculatedProtein;
  final List<String> complications;

  PatientFact({
    required this.diseaseId,
    required this.calculatedCalories,
    this.calculatedProtein,
    this.complications = const [],
  });
}

/// Kesimpulan (Conclusion) dari Forward Chaining
class DietPrescription {
  final DiseaseGuideline guideline;
  final DietDistributionRule distribution;

  DietPrescription({
    required this.guideline,
    required this.distribution,
  });
}

// --- Inference Engine ---

/// Single Engine yang memproses Forward Chaining untuk semua jenis penyakit
class ExpertSystemEngine {
  // In-Memory Knowledge Base Registry
  final Map<String, DiseaseGuideline> _guidelineRegistry = {};
  final Map<String, List<DietDistributionRule>> _distributionRegistry = {};

  ExpertSystemEngine() {
    _initializeKnowledgeBase();
  }

  /// Registrasi semua basis pengetahuan lokal di sini.
  /// Saat ada penyakit Ginjal, cukup daftarkan di method ini.
  void _initializeKnowledgeBase() {
    // Register Diabetes
    _guidelineRegistry[diabetesGuideline.diseaseId] = diabetesGuideline;
    _distributionRegistry[diabetesGuideline.diseaseId] = diabetesDistributionRules;
    
    // Register Ginjal <-- TAMBAHKAN INI
    _guidelineRegistry[kidneyGuideline.diseaseId] = kidneyGuideline;
    _distributionRegistry[kidneyGuideline.diseaseId] = kidneyDistributionRules;
  }

  /// Proses Forward Chaining: Menerima Fakta -> Menghasilkan Resep Diet
  DietPrescription forwardChain(PatientFact fact) {
    // 1. Ekstraksi Aturan Universal (Rule 1)
    final guideline = _guidelineRegistry[fact.diseaseId];
    if (guideline == null) {
      throw Exception("Knowledge Base tidak ditemukan untuk penyakit: ${fact.diseaseId}");
    }

    // 2. Ekstraksi Aturan Distribusi yang tersedia (Rule 2)
    final availableRules = _distributionRegistry[fact.diseaseId];
    if (availableRules == null || availableRules.isEmpty) {
      throw Exception("Aturan distribusi kalori tidak ditemukan untuk penyakit: ${fact.diseaseId}");
    }

    // 3. Pencocokan Data (Pattern Matching): Cari aturan kalori terdekat dengan fakta
    DietDistributionRule? matchedRule;
    double smallestDifference = double.infinity;

    double targetToMatch = fact.diseaseId == 'ginjal' && fact.calculatedProtein != null 
        ? fact.calculatedProtein! 
        : fact.calculatedCalories;

    for (var rule in availableRules) {
      // Menghitung selisih absolut antara kalori pasien dengan target rule
      double difference = (targetToMatch - rule.targetCalories).abs();
      if (difference < smallestDifference) {
        smallestDifference = difference;
        matchedRule = rule;
      }
    }

    // 4. Return Kesimpulan (Resep Universal + Distribusi spesifik)
    return DietPrescription(
      guideline: guideline,
      distribution: matchedRule!,
    );
  }
}