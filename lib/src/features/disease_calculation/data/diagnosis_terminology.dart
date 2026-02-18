// lib/src/features/disease_calculation/data/diagnosis_terminology.dart

import 'terminology_item.dart';

// ─── Domain Constants ─────────────────────────────────────────────────────────
class _Domain {
  _Domain._();
  static const ni = 'NI (Asupan)';
  static const nc = 'NC (Klinis)';
  static const nb = 'NB (Perilaku)';
}

class DiagnosisTerminology {
  static const List<TerminologyItem> allDiagnoses = [

    // ══════════════════════════════════════════════════════════════
    // DOMAIN NI — ASUPAN
    // ══════════════════════════════════════════════════════════════

    // ── NI-1: Keseimbangan Energi ─────────────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-1',
      category: 'Keseimbangan Energi',
      code: 'NI-1.1',
      label: 'Peningkatan energy expenditure',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-1',
      category: 'Keseimbangan Energi',
      code: 'NI-1.2',
      label: 'Asupan energi tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-1',
      category: 'Keseimbangan Energi',
      code: 'NI-1.3',
      label: 'Kelebihan asupan energi',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-1',
      category: 'Keseimbangan Energi',
      code: 'NI-1.4',
      label: 'Perkiraan asupan energi suboptimal',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-1',
      category: 'Keseimbangan Energi',
      code: 'NI-1.5',
      label: 'Perkiraan kelebihan asupan energi',
    ),

    // ── NI-2: Asupan Oral / Dukungan Gizi ────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-2',
      category: 'Asupan Oral',
      code: 'NI-2.1',
      label: 'Asupan makanan/minuman oral tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-2',
      category: 'Asupan Oral',
      code: 'NI-2.2',
      label: 'Kelebihan asupan makanan/minuman oral',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-2',
      category: 'Dukungan Gizi',
      code: 'NI-2.3',
      label: 'Asupan enteral/parenteral tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-2',
      category: 'Dukungan Gizi',
      code: 'NI-2.4',
      label: 'Kelebihan asupan enteral/parenteral',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-2',
      category: 'Dukungan Gizi',
      code: 'NI-2.5',
      label: 'Komposisi/infus enteral/parenteral tidak tepat',
    ),

    // ── NI-3: Asupan Cairan ───────────────────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-3',
      category: 'Asupan Cairan',
      code: 'NI-3.1',
      label: 'Asupan cairan tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-3',
      category: 'Asupan Cairan',
      code: 'NI-3.2',
      label: 'Kelebihan asupan cairan',
    ),

    // ── NI-4: Zat Bioaktif ────────────────────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-4',
      category: 'Zat Bioaktif',
      code: 'NI-4.1',
      label: 'Asupan substansi bioaktif tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-4',
      category: 'Zat Bioaktif',
      code: 'NI-4.2',
      label: 'Kelebihan asupan substansi bioaktif',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-4',
      category: 'Zat Bioaktif',
      code: 'NI-4.3',
      label: 'Konsumsi alkohol berlebih',
    ),

    // ── NI-5: Zat Gizi (Umum) ────────────────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Zat Gizi',
      code: 'NI-5.1',
      label: 'Peningkatan kebutuhan zat gizi',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Zat Gizi',
      code: 'NI-5.2',
      label: 'Malnutrisi nyata (kurang gizi)',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Zat Gizi',
      code: 'NI-5.3',
      label: 'Asupan energi protein tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Zat Gizi',
      code: 'NI-5.4',
      label: 'Penurunan kebutuhan zat gizi',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Zat Gizi',
      code: 'NI-5.5',
      label: 'Ketidakseimbangan zat gizi',
    ),

    // ── NI-5.6: Lemak dan Kolesterol ─────────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Lemak',
      code: 'NI-5.6.1',
      label: 'Asupan lemak tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Lemak',
      code: 'NI-5.6.2',
      label: 'Kelebihan asupan lemak',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Lemak',
      code: 'NI-5.6.3',
      label: 'Asupan jenis lemak tidak sesuai',
    ),

    // ── NI-5.7: Protein ───────────────────────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Protein',
      code: 'NI-5.7.1',
      label: 'Asupan protein tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Protein',
      code: 'NI-5.7.2',
      label: 'Kelebihan asupan protein',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Protein (HBV/LBV)',
      code: 'NI-5.7.3',
      label: 'Asupan jenis protein tidak sesuai',
    ),

    // ── NI-5.8: Karbohidrat dan Serat ────────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Karbohidrat',
      code: 'NI-5.8.1',
      label: 'Asupan karbohidrat tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Karbohidrat',
      code: 'NI-5.8.2',
      label: 'Kelebihan asupan karbohidrat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Karbohidrat (Gula Sederhana)',
      code: 'NI-5.8.3',
      label: 'Asupan jenis karbohidrat tidak sesuai',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Karbohidrat (Jadwal)',
      code: 'NI-5.8.4',
      label: 'Asupan karbohidrat tidak konsisten',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Serat',
      code: 'NI-5.8.5',
      label: 'Asupan serat tidak adekuat',
    ),

    // ── NI-5.9: Vitamin ───────────────────────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Vitamin (Sebutkan jenis)',
      code: 'NI-5.9.1',
      label: 'Asupan vitamin tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Vitamin (Sebutkan jenis)',
      code: 'NI-5.9.2',
      label: 'Kelebihan asupan vitamin',
    ),

    // ── NI-5.10: Mineral ──────────────────────────────────────────
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Mineral (Sebutkan jenis)',
      code: 'NI-5.10.1',
      label: 'Asupan mineral tidak adekuat',
    ),
    TerminologyItem(
      domain: _Domain.ni,
      classCode: 'NI-5',
      category: 'Mineral (Sebutkan jenis)',
      code: 'NI-5.10.2',
      label: 'Kelebihan asupan mineral',
    ),

    // ══════════════════════════════════════════════════════════════
    // DOMAIN NC — KLINIS
    // ══════════════════════════════════════════════════════════════

    // ── NC-1: Fungsional ──────────────────────────────────────────
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-1',
      category: 'Fungsional',
      code: 'NC-1.1',
      label: 'Kesulitan menelan (Disfagia)',
    ),
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-1',
      category: 'Fungsional',
      code: 'NC-1.2',
      label: 'Kesulitan mengunyah/menggigit',
    ),
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-1',
      category: 'Fungsional',
      code: 'NC-1.3',
      label: 'Kesulitan menyusui',
    ),
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-1',
      category: 'Fungsional (Mual/Muntah/Diare)',
      code: 'NC-1.4',
      label: 'Perubahan fungsi gastrointestinal',
    ),

    // ── NC-2: Biokimia ────────────────────────────────────────────
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-2',
      category: 'Biokimia',
      code: 'NC-2.1',
      label: 'Utilisasi zat gizi terganggu',
    ),
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-2',
      category: 'Biokimia (Gula/Kolesterol/Ginjal)',
      code: 'NC-2.2',
      label: 'Perubahan nilai lab terkait gizi',
    ),
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-2',
      category: 'Biokimia',
      code: 'NC-2.3',
      label: 'Interaksi makanan dan obat',
    ),
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-2',
      category: 'Biokimia',
      code: 'NC-2.4',
      label: 'Prediksi interaksi makanan dan obat',
    ),

    // ── NC-3: Berat Badan ─────────────────────────────────────────
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-3',
      category: 'Berat Badan',
      code: 'NC-3.1',
      label: 'Berat badan kurang (Underweight)',
    ),
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-3',
      category: 'Berat Badan',
      code: 'NC-3.2',
      label: 'Penurunan berat badan yang tidak direncanakan',
    ),
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-3',
      category: 'Berat Badan',
      code: 'NC-3.3',
      label: 'Kelebihan berat badan/Obesitas',
    ),
    TerminologyItem(
      domain: _Domain.nc,
      classCode: 'NC-3',
      category: 'Berat Badan',
      code: 'NC-3.4',
      label: 'Kenaikan berat badan yang tidak direncanakan',
    ),

    // ══════════════════════════════════════════════════════════════
    // DOMAIN NB — PERILAKU DAN LINGKUNGAN
    // ══════════════════════════════════════════════════════════════

    // ── NB-1: Pengetahuan dan Kepercayaan ─────────────────────────
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-1',
      category: 'Pengetahuan',
      code: 'NB-1.1',
      label: 'Kurang pengetahuan terkait makanan/gizi',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-1',
      category: 'Kepercayaan',
      code: 'NB-1.2',
      label: 'Perilaku/kepercayaan yang salah terkait gizi',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-1',
      category: 'Motivasi',
      code: 'NB-1.3',
      label: 'Tidak siap untuk diet/merubah gaya hidup',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-1',
      category: 'Monitoring',
      code: 'NB-1.4',
      label: 'Kurang dapat memonitor diri sendiri',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-1',
      category: 'Pola Makan',
      code: 'NB-1.5',
      label: 'Gangguan pola makan',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-1',
      category: 'Kepatuhan',
      code: 'NB-1.6',
      label: 'Kepatuhan gizi terbatas',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-1',
      category: 'Pengetahuan',
      code: 'NB-1.7',
      label: 'Pemilihan makanan yang salah',
    ),

    // ── NB-2: Aktivitas Fisik dan Fungsi Fisik ────────────────────
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-2',
      category: 'Aktivitas',
      code: 'NB-2.1',
      label: 'Aktivitas fisik kurang',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-2',
      category: 'Aktivitas',
      code: 'NB-2.2',
      label: 'Aktivitas fisik berlebihan',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-2',
      category: 'Fungsi Fisik',
      code: 'NB-2.3',
      label: 'Tidak mampu mengurus diri sendiri',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-2',
      category: 'Fungsi Fisik',
      code: 'NB-2.4',
      label: 'Kemampuan menyiapkan makanan terganggu',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-2',
      category: 'Fungsi Fisik',
      code: 'NB-2.5',
      label: 'Kualitas hidup gizi buruk',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-2',
      category: 'Fungsi Fisik',
      code: 'NB-2.6',
      label: 'Kesulitan makan secara mandiri',
    ),

    // ── NB-3: Keamanan dan Akses Makanan ──────────────────────────
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-3',
      category: 'Lingkungan',
      code: 'NB-3.1',
      label: 'Konsumsi makanan tidak aman',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-3',
      category: 'Lingkungan',
      code: 'NB-3.2',
      label: 'Akses makanan terbatas (Food Insecurity)',
    ),
    TerminologyItem(
      domain: _Domain.nb,
      classCode: 'NB-3',
      category: 'Lingkungan',
      code: 'NB-3.3',
      label: 'Akses suplai gizi/air terbatas',
    ),
  ];
}