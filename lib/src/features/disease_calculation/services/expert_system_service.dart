// lib/src/features/disease_calculation/services/expert_system_service.dart

import '../data/nutrition_reference_data.dart';

// Model sederhana untuk input data pasien (Bisa disesuaikan dengan Patient Model Anda)
class ExpertSystemInput {
  final double imt;
  final double? gds;      // Glukosa Darah Sewaktu
  final double? gdp;      // Glukosa Darah Puasa
  final double? hba1c;
  final double? cholesterol;
  final String bloodPressure; // Format "120/80" atau status "Tinggi"
  final List<String> dietaryHistory; // Contoh: ["Suka manis", "Jarang olahraga", "Makan tidak teratur"]
  final bool hasKidneyIssue; // Dari riwayat medis / Ureum Creatinin
  final String? medicalDiagnosis;

  ExpertSystemInput({
    required this.imt,
    this.gds,
    this.gdp,
    this.hba1c,
    this.cholesterol,
    this.bloodPressure = "Normal",
    this.dietaryHistory = const [],
    this.hasKidneyIssue = false,
    this.medicalDiagnosis,
  });
}

class ExpertSystemResult {
  final List<NutritionReferenceItem> suggestedDiagnoses;
  final List<NutritionReferenceItem> suggestedInterventions;
  final List<NutritionReferenceItem> suggestedMonitoring;

  ExpertSystemResult({
    required this.suggestedDiagnoses,
    required this.suggestedInterventions,
    required this.suggestedMonitoring,
  });
}

class DiabetesExpertService {
  
  ExpertSystemResult generateCarePlan(ExpertSystemInput input) {
    final List<NutritionReferenceItem> diagnoses = [];
    final List<NutritionReferenceItem> interventions = [];
    final List<NutritionReferenceItem> monitoring = [];

    // --- 1. LOGIKA DIAGNOSIS (Problem Identification) ---

    bool isMedicallyDiabetes = false;
    if (input.medicalDiagnosis != null) {
      final dx = input.medicalDiagnosis!.toLowerCase();
      if (dx.contains('diabetes') || dx.contains('dm') || dx.contains('kencing manis')) {
        isMedicallyDiabetes = true;
      }
    }

    bool highLabs = (input.gds != null && input.gds! >= 200) || 
                    (input.gdp != null && input.gdp! >= 126) ||
                    (input.hba1c != null && input.hba1c! >= 7.0);

    if (highLabs) {
      // Jika Lab Tinggi -> Pasti Masalah Gizi (NC-2.2)
      diagnoses.add(NutritionKnowledgeBase.diagnoses.firstWhere((d) => d.code == 'NC-2.2'));
    } 
    
    // LOGIKA KHUSUS: Pasien DM tapi Gula Normal (Terkontrol)
    // Kita bisa mengangkat diagnosis risiko atau perilaku jika ada riwayat makan salah
    if (isMedicallyDiabetes && !highLabs) {
       // Opsional: Bisa tambahkan diagnosis "NB-1.7 Pemilihan makanan salah" 
       // jika riwayat makannya buruk, meskipun gula darah saat ini bagus.
       if (input.dietaryHistory.isNotEmpty) {
          diagnoses.add(NutritionKnowledgeBase.diagnoses.firstWhere((d) => d.code == 'NB-1.7'));
       }
    }

    // A. Status Gizi (Antropometri)
    // Cut-off IMT Asia Pasifik (PERKENI 2024): >= 23 BB Lebih, >= 25 Obesitas
    if (input.imt >= 25) {
      diagnoses.add(NutritionKnowledgeBase.diagnoses.firstWhere((d) => d.code == 'NC-3.3'));
    } else if (input.imt < 18.5) {
      diagnoses.add(NutritionKnowledgeBase.diagnoses.firstWhere((d) => d.code == 'NC-3.1'));
    }

    // B. Nilai Lab (Glukosa)
    // Target: HbA1c < 7%, GDP 80-130, GDS < 200 (Pedoman PERKENI 2024, Tabel 7)
    bool hyperglycemia = (input.gds != null && input.gds! >= 200) || 
                         (input.gdp != null && input.gdp! >= 126) ||
                         (input.hba1c != null && input.hba1c! >= 7.0);
    
    bool dyslipidemia = (input.cholesterol != null && input.cholesterol! > 200);

    if (hyperglycemia || dyslipidemia) {
      diagnoses.add(NutritionKnowledgeBase.diagnoses.firstWhere((d) => d.code == 'NC-2.2'));
    }

    // C. Riwayat Makan (Intake/Behavior)
    if (input.dietaryHistory.contains('Suka manis') || input.dietaryHistory.contains('Sering ngemil')) {
      diagnoses.add(NutritionKnowledgeBase.diagnoses.firstWhere((d) => d.code == 'NI-5.8.3'));
    }
    if (input.dietaryHistory.contains('Makan tidak teratur')) {
      diagnoses.add(NutritionKnowledgeBase.diagnoses.firstWhere((d) => d.code == 'NB-1.5'));
    }

    // --- 2. LOGIKA INTERVENSI (Planning) ---
    if (isMedicallyDiabetes || highLabs) {
      interventions.add(NutritionKnowledgeBase.interventions.firstWhere((i) => i.code == 'ND-1.1')); // Diet Seimbang
      
      // Tambahkan detail spesifik untuk DM
      interventions.add(NutritionReferenceItem(
        code: 'ND-1.2', 
        label: 'Diet Diabetes Melitus (Prinsip 3J)',
        definition: 'Jadwal, Jumlah, dan Jenis makanan diatur ketat sesuai kebutuhan.',
      ));

      interventions.add(NutritionKnowledgeBase.interventions.firstWhere((i) => i.code == 'E-1.1')); // Edukasi
    }
    // Intervensi Dasar DM (3J)
    interventions.add(NutritionKnowledgeBase.interventions.firstWhere((i) => i.code == 'ND-1.1'));
    interventions.add(NutritionKnowledgeBase.interventions.firstWhere((i) => i.code == 'E-1.1')); // Edukasi wajib

    // Jika Obesitas -> Diet Rendah Kalori
    if (input.imt >= 25) {
      var dietMod = NutritionKnowledgeBase.interventions.firstWhere((i) => i.code == 'ND-1.2');
      interventions.add(NutritionReferenceItem(
        code: dietMod.code,
        label: '${dietMod.label} (Defisit 500-750 kkal)',
        definition: dietMod.definition,
      ));
      
      // Rekomendasi Aktivitas Fisik (RC-1.4)
      interventions.add(NutritionKnowledgeBase.interventions.firstWhere((i) => i.code == 'RC-1.4'));
    }

    // Jika Hipertensi -> Diet Rendah Garam (DASH)
    if (input.bloodPressure.contains('Tinggi') || input.bloodPressure.contains('Hipertensi')) {
      var dietMod = NutritionKnowledgeBase.interventions.firstWhere((i) => i.code == 'ND-1.2');
      interventions.add(NutritionReferenceItem(
        code: dietMod.code,
        label: '${dietMod.label} (Rendah Garam/DASH)',
        definition: 'Batasi Natrium < 2300mg/hari',
      ));
    }

    // --- 3. LOGIKA MONITORING (Monev) ---
    
    // Monitoring Glukosa (Wajib untuk DM)
    monitoring.add(NutritionKnowledgeBase.monitoring.firstWhere((m) => m.code == 'S-2.5'));
    
    // Monitoring Asupan
    monitoring.add(NutritionKnowledgeBase.monitoring.firstWhere((m) => m.code == 'FH-1.1.1'));

    // Monitoring BB (Jika status gizi bermasalah)
    if (input.imt >= 23 || input.imt < 18.5) {
      monitoring.add(NutritionKnowledgeBase.monitoring.firstWhere((m) => m.code == 'S-1.1'));
    }

    if (isMedicallyDiabetes || highLabs) {
      monitoring.add(NutritionKnowledgeBase.monitoring.firstWhere((m) => m.code == 'S-2.5')); // Profil Glukosa
      monitoring.add(NutritionKnowledgeBase.monitoring.firstWhere((m) => m.code == 'FH-1.1.1')); // Asupan Energi
    }

    return ExpertSystemResult(
      suggestedDiagnoses: diagnoses,
      suggestedInterventions: interventions,
      suggestedMonitoring: monitoring,
    );
  }
}