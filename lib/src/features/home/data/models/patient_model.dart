// lib/src/features/home/data/models/patient_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Patient {
  final String id;
  final String noRM;
  final String namaLengkap;
  final DateTime tanggalLahir;
  final String diagnosisMedis;
  final num beratBadan;
  final num tinggiBadan;
  final String jenisKelamin; // Tambahkan ini
  final String aktivitas; // Tambahkan ini
  final num imt;
  final int skorIMT;
  final int skorKehilanganBB;
  final int skorEfekPenyakit;
  final int totalSkor;
  final DateTime tanggalPemeriksaan;

  Patient({
    required this.id,
    required this.noRM,
    required this.namaLengkap,
    required this.tanggalLahir,
    required this.diagnosisMedis,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.jenisKelamin, // Tambahkan ini
    required this.aktivitas, // Tambahkan ini
    required this.imt,
    required this.skorIMT,
    required this.skorKehilanganBB,
    required this.skorEfekPenyakit,
    required this.totalSkor,
    required this.tanggalPemeriksaan,
  });

  factory Patient.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Patient(
      id: doc.id,
      noRM: data['noRM'] ?? '',
      namaLengkap: data['namaLengkap'] ?? '',
      tanggalLahir: (data['tanggalLahir'] as Timestamp).toDate(),
      diagnosisMedis: data['diagnosisMedis'] ?? '',
      beratBadan: data['beratBadan'] ?? 0,
      tinggiBadan: data['tinggiBadan'] ?? 0,
      jenisKelamin: data['jenisKelamin'] ?? 'Perempuan', // Tambahkan ini
      aktivitas: data['aktivitas'] ?? 'Bed rest', // Tambahkan ini
      imt: data['imt'] ?? 0,
      skorIMT: data['skorIMT'] ?? 0,
      skorKehilanganBB: data['skorKehilanganBB'] ?? 0,
      skorEfekPenyakit: data['skorEfekPenyakit'] ?? 0,
      totalSkor: data['totalSkor'] ?? 0,
      tanggalPemeriksaan: (data['tanggalPemeriksaan'] as Timestamp).toDate(),
    );
  }

  // --- GETTER UNTUK KALKULASI ---

  int get usia {
    return DateTime.now().difference(tanggalLahir).inDays ~/ 365;
  }

  // 1. Berat Badan Ideal (BBI)
  double get bbi {
    if (jenisKelamin == 'Laki-laki') {
      return (tinggiBadan - 100) - ((tinggiBadan - 100) * 0.10);
    } else {
      return (tinggiBadan - 100) - ((tinggiBadan - 100) * 0.15);
    }
  }

  // 2. Basal Metabolic Rate (BMR) - Harris Benedict
  double get bmr {
    if (jenisKelamin == 'Laki-laki') {
      return 66.47 + (13.75 * beratBadan) + (5.003 * tinggiBadan) - (6.755 * usia);
    } else {
      return 655.1 + (9.563 * beratBadan) + (1.850 * tinggiBadan) - (4.676 * usia);
    }
  }

  // 3. Total Daily Energy Expenditure (TDEE)
  double get tdee {
    double activityFactor = 1.2; // Default (Sangat Jarang)
    switch (aktivitas) {
      case 'Bed rest':
        activityFactor = 1.2;
        break;
      case 'Ringan':
        activityFactor = 1.375;
        break;
      case 'Sedang':
        activityFactor = 1.55;
        break;
      case 'Berat':
        activityFactor = 1.725;
        break;
    }
    return bmr * activityFactor;
  }
  
  String get interpretasi {
    if (totalSkor == 0) return 'Resiko rendah';
    if (totalSkor == 1) return 'Resiko menengah';
    if (totalSkor >= 2 && totalSkor <= 3) return 'Resiko tinggi';
    if (totalSkor >= 4) return 'Resiko sangat tinggi';
    return 'Tidak diketahui';
  }
  
  String get tanggalLahirFormatted => DateFormat('d MMMM y').format(tanggalLahir);
}