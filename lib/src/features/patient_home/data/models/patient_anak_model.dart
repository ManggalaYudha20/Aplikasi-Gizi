// lib\src\features\patient_home\data\models\patient_anak_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  // --- Bidang Spesifik Anak (Contoh) ---
  final String? statusGiziAnak; // Misal: "Gizi Baik (Normal)"
  final double? zScoreBB;
  final double? zScoreTB;
  final double? zScoreBBTB;
  final double? zScoreIMTU;
  final String? statusGiziBBTB; // Status berdasarkan BB/TB (biasanya indikator utama status gizi akut)
  final String? statusGiziIMTU;
  final String? namaNutrisionis;
  final int? kehilanganBeratBadan;
  final int? kehilanganNafsuMakan;
  final int? anakSakitBerat;

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
    this.statusGiziAnak,
    this.zScoreBB,
    this.zScoreTB,
    this.namaNutrisionis,
    this.kehilanganBeratBadan,
    this.kehilanganNafsuMakan,
    this.anakSakitBerat,
    this.zScoreBBTB,
    this.zScoreIMTU,
    this.statusGiziBBTB,
    this.statusGiziIMTU,
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
      statusGiziAnak: data['statusGiziAnak'] as String?,
      zScoreBB: data['zScoreBB'] as double?,
      zScoreTB: data['zScoreTB'] as double?,
      namaNutrisionis: data['namaNutrisionis'] as String?,
      kehilanganBeratBadan: parseScore(data['kehilanganBeratBadan']),
      kehilanganNafsuMakan: parseScore(data['kehilanganNafsuMakan']),
      anakSakitBerat: parseScore(data['anakSakitBerat']),
      zScoreBBTB: data['zScoreBBTB'] as double?,
      zScoreIMTU: data['zScoreIMTU'] as double?,
      statusGiziBBTB: data['statusGiziBBTB'] as String?,
      statusGiziIMTU: data['statusGiziIMTU'] as String?,
      
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
      'statusGiziAnak': statusGiziAnak,
      'zScoreBB': zScoreBB,
      'zScoreTB': zScoreTB,
      'namaNutrisionis': namaNutrisionis,
      'diagnosisMedis': diagnosisMedis,
      'kehilanganBeratBadan': kehilanganBeratBadan,
      'kehilanganNafsuMakan': kehilanganNafsuMakan,
      'anakSakitBerat': anakSakitBerat,
      'zScoreBBTB': zScoreBBTB,
      'zScoreIMTU': zScoreIMTU,
      'statusGiziBBTB': statusGiziBBTB,
      'statusGiziIMTU': statusGiziIMTU,
    };
  }

  // --- GETTER ---
  int get usiaInDays {
    return DateTime.now().difference(tanggalLahir).inDays;
  }
  
  String get usiaFormatted {
    final days = usiaInDays;
    final years = days ~/ 365;
    final months = (days % 365) ~/ 30;
    
    if (years > 0) {
      return '$years tahun $months bulan';
    } else {
      return '$months bulan';
    }
  }

  String get tanggalLahirFormatted => DateFormat('d MMMM y','id_ID').format(tanggalLahir);

  // 1. Skor Antropometri (Contoh logika sederhana berdasarkan Z-Score)
  int get skorAntropometri {
    // Jika Z-Score BB atau TB sangat rendah, skor naik (Contoh logika PYMS)
    // Sesuaikan ambang batas ini dengan standar RS Anda
    if ((zScoreBB ?? 0) < -2 || (zScoreTB ?? 0) < -2) {
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
}