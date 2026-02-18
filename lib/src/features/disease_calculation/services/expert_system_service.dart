import '../data/terminology_item.dart';
import '../data/diagnosis_terminology.dart'; // Data Diagnosa
import '../data/intervensi_data.dart';      // Data Intervensi
import '../data/monitoring_data.dart';      // Data Monitoring
import 'package:flutter/widgets.dart';

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
  // PERUBAHAN: Menggunakan List<TerminologyItem>
  final List<TerminologyItem> suggestedDiagnoses;
  final List<TerminologyItem> suggestedInterventions;
  final List<TerminologyItem> suggestedMonitoring;

  ExpertSystemResult({
    required this.suggestedDiagnoses,
    required this.suggestedInterventions,
    required this.suggestedMonitoring,
  });
}

class DiseaseExpertService {
  
  ExpertSystemResult generateCarePlan(ExpertSystemInput input) {
    // PERUBAHAN: List menggunakan TerminologyItem
    final List<TerminologyItem> diagnoses = [];
    final List<TerminologyItem> interventions = [];
    final List<TerminologyItem> monitoring = [];

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

    // A. Domain Klinis (NC) - Nilai Lab
    if (isDiabetes) {
      _addDiagnosis(diagnoses, 'NC-2.2', 
        customDef: 'Kadar glukosa darah/HbA1c di atas nilai normal');
    }

    if (isKidney) {
      _addDiagnosis(diagnoses, 'NC-2.2',
          customDef: 'Peningkatan profil ginjal (Ureum/Kreatinin)');
      
      // Manual add untuk kode yang mungkin tidak ada di list standar
      diagnoses.add(const TerminologyItem(
        domain: 'NI', // Default domain
        classCode: 'NI-5', 
        code: 'NI-5.4', 
        label: 'Penurunan kebutuhan zat gizi (Protein)', 
        category: 'Berkaitan dengan gangguan fungsi ginjal' // Definisi masuk ke category
      ));
    }

    // B. Domain Asupan (NI)
    // Kelebihan Karbohidrat
    if (input.dietaryHistory.any((h) => h.toLowerCase().contains('manis'))) {
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

    // Intervensi Diabetes
    if (isDiabetes) {
      _addIntervention(interventions, 'ND-1.2', 
        note: 'Diet Diabetes Melitus (3J): Atur Jadwal, Jumlah, Jenis.');
    }

    // Intervensi Ginjal (CKD)
    if (isKidney) {
      bool isHD = input.medicalDiagnosis?.toLowerCase().contains('hd') ?? false;

      if (isHD) {
        _addIntervention(interventions, 'ND-1.2', 
          note: 'Tinggi Protein (1.2 g/kg BB) untuk pasien Dialisis.');
      } else {
         _addIntervention(interventions, 'ND-1.2', 
          note: 'Rendah Protein (0.6-0.8 g/kg BB) untuk meringankan ginjal.');
      }

      _addIntervention(interventions, 'ND-1.2', 
          note: 'Restriksi Cairan: Urin output + 500ml.');
    }

    // Intervensi Hipertensi
    if (isHypertension) {
      _addIntervention(interventions, 'ND-1.2', 
          note: 'Diet Rendah Garam (RG) / DASH. Batasi Natrium < 2000mg.');
    }

    // Edukasi Gizi
    _addIntervention(interventions, 'NE-1.1'); 
    _addIntervention(interventions, 'NC-1.4'); // Konseling/Motivasi

    // --- 4. MONITORING & EVALUASI (ME - Monitoring) ---
    
    // Asupan Energi
    _addMonitoring(monitoring, 'FI-1.1'); 

    if (isDiabetes) {
      _addMonitoring(monitoring, 'S-2.5', note: 'GDS/GDP/HbA1c');
    }

    if (isKidney) {
      _addMonitoring(monitoring, 'S-2.2', note: 'Ureum/Kreatinin/Elektrolit');
      _addMonitoring(monitoring, 'S-3.1', note: 'Edema & Balance Cairan'); 
    }

    if (isHypertension) {
      _addMonitoring(monitoring, 'S-1.1', note: 'Tekanan Darah (Tanda Vital)');
    }

    if (input.imt >= 25 || input.imt < 18.5) {
      _addMonitoring(monitoring, 'S-3.1', note: 'Berat Badan & IMT');
    }

    return ExpertSystemResult(
      suggestedDiagnoses: diagnoses,
      suggestedInterventions: interventions,
      suggestedMonitoring: monitoring,
    );
  }

  // ===========================================================================
  // HELPER FUNCTIONS 
  // ===========================================================================

  void _addDiagnosis(
      List<TerminologyItem> list, String code, {String? customDef}) {
    try {
      final found = DiagnosisTerminology.allDiagnoses.firstWhere(
        (item) => item.code == code,
        orElse: () => const TerminologyItem(
            domain: 'UNKNOWN', 
            classCode: 'UNK', 
            category: 'Error', 
            code: 'NOT_FOUND', 
            label: 'Diagnosa Tidak Ditemukan'), 
      );

      if (found.code != 'NOT_FOUND') {
        // PERBAIKAN: Membuat TerminologyItem baru dengan data yang disesuaikan
        list.add(TerminologyItem(
          domain: found.domain,
          classCode: found.classCode,
          code: found.code,
          label: found.label,
          // Map customDef ke category agar muncul sebagai detail/catatan
          category: customDef ?? found.category, 
        ));
      }
    } catch (e) {
      debugPrint("Warning: Diagnosis code $code error: $e");
    }
  }

  void _addIntervention(
      List<TerminologyItem> list, String code, {String? note}) {
    try {
      final found = IntervensiData.allInterventions.firstWhere(
        (item) => item.code == code,
      );

      String displayLabel = found.label;
      // Gunakan kategori asli sebagai dasar, tambahkan note jika ada
      String displayCategory = found.category; 

      if (note != null) {
        displayCategory = "$displayCategory. Catatan: $note";
      }

      list.add(TerminologyItem(
        domain: found.domain,
        classCode: found.classCode,
        code: found.code,
        label: displayLabel,
        category: displayCategory, // Simpan detail/catatan di sini
      ));
    } catch (e) {
       debugPrint("Warning: Intervention code $code not found.");
    }
  }

  void _addMonitoring(
      List<TerminologyItem> list, String code, {String? note}) {
    try {
      final found = MonitoringData.allMonitoringItems.firstWhere(
        (item) => item.code == code,
      );

      String displayCategory = found.category;
      if (note != null) {
        displayCategory = "$displayCategory ($note)";
      }

      list.add(TerminologyItem(
        domain: found.domain,
        classCode: found.classCode,
        code: found.code,
        label: found.label,
        category: displayCategory, // Simpan detail/catatan di sini
      ));
    } catch (e) {
       debugPrint("Warning: Monitoring code $code not found.");
    }
  }
}