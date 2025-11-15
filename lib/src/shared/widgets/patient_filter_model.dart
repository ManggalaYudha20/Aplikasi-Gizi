// lib/src/shared/widgets/patient_filter_model.dart
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';

class PatientFilterModel {
  final String? statusGizi;
  final DateTimeRange? dateRange;
  final String? ageGroup;

  // Opsi grup usia
  static const String ageAnak = 'Anak (0-18 th)';
  static const String ageDewasa = 'Dewasa (19-64 th)';
  static const String ageLansia = 'Lansia (65+ th)';

  PatientFilterModel({
    this.statusGizi,
    this.dateRange,
    this.ageGroup,
  });

  /// Cek apakah ada filter yang aktif
  bool get isDefault {
    return statusGizi == null && dateRange == null && ageGroup == null;
  }

  /// Fungsi utama untuk memfilter
  bool matches(Patient patient) {
    // 1. Filter Status Gizi
    final bool matchesStatusGizi;
    if (statusGizi == null) {
      matchesStatusGizi = true;
    } else {
      // .contains() sudah benar, untuk mencakup status seperti "Gizi Kurang (BB/U)"
      matchesStatusGizi = patient.monevStatusGizi?.contains(statusGizi!) ?? false;
    }

    // 2. Filter Rentang Tanggal (FIXED LOGIC)
    final bool matchesDateRange;
    if (dateRange == null) {
      matchesDateRange = true;
    } else {
      final tglPemeriksaan = patient.tanggalPemeriksaan;
      
      // 'start' sudah benar (jam 00:00)
      final rangeStart = dateRange!.start;
      // 'end' dari picker adalah jam 00:00, jadi tambah 1 hari
      // agar menjadi jam 00:00 hari BERIKUTNYA.
      final rangeEnd = dateRange!.end.add(const Duration(days: 1));

      // Logika yang benar:
      // tglPemeriksaan >= rangeStart AND tglPemeriksaan < rangeEnd
      matchesDateRange = !tglPemeriksaan.isBefore(rangeStart) &&
                         tglPemeriksaan.isBefore(rangeEnd);
    }

    // 3. Filter Grup Usia (FIXED LOGIC)
    final bool matchesAgeGroup;
    if (ageGroup == null) {
      matchesAgeGroup = true;
    } else {
      // --- INI ADALAH KALKULASI USIA YANG BENAR ---
      DateTime today = DateTime.now();
      int age = today.year - patient.tanggalLahir.year;
      // Cek apakah ulang tahun sudah lewat tahun ini
      if (patient.tanggalLahir.month > today.month ||
          (patient.tanggalLahir.month == today.month && patient.tanggalLahir.day > today.day)) {
        age--; // Kurangi 1 jika belum ulang tahun
      }
      // ---------------------------------------------

      if (ageGroup == ageAnak) {
        matchesAgeGroup = age <= 18;
      } else if (ageGroup == ageDewasa) {
        matchesAgeGroup = age > 18 && age < 65; // (19-64)
      } else if (ageGroup == ageLansia) {
        matchesAgeGroup = age >= 65;
      } else {
        matchesAgeGroup = false;
      }
    }

    return matchesStatusGizi && matchesDateRange && matchesAgeGroup;
  }
}