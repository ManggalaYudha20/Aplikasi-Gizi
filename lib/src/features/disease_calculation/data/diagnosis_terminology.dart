import 'nutrition_reference_data.dart';

// Data lengkap Diagnosa Gizi (NI, NB, NC)
class DiagnosisTerminology {
  static const List<NutritionReferenceItem> allDiagnoses = [
    // ==========================================================
    // DOMAIN ASUPAN (NI)
    // ==========================================================
    
    // --- Keseimbangan Energi ---
    NutritionReferenceItem(code: 'NI-1.1', label: 'Peningkatan energy expenditure', definition: 'Keseimbangan Energi'),
    NutritionReferenceItem(code: 'NI-1.2', label: 'Asupan energi tidak adekuat', definition: 'Keseimbangan Energi'),
    NutritionReferenceItem(code: 'NI-1.3', label: 'Kelebihan asupan energi', definition: 'Keseimbangan Energi'),
    NutritionReferenceItem(code: 'NI-1.4', label: 'Perkiraan asupan energi suboptimal', definition: 'Keseimbangan Energi'),
    NutritionReferenceItem(code: 'NI-1.5', label: 'Perkiraan kelebihan asupan energi', definition: 'Keseimbangan Energi'),

    // --- Asupan Melalui Oral atau Dukungan Gizi ---
    NutritionReferenceItem(code: 'NI-2.1', label: 'Asupan makanan/minuman oral tidak adekuat', definition: 'Asupan Oral'),
    NutritionReferenceItem(code: 'NI-2.2', label: 'Kelebihan asupan makanan/minuman oral', definition: 'Asupan Oral'),
    NutritionReferenceItem(code: 'NI-2.3', label: 'Asupan enteral/parenteral tidak adekuat', definition: 'Dukungan Gizi'),
    NutritionReferenceItem(code: 'NI-2.4', label: 'Kelebihan asupan enteral/parenteral', definition: 'Dukungan Gizi'),
    NutritionReferenceItem(code: 'NI-2.5', label: 'Komposisi/infus enteral/parenteral tidak tepat', definition: 'Dukungan Gizi'),

    // --- Asupan Cairan ---
    NutritionReferenceItem(code: 'NI-3.1', label: 'Asupan cairan tidak adekuat', definition: 'Asupan Cairan'),
    NutritionReferenceItem(code: 'NI-3.2', label: 'Kelebihan asupan cairan', definition: 'Asupan Cairan'),

    // --- Zat Bioaktif (Suplemen/Alkohol) ---
    NutritionReferenceItem(code: 'NI-4.1', label: 'Asupan substansi bioaktif tidak adekuat', definition: 'Zat Bioaktif'),
    NutritionReferenceItem(code: 'NI-4.2', label: 'Kelebihan asupan substansi bioaktif', definition: 'Zat Bioaktif'),
    NutritionReferenceItem(code: 'NI-4.3', label: 'Konsumsi alkohol berlebih', definition: 'Zat Bioaktif'),

    // --- Zat Gizi (Umum) ---
    NutritionReferenceItem(code: 'NI-5.1', label: 'Peningkatan kebutuhan zat gizi', definition: 'Zat Gizi'),
    NutritionReferenceItem(code: 'NI-5.2', label: 'Malnutrisi nyata (kurang gizi)', definition: 'Zat Gizi'),
    NutritionReferenceItem(code: 'NI-5.3', label: 'Asupan energi protein tidak adekuat', definition: 'Zat Gizi'),
    NutritionReferenceItem(code: 'NI-5.4', label: 'Penurunan kebutuhan zat gizi', definition: 'Zat Gizi'),
    NutritionReferenceItem(code: 'NI-5.5', label: 'Ketidakseimbangan zat gizi', definition: 'Zat Gizi'),

    // --- Lemak dan Kolesterol ---
    NutritionReferenceItem(code: 'NI-5.6.1', label: 'Asupan lemak tidak adekuat', definition: 'Lemak'),
    NutritionReferenceItem(code: 'NI-5.6.2', label: 'Kelebihan asupan lemak', definition: 'Lemak'),
    NutritionReferenceItem(code: 'NI-5.6.3', label: 'Asupan jenis lemak tidak sesuai', definition: 'Lemak'),

    // --- Protein ---
    NutritionReferenceItem(code: 'NI-5.7.1', label: 'Asupan protein tidak adekuat', definition: 'Protein'),
    NutritionReferenceItem(code: 'NI-5.7.2', label: 'Kelebihan asupan protein', definition: 'Protein'),
    NutritionReferenceItem(code: 'NI-5.7.3', label: 'Asupan jenis protein tidak sesuai', definition: 'Protein (HBV/LBV)'),

    // --- Karbohidrat dan Serat ---
    NutritionReferenceItem(code: 'NI-5.8.1', label: 'Asupan karbohidrat tidak adekuat', definition: 'Karbohidrat'),
    NutritionReferenceItem(code: 'NI-5.8.2', label: 'Kelebihan asupan karbohidrat', definition: 'Karbohidrat'),
    NutritionReferenceItem(code: 'NI-5.8.3', label: 'Asupan jenis karbohidrat tidak sesuai', definition: 'Karbohidrat (Gula Sederhana)'),
    NutritionReferenceItem(code: 'NI-5.8.4', label: 'Asupan karbohidrat tidak konsisten', definition: 'Karbohidrat (Jadwal)'),
    NutritionReferenceItem(code: 'NI-5.8.5', label: 'Asupan serat tidak adekuat', definition: 'Serat'),

    // --- Vitamin ---
    NutritionReferenceItem(code: 'NI-5.9.1', label: 'Asupan vitamin tidak adekuat', definition: 'Vitamin (Sebutkan jenis)'),
    NutritionReferenceItem(code: 'NI-5.9.2', label: 'Kelebihan asupan vitamin', definition: 'Vitamin (Sebutkan jenis)'),

    // --- Mineral ---
    NutritionReferenceItem(code: 'NI-5.10.1', label: 'Asupan mineral tidak adekuat', definition: 'Mineral (Sebutkan jenis)'),
    NutritionReferenceItem(code: 'NI-5.10.2', label: 'Kelebihan asupan mineral', definition: 'Mineral (Sebutkan jenis)'),
    
    // ==========================================================
    // DOMAIN KLINIS (NC)
    // ==========================================================

    // --- Fungsional ---
    NutritionReferenceItem(code: 'NC-1.1', label: 'Kesulitan menelan (Disfagia)', definition: 'Fungsional'),
    NutritionReferenceItem(code: 'NC-1.2', label: 'Kesulitan mengunyah/menggigit', definition: 'Fungsional'),
    NutritionReferenceItem(code: 'NC-1.3', label: 'Kesulitan menyusui', definition: 'Fungsional'),
    NutritionReferenceItem(code: 'NC-1.4', label: 'Perubahan fungsi gastrointestinal', definition: 'Fungsional (Mual/Muntah/Diare)'),

    // --- Biokimia ---
    NutritionReferenceItem(code: 'NC-2.1', label: 'Utilisasi zat gizi terganggu', definition: 'Biokimia'),
    NutritionReferenceItem(code: 'NC-2.2', label: 'Perubahan nilai lab terkait gizi', definition: 'Biokimia (Gula/Kolesterol/Ginjal)'),
    NutritionReferenceItem(code: 'NC-2.3', label: 'Interaksi makanan dan obat', definition: 'Biokimia'),
    NutritionReferenceItem(code: 'NC-2.4', label: 'Prediksi interaksi makanan dan obat', definition: 'Biokimia'),

    // --- Berat Badan ---
    NutritionReferenceItem(code: 'NC-3.1', label: 'Berat badan kurang (Underweight)', definition: 'Berat Badan'),
    NutritionReferenceItem(code: 'NC-3.2', label: 'Penurunan berat badan yang tidak direncanakan', definition: 'Berat Badan'),
    NutritionReferenceItem(code: 'NC-3.3', label: 'Kelebihan berat badan/Obesitas', definition: 'Berat Badan'),
    NutritionReferenceItem(code: 'NC-3.4', label: 'Kenaikan berat badan yang tidak direncanakan', definition: 'Berat Badan'),

    // ==========================================================
    // DOMAIN PERILAKU DAN LINGKUNGAN (NB)
    // ==========================================================

    // --- Pengetahuan dan Kepercayaan ---
    NutritionReferenceItem(code: 'NB-1.1', label: 'Kurang pengetahuan terkait makanan/gizi', definition: 'Pengetahuan'),
    NutritionReferenceItem(code: 'NB-1.2', label: 'Perilaku/kepercayaan yang salah terkait gizi', definition: 'Kepercayaan'),
    NutritionReferenceItem(code: 'NB-1.3', label: 'Tidak siap untuk diet/merubah gaya hidup', definition: 'Motivasi'),
    NutritionReferenceItem(code: 'NB-1.4', label: 'Kurang dapat memonitor diri sendiri', definition: 'Monitoring'),
    NutritionReferenceItem(code: 'NB-1.5', label: 'Gangguan pola makan', definition: 'Pola Makan'),
    NutritionReferenceItem(code: 'NB-1.6', label: 'Kepatuhan gizi terbatas', definition: 'Kepatuhan'),
    NutritionReferenceItem(code: 'NB-1.7', label: 'Pemilihan makanan yang salah', definition: 'Pengetahuan'),

    // --- Aktivitas Fisik dan Fungsi Fisik ---
    NutritionReferenceItem(code: 'NB-2.1', label: 'Aktivitas fisik kurang', definition: 'Aktivitas'),
    NutritionReferenceItem(code: 'NB-2.2', label: 'Aktivitas fisik berlebihan', definition: 'Aktivitas'),
    NutritionReferenceItem(code: 'NB-2.3', label: 'Tidak mampu mengurus diri sendiri', definition: 'Fungsi Fisik'),
    NutritionReferenceItem(code: 'NB-2.4', label: 'Kemampuan menyiapkan makanan terganggu', definition: 'Fungsi Fisik'),
    NutritionReferenceItem(code: 'NB-2.5', label: 'Kualitas hidup gizi buruk', definition: 'Fungsi Fisik'),
    NutritionReferenceItem(code: 'NB-2.6', label: 'Kesulitan makan secara mandiri', definition: 'Fungsi Fisik'),

    // --- Keamanan dan Akses Makanan ---
    NutritionReferenceItem(code: 'NB-3.1', label: 'Konsumsi makanan tidak aman', definition: 'Lingkungan'),
    NutritionReferenceItem(code: 'NB-3.2', label: 'Akses makanan terbatas (Food Insecurity)', definition: 'Lingkungan'),
    NutritionReferenceItem(code: 'NB-3.3', label: 'Akses suplai gizi/air terbatas', definition: 'Lingkungan'),
  ];
}