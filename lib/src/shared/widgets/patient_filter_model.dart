// lib/src/shared/widgets/patient_filter_model.dart
import 'package:flutter/material.dart';
// HAPUS: import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
// TAMBAHKAN:
import 'package:cloud_firestore/cloud_firestore.dart';

class PatientFilterModel {
  final String? statusGizi;
  final DateTimeRange? dateRange;
  final String? ageGroup;
  final bool? isCompleted;

  // Opsi grup usia
  static const String ageAnak = 'Anak (0-18 th)';
  static const String ageDewasa = 'Dewasa (19-64 th)';
  static const String ageLansia = 'Lansia (65+ th)';

  PatientFilterModel({
    this.statusGizi,
    this.dateRange,
    this.ageGroup,
    this.isCompleted,
  });

  /// Cek apakah ada filter yang aktif
  bool get isDefault {
    return statusGizi == null && dateRange == null && ageGroup == null && isCompleted == null;
  }

  /// Fungsi utama untuk memfilter
  // --- PERUBAHAN UTAMA DI SINI ---
  bool matches(Map<String, dynamic> data) {
    // Ambil tipe pasien
    final String tipePasien = data['tipePasien'] ?? 'dewasa';

    if (isCompleted != null) {
      // Ambil status dari database, default false jika tidak ada
      final bool statusData = data['isCompleted'] ?? false; 
      
      // Jika status di data beda dengan filter yang diinginkan, return false
      if (statusData != isCompleted) return false;
    }

    // --- Filter 1: Status Gizi (Kondisional) ---
    bool matchesStatusGizi = true; 
    if (statusGizi != null) {
      // 1. Ubah Filter ke Huruf Kecil (Lowercase)
      //    Contoh: "Gizi Baik (Normal)" -> "gizi baik (normal)"
      final String filterLower = statusGizi!.toLowerCase();

      // 2. Tentukan kata kunci sederhana (Opsional, agar pencarian lebih fleksibel)
      //    Ini membantu jika di DB tertulis "Gizi Baik" tapi filternya "Gizi Baik (Normal)"
      String keyword = filterLower;
      if (filterLower.contains('kurang')) {
        keyword = 'kurang';
      } else if (filterLower.contains('baik')) {
        keyword = 'baik';
      } else if (filterLower.contains('lebih')) {
        keyword = 'lebih';
      } else if (filterLower.contains('obesitas')) {
        keyword = 'obesitas';
      }

      if (tipePasien == 'anak') {
        // Ambil data dan ubah ke huruf kecil
        final String statusIMTU = (data['statusGiziIMTU'] ?? '').toLowerCase();
        final String statusBBU = (data['statusGiziBBU'] ?? '').toLowerCase();
        final String statusLegacy = (data['statusGiziAnak'] ?? '').toLowerCase(); // Data lama

        // Cek apakah data mengandung kata kunci (menggunakan keyword yang lebih pendek/fleksibel)
        matchesStatusGizi = statusIMTU.contains(keyword) || 
                            statusBBU.contains(keyword) ||
                            statusLegacy.contains(keyword);
                            
      } else {
        // Logika Dewasa (Juga di-lowercase)
        final String statusGiziDewasa = (data['monevStatusGizi'] ?? '').toLowerCase();
        matchesStatusGizi = statusGiziDewasa.contains(keyword);
      }
    }
    // Jika gagal filter, langsung hentikan
    if (!matchesStatusGizi) return false;

    // --- Ambil data tanggal universal ---
    final DateTime? tglPemeriksaan =
        (data['tanggalPemeriksaan'] as Timestamp?)?.toDate();
    final DateTime? tglLahir = (data['tanggalLahir'] as Timestamp?)?.toDate();

    // Jika data tanggal penting tidak ada, anggap tidak cocok
    if (tglPemeriksaan == null || tglLahir == null) return false;

    // --- Filter 2: Rentang Tanggal (Universal) ---
    bool matchesDateRange = true; // Asumsi lolos
    if (dateRange != null) {
      final rangeStart = dateRange!.start;
      final rangeEnd = dateRange!.end.add(const Duration(days: 1));
      matchesDateRange = !tglPemeriksaan.isBefore(rangeStart) &&
          tglPemeriksaan.isBefore(rangeEnd);
    }
    // Jika gagal filter, langsung hentikan
    if (!matchesDateRange) return false;

    // --- Filter 3: Grup Usia (Universal) ---
    bool matchesAgeGroup = true; // Asumsi lolos
    if (ageGroup != null) {
      DateTime today = DateTime.now();
      int age = today.year - tglLahir.year;
      if (tglLahir.month > today.month ||
          (tglLahir.month == today.month && tglLahir.day > today.day)) {
        age--;
      }

      if (ageGroup == ageAnak) {
        matchesAgeGroup = age <= 18;
      } else if (ageGroup == ageDewasa) {
        matchesAgeGroup = age > 18 && age < 65;
      } else if (ageGroup == ageLansia) {
        matchesAgeGroup = age >= 65;
      } else {
        matchesAgeGroup = false;
      }
    }
    // Jika gagal filter, langsung hentikan
    if (!matchesAgeGroup) return false;

    // Lolos semua filter
    return true;
  }
}