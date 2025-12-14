import '../data/nutrition_reference_data.dart';
import '../data/diagnosis_terminology.dart'; // Data Diagnosa
import '../data/intervensi_data.dart';      // Data Intervensi
import '../data/monitoring_data.dart';      // Data Monitoring
import 'package:flutter/widgets.dart';
// Pastikan path import TerminologyItem ini sesuai dengan struktur folder Anda
// import '../data/models/terminology_item.dart'; 

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
    bool isHypertension =
        input.bloodPressure.toLowerCase().contains('tinggi') ||
        input.bloodPressure.toLowerCase().contains('hipertensi');

    // --- 2. DIAGNOSIS GIZI (P - Problem) ---
    // Menggunakan helper _findDiagnosis untuk mengambil data baku

    // A. Domain Klinis (NC) - Nilai Lab
    if (isDiabetes) {
      _addDiagnosis(diagnoses, 'NC-2.2', 
        customDef: 'Kadar glukosa darah/HbA1c di atas nilai normal');
    }

    if (isKidney) {
      _addDiagnosis(diagnoses, 'NC-2.2',
          customDef: 'Peningkatan profil ginjal (Ureum/Kreatinin)');
      
      // Note: Kode NI-5.4 mungkin tidak ada di list standar diagnosis, 
      // pastikan kode ini ada di DiagnosisTerminology atau gunakan kode yang mendekati.
      // Jika tidak ada di list, kita buat manual sebagai fallback.
      diagnoses.add(NutritionReferenceItem(
        code: 'NI-5.4', 
        label: 'Penurunan kebutuhan zat gizi (Protein)', 
        definition: 'Berkaitan dengan gangguan fungsi ginjal'
      ));
    }

    // B. Domain Asupan (NI)
    // Kelebihan Karbohidrat
    if (input.dietaryHistory.any((h) => h.toLowerCase().contains('manis'))) {
       // Kode NI-5.8.3
       _addDiagnosis(diagnoses, 'NI-5.8.3', 
         customDef: 'Sering mengonsumsi gula murni/makanan manis');
    }

    // Kelebihan Natrium
    if (input.dietaryHistory.any((h) => h.toLowerCase().contains('asin')) &&
        (isHypertension || isKidney)) {
       _addDiagnosis(diagnoses, 'NI-5.10.2', 
         customDef: 'Sering mengonsumsi makanan asin/awetan');
    }

    // Hiperkalemia
    if (input.kalium != null && input.kalium! > 5.0) {
       _addDiagnosis(diagnoses, 'NI-5.10.1', 
         customDef: 'Kadar Kalium darah tinggi (Hiperkalemia)');
    }

    // C. Domain Perilaku (NB)
    // Kurang Olahraga
    if (input.dietaryHistory.any((h) =>
        h.toLowerCase().contains('olahraga') ||
        h.toLowerCase().contains('aktivitas'))) {
       _addDiagnosis(diagnoses, 'NB-2.1', 
         customDef: 'Jarang berolahraga (< 150 menit/minggu)');
    }

    // Pemilihan Makanan Salah
    if (isDiabetes || isKidney) {
       _addDiagnosis(diagnoses, 'NB-1.7', 
         customDef: 'Kurang pengetahuan terkait makanan yang dianjurkan');
    }

    // D. Status Gizi (Antropometri)
    if (input.imt >= 25) {
      _addDiagnosis(diagnoses, 'NC-3.3', customDef: 'IMT diatas normal (Overweight/Obesitas)');
    } else if (input.imt < 18.5) {
      _addDiagnosis(diagnoses, 'NC-3.1', customDef: 'IMT dibawah normal (Underweight)');
    }

    // --- 3. INTERVENSI GIZI (I - Intervention) ---
    // Menggunakan helper _addIntervention dari data IntervensiData

    // Intervensi Diabetes
    if (isDiabetes) {
      _addIntervention(interventions, 'ND-1.2', 
        note: 'Diet Diabetes Melitus (3J): Atur Jadwal, Jumlah, Jenis.');
    }

    // Intervensi Ginjal (CKD)
    if (isKidney) {
      bool isHD = input.medicalDiagnosis?.toLowerCase().contains('hd') ?? false;

      if (isHD) {
        // Diet Tinggi Protein (Dialisis) - Biasanya ND-1.2 Modifikasi Komposisi
        _addIntervention(interventions, 'ND-1.2', 
          note: 'Tinggi Protein (1.2 g/kg BB) untuk pasien Dialisis.');
      } else {
        // Diet Rendah Protein (Pre-Dialisis)
         _addIntervention(interventions, 'ND-1.2', 
          note: 'Rendah Protein (0.6-0.8 g/kg BB) untuk meringankan ginjal.');
      }

      // Restriksi Cairan (ND-1.3 Makanan/Minuman tertentu - atau ND-1.2)
      _addIntervention(interventions, 'ND-1.2', 
          note: 'Restriksi Cairan: Urin output + 500ml.');
    }

    // Intervensi Hipertensi
    if (isHypertension) {
      _addIntervention(interventions, 'ND-1.2', 
          note: 'Diet Rendah Garam (RG) / DASH. Batasi Natrium < 2000mg.');
    }

    // Edukasi Gizi (Selalu ada)
    // Di IntervensiData, domain edukasi kodenya NE-1.1 dst. Kita ambil Edukasi Awal.
    _addIntervention(interventions, 'NE-1.1'); 
    _addIntervention(interventions, 'NC-1.4'); // Konseling/Motivasi

    // --- 4. MONITORING & EVALUASI (ME - Monitoring) ---
    // Menggunakan helper _addMonitoring dari data MonitoringData
    
    // Asupan Energi (FI-1.1) - Sebelumnya FH-1.1.1 (kode lama), sekarang pakai FI-1.1 sesuai data baru
    _addMonitoring(monitoring, 'FI-1.1'); 

    if (isDiabetes) {
      // Profil Glukosa (S-2.5)
      _addMonitoring(monitoring, 'S-2.5', note: 'GDS/GDP/HbA1c');
    }

    if (isKidney) {
      // Profil Ginjal (S-2.2)
      _addMonitoring(monitoring, 'S-2.2', note: 'Ureum/Kreatinin/Elektrolit');
      // Balance Cairan (S-3.1 - Fisik atau FI-2.2 Asupan Cairan)
      // Kita pakai S-3.1 Fisik (Edema) jika ada di data, atau input manual
      _addMonitoring(monitoring, 'S-3.1', note: 'Edema & Balance Cairan'); 
    }

    if (isHypertension) {
      // Tekanan Darah (S-3.1 - Pemeriksaan Fisik)
      // Note: Di MonitoringData S-3.1 adalah Antropometri.
      // Kita cari yang fisik umum atau tanda vital. Jika tidak ada di CSV, sistem akan skip/pakai default.
      // S-3.1 di data baru = Antropometri. 
      // Kita pakai Fisik Umum (S-1.1) untuk tanda vital jika S-3 spesifik vital sign tidak ada.
      _addMonitoring(monitoring, 'S-1.1', note: 'Tekanan Darah (Tanda Vital)');
    }

    if (input.imt >= 25 || input.imt < 18.5) {
      // Berat Badan / IMT (S-3.1 Antropometri)
      _addMonitoring(monitoring, 'S-3.1', note: 'Berat Badan & IMT');
    }

    return ExpertSystemResult(
      suggestedDiagnoses: diagnoses,
      suggestedInterventions: interventions,
      suggestedMonitoring: monitoring,
    );
  }

  // ===========================================================================
  // HELPER FUNCTIONS (PENCARI DATA DARI FILE REFERENSI)
  // ===========================================================================

  /// Mencari Diagnosis dari `diagnosis_terminology.dart`
  void _addDiagnosis(
      List<NutritionReferenceItem> list, String code, {String? customDef}) {
    try {
      // Cari object asli dari list static
      final found = DiagnosisTerminology.allDiagnoses.firstWhere(
        (item) => item.code == code,
        orElse: () => NutritionReferenceItem(code: code, label: 'Diagnosa Tidak Ditemukan', definition: ''),
      );

      // Jika customDef ada, kita replace definition bawaan agar lebih spesifik ke pasien
      if (found.label != 'Diagnosa Tidak Ditemukan') {
        list.add(NutritionReferenceItem(
          code: found.code,
          label: found.label,
          definition: customDef ?? found.definition,
        ));
      }
    } catch (e) {
      // Handle jika kode salah ketik/tidak ada
      debugPrint("Warning: Diagnosis code $code not found.");
    }
  }

  /// Mencari Intervensi dari `intervensi_data.dart`
  void _addIntervention(
      List<NutritionReferenceItem> list, String code, {String? note}) {
    try {
      // IntervensiData menggunakan TerminologyItem, kita perlu konversi ke NutritionReferenceItem
      final found = IntervensiData.allInterventions.firstWhere(
        (item) => item.code == code,
      );

      // Gabungkan label asli dengan catatan khusus (jika ada)
      // Contoh: "Modifikasi Diet" + " (Rendah Garam)"
      String displayLabel = found.label;
      String displayDef = found.category; // Gunakan kategori sebagai definisi default

      if (note != null) {
        displayDef = "$displayDef. Catatan: $note";
      }

      list.add(NutritionReferenceItem(
        code: found.code,
        label: displayLabel,
        definition: displayDef,
      ));
    } catch (e) {
      // Jika tidak ketemu (misal kode salah), skip saja atau print debug
       debugPrint("Warning: Intervention code $code not found.");
    }
  }

  /// Mencari Monitoring dari `monitoring_data.dart`
  void _addMonitoring(
      List<NutritionReferenceItem> list, String code, {String? note}) {
    try {
      final found = MonitoringData.allMonitoringItems.firstWhere(
        (item) => item.code == code,
      );

      String displayDef = found.category;
      if (note != null) {
        displayDef = "$displayDef ($note)";
      }

      list.add(NutritionReferenceItem(
        code: found.code,
        label: found.label,
        definition: displayDef,
      ));
    } catch (e) {
       debugPrint("Warning: Monitoring code $code not found.");
    }
  }
}