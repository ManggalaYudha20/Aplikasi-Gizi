// lib/src/shared/widgets/patient_filter_model.dart
import 'package:flutter/material.dart';
// HAPUS: import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
// TAMBAHKAN:
import 'package:cloud_firestore/cloud_firestore.dart';

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
  // --- PERUBAHAN UTAMA DI SINI ---
  bool matches(Map<String, dynamic> data) {
    // Ambil tipe pasien
    final String tipePasien = data['tipePasien'] ?? 'dewasa';

    // --- Filter 1: Status Gizi (Kondisional) ---
    bool matchesStatusGizi = true; // Asumsi lolos
    if (statusGizi != null) {
      if (tipePasien == 'anak') {
        final String statusGiziAnak = data['statusGiziAnak'] ?? '';
        matchesStatusGizi = statusGiziAnak.contains(statusGizi!);
      } else {
        final String statusGiziDewasa = data['monevStatusGizi'] ?? '';
        matchesStatusGizi = statusGiziDewasa.contains(statusGizi!);
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