import '../data/nutrition_reference_data.dart';

class ExpertSystemInput {
  final double imt;
  final double? gds;      
  final double? gdp;      
  final double? hba1c;
  final double? cholesterol;
  
  // PARAMETER GINJAL & ELEKTROLIT
  final double? ureum;
  final double? kreatinin;
  final double? kalium;
  
  final String bloodPressure; 
  final List<String> dietaryHistory; 
  final bool hasKidneyIssue; 
  final String? medicalDiagnosis;

  ExpertSystemInput({
    required this.imt,
    this.gds,
    this.gdp,
    this.hba1c,
    this.cholesterol,
    this.ureum,
    this.kreatinin,
    this.kalium,
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

class DiseaseExpertService {
  
  ExpertSystemResult generateCarePlan(ExpertSystemInput input) {
    final List<NutritionReferenceItem> diagnoses = [];
    final List<NutritionReferenceItem> interventions = [];
    final List<NutritionReferenceItem> monitoring = [];

    // --- 1. DETEKSI MASALAH KLINIS (Problem Identification) ---
    
    // Cek Diabetes (Lab: GDS >= 200, GDP >= 126, HbA1c >= 6.5)
    bool isDiabetes = false;
    if ((input.medicalDiagnosis?.toLowerCase().contains('diabetes') ?? false) ||
        (input.medicalDiagnosis?.toLowerCase().contains('dm') ?? false) ||
        (input.gds != null && input.gds! >= 200) || 
        (input.gdp != null && input.gdp! >= 126) ||
        (input.hba1c != null && input.hba1c! >= 6.5)) {
      isDiabetes = true;
    }

    // Cek Ginjal Kronik (Lab: Ureum > 50, Kreatinin > 1.5)
    bool isKidney = input.hasKidneyIssue;
    if (!isKidney) {
      if ((input.ureum != null && input.ureum! > 50) || 
          (input.kreatinin != null && input.kreatinin! > 1.5)) {
        isKidney = true;
      }
    }

    // Cek Hipertensi (TD > 140/90)
    bool isHypertension = input.bloodPressure.toLowerCase().contains('tinggi') || 
                          input.bloodPressure.toLowerCase().contains('hipertensi');
    
    // --- 2. DIAGNOSIS GIZI (P - Problem) ---

    // A. Domain Klinis (NC) - Nilai Lab
    if (isDiabetes) {
      diagnoses.add(NutritionReferenceItem(
        code: 'NC-2.2', 
        label: 'Perubahan nilai lab terkait gizi (Glukosa/HbA1c)', 
        definition: 'Kadar glukosa darah/HbA1c di atas nilai normal'
      ));
    }
    
    if (isKidney) {
      diagnoses.add(NutritionReferenceItem(
        code: 'NC-2.2', 
        label: 'Perubahan nilai lab terkait gizi (Profil Ginjal)', 
        definition: 'Peningkatan kadar Ureum/Kreatinin akibat penurunan fungsi ginjal'
      ));
      // Diagnosis spesifik penurunan kebutuhan protein untuk ginjal
      diagnoses.add(NutritionReferenceItem(
        code: 'NI-5.4', 
        label: 'Penurunan kebutuhan zat gizi (Protein)', 
        definition: 'Berkaitan dengan gangguan fungsi ginjal (ureum/kreatinin tinggi)'
      ));
    }

    // B. Domain Asupan (NI)
    // Kelebihan Karbohidrat (Suka Manis)
    if (input.dietaryHistory.any((h) => h.toLowerCase().contains('manis'))) {
      diagnoses.add(NutritionReferenceItem(
        code: 'NI-5.8.3', 
        label: 'Kelebihan asupan karbohidrat sederhana', 
        definition: 'Sering mengonsumsi gula murni/makanan manis'
      ));
    }

    // Kelebihan Natrium (Suka Asin + Hipertensi/Ginjal)
    if (input.dietaryHistory.any((h) => h.toLowerCase().contains('asin')) && (isHypertension || isKidney)) {
      diagnoses.add(NutritionReferenceItem(
        code: 'NI-5.10.2', 
        label: 'Kelebihan asupan mineral (Natrium)', 
        definition: 'Sering mengonsumsi makanan asin/awetan'
      ));
    }

    // Hiperkalemia pada Ginjal
    if (input.kalium != null && input.kalium! > 5.0) {
      diagnoses.add(NutritionReferenceItem(
        code: 'NI-5.10.1', 
        label: 'Kelebihan asupan mineral (Kalium)', 
        definition: 'Kadar Kalium darah tinggi (Hiperkalemia)'
      ));
    }

    // C. Domain Perilaku (NB)
    // Kurang Olahraga
    if (input.dietaryHistory.any((h) => h.toLowerCase().contains('olahraga') || h.toLowerCase().contains('aktivitas'))) {
       diagnoses.add(NutritionReferenceItem(
        code: 'NB-2.1', 
        label: 'Kurang aktivitas fisik', 
        definition: 'Jarang berolahraga (< 150 menit/minggu)'
      ));
    }

    // Pemilihan Makanan Salah (Umum untuk DM/Ginjal)
    if (isDiabetes || isKidney) {
       diagnoses.add(NutritionReferenceItem(
        code: 'NB-1.7', 
        label: 'Pemilihan makanan yang salah', 
        definition: 'Kurang pengetahuan terkait makanan yang dianjurkan'
      ));
    }

    // D. Status Gizi (Antropometri)
    if (input.imt >= 25) {
      diagnoses.add(NutritionReferenceItem(code: 'NC-3.3', label: 'Obesitas/Berat Badan Lebih', definition: 'IMT diatas normal'));
    } else if (input.imt < 18.5) {
      diagnoses.add(NutritionReferenceItem(code: 'NC-3.1', label: 'Berat Badan Kurang', definition: 'IMT dibawah normal'));
    }

    // --- 3. INTERVENSI GIZI (I - Intervention) ---

    // Intervensi Diabetes
    if (isDiabetes) {
      interventions.add(NutritionReferenceItem(
        code: 'ND-1.2', 
        label: 'Diet Diabetes Melitus (3J)', 
        definition: 'Atur Jadwal, Jumlah, dan Jenis makanan. Batasi Karbohidrat Sederhana.'
      ));
    }

    // Intervensi Ginjal (CKD)
    if (isKidney) {
      // Cek apakah pasien HD (Hemodialisa) atau Pre-HD
      bool isHD = input.medicalDiagnosis?.toLowerCase().contains('hd') ?? false;
      
      if (isHD) {
         interventions.add(NutritionReferenceItem(
          code: 'ND-1.2', 
          label: 'Diet Tinggi Protein (Dialisis)', 
          definition: '1.2 g/kg BB untuk mengganti protein yang hilang saat cuci darah.'
        ));
      } else {
         interventions.add(NutritionReferenceItem(
          code: 'ND-1.2', 
          label: 'Diet Rendah Protein (RP)', 
          definition: '0.6 - 0.8 g/kg BB untuk meringankan kerja ginjal.'
        ));
      }

      // Restriksi Cairan
      interventions.add(NutritionReferenceItem(
        code: 'ND-1.2', 
        label: 'Restriksi Cairan', 
        definition: 'Sesuaikan dengan urin output + 500ml (IWL).'
      ));
    }

    // Intervensi Hipertensi
    if (isHypertension) {
      interventions.add(NutritionReferenceItem(
        code: 'ND-1.2', 
        label: 'Diet Rendah Garam (RG) / DASH', 
        definition: 'Batasi Natrium < 2000 mg/hari.'
      ));
    }

    // Edukasi Gizi (Selalu ada)
    interventions.add(NutritionReferenceItem(code: 'E-1.1', label: 'Edukasi & Konseling Gizi', definition: ''));

    // --- 4. MONITORING & EVALUASI (ME - Monitoring) ---
    
    monitoring.add(NutritionReferenceItem(code: 'FH-1.1.1', label: 'Asupan Energi & Zat Gizi', definition: '')); //
    
    if (isDiabetes) {
      monitoring.add(NutritionReferenceItem(code: 'S-2.5', label: 'Profil Glukosa Darah (GDS/GDP/HbA1c)', definition: '')); //
    }
    
    if (isKidney) {
      monitoring.add(NutritionReferenceItem(code: 'S-2.2', label: 'Profil Ginjal (Ureum/Kreatinin/Elektrolit)', definition: ''));
      monitoring.add(NutritionReferenceItem(code: 'S-3.1', label: 'Balance Cairan & Edema', definition: ''));
    }
    
    if (isHypertension) {
      monitoring.add(NutritionReferenceItem(code: 'S-3.1', label: 'Tekanan Darah', definition: '')); //
    }

    if (input.imt >= 25 || input.imt < 18.5) {
      monitoring.add(NutritionReferenceItem(code: 'S-1.1', label: 'Berat Badan / IMT', definition: '')); //
    }

    return ExpertSystemResult(
      suggestedDiagnoses: diagnoses,
      suggestedInterventions: interventions,
      suggestedMonitoring: monitoring,
    );
  }
}