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
  final num? lila;
  final num? tl;
  final num? beratBadanDulu;
  final String? kehilanganNafsuMakan;
  final String? alergiMakanan;
  final String? detailAlergi;
  final String? polaMakan;
  final String? biokimiaGDS;
  final String? biokimiaUreum;
  final String? biokimiaHGB;
  final String? klinikTD;
  final String? klinikNadi;
  final String? klinikSuhu;
  final String? klinikRR;
  final String? riwayatPenyakitSekarang;
  final String? riwayatPenyakitDahulu;
  final String? diagnosaGizi;
  final String? intervensiDiet;
  final String? intervensiBentukMakanan;
  final String? intervensiVia;
  final String? intervensiTujuan;
  final String? monevAsupan;
  final String? monevStatusGizi;
  final String? biokimiaENT;
  final String? klinikKU;
  final String? klinikKES;
  final String? klinikSPO2;
  final String? namaNutrisionis;
  final String createdBy;
  final String? monevHasilLab;
  final bool isCompleted;
  final bool? sukaManis;
  final bool? sukaAsin;
  final bool? makanBerlemak;
  final bool? jarangOlahraga;

  Patient({
    required this.id,
    required this.noRM,
    required this.namaLengkap,
    required this.tanggalLahir,
    required this.diagnosisMedis,
    required this.beratBadan,
    required this.tinggiBadan,
    required this.jenisKelamin, 
    required this.aktivitas, 
    required this.imt,
    required this.skorIMT,
    required this.skorKehilanganBB,
    required this.skorEfekPenyakit,
    required this.totalSkor,
    required this.tanggalPemeriksaan,
    this.lila, 
    this.tl,
    this.beratBadanDulu,
    this.kehilanganNafsuMakan,
    this.alergiMakanan,
    this.detailAlergi,
    this.polaMakan,
    this.biokimiaGDS,
    this.biokimiaUreum,
    this.biokimiaHGB,
    this.klinikTD,
    this.klinikNadi,
    this.klinikSuhu,
    this.klinikRR,
    this.riwayatPenyakitSekarang,
    this.riwayatPenyakitDahulu,
    this.diagnosaGizi,
    this.intervensiDiet,
    this.intervensiBentukMakanan,
    this.intervensiVia,
    this.intervensiTujuan,
    this.monevAsupan,
    this.monevStatusGizi,
    this.monevHasilLab,
    this.biokimiaENT,
    this.klinikKU,
    this.klinikKES,
    this.klinikSPO2,
    this.namaNutrisionis,
    required this.createdBy,
    this.isCompleted = false,
    this.sukaManis,
    this.sukaAsin,
    this.makanBerlemak,
    this.jarangOlahraga,
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
      jenisKelamin: data['jenisKelamin'] ?? 'Laki-laki', // Tambahkan ini
      aktivitas: data['aktivitas'] ?? 'Sangat Jarang', // Tambahkan ini
      imt: data['imt'] ?? 0,
      skorIMT: data['skorIMT'] ?? 0,
      skorKehilanganBB: data['skorKehilanganBB'] ?? 0,
      skorEfekPenyakit: data['skorEfekPenyakit'] ?? 0,
      totalSkor: data['totalSkor'] ?? 0,
      tanggalPemeriksaan: (data['tanggalPemeriksaan'] as Timestamp).toDate(),
      lila: data['lila'] as num?,
      tl: data['tl'] as num?,
      beratBadanDulu: data['beratBadanDulu'] as num?,
      kehilanganNafsuMakan: data['kehilanganNafsuMakan'] as String?,
      // BARU: Ambil data asuhan gizi
      alergiMakanan: data['alergiMakanan'] as String?,
      detailAlergi: data['detailAlergi'] as String?,
      polaMakan: data['polaMakan'] as String?,
      biokimiaGDS: data['biokimiaGDS'] as String?,
      biokimiaUreum: data['biokimiaUreum'] as String?,
      biokimiaHGB: data['biokimiaHGB'] as String?,
      klinikTD: data['klinikTD'] as String?,
      klinikNadi: data['klinikNadi'] as String?,
      klinikSuhu: data['klinikSuhu'] as String?,
      klinikRR: data['klinikRR'] as String?,
      riwayatPenyakitSekarang: data['riwayatPenyakitSekarang'] as String?,
      riwayatPenyakitDahulu: data['riwayatPenyakitDahulu'] as String?,
      diagnosaGizi: data['diagnosaGizi'] as String?,
      intervensiDiet: data['intervensiDiet'] as String?,
      intervensiBentukMakanan: data['intervensiBentukMakanan'] as String?,
      intervensiVia: data['intervensiVia'] as String?,
      intervensiTujuan: data['intervensiTujuan'] as String?,
      monevAsupan: data['monevAsupan'] as String?,
      monevStatusGizi: data['monevStatusGizi'] as String?,
      monevHasilLab: data['monevHasilLab'] as String?,
      biokimiaENT: data['biokimiaENT'] as String?,
      klinikKU: data['klinikKU'] as String?,
      klinikKES: data['klinikKES'] as String?,
      klinikSPO2: data['klinikSPO2'] as String?,
      namaNutrisionis: data['namaNutrisionis'] as String?,
      createdBy: data['createdBy'] ?? '',
      isCompleted: data['isCompleted'] ?? false,

      sukaManis: data['sukaManis'] as bool? ?? false,
      sukaAsin: data['sukaAsin'] as bool? ?? false,
      makanBerlemak: data['makanBerlemak'] as bool? ?? false,
      jarangOlahraga: data['jarangOlahraga'] as bool? ?? false,
    );
  }

   Map<String, dynamic> toMap() {
    return {
      'noRM': noRM,
      'namaLengkap': namaLengkap,
      'tanggalLahir': tanggalLahir,
      'diagnosisMedis': diagnosisMedis,
      'beratBadan': beratBadan,
      'tinggiBadan': tinggiBadan,
      'jenisKelamin': jenisKelamin,
      'aktivitas': aktivitas,
      'imt': imt,
      'skorIMT': skorIMT,
      'skorKehilanganBB': skorKehilanganBB,
      'skorEfekPenyakit': skorEfekPenyakit,
      'totalSkor': totalSkor,
      'tanggalPemeriksaan': tanggalPemeriksaan,
      'lila': lila,
      'tl': tl,
      'beratBadanDulu': beratBadanDulu,
      'kehilanganNafsuMakan': kehilanganNafsuMakan,
      'alergiMakanan': alergiMakanan,
      'detailAlergi': detailAlergi,
      'polaMakan': polaMakan,
      'biokimiaGDS': biokimiaGDS,
      'biokimiaUreum': biokimiaUreum,
      'biokimiaHGB': biokimiaHGB,
      'klinikTD': klinikTD,
      'klinikNadi': klinikNadi,
      'klinikSuhu': klinikSuhu,
      'klinikRR': klinikRR,
      'riwayatPenyakitSekarang': riwayatPenyakitSekarang,
      'riwayatPenyakitDahulu': riwayatPenyakitDahulu,
      'diagnosaGizi': diagnosaGizi,
      'intervensiDiet': intervensiDiet,
      'intervensiBentukMakanan': intervensiBentukMakanan,
      'intervensiVia': intervensiVia,
      'intervensiTujuan': intervensiTujuan,
      'monevAsupan': monevAsupan,
      'monevStatusGizi': monevStatusGizi,
      'monevHasilLab' : monevHasilLab,
      'biokimiaENT': biokimiaENT,
      'klinikKU': klinikKU,
      'klinikKES': klinikKES,
      'klinikSPO2': klinikSPO2,
      'namaNutrisionis': namaNutrisionis,
      'createdBy': createdBy,
      'isCompleted': isCompleted,

      'sukaManis': sukaManis ?? false,
      'sukaAsin': sukaAsin ?? false,
      'makanBerlemak': makanBerlemak ?? false,
      'jarangOlahraga': jarangOlahraga ?? false,
    };
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
      case 'Sangat Jarang':
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
      case 'Sangat Aktif':
        activityFactor = 1.9;
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
  // BARU: Getter untuk status gizi berdasarkan IMT
  String get statusGizi {
    if (imt < 18.5) {
      return 'Gizi Kurang (Underweight)';
    } else if (imt >= 18.5 && imt <= 24.9) {
      return 'Gizi Baik (Normal)';
    } else if (imt >= 25 && imt <= 29.9) {
      return 'Gizi Lebih (Overweight)';
    } else {
      return 'Obesitas';
    }
  }
  
  String get tanggalLahirFormatted => DateFormat('d MMMM y','id_ID').format(tanggalLahir);
}