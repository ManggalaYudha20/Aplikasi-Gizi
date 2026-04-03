// lib/src/shared/clinical_data/services/expert_system_service.dart
//
// VERSI DITINGKATKAN — berdasarkan panduan klinis:
//   • Penatalaksanaan Nutrisi Diet Diabetes Melitus (PERKENI 2024)
//   • Diet Ginjal Kronik Pre-Hemodialisis
//   • Diet Ginjal Kronik dengan Hemodialisis
// ─────────────────────────────────────────────────────────────────────────────

import '../data/models/terminology_item.dart';
import '../data/models/diagnosis_terminology.dart';
import '../data/models/intervensi_data.dart';
import '../data/models/monitoring_data.dart';
import 'package:flutter/widgets.dart';

// ═════════════════════════════════════════════════════════════════════════════
// INPUT MODEL
// ═════════════════════════════════════════════════════════════════════════════

class ExpertSystemInput {
  final double imt;

  // ── Lab Glukosa & HbA1c ──────────────────────────────────────────────────
  final double? gds;
  final double? gdp;
  final double? hba1c;

  // ── Lab Lipid ────────────────────────────────────────────────────────────
  final double? cholesterol; // Kolesterol Total  (mg/dL)
  final double? ldl; // LDL               (mg/dL)
  final double? hdl; // HDL               (mg/dL)
  final double? trigliserida; // Trigliserida       (mg/dL)

  // ── Lab Ginjal & Elektrolit ──────────────────────────────────────────────
  final double? ureum; // mg/dL  — normal ≤ 50
  final double? kreatinin; // mg/dL  — normal ≤ 1.5
  final double? kalium; // mEq/L  — normal 3.5–5.0
  final double? natrium; // mEq/L  — normal 135–145
  final double? fosfor; // mg/dL  — normal 2.5–4.5
  final double? kalsium; // mg/dL  — normal 8.5–10.5
  final double? albumin; // g/dL   — normal 3.5–5.0

  // ── Lab Darah Rutin ──────────────────────────────────────────────────────
  final double? hgb; // Hemoglobin  (g/dL)

  // ── Klinis ───────────────────────────────────────────────────────────────
  final String bloodPressure; // "Normal" | "Hipertensi" | "Tinggi"
  final int? sistolik; // mmHg
  final int? diastolik; // mmHg

  // ── Riwayat Diet / Kebiasaan ─────────────────────────────────────────────
  final List<String> dietaryHistory;
  final bool sukaManis;
  final bool sukaAsin;
  final bool makanBerlemak;
  final bool jarangOlahraga;

  // ── Diagnosa Medis ───────────────────────────────────────────────────────
  /// Teks bebas dari field "Diagnosis Medis" yang diisi dokter/user.
  final String? medicalDiagnosis;

  // ── Flag Penyakit Klinis (override manual jika tab khusus tersedia) ───────
  final bool hasKidneyIssue;
  final bool isHemodialysis; // true = CKD + HD; false = CKD Pre-HD

  // ── Data Fisik tambahan ──────────────────────────────────────────────────
  final double? beratBadan; // kg — untuk hitung kebutuhan per kg BB
  final int? usia; // tahun — mempengaruhi kebutuhan energi

  const ExpertSystemInput({
    required this.imt,
    this.gds,
    this.gdp,
    this.hba1c,
    this.cholesterol,
    this.ldl,
    this.hdl,
    this.trigliserida,
    this.ureum,
    this.kreatinin,
    this.kalium,
    this.natrium,
    this.fosfor,
    this.kalsium,
    this.albumin,
    this.hgb,
    this.bloodPressure = 'Normal',
    this.sistolik,
    this.diastolik,
    this.dietaryHistory = const [],
    this.sukaManis = false,
    this.sukaAsin = false,
    this.makanBerlemak = false,
    this.jarangOlahraga = false,
    this.medicalDiagnosis,
    this.hasKidneyIssue = false,
    this.isHemodialysis = false,
    this.beratBadan,
    this.usia,
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// RESULT MODEL
// ═════════════════════════════════════════════════════════════════════════════

class ExpertSystemResult {
  final List<TerminologyItem> suggestedDiagnoses;
  final List<TerminologyItem> suggestedInterventions;
  final List<TerminologyItem> suggestedMonitoring;

  /// Catatan naratif singkat tentang rencana diet yang direkomendasikan.
  final List<String> dietNotes;

  ExpertSystemResult({
    required this.suggestedDiagnoses,
    required this.suggestedInterventions,
    required this.suggestedMonitoring,
    this.dietNotes = const [],
  });
}

// ═════════════════════════════════════════════════════════════════════════════
// SERVICE UTAMA
// ═════════════════════════════════════════════════════════════════════════════

class DiseaseExpertService {
  ExpertSystemResult generateCarePlan(ExpertSystemInput input) {
    final List<TerminologyItem> diagnoses = [];
    final List<TerminologyItem> interventions = [];
    final List<TerminologyItem> monitoring = [];
    final List<String> dietNotes = [];

    // ─────────────────────────────────────────────────────────────────────────
    // LANGKAH 1 — DETEKSI PENYAKIT
    // ─────────────────────────────────────────────────────────────────────────

    // Diabetes Melitus
    final bool isDiabetes = _isDiabetes(input);

    // CKD (Pre-HD atau HD)
    final bool isKidney = _isKidney(input);

    // Hemodialisis: flag eksplisit ATAU keyword di diagnosis medis
    final bool isHD =
        isKidney &&
        (input.isHemodialysis ||
            (_containsKeyword(input.medicalDiagnosis, [
              'hemodialisis',
              'hd',
              'cuci darah',
            ])));

    // Hipertensi: dari field TD atau keyword
    final bool isHypertension = _isHypertension(input);

    // Dislipidemia
    final bool isDislipidemia = _isDislipidemia(input);

    // Hiperkalemia
    final bool isHiperkalemia = input.kalium != null && input.kalium! > 5.0;

    // Hiperfosfatemia
    final bool isHiperfosfat = input.fosfor != null && input.fosfor! > 4.5;

    // Anemia
    final bool isAnemia =
        input.hgb != null &&
        ((input.hgb! < 13.0 && _isMale(input)) ||
            (input.hgb! < 12.0 && !_isMale(input)));

    // Hipoalbuminemia
    final bool isHipoalbumin = input.albumin != null && input.albumin! < 3.5;

    // ─────────────────────────────────────────────────────────────────────────
    // LANGKAH 2 — DIAGNOSIS GIZI (P – E – S)
    // ─────────────────────────────────────────────────────────────────────────

    // ── A. Status Gizi (Antropometri) ────────────────────────────────────────
    if (input.imt >= 30) {
      _addDiagnosis(
        diagnoses,
        'NC-3.3',
        customDef: 'IMT ${input.imt.toStringAsFixed(1)} kg/m² — Obesitas',
      );
    } else if (input.imt >= 25) {
      _addDiagnosis(
        diagnoses,
        'NC-3.3',
        customDef: 'IMT ${input.imt.toStringAsFixed(1)} kg/m² — Overweight',
      );
    } else if (input.imt < 18.5) {
      _addDiagnosis(
        diagnoses,
        'NC-3.1',
        customDef: 'IMT ${input.imt.toStringAsFixed(1)} kg/m² — Underweight',
      );
    }

    // ── B. Nilai Lab (Domain Klinis – NC-2.2) ────────────────────────────────
    if (isDiabetes) {
      final labDetail = _buildDiabetesLabDetail(input);
      _addDiagnosis(
        diagnoses,
        'NC-2.2',
        customDef: 'Kadar glukosa darah/HbA1c di atas nilai normal. $labDetail',
      );
    }

    if (isKidney) {
      final renalDetail = _buildRenalLabDetail(input);
      _addDiagnosis(
        diagnoses,
        'NC-2.2',
        customDef:
            'Gangguan fungsi ginjal (CKD${isHD ? " + HD" : " Pre-HD"}). $renalDetail',
      );
    }

    if (isDislipidemia) {
      _addDiagnosis(
        diagnoses,
        'NC-2.2',
        customDef: 'Profil lipid abnormal — ${_buildLipidDetail(input)}',
      );
    }

    // ── C. Domain Asupan (NI) ────────────────────────────────────────────────

    // Kelebihan karbohidrat sederhana (DM)
    if (isDiabetes &&
        (input.sukaManis ||
            _containsKeyword(input.medicalDiagnosis, ['manis']))) {
      _addDiagnosis(
        diagnoses,
        'NI-5.8.3',
        customDef:
            'Konsumsi gula murni/makanan manis berlebih (kontraindikasi DM)',
      );
    }

    // Asupan karbohidrat tidak konsisten (DM)
    if (isDiabetes) {
      _addDiagnosis(
        diagnoses,
        'NI-5.8.4',
        customDef:
            'Pola makan tidak teratur — perlu prinsip 3J (Jadwal, Jumlah, Jenis)',
      );
    }

    // Asupan serat kurang (DM)
    if (isDiabetes) {
      _addDiagnosis(
        diagnoses,
        'NI-5.8.5',
        customDef: 'Asupan serat dianjurkan ≥ 25 g/hari dari sayur dan buah',
      );
    }

    // Kelebihan lemak jenuh / kolesterol (DM atau dislipidemia)
    if ((isDiabetes || isDislipidemia) && input.makanBerlemak) {
      _addDiagnosis(
        diagnoses,
        'NI-5.6.3',
        customDef:
            'Asupan lemak jenuh > 10% kebutuhan energi / kolesterol > 300 mg/hari',
      );
    }

    // Kelebihan natrium (Hipertensi / CKD)
    if ((isHypertension || isKidney) &&
        (input.sukaAsin ||
            _containsKeyword(input.dietaryHistory, [
              'asin',
              'awetan',
              'ikan asin',
              'telor asin',
            ]))) {
      _addDiagnosis(
        diagnoses,
        'NI-5.10.2',
        customDef: 'Asupan natrium berlebih — perlu restriksi < 2000 mg/hari',
      );
    }

    // Hiperkalemia (CKD)
    if (isHiperkalemia) {
      _addDiagnosis(
        diagnoses,
        'NI-5.10.2',
        customDef:
            'Kadar Kalium tinggi (${input.kalium} mEq/L) — batasi makanan tinggi kalium '
            '(pisang, belimbing, alpukat, bayam, kangkung)',
      );
    }

    // Hiperfosfatemia (CKD)
    if (isHiperfosfat) {
      _addDiagnosis(
        diagnoses,
        'NI-5.10.2',
        customDef:
            'Kadar Fosfor tinggi (${input.fosfor} mg/dL) — batasi fosfor 800–1000 mg/hari',
      );
    }

    // Penurunan kebutuhan protein (CKD Pre-HD)
    if (isKidney && !isHD) {
      _addDiagnosis(
        diagnoses,
        'NI-5.4',
        customDef:
            'Penurunan kebutuhan protein akibat gangguan fungsi ginjal '
            '— kebutuhan 0.6–0.8 g/kg BB/hari (50% bernilai biologik tinggi)',
      );
    }

    // Peningkatan kebutuhan protein (CKD + HD)
    if (isHD) {
      _addDiagnosis(
        diagnoses,
        'NI-5.1',
        customDef:
            'Peningkatan kebutuhan protein akibat kehilangan asam amino saat dialisis '
            '— kebutuhan 1.2 g/kg BB/hari (50% protein hewani)',
      );
    }

    // Kelebihan cairan (CKD)
    if (isKidney) {
      _addDiagnosis(
        diagnoses,
        'NI-3.2',
        customDef:
            'Risiko kelebihan cairan — kebutuhan cairan dibatasi '
            '(urine output 24 jam + 500–750 ml)',
      );
    }

    // Anemia gizi (CKD / umum)
    if (isAnemia) {
      _addDiagnosis(
        diagnoses,
        'NI-5.10.1',
        customDef:
            'Hemoglobin rendah (${input.hgb?.toStringAsFixed(1)} g/dL) '
            '— kemungkinan anemia gizi / anemia penyakit kronik',
      );
    }

    // Hipoalbuminemia
    if (isHipoalbumin) {
      _addDiagnosis(
        diagnoses,
        'NI-5.3',
        customDef:
            'Albumin rendah (${input.albumin?.toStringAsFixed(1)} g/dL) '
            '— risiko malnutrisi protein-energi',
      );
    }

    // ── D. Domain Perilaku (NB) ──────────────────────────────────────────────
    if (input.jarangOlahraga ||
        _containsKeyword(input.dietaryHistory, [
          'jarang olahraga',
          'tidak olahraga',
        ])) {
      _addDiagnosis(
        diagnoses,
        'NB-2.1',
        customDef: 'Aktivitas fisik < 150 menit/minggu',
      );
    }

    if (isDiabetes || isKidney) {
      _addDiagnosis(
        diagnoses,
        'NB-1.7',
        customDef:
            'Pemilihan jenis/jumlah/jadwal makanan tidak sesuai kondisi penyakit',
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // LANGKAH 3 — INTERVENSI GIZI
    // ─────────────────────────────────────────────────────────────────────────

    // ── DIABETES MELITUS ─────────────────────────────────────────────────────
    if (isDiabetes && !isKidney) {
      // Prinsip 3J
      _addIntervention(
        interventions,
        'ND-1.2',
        note:
            'Diet Diabetes Melitus — Prinsip 3J: atur Jadwal, Jumlah, dan Jenis makanan. '
            'KH 60–70%, Protein 10–15%, Lemak 20–25% dari total energi. '
            'Serat ≥ 25 g/hari. Batasi kolesterol ≤ 300 mg/hari. '
            'Gula murni hanya diperbolehkan ≤ 5% energi total jika GD terkontrol.',
      );

      dietNotes.add(
        '📋 DIABETES MELITUS:\n'
        '• Energi: sesuai kebutuhan untuk mencapai/mempertahankan BB normal.\n'
        '• KH: 60–70% total energi (utamakan KH kompleks, batasi gula sederhana).\n'
        '• Protein: 10–15% total energi.\n'
        '• Lemak: 20–25% total energi; lemak jenuh < 10%; kolesterol ≤ 300 mg/hari.\n'
        '• Serat: ≥ 25 g/hari (sayur dan buah).\n'
        '• Hindari: gula pasir, sirup, jeli, minuman manis, kue manis, gorengan, ikan asin.\n'
        '• Gunakan gula alternatif dalam jumlah terbatas (sorbitol, aspartam).',
      );
    }

    // ── CKD PRE-HEMODIALISIS ─────────────────────────────────────────────────
    if (isKidney && !isHD) {
      final energyNote = (input.usia != null && input.usia! >= 60)
          ? '30 kkal/kg BB (usia ≥ 60 tahun)'
          : '35 kkal/kg BB (usia < 60 tahun)';

      _addIntervention(
        interventions,
        'ND-1.2',
        note:
            'Diet Ginjal Kronik Pre-HD. Energi $energyNote. '
            'Protein rendah 0.6–0.8 g/kg BB/hari (50% bernilai biologik tinggi — hewani). '
            'Lemak 25–30% total energi (jenuh < 10%). '
            'Natrium < 2000 mg/hari. '
            'Kalium 39 mg/kg BB/hari (sesuaikan lab). '
            'Kalsium 1200 mg/hari. Fosfor 800–1000 mg/hari. '
            'Cairan: urine output 24 jam + 500–750 ml.',
      );

      if (isDiabetes) {
        _addIntervention(
          interventions,
          'ND-1.2',
          note:
              'Komorbid DM + CKD Pre-HD: terapkan sekaligus prinsip diet DM '
              '(batasi gula murni, serat ≥ 25 g/hari) dan restriksi protein ginjal.',
        );
      }

      dietNotes.add(
        '📋 GINJAL KRONIK PRE-HEMODIALISIS:\n'
        '• Energi: $energyNote.\n'
        '• Protein: 0.6–0.8 g/kg BB/hari; 50% dari sumber hewani (telur, ayam, ikan, daging).\n'
        '  – Hindari: kacang-kacangan, tahu, tempe, ikan asin.\n'
        '• Lemak: 25–30% total energi; jenuh < 10%; kolesterol < 300 mg/hari jika dislipidemia.\n'
        '• KH: sisa kebutuhan energi.\n'
        '• Natrium: < 2000 mg/hari.\n'
        '• Kalium: 39 mg/kg BB/hari — sesuaikan dengan nilai laboratorium.\n'
        '• Fosfor: 800–1000 mg/hari.\n'
        '• Kalsium: 1200 mg/hari.\n'
        '• Cairan: urine output 24 jam + 500–750 ml.\n'
        '• Sayuran/buah tinggi kalium (pisang, belimbing, alpukat, bayam, kangkung) DIBATASI jika hiperkalemia.',
      );
    }

    // ── CKD + HEMODIALISIS ───────────────────────────────────────────────────
    if (isHD) {
      final energyNoteHD = (input.usia != null && input.usia! >= 60)
          ? '30–35 kkal/kg BB ideal (usia ≥ 60 tahun)'
          : '35 kkal/kg BB ideal (usia < 60 tahun)';

      _addIntervention(
        interventions,
        'ND-1.2',
        note:
            'Diet Ginjal Kronik + Hemodialisis. Energi $energyNoteHD. '
            'Protein TINGGI 1.2 g/kg BB ideal/hari (50% protein hewani — telur, ayam, ikan, daging). '
            'KH 55–70%, Lemak 15–30% total energi. '
            'Natrium: 1 g + 1 g per 500 ml urine/hari (jika anuric: 2 g/hari). '
            'Kalium: 2 g + 1 g per 1 L urine/hari (atau 40 mg/kg BB). '
            'Fosfor: < 17 mg/kg BB ideal/hari (800–1000 mg). '
            'Kalsium: 1000–2000 mg/hari (suplementasi jika perlu). '
            'Cairan: urine output 24 jam + 500–750 ml.',
      );

      if (isDiabetes) {
        _addIntervention(
          interventions,
          'ND-1.2',
          note:
              'Komorbid DM + CKD-HD: kontrol gula tetap diutamakan. '
              'Pertimbangkan formula enteral tinggi protein rendah KH sederhana '
              'jika asupan oral tidak mencukupi.',
        );
      }

      // Suplemen jika nafsu makan turun
      _addIntervention(
        interventions,
        'ND-3.1.1',
        note:
            'Pertimbangkan suplemen/minuman enteral tinggi protein dan energi '
            'jika asupan oral < 80% kebutuhan (sesuai panduan CKD-HD).',
      );

      dietNotes.add(
        '📋 GINJAL KRONIK + HEMODIALISIS:\n'
        '• Energi: $energyNoteHD.\n'
        '• Protein: 1.2 g/kg BB ideal/hari; 50% dari protein hewani.\n'
        '  – Dianjurkan: telur, daging, ayam, ikan. Batasi tahu/tempe.\n'
        '• KH: 55–70% total energi (utamakan nasi, bihun, mi, makaroni).\n'
        '• Lemak: 15–30% total energi (minyak jagung, kacang — hindari lemak hewan).\n'
        '• Natrium: 1 g + 1 g per 500 ml urine/hari (anuric: 2 g/hari).\n'
        '• Kalium: 2 g + 1 g per 1 L urine/hari. BATASI sayur/buah tinggi kalium.\n'
        '• Fosfor: < 17 mg/kg BB ideal/hari (800–1000 mg). Hindari kacang, susu berlebih.\n'
        '• Kalsium: 1000–2000 mg/hari; suplementasi kalsium jika perlu.\n'
        '• Cairan: urine output 24 jam + 500–750 ml.\n'
        '• Jika nafsu makan menurun: berikan suplemen enteral tinggi protein.',
      );
    }

    // ── HIPERTENSI ────────────────────────────────────────────────────────────
    if (isHypertension && !isKidney) {
      _addIntervention(
        interventions,
        'ND-1.2',
        note:
            'Diet Rendah Garam (DASH). Batasi natrium < 2000 mg/hari. '
            'Hindari: ikan asin, telor asin, makanan awetan, fast food.',
      );
      dietNotes.add(
        '📋 HIPERTENSI:\n'
        '• Batasi natrium < 2000 mg/hari (Diet Rendah Garam / DASH).\n'
        '• Hindari: ikan asin, telor asin, kecap berlebih, makanan olahan/kaleng.',
      );
    }

    // ── DISLIPIDEMIA ─────────────────────────────────────────────────────────
    if (isDislipidemia) {
      _addIntervention(
        interventions,
        'ND-1.2',
        note:
            'Diet Rendah Lemak Jenuh. Kolesterol ≤ 300 mg/hari. '
            'Lemak jenuh < 10% total energi. '
            'Batasi: gorengan, fast food, lemak hewan, santan kental.',
      );
    }

    // ── HIPERKALEMIA (CKD) ───────────────────────────────────────────────────
    if (isHiperkalemia) {
      _addIntervention(
        interventions,
        'ND-1.3',
        note:
            'Batasi makanan tinggi kalium: pisang, belimbing, bit, alpukat, mangga, '
            'semangka, melon, bayam, daun singkong, kangkung, asparagus. '
            'Pilih sayur/buah rendah kalium: wortel, labu siam, buncis, pepaya, pir, apel. '
            'Teknik merebus sayur (buang air rebusan) membantu menurunkan kalium.',
      );
    }

    // ── HIPERFOSFATEMIA (CKD) ─────────────────────────────────────────────────
    if (isHiperfosfat) {
      _addIntervention(
        interventions,
        'ND-1.3',
        note:
            'Batasi fosfor makanan: 800–1000 mg/hari. '
            'Batasi susu, keju, kacang-kacangan, minuman bersoda gelap.',
      );
    }

    // ── ANEMIA ────────────────────────────────────────────────────────────────
    if (isAnemia) {
      _addIntervention(
        interventions,
        'ND-3.2.4',
        note:
            'Pertimbangkan suplementasi zat besi/asam folat sesuai indikasi. '
            'Tingkatkan sumber protein hewani sebagai sumber Fe-heme.',
      );
    }

    // ── Edukasi Gizi ─────────────────────────────────────────────────────────
    _addIntervention(
      interventions,
      'NE-1.1',
      note: 'Edukasi singkat: tujuan diet, makanan dianjurkan vs dibatasi.',
    );
    _addIntervention(
      interventions,
      'NE-2.2',
      note:
          'Edukasi mendalam: cara membaca label pangan, estimasi porsi, pengganti bahan makanan.',
    );

    // ── Konseling Gizi ────────────────────────────────────────────────────────
    _addIntervention(
      interventions,
      'NC-1.4',
      note: 'Konseling motivasi: tahap kesiapan perubahan perilaku diet.',
    );
    _addIntervention(
      interventions,
      'NC-2.2',
      note: 'Strategi penetapan tujuan dan pemecahan masalah diet sehari-hari.',
    );

    // ─────────────────────────────────────────────────────────────────────────
    // LANGKAH 4 — MONITORING & EVALUASI
    // ─────────────────────────────────────────────────────────────────────────

    // Asupan Energi — selalu monitor
    _addMonitoring(
      monitoring,
      'FI-1.1',
      note: 'Total asupan energi vs kebutuhan (food recall 24 jam)',
    );

    // Asupan Makronutrien
    _addMonitoring(
      monitoring,
      'FI-5.2',
      note: isDiabetes
          ? 'Asupan Protein (10–15% energi — DM)'
          : isHD
          ? 'Asupan Protein (1.2 g/kg BB/hari — HD)'
          : isKidney
          ? 'Asupan Protein (0.6–0.8 g/kg BB/hari — CKD Pre-HD)'
          : 'Asupan Protein',
    );

    _addMonitoring(
      monitoring,
      'FI-5.3',
      note: isDiabetes
          ? 'Asupan KH (60–70% energi); pantau konsumsi gula sederhana'
          : 'Asupan Karbohidrat',
    );

    _addMonitoring(
      monitoring,
      'FI-5.1',
      note: 'Asupan Lemak (jenuh < 10% energi; kolesterol ≤ 300 mg/hari)',
    );

    if (isDiabetes) {
      _addMonitoring(
        monitoring,
        'FI-5.4',
        note: 'Asupan Serat (target ≥ 25 g/hari — DM)',
      );
    }

    // Glukosa Darah (DM)
    if (isDiabetes) {
      _addMonitoring(
        monitoring,
        'S-2.5',
        note:
            'GDS, GDP, HbA1c — target GDS < 200 mg/dL, GDP < 126 mg/dL, HbA1c < 6.5%',
      );
    }

    // Profil Ginjal & Elektrolit (CKD)
    if (isKidney) {
      _addMonitoring(
        monitoring,
        'S-2.2',
        note: 'Ureum, Kreatinin, GFR, Natrium, Kalium, Fosfor, Kalsium',
      );
      _addMonitoring(
        monitoring,
        'S-3.1',
        note:
            'Berat Badan Kering, Edema, Balance Cairan (timbang setiap kunjungan)',
      );
    }

    // Profil Lipid (Dislipidemia / DM / CKD)
    if (isDislipidemia || isDiabetes || isKidney) {
      _addMonitoring(
        monitoring,
        'S-2.7',
        note: 'Kolesterol Total, LDL, HDL, Trigliserida',
      );
    }

    // Tekanan Darah (Hipertensi)
    if (isHypertension) {
      _addMonitoring(
        monitoring,
        'S-1.1',
        note: 'Tekanan Darah (target < 140/90 mmHg)',
      );
    }

    // Antropometri (IMT abnormal)
    if (input.imt >= 25 || input.imt < 18.5) {
      _addMonitoring(
        monitoring,
        'S-3.1',
        note: 'Berat Badan & IMT (target IMT 18.5–24.9 kg/m²)',
      );
    }

    // Anemia (CKD / umum)
    if (isAnemia || isKidney) {
      _addMonitoring(
        monitoring,
        'S-2.10',
        note: 'Hb, Hematokrit, Albumin — profil anemia gizi',
      );
    }

    // Protein Serum
    if (isHipoalbumin || isKidney || isHD) {
      _addMonitoring(
        monitoring,
        'S-2.11',
        note: 'Albumin serum (target ≥ 3.5 g/dL)',
      );
    }

    // Perilaku / Kepatuhan Diet
    _addMonitoring(
      monitoring,
      'BE-1.2',
      note: 'Pengetahuan pasien terkait makanan dan zat gizi yang dianjurkan',
    );
    _addMonitoring(
      monitoring,
      'BE-2.1',
      note: 'Kemampuan merencanakan menu sehari-hari sesuai diet',
    );

    return ExpertSystemResult(
      suggestedDiagnoses: diagnoses,
      suggestedInterventions: interventions,
      suggestedMonitoring: monitoring,
      dietNotes: dietNotes,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER — DETEKSI PENYAKIT
  // ═══════════════════════════════════════════════════════════════════════════

  bool _isDiabetes(ExpertSystemInput i) =>
      _containsKeyword(i.medicalDiagnosis, [
        'diabetes',
        'dm',
        'dm tipe',
        'kencing manis',
      ]) ||
      (i.gds != null && i.gds! >= 200) ||
      (i.gdp != null && i.gdp! >= 126) ||
      (i.hba1c != null && i.hba1c! >= 6.5);

  bool _isKidney(ExpertSystemInput i) =>
      i.hasKidneyIssue ||
      _containsKeyword(i.medicalDiagnosis, [
        'ckd',
        'ginjal kronik',
        'chronic kidney',
        'penyakit ginjal',
        'hemodialisis',
        'cuci darah',
        'uremia',
      ]) ||
      (i.ureum != null && i.ureum! > 50) ||
      (i.kreatinin != null && i.kreatinin! > 1.5);

  bool _isHypertension(ExpertSystemInput i) {
    if (_containsKeyword(i.medicalDiagnosis, [
      'hipertensi',
      'hypertensi',
      'tekanan darah tinggi',
    ])) {
      return true;
    }
    if (i.bloodPressure.toLowerCase().contains('hipertensi') ||
        i.bloodPressure.toLowerCase().contains('tinggi')) {
      return true;
    }
    if (i.sistolik != null && i.diastolik != null) {
      return i.sistolik! >= 140 || i.diastolik! >= 90;
    }
    return false;
  }

  bool _isDislipidemia(ExpertSystemInput i) =>
      (i.cholesterol != null && i.cholesterol! > 200) ||
      (i.ldl != null && i.ldl! > 130) ||
      (i.trigliserida != null && i.trigliserida! > 150) ||
      (i.hdl != null && i.hdl! < 40);

  /// Tebak jenis kelamin dari medicalDiagnosis atau default male
  bool _isMale(ExpertSystemInput i) => !_containsKeyword(i.medicalDiagnosis, [
    'perempuan',
    'wanita',
    'ny.',
    'ny ',
    'nn.',
  ]);

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER — DETAIL LABEL
  // ═══════════════════════════════════════════════════════════════════════════

  String _buildDiabetesLabDetail(ExpertSystemInput i) {
    final parts = <String>[];
    if (i.gds != null) parts.add('GDS: ${i.gds} mg/dL');
    if (i.gdp != null) parts.add('GDP: ${i.gdp} mg/dL');
    if (i.hba1c != null) parts.add('HbA1c: ${i.hba1c}%');
    return parts.join(', ');
  }

  String _buildRenalLabDetail(ExpertSystemInput i) {
    final parts = <String>[];
    if (i.ureum != null) parts.add('Ureum: ${i.ureum} mg/dL');
    if (i.kreatinin != null) parts.add('Kreatinin: ${i.kreatinin} mg/dL');
    if (i.kalium != null) parts.add('Kalium: ${i.kalium} mEq/L');
    if (i.natrium != null) parts.add('Natrium: ${i.natrium} mEq/L');
    if (i.fosfor != null) parts.add('Fosfor: ${i.fosfor} mg/dL');
    return parts.join(', ');
  }

  String _buildLipidDetail(ExpertSystemInput i) {
    final parts = <String>[];
    if (i.cholesterol != null) parts.add('Kol.Total: ${i.cholesterol} mg/dL');
    if (i.ldl != null) parts.add('LDL: ${i.ldl} mg/dL');
    if (i.hdl != null) parts.add('HDL: ${i.hdl} mg/dL');
    if (i.trigliserida != null) parts.add('TG: ${i.trigliserida} mg/dL');
    return parts.join(', ');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER — KEYWORD CHECK
  // ═══════════════════════════════════════════════════════════════════════════

  bool _containsKeyword(dynamic value, List<String> keywords) {
    if (value == null) return false;
    String text;
    if (value is String) {
      text = value.toLowerCase();
    } else if (value is List<String>) {
      text = value.join(' ').toLowerCase();
    } else {
      return false;
    }
    return keywords.any((k) => text.contains(k.toLowerCase()));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HELPER — ADD ITEM (Diagnosis / Intervensi / Monitoring)
  // ═══════════════════════════════════════════════════════════════════════════

  void _addDiagnosis(
    List<TerminologyItem> list,
    String code, {
    String? customDef,
  }) {
    try {
      final found = DiagnosisTerminology.allDiagnoses.firstWhere(
        (item) => item.code == code,
      );
      list.add(
        TerminologyItem(
          domain: found.domain,
          classCode: found.classCode,
          code: found.code,
          label: found.label,
          category: customDef ?? found.category,
        ),
      );
    } catch (e) {
      debugPrint('⚠️  Diagnosis code "$code" not found: $e');
    }
  }

  void _addIntervention(
    List<TerminologyItem> list,
    String code, {
    String? note,
  }) {
    try {
      final found = IntervensiData.allInterventions.firstWhere(
        (item) => item.code == code,
      );
      list.add(
        TerminologyItem(
          domain: found.domain,
          classCode: found.classCode,
          code: found.code,
          label: found.label,
          category: note != null
              ? '${found.category}. Catatan: $note'
              : found.category,
        ),
      );
    } catch (e) {
      debugPrint('⚠️  Intervention code "$code" not found: $e');
    }
  }

  void _addMonitoring(List<TerminologyItem> list, String code, {String? note}) {
    try {
      final found = MonitoringData.allMonitoringItems.firstWhere(
        (item) => item.code == code,
      );
      list.add(
        TerminologyItem(
          domain: found.domain,
          classCode: found.classCode,
          code: found.code,
          label: found.label,
          category: note != null ? '${found.category} ($note)' : found.category,
        ),
      );
    } catch (e) {
      debugPrint('⚠️  Monitoring code "$code" not found: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTRY POINT DARI FORM — semua parsing data form dilakukan di sini
  // sehingga data_form_page.dart hanya perlu memanggil buildAndRun()
  // ═══════════════════════════════════════════════════════════════════════════

  /// Terima data mentah dari form (semua bertipe String / bool / DateTime?),
  /// parsing sendiri, lalu langsung kembalikan [ExpertSystemResult].
  ExpertSystemResult buildAndRun({
    // ── Fisik ────────────────────────────────────────────────────────────────
    required String beratBadanText,
    required String tinggiBadanText,
    DateTime? tanggalLahir,
    // ── Lab (nilai raw dari TextEditingController) ───────────────────────────
    required Map<String, String>
    labValues, // key = jenis lab, value = teks angka
    // ── Klinis ───────────────────────────────────────────────────────────────
    required String sistolikText,
    required String diastolikText,
    required String tdText, // gabungan "120/80" — untuk bloodPressure
    // ── Diagnosis Medis ──────────────────────────────────────────────────────
    required String diagnosisMedis,
    // ── Kebiasaan Makan ──────────────────────────────────────────────────────
    required bool sukaManis,
    required bool sukaAsin,
    required bool makanBerlemak,
    required bool jarangOlahraga,
  }) {
    // 1. Hitung IMT
    final double? bb = double.tryParse(beratBadanText);
    final double? tb = double.tryParse(tinggiBadanText);
    double imt = 0;
    if (bb != null && tb != null && tb > 0) {
      final tbM = tb / 100;
      imt = bb / (tbM * tbM);
    }

    // 2. Hitung Usia
    int? usia;
    if (tanggalLahir != null) {
      final now = DateTime.now();
      usia = now.year - tanggalLahir.year;
      if (now.month < tanggalLahir.month ||
          (now.month == tanggalLahir.month && now.day < tanggalLahir.day)) {
        usia--;
      }
    }

    // 3. Parse nilai lab
    double? parseVal(String key) {
      final raw = labValues[key];
      if (raw == null || raw.isEmpty) return null;
      final clean = raw.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean);
    }

    // 4. Parse tekanan darah
    final int? sistolik = int.tryParse(sistolikText);
    final int? diastolik = int.tryParse(diastolikText);

    // 5. Bangun dietaryHistory dari kebiasaan
    final List<String> dietaryHistory = [
      if (sukaManis) 'Suka manis',
      if (sukaAsin) 'Suka asin',
      if (makanBerlemak) 'Suka berlemak',
      if (jarangOlahraga) 'Jarang olahraga',
    ];

    // 6. Rakit ExpertSystemInput dan jalankan
    final input = ExpertSystemInput(
      imt: imt,
      gds: parseVal('GDS'),
      gdp: parseVal('GDP'),
      hba1c: parseVal('HbA1c'),
      cholesterol: parseVal('Kolesterol Total'),
      ldl: parseVal('LDL'),
      hdl: parseVal('HDL'),
      trigliserida: parseVal('Trigliserida'),
      ureum: parseVal('Ureum'),
      kreatinin: parseVal('Kreatinin'),
      kalium: parseVal('Kalium'),
      natrium: parseVal('Natrium'),
      hgb: parseVal('HGB'),
      sistolik: sistolik,
      diastolik: diastolik,
      bloodPressure: tdText,
      dietaryHistory: dietaryHistory,
      sukaManis: sukaManis,
      sukaAsin: sukaAsin,
      makanBerlemak: makanBerlemak,
      jarangOlahraga: jarangOlahraga,
      medicalDiagnosis: diagnosisMedis,
      beratBadan: bb,
      usia: usia,
    );

    return generateCarePlan(input);
  }

  // ── Helper: bangun teks Signs dari satu TerminologyItem + nilai lab ─────────
  /// Dipanggil dari data_form_page saat mengisi field S (Signs/Symptoms).
  static String buildSigns(
    TerminologyItem diag, {
    double? gds,
    double? gdp,
    double? hba1c,
    double? ureum,
    double? kreatinin,
    double? kolesterol,
    double? ldl,
    double? hdl,
    double? trigliserida,
    double? kalium,
    double? natrium,
    double? hgb,
    int? sistolik,
    int? diastolik,
    double? imt,
    bool sukaAsin = false,
  }) {
    switch (diag.code) {
      case 'NC-2.2':
        final parts = <String>[];
        if (gds != null) {
          parts.add('GDS: ${gds.round()} mg/dL');
        }
        if (gdp != null) {
          parts.add('GDP: ${gdp.round()} mg/dL');
        }
        if (hba1c != null) {
          parts.add('HbA1c: $hba1c%');
        }
        if (ureum != null) {
          parts.add('Ureum: ${ureum.round()} mg/dL');
        }
        if (kreatinin != null) {
          parts.add('Kreatinin: $kreatinin mg/dL');
        }
        if (kolesterol != null) {
          parts.add('Kol.Total: ${kolesterol.round()} mg/dL');
        }
        if (ldl != null) {
          parts.add('LDL: ${ldl.round()} mg/dL');
        }
        if (hdl != null) {
          parts.add('HDL: ${hdl.round()} mg/dL');
        }
        if (trigliserida != null) {
          parts.add('TG: ${trigliserida.round()} mg/dL');
        }
        if (kalium != null) {
          parts.add('Kalium: $kalium mEq/L');
        }
        return parts.isNotEmpty
            ? 'Hasil Lab: ${parts.join(', ')}'
            : 'Perubahan nilai lab terkait gizi';
      case 'NC-3.3':
      case 'NC-3.1':
        return imt != null ? 'IMT: ${imt.toStringAsFixed(1)} kg/m²' : '';
      case 'NI-5.8.3':
      case 'NI-5.8.4':
        return 'Riwayat: suka makanan/minuman manis';
      case 'NI-5.8.5':
        return 'Asupan serat perlu ditingkatkan (≥ 25 g/hari)';
      case 'NI-5.6.3':
        return 'Riwayat: sering konsumsi makanan berlemak/gorengan';
      case 'NI-5.10.2':
        final parts = <String>[];
        if (sukaAsin) {
          parts.add('riwayat suka asin');
        }
        if (kalium != null) {
          parts.add('Kalium: $kalium mEq/L');
        }
        if (natrium != null) {
          parts.add('Natrium: $natrium mEq/L');
        }
        if (sistolik != null && diastolik != null) {
          parts.add('TD: $sistolik/$diastolik mmHg');
        }
        return parts.join('; ');
      case 'NI-5.10.1':
        return hgb != null ? 'Hb: $hgb g/dL' : '';
      case 'NI-5.4':
        return kreatinin != null
            ? 'Kreatinin: $kreatinin mg/dL — restriksi protein'
            : 'Gangguan fungsi ginjal';
      case 'NI-5.1':
        return 'CKD + HD: kehilangan asam amino saat dialisis';
      case 'NI-3.2':
        return 'Risiko overload cairan — monitor urine output';
      case 'NI-5.3':
        return 'Albumin rendah — risiko malnutrisi';
      case 'NB-2.1':
        return 'Riwayat: jarang berolahraga (< 150 menit/minggu)';
      case 'NB-1.7':
        return 'Pemilihan makanan belum sesuai kondisi penyakit';
      default:
        return '';
    }
  }
  // ═══════════════════════════════════════════════════════════════════════════
  // ENTRY POINT DARI FORM ANAK (PEDIATRIC)
  // ═══════════════════════════════════════════════════════════════════════════

  ExpertSystemResult buildAndRunPediatric({
    required String beratBadanText,
    required String tinggiBadanText,
    required String statusBBTB,
    required String statusTBU,
    required List<String> alergiList,
    required Map<String, String> labValues,
    required String diagnosisMedis,
  }) {
    final List<TerminologyItem> diagnoses = [];
    final List<TerminologyItem> interventions = [];
    final List<TerminologyItem> monitoring = [];
    final List<String> dietNotes = [];

    // --- PARSING NILAI LAB ---
    double? parseVal(String key) {
      final raw = labValues[key];
      if (raw == null || raw.isEmpty) return null;
      final clean = raw.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), '');
      return double.tryParse(clean);
    }

    final double? gds = parseVal('GDS');
    final double? gdp = parseVal('GDP');
    final double? hba1c = parseVal('HbA1c');
    final double? ureum = parseVal('Ureum');
    final double? kreatinin = parseVal('Kreatinin');

    // --- DETEKSI KONDISI KLINIS ---
    final bool isDiabetes =
        _containsKeyword(diagnosisMedis, [
          'diabetes',
          'dm',
          'dm tipe 1',
          'kencing manis',
        ]) ||
        (gds != null && gds >= 200) ||
        (gdp != null && gdp >= 126) ||
        (hba1c != null && hba1c >= 6.5);

    final bool isKidney =
        _containsKeyword(diagnosisMedis, [
          'ckd',
          'ginjal',
          'nefrotik',
          'hemodialisis',
          'gagal ginjal',
        ]) ||
        (ureum != null && ureum > 50) ||
        (kreatinin != null &&
            kreatinin >
                1.2); // Batas normal kreatinin anak umumnya lebih rendah

    // ─────────────────────────────────────────────────────────────────────────
    // LANGKAH 1 — DIAGNOSIS GIZI ANAK (PES)
    // ─────────────────────────────────────────────────────────────────────────

    // 1. Gizi Kurang / Gizi Buruk
    if (statusBBTB.contains('Buruk') || statusBBTB.contains('Kurang')) {
      _addDiagnosis(
        diagnoses,
        'NI-2.1',
        customDef:
            'Asupan oral tidak adekuat — Status Gizi BB/TB: $statusBBTB, BB aktual $beratBadanText kg',
      );
    }

    // 2. Pendek / Sangat Pendek (Stunting)
    if (statusTBU.contains('Pendek')) {
      _addDiagnosis(
        diagnoses,
        'NC-3.2',
        customDef:
            'Pertumbuhan janin/bayi/anak terhambat — Status Gizi TB/U: $statusTBU, TB aktual $tinggiBadanText cm',
      );
    }

    // 3. Gizi Lebih / Obesitas
    if (statusBBTB.contains('Lebih') || statusBBTB.contains('Obesitas')) {
      _addDiagnosis(
        diagnoses,
        'NC-3.3',
        customDef:
            'Berat badan lebih/Obesitas — Status Gizi BB/TB: $statusBBTB',
      );
    }

    // 4. Diabetes Melitus pada Anak
    if (isDiabetes) {
      _addDiagnosis(
        diagnoses,
        'NC-2.2',
        customDef:
            'Perubahan nilai lab terkait gizi (Hiperglikemia/DM) — GDS/GDP/HbA1c tinggi atau riwayat DM Tipe 1',
      );
      _addDiagnosis(
        diagnoses,
        'NI-5.8.3',
        customDef:
            'Asupan karbohidrat tidak konsisten / kelebihan gula sederhana',
      );
    }

    // 5. Gangguan Ginjal pada Anak
    if (isKidney) {
      _addDiagnosis(
        diagnoses,
        'NC-2.2',
        customDef:
            'Perubahan nilai lab terkait gizi (Gangguan Ginjal) — Ureum/Kreatinin tinggi atau Sindrom Nefrotik/CKD',
      );
      _addDiagnosis(
        diagnoses,
        'NI-5.4',
        customDef: 'Penurunan kebutuhan protein terkait fungsi ginjal',
      );
    }

    // 6. Alergi Makanan
    if (alergiList.isNotEmpty) {
      _addDiagnosis(
        diagnoses,
        'NC-2.2',
        customDef:
            'Perubahan nilai lab terkait gizi (Reaksi Alergi) — Riwayat alergi: ${alergiList.join(", ")}',
      );
    }

    // ─────────────────────────────────────────────────────────────────────────
    // LANGKAH 2 — INTERVENSI GIZI ANAK
    // ─────────────────────────────────────────────────────────────────────────

    // Prioritas Intervensi Penyakit Klinis
    if (isKidney) {
      _addIntervention(
        interventions,
        'ND-1.2',
        note:
            'Diet Ginjal Anak: Restriksi protein sesuai LPT (Luas Permukaan Tubuh) dan panduan fungsi ginjal. Batasi natrium, kalium, dan cairan jika ada indikasi.',
      );
    } else if (isDiabetes) {
      _addIntervention(
        interventions,
        'ND-1.2',
        note:
            'Diet DM Tipe 1 / Tipe 2: Pengaturan jadwal, jumlah, dan jenis karbohidrat (3J) disesuaikan dengan dosis insulin anak.',
      );
    } else if (statusBBTB.contains('Buruk') || statusBBTB.contains('Kurang')) {
      _addIntervention(
        interventions,
        'ND-1.2',
        note:
            'Diet ETPT (Energi Tinggi Protein Tinggi) untuk kejar tumbuh (catch-up growth).',
      );
    } else if (statusBBTB.contains('Lebih') ||
        statusBBTB.contains('Obesitas')) {
      _addIntervention(
        interventions,
        'ND-1.2',
        note:
            'Diet Gizi Seimbang & Rendah Kalori (sesuaikan usia agar tidak mengganggu pertumbuhan linear).',
      );
    } else {
      _addIntervention(
        interventions,
        'ND-1.2',
        note: 'Diet Gizi Seimbang untuk mendukung tumbuh kembang optimal anak.',
      );
    }

    if (alergiList.isNotEmpty) {
      _addIntervention(
        interventions,
        'ND-1.2',
        note: 'Diet Eliminasi Alergen (Hindari: ${alergiList.join(", ")}).',
      );
    }

    _addIntervention(
      interventions,
      'NE-1.1',
      note:
          'Edukasi gizi seimbang dan pola asuh makan (feeding rules) untuk orang tua/pengasuh.',
    );

    // ─────────────────────────────────────────────────────────────────────────
    // LANGKAH 3 — MONITORING & EVALUASI ANAK
    // ─────────────────────────────────────────────────────────────────────────

    _addMonitoring(
      monitoring,
      'S-3.1',
      note:
          'Pemantauan Antropometri berkala (BB, TB, Lingkar Kepala) sesuai kurva pertumbuhan WHO/Kemenkes.',
    );
    _addMonitoring(
      monitoring,
      'FI-1.1',
      note:
          'Evaluasi asupan Energi & Zat Gizi Makro (Recall 24 jam / Food Diary).',
    );

    if (isDiabetes) {
      _addMonitoring(
        monitoring,
        'S-2.5',
        note: 'Pantau profil glukosa darah harian dan HbA1c secara berkala.',
      );
    }
    if (isKidney) {
      _addMonitoring(
        monitoring,
        'S-2.2',
        note:
            'Pantau Ureum, Kreatinin, elektrolit (Natrium/Kalium), dan profil urin.',
      );
      _addMonitoring(
        monitoring,
        'S-3.1',
        note:
            'Pantau adanya edema dan timbang berat badan setiap hari (keseimbangan cairan).',
      );
    }

    return ExpertSystemResult(
      suggestedDiagnoses: diagnoses,
      suggestedInterventions: interventions,
      suggestedMonitoring: monitoring,
      dietNotes: dietNotes,
    );
  }
}
