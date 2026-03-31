// lib\src\features\patient_home\data\models\patient_anak_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/schofield_calculator_service.dart';

class PatientAnak {
  final String id;
  final String noRM;
  final String namaLengkap;
  final DateTime tanggalLahir;
  final String jenisKelamin;
  final num beratBadan;
  final num tinggiBadan; 
  final DateTime tanggalPemeriksaan;
  final String createdBy;
  final String tipePasien; // Wajib: 'anak'
  final String diagnosisMedis;

  // --- Bidang Spesifik Anak ---
  final String? statusGiziBBU;
  final String? statusGiziTBU;
  final double? zScoreBBU;
  final double? zScoreTBU;
  final double? zScoreBBTB;
  final double? zScoreIMTU;
  final String? statusGiziBBTB;
  final String? statusGiziIMTU;
  
  // --- Antropometri Tambahan ---
  final double? lila; // Lingkar Lengan Atas
  final double? lingkarKepala; // LK
  final double? bbi; // Berat Badan Ideal
  final String? faktorAktivitas;
  final String? faktorStres;

  // --- Skrining Risiko ---
  final String? namaNutrisionis;
  final int? kehilanganBeratBadan;
  final int? kehilanganNafsuMakan;
  final int? anakSakitBerat;

  // --- Asuhan Gizi (Baru ditambahkan) ---
  // 1. Biokimia
  final Map<String, String> labResults;

  // 2. Klinik/Fisik
  final String? klinikTD;
  final String? klinikNadi;
  final String? klinikSuhu;
  final String? klinikRR;
  final String? klinikSPO2;
  final String? klinikKU;
  final String? klinikKES;

  // 3. Riwayat Personal
  final String? riwayatPenyakitSekarang;
  final String? riwayatPenyakitDahulu;
  final String? alergiMakanan; // Tambahan umum
  final String? polaMakan;     // Tambahan umum

  // 4. Diagnosa Gizi
  final String? diagnosaGizi;

  // 5. Intervensi Gizi
  final String? intervensiDiet; // Jenis Diet
  final String? intervensiBentukMakanan; // BM
  final String? intervensiVia;
  final String? intervensiTujuan;

  // 6. Monev
  final String? monevAsupan;
  final String? monevHasilLab;
  final bool isCompleted;
  final String? monevIndikator;

  PatientAnak({
    required this.id,
    required this.noRM,
    required this.namaLengkap,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.tanggalPemeriksaan,
    required this.createdBy,
    required this.diagnosisMedis,
    this.tipePasien = 'anak', // Default
    this.statusGiziBBU,
    this.statusGiziTBU,
    this.zScoreBBU,
    this.zScoreTBU,
    this.namaNutrisionis,
    this.kehilanganBeratBadan,
    this.kehilanganNafsuMakan,
    this.anakSakitBerat,
    this.zScoreBBTB,
    this.zScoreIMTU,
    this.statusGiziBBTB,
    this.statusGiziIMTU,
    this.lila,
    this.lingkarKepala,
    this.bbi,
    this.faktorAktivitas,
  this.faktorStres,
    this.labResults = const {},
    this.klinikTD,
    this.klinikNadi,
    this.klinikSuhu,
    this.klinikRR,
    this.klinikSPO2,
    this.klinikKU,
    this.klinikKES,
    this.riwayatPenyakitSekarang,
    this.riwayatPenyakitDahulu,
    this.alergiMakanan,
    this.polaMakan,
    this.diagnosaGizi,
    this.intervensiDiet,
    this.intervensiBentukMakanan,
    this.intervensiVia,
    this.intervensiTujuan,
    this.monevAsupan,
    this.monevHasilLab,
    this.isCompleted = false,
    this.monevIndikator,
  });

  factory PatientAnak.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;

    // --- FUNGSI BANTUAN (HELPER) ---
    // Fungsi ini mendeteksi apakah data di database berupa String atau Int,
    // lalu mengonversinya menjadi Int dengan aman.
    int? parseScore(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val; // Jika sudah angka, kembalikan
      if (val is String) {
        // Coba ubah "2" jadi 2
        final parsed = int.tryParse(val);
        if (parsed != null) return parsed;

        // JIKA DATA LAMA ("Ya", "Tidak", dll) -> Mapping manual ke Skor
        final v = val.toLowerCase();
        if (v == 'ya') return 2;
        if (v == 'tidak') return 0;
        
        // Mapping Nafsu Makan
        if (v.contains('biasa')) return 0;
        if (v.contains('penurunan')) return 1;
        if (v.contains('tidak makan') || v.contains('sedikit')) return 2;
      }
      return 0; // Default jika tidak dikenali
    }

    Map<String, String> parsedLabs = {};
    if (data['labResults'] != null) {
      parsedLabs = Map<String, String>.from(data['labResults']);
    }

    return PatientAnak(
      id: doc.id,
      noRM: data['noRM'] ?? '',
      namaLengkap: data['namaLengkap'] ?? '',
      tanggalLahir: (data['tanggalLahir'] as Timestamp).toDate(),
      jenisKelamin: data['jenisKelamin'] ?? 'Laki-laki',
      beratBadan: data['beratBadan'] ?? 0,
      tinggiBadan: data['tinggiBadan'] ?? 0,
      tanggalPemeriksaan: (data['tanggalPemeriksaan'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      tipePasien: data['tipePasien'] ?? 'anak',
      diagnosisMedis: data['diagnosisMedis'] ?? '',

      // Data anak
      statusGiziBBU: (data['statusGiziBBU'] as String?) ?? (data['statusGiziAnak'] as String?),
      // Field baru
      statusGiziTBU: data['statusGiziTBU'] as String?,
      // Mengambil 'zScoreBBU', jika null coba ambil 'zScoreBB'
      zScoreBBU: (data['zScoreBBU'] ?? data['zScoreBB'])?.toDouble(),
      // Mengambil 'zScoreTBU', jika null coba ambil 'zScoreTB'
      zScoreTBU: (data['zScoreTBU'] ?? data['zScoreTB'])?.toDouble(),
      namaNutrisionis: data['namaNutrisionis'] as String?,
      kehilanganBeratBadan: parseScore(data['kehilanganBeratBadan']),
      kehilanganNafsuMakan: parseScore(data['kehilanganNafsuMakan']),
      anakSakitBerat: parseScore(data['anakSakitBerat']),
      zScoreBBTB: data['zScoreBBTB'] as double?,
      zScoreIMTU: data['zScoreIMTU'] as double?,
      statusGiziBBTB: data['statusGiziBBTB'] as String?,
      statusGiziIMTU: data['statusGiziIMTU'] as String?,
      lila: (data['lila'] as num?)?.toDouble(),
      lingkarKepala: (data['lingkarKepala'] as num?)?.toDouble(),
      bbi: (data['bbi'] as num?)?.toDouble(),
      faktorAktivitas: data['faktorAktivitas'] as String?,
  faktorStres: data['faktorStres'] as String?,
      
      labResults: parsedLabs,
      
      klinikTD: data['klinikTD'] as String?,
      klinikNadi: data['klinikNadi'] as String?,
      klinikSuhu: data['klinikSuhu'] as String?,
      klinikRR: data['klinikRR'] as String?,
      klinikSPO2: data['klinikSPO2'] as String?,
      klinikKU: data['klinikKU'] as String?,
      klinikKES: data['klinikKES'] as String?,
      
      riwayatPenyakitSekarang: data['riwayatPenyakitSekarang'] as String?,
      riwayatPenyakitDahulu: data['riwayatPenyakitDahulu'] as String?,
      alergiMakanan: data['alergiMakanan'] as String?,
      polaMakan: data['polaMakan'] as String?,
      
      diagnosaGizi: data['diagnosaGizi'] as String?,
      
      intervensiDiet: data['intervensiDiet'] as String?,
      intervensiBentukMakanan: data['intervensiBentukMakanan'] as String?,
      intervensiVia: data['intervensiVia'] as String?,
      intervensiTujuan: data['intervensiTujuan'] as String?,
      
      monevAsupan: data['monevAsupan'] as String?,
      monevHasilLab: data['monevHasilLab'] as String?,
      isCompleted: data['isCompleted'] ?? false,
      monevIndikator: data['monevIndikator'] as String?,
      
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'noRM': noRM,
      'namaLengkap': namaLengkap,
      'tanggalLahir': tanggalLahir,
      'jenisKelamin': jenisKelamin,
      'beratBadan': beratBadan,
      'tinggiBadan': tinggiBadan,
      'tanggalPemeriksaan': tanggalPemeriksaan,
      'createdBy': createdBy,
      'tipePasien': tipePasien, // Wajib ada
      
      // Data anak
      'statusGiziBBU': statusGiziBBU,
      'statusGiziTBU': statusGiziTBU, // Field baru disimpan
      'zScoreBBU': zScoreBBU,
      'zScoreTBU': zScoreTBU,
      'namaNutrisionis': namaNutrisionis,
      'diagnosisMedis': diagnosisMedis,
      'kehilanganBeratBadan': kehilanganBeratBadan,
      'kehilanganNafsuMakan': kehilanganNafsuMakan,
      'anakSakitBerat': anakSakitBerat,
      'zScoreBBTB': zScoreBBTB,
      'zScoreIMTU': zScoreIMTU,
      'statusGiziBBTB': statusGiziBBTB,
      'statusGiziIMTU': statusGiziIMTU,
      'lila': lila,
      'lingkarKepala': lingkarKepala,
      'bbi': bbi,
      'faktorAktivitas': faktorAktivitas,
  'faktorStres': faktorStres,
      'labResults': labResults,
      'klinikTD': klinikTD,
      'klinikNadi': klinikNadi,
      'klinikSuhu': klinikSuhu,
      'klinikRR': klinikRR,
      'klinikSPO2': klinikSPO2,
      'klinikKU': klinikKU,
      'klinikKES': klinikKES,
      'riwayatPenyakitSekarang': riwayatPenyakitSekarang,
      'riwayatPenyakitDahulu': riwayatPenyakitDahulu,
      'alergiMakanan': alergiMakanan,
      'polaMakan': polaMakan,
      'diagnosaGizi': diagnosaGizi,
      'intervensiDiet': intervensiDiet,
      'intervensiBentukMakanan': intervensiBentukMakanan,
      'intervensiVia': intervensiVia,
      'intervensiTujuan': intervensiTujuan,
      'monevAsupan': monevAsupan,
      'monevHasilLab': monevHasilLab,
      'isCompleted': isCompleted,
      'monevIndikator': monevIndikator,
    };
  }

  // --- GETTER ---
  int get usiaInDays {
    return DateTime.now().difference(tanggalLahir).inDays;
  }

  // ---------------------------------------------------------------------------
  // Getter usia berbasis kalender (lebih akurat dari pembagian 365 hari).
  //
  // Algoritma:
  //   - Hitung selisih tahun kalender antara hari ini dan tanggalLahir.
  //   - Koreksi mundur 1 tahun jika bulan+hari ulang tahun belum tercapai
  //     di tahun berjalan (mencegah over-count).
  //   - usiaBulan = sisa bulan setelah usiaTahun dikurangi.
  //
  // Contoh:
  //   Lahir: 15 Maret 2020, Hari ini: 10 Feb 2026
  //   → usiaTahun = 5  (ulang tahun ke-6 belum tiba)
  //   → usiaBulan = 10
  //   → totalBulan = 70  → _isAnak5Tahunkeatas = true ✓
  // ---------------------------------------------------------------------------

  /// Komponen tahun usia (kalender).
  int get usiaTahun {
    final now = DateTime.now();
    int years = now.year - tanggalLahir.year;
    // Mundurkan 1 jika bulan/hari ulang tahun belum lewat tahun ini.
    if (now.month < tanggalLahir.month ||
        (now.month == tanggalLahir.month && now.day < tanggalLahir.day)) {
      years -= 1;
    }
    return years.clamp(0, 999);
  }

  /// Komponen bulan sisa setelah dikurangi [usiaTahun] (0–11).
  int get usiaBulan {
    final now = DateTime.now();
    int months = now.month - tanggalLahir.month;
    if (now.day < tanggalLahir.day) {
      months -= 1; // Hari ulang bulan belum tercapai
    }
    return ((months % 12) + 12) % 12; // Selalu positif, rentang 0–11
  }

  String get usiaFormatted {
    if (usiaTahun > 0) {
      return '$usiaTahun tahun $usiaBulan bulan';
    } else {
      return '$usiaBulan bulan';
    }
  }

  String get tanggalLahirFormatted => DateFormat('d MMMM y','id_ID').format(tanggalLahir);

  // 1. Skor Antropometri (Contoh logika sederhana berdasarkan Z-Score)
  int get skorAntropometri {
    // Jika Z-Score BB atau TB sangat rendah, skor naik (Contoh logika PYMS)
    // Sesuaikan ambang batas ini dengan standar RS Anda
    if ((zScoreBBU ?? 0) < -2 || (zScoreTBU ?? 0) < -2) {
      return 2; // Beresiko
    }
    return 0;
  }

  // 2. Total Skor PYMS
  int get totalPymsScore {
    int total = 0;
    total += skorAntropometri;
    total += (kehilanganBeratBadan ?? 0);
    total += (kehilanganNafsuMakan ?? 0);
    total += (anakSakitBerat ?? 0);
    return total;
  }

  String get pymsInterpretation {
    final score = totalPymsScore;
    if (score >= 2) return "Resiko tinggi";
    if (score == 1) return "Resiko rendah";
    return "Tanpa resiko";
  }

  Map<String, double> hitungKebutuhanGizi() {
    // 1. Tentukan Berat Badan (Prioritas: BBI -> Berat Aktual)
    double weightToUse = (bbi != null && bbi! > 0) ? bbi! : beratBadan.toDouble();
    double heightCm = tinggiBadan.toDouble();
    double ageInYearsFraction = usiaInDays / 365.25;
    bool isMale = jenisKelamin.toLowerCase().contains('laki');

    // 2. Hitung BMR Schofield
    double bmr = 0.0;
    try {
      bmr = SchofieldCalculatorService.calculateWithWeightAndHeight(
        weightKg: beratBadan.toDouble(), // BMR biasanya menggunakan BB aktual
        heightCm: heightCm,
        ageInYears: ageInYearsFraction,
        isMale: isMale,
      );
    } catch (e) {
      bmr = 0.0; // Fallback jika usia di luar range
    }

    // 3. Hitung TDEE
    double fa = SchofieldCalculatorService.activityFactors[faktorAktivitas ?? 'Tanpa Faktor Aktivitas'] ?? 1.0;
    double fs = SchofieldCalculatorService.stressFactors[faktorStres ?? 'Tanpa Faktor Stres'] ?? 1.0;
    double tdee = bmr * fa * fs;

    // 4. Hitung Makronutrien
    double proteinPerKg = 0;
    if (ageInYearsFraction < 0.5) {
      proteinPerKg = 2.2;
    } else if (ageInYearsFraction < 1) {
      proteinPerKg = 1.5;
    } else if (ageInYearsFraction <= 3) {
      proteinPerKg = 1.23;
    } else if (ageInYearsFraction <= 6) {
      proteinPerKg = 1.2;
    } else if (ageInYearsFraction <= 10) {
      proteinPerKg = 1.0;
    } else {
      if (ageInYearsFraction <= 14) {
        proteinPerKg = 1.0;
      } else {
        proteinPerKg = 0.8;
      }
    }

    double totalProtein = proteinPerKg * weightToUse;
    double totalLemak = (0.35 * tdee) / 9; // 35% dari TDEE
    double totalKarbo = (tdee - (totalProtein * 4) - (totalLemak * 9)) / 4;
    if (totalKarbo < 0) totalKarbo = 0;

    // 5. Hitung Cairan (Rumus Standar Holliday-Segar)
    double totalCairan = 0;
    if (weightToUse <= 10) {
      totalCairan = 100 * weightToUse;
    } else if (weightToUse <= 20) {
      totalCairan = 1000 + 50;
    } else {
      totalCairan = 1500 + 20;
    }

    return {
      'bmr': bmr,
      'tdee': tdee,
      'protein': totalProtein,
      'lemak': totalLemak,
      'karbo': totalKarbo,
      'cairan': totalCairan,
    };
  }
}