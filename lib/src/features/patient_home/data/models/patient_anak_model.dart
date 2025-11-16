// lib\src\features\patient_home\data\models\patient_anak_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PatientAnak {
  final String id;
  final String noRM;
  final String namaLengkap;
  final DateTime tanggalLahir;
  final String jenisKelamin;
  final num beratBadan; // kg
  final num tinggiBadan; // cm
  final num? lila; // cm
  final DateTime tanggalPemeriksaan;
  final String createdBy;
  final String tipePasien; // Wajib: 'anak'

  // --- Bidang Spesifik Anak (Contoh) ---
  final String? statusGiziAnak; // Misal: "Gizi Baik (Normal)"
  final double? zScoreBB;
  final double? zScoreTB;
  final String? namaNutrisionis;

  PatientAnak({
    required this.id,
    required this.noRM,
    required this.namaLengkap,
    required this.tanggalLahir,
    required this.jenisKelamin,
    required this.beratBadan,
    required this.tinggiBadan,
    this.lila,
    required this.tanggalPemeriksaan,
    required this.createdBy,
    this.tipePasien = 'anak', // Default
    this.statusGiziAnak,
    this.zScoreBB,
    this.zScoreTB,
    this.namaNutrisionis,
  });

  factory PatientAnak.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PatientAnak(
      id: doc.id,
      noRM: data['noRM'] ?? '',
      namaLengkap: data['namaLengkap'] ?? '',
      tanggalLahir: (data['tanggalLahir'] as Timestamp).toDate(),
      jenisKelamin: data['jenisKelamin'] ?? 'Laki-laki',
      beratBadan: data['beratBadan'] ?? 0,
      tinggiBadan: data['tinggiBadan'] ?? 0,
      lila: data['lila'] as num?,
      tanggalPemeriksaan: (data['tanggalPemeriksaan'] as Timestamp).toDate(),
      createdBy: data['createdBy'] ?? '',
      tipePasien: data['tipePasien'] ?? 'anak',

      // Data anak
      statusGiziAnak: data['statusGiziAnak'] as String?,
      zScoreBB: data['zScoreBB'] as double?,
      zScoreTB: data['zScoreTB'] as double?,
      namaNutrisionis: data['namaNutrisionis'] as String?,
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
      'lila': lila,
      'tanggalPemeriksaan': tanggalPemeriksaan,
      'createdBy': createdBy,
      'tipePasien': tipePasien, // Wajib ada
      
      // Data anak
      'statusGiziAnak': statusGiziAnak,
      'zScoreBB': zScoreBB,
      'zScoreTB': zScoreTB,
      'namaNutrisionis': namaNutrisionis,
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
}