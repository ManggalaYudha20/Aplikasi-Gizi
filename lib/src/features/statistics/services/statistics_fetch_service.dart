// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\statistics\services\statistics_fetch_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' show Colors, DateTimeRange, debugPrint;

import 'package:aplikasi_diagnosa_gizi/src/features/statistics/data/models/chart_data_model.dart';

class StatisticsFetchService {
  StatisticsFetchService._(); // prevent instantiation – all methods are static

  // ─── Firestore Query Builder ────────────────────────────────────────────────

  /// Returns a Firestore query scoped to the current user when not admin, or
  /// the full `patients` collection when admin.
  static Query<Map<String, dynamic>> buildPatientsQuery({
    required bool isAdmin,
  }) {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance.collection(
      'patients',
    );

    if (!isAdmin) {
      query = query.where('createdBy', isEqualTo: uid);
    }
    return query;
  }

  // ─── User Stats ─────────────────────────────────────────────────────────────

  /// Fetches the full user list and returns role distribution.
  /// Returns `null` on error (caller should show a toast / ignore silently).
  static Future<UserStats?> fetchUserStats() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();

      int admins = 0, nutritionists = 0, guests = 0;
      for (final doc in snap.docs) {
        final role = (doc.data()['role'] as String?) ?? 'tamu';
        if (role == 'admin') {
          admins++;
        } else if (role == 'ahli_gizi' || role == 'nutrisionis') {
          nutritionists++;
        } else {
          guests++;
        }
      }

      return UserStats(
        totalUsers: snap.docs.length,
        roleCounts: {
          'admin': admins,
          'ahli_gizi': nutritionists,
          'tamu': guests,
        },
      );
    } catch (e) {
      debugPrint("StatisticsFetchService: Error fetching users: $e");
      return null;
    }
  }

  // ─── Date Filtering ─────────────────────────────────────────────────────────

  /// Client-side date filter applied to a snapshot document list.
  /// When [dateRange] is null every document passes.
  static List<QueryDocumentSnapshot> filterDocsByDate(
    List<QueryDocumentSnapshot> docs,
    DateTimeRange? dateRange,
  ) {
    if (dateRange == null) return docs;

    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['tanggalPemeriksaan'] == null) return false;
      try {
        final ts = data['tanggalPemeriksaan'] as Timestamp;
        final date = ts.toDate();
        return date.isAfter(
              dateRange.start.subtract(const Duration(seconds: 1)),
            ) &&
            date.isBefore(dateRange.end.add(const Duration(seconds: 1)));
      } catch (_) {
        return false;
      }
    }).toList();
  }

  // ─── Patient Data Aggregation ───────────────────────────────────────────────

  /// Iterates over [docs] and produces an [AggregatedPatientData] snapshot.
  static AggregatedPatientData aggregatePatientData(
    List<QueryDocumentSnapshot> docs,
  ) {
    int totalDewasa = 0, totalAnak = 0, totalLaki = 0, totalPerempuan = 0;

    final Map<String, double> statusGiziMap = {};
    final Map<String, double> statusGiziAnakBBUMap = {};
    final Map<String, double> diagnosisMap = {};

    final Map<String, double> usiaMap = {
      "Balita (0-5)": 0,
      "Anak (6-11)": 0,
      "Remaja (12-25)": 0,
      "Dewasa (26-45)": 0,
      "Lansia (>45)": 0,
    };
    final Map<String, double> bbMap = {
      "< 40 kg": 0,
      "40 - 50 kg": 0,
      "50 - 60 kg": 0,
      "60 - 70 kg": 0,
      "70 - 80 kg": 0,
      "> 80 kg": 0,
    };
    final Map<String, double> tbMap = {
      "< 150 cm": 0,
      "150 - 160 cm": 0,
      "160 - 170 cm": 0,
      "> 170 cm": 0,
    };

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String tipe = (data['tipePasien'] as String?) ?? 'dewasa';

      // A. Tipe & Gender
      if (tipe == 'anak') {
        totalAnak++;
        String statusBBU = _cleanString(data['statusGiziBBU']);
        if (statusBBU == "Tidak Diketahui") {
          statusBBU = _cleanString(data['statusGiziAnak']);
        }
        if (statusBBU != "Tidak Diketahui") {
          final key = statusBBU.length > 1
              ? statusBBU[0].toUpperCase() + statusBBU.substring(1)
              : statusBBU;
          statusGiziAnakBBUMap[key] = (statusGiziAnakBBUMap[key] ?? 0) + 1;
        }
      } else {
        totalDewasa++;
      }

      final String gender = (data['jenisKelamin'] as String?) ?? '';
      if (gender.toLowerCase().contains('laki')) {
        totalLaki++;
      } else if (gender.toLowerCase().contains('perempuan')) {
        totalPerempuan++;
      }

      // B. Status Gizi Dewasa
      if (tipe != 'anak') {
        final String status = _cleanString(data['monevStatusGizi']);
        if (status != "Tidak Diketahui") {
          final key = status.length > 1
              ? status[0].toUpperCase() + status.substring(1).toLowerCase()
              : status;
          statusGiziMap[key] = (statusGiziMap[key] ?? 0) + 1;
        }
      }

      // C. Diagnosis
      final String diag = _cleanString(data['diagnosisMedis']);
      if (diag != "Tidak Diketahui") {
        diagnosisMap[diag] = (diagnosisMap[diag] ?? 0) + 1;
      }

      // D. Usia
      if (data['tanggalLahir'] is Timestamp) {
        final int age = _calculateAge(
          (data['tanggalLahir'] as Timestamp).toDate(),
        );
        if (age <= 5) {
          usiaMap["Balita (0-5)"] = usiaMap["Balita (0-5)"]! + 1;
        } else if (age <= 11) {
          usiaMap["Anak (6-11)"] = usiaMap["Anak (6-11)"]! + 1;
        } else if (age <= 25) {
          usiaMap["Remaja (12-25)"] = usiaMap["Remaja (12-25)"]! + 1;
        } else if (age <= 45) {
          usiaMap["Dewasa (26-45)"] = usiaMap["Dewasa (26-45)"]! + 1;
        } else {
          usiaMap["Lansia (>45)"] = usiaMap["Lansia (>45)"]! + 1;
        }
      }

      // E. Berat Badan
      final double bb = _parseDouble(data['beratBadan']);
      if (bb > 0) {
        if (bb < 40) {
          bbMap["< 40 kg"] = bbMap["< 40 kg"]! + 1;
        } else if (bb < 50) {
          bbMap["40 - 50 kg"] = bbMap["40 - 50 kg"]! + 1;
        } else if (bb < 60) {
          bbMap["50 - 60 kg"] = bbMap["50 - 60 kg"]! + 1;
        } else if (bb < 70) {
          bbMap["60 - 70 kg"] = bbMap["60 - 70 kg"]! + 1;
        } else if (bb < 80) {
          bbMap["70 - 80 kg"] = bbMap["70 - 80 kg"]! + 1;
        } else {
          bbMap["> 80 kg"] = bbMap["> 80 kg"]! + 1;
        }
      }

      // F. Tinggi Badan
      final double tb = _parseDouble(data['tinggiBadan']);
      if (tb > 0) {
        if (tb < 150) {
          tbMap["< 150 cm"] = tbMap["< 150 cm"]! + 1;
        } else if (tb < 160) {
          tbMap["150 - 160 cm"] = tbMap["150 - 160 cm"]! + 1;
        } else if (tb < 170) {
          tbMap["160 - 170 cm"] = tbMap["160 - 170 cm"]! + 1;
        } else {
          tbMap["> 170 cm"] = tbMap["> 170 cm"]! + 1;
        }
      }
    }

    // Remove zero-value buckets from ordered maps before returning.
    usiaMap.removeWhere((_, v) => v == 0);
    bbMap.removeWhere((_, v) => v == 0);
    tbMap.removeWhere((_, v) => v == 0);

    return AggregatedPatientData(
      totalDewasa: totalDewasa,
      totalAnak: totalAnak,
      totalLaki: totalLaki,
      totalPerempuan: totalPerempuan,
      statusGiziMap: statusGiziMap,
      statusGiziAnakBBUMap: statusGiziAnakBBUMap,
      diagnosisMap: diagnosisMap,
      usiaMap: usiaMap,
      bbMap: bbMap,
      tbMap: tbMap,
    );
  }

  // ─── Chart Config Builder ───────────────────────────────────────────────────

  /// Maps a [selectedCategory] string to a [ChartConfig] ready for rendering.
  static ChartConfig buildChartConfig({
    required String selectedCategory,
    required AggregatedPatientData data,
    required UserStats? userStats,
    required bool isAdmin,
  }) {
    String chartTitle = "";
    Map<String, double> rawData = {};
    List<dynamic> chartColors = [];

    switch (selectedCategory) {
      case 'Pengguna':
        if (isAdmin && userStats != null) {
          chartTitle = "Distribusi Role Pengguna";
          rawData = {
            "Admin": userStats.roleCounts['admin']!.toDouble(),
            "Ahli Gizi": userStats.roleCounts['ahli_gizi']!.toDouble(),
            "Tamu": userStats.roleCounts['tamu']!.toDouble(),
          };
          chartColors = [Colors.red, Colors.teal, Colors.lightGreen];
        }
        break;

      case 'Kategori Pasien':
        chartTitle = "Persentase Tipe Pasien";
        rawData = {
          "Dewasa": data.totalDewasa.toDouble(),
          "Anak": data.totalAnak.toDouble(),
        };
        chartColors = [Colors.blue, Colors.orange];
        break;

      case 'Jenis Kelamin':
        chartTitle = "Persentase Gender";
        rawData = {
          "Laki-laki": data.totalLaki.toDouble(),
          "Perempuan": data.totalPerempuan.toDouble(),
        };
        chartColors = [Colors.cyan, Colors.pinkAccent];
        break;

      case 'Status Gizi (Dewasa)':
        chartTitle = "Status Gizi (Dewasa)";
        rawData = data.statusGiziMap;
        chartColors = [
          Colors.orange,
          Colors.green,
          Colors.red,
          Colors.blueGrey,
          Colors.purple,
        ];
        break;

      case 'Status Gizi Anak (BB/U)':
        chartTitle = "Status Gizi Anak (BB/U)";
        rawData = data.statusGiziAnakBBUMap;
        chartColors = [
          Colors.green,
          Colors.redAccent,
          Colors.orangeAccent,
          Colors.blueAccent,
          Colors.purpleAccent,
        ];
        break;

      case 'Diagnosis Medis':
        chartTitle = "Diagnosis Medis Terbanyak";
        final sortedKeys = data.diagnosisMap.keys.toList(growable: false)
          ..sort(
            (k1, k2) =>
                data.diagnosisMap[k2]!.compareTo(data.diagnosisMap[k1]!),
          );
        double countLainnya = 0;
        for (int i = 0; i < sortedKeys.length; i++) {
          if (i < 5) {
            rawData[sortedKeys[i]] = data.diagnosisMap[sortedKeys[i]]!;
          } else {
            countLainnya += data.diagnosisMap[sortedKeys[i]]!;
          }
        }
        if (countLainnya > 0) rawData["Lainnya"] = countLainnya;
        chartColors = [
          Colors.redAccent,
          Colors.blueAccent,
          Colors.orangeAccent,
          Colors.green,
          Colors.purpleAccent,
          Colors.grey,
        ];
        break;

      case 'Usia':
        chartTitle = "Rentang Usia Pasien";
        rawData = data.usiaMap;
        chartColors = [
          Colors.lightBlue,
          Colors.blue,
          Colors.indigo,
          Colors.deepPurple,
          Colors.teal,
        ];
        break;

      case 'Berat Badan':
        chartTitle = "Sebaran Berat Badan";
        rawData = data.bbMap;
        chartColors = [
          Colors.brown.shade300,
          Colors.brown.shade400,
          Colors.brown.shade500,
          Colors.brown.shade600,
          Colors.brown.shade700,
          Colors.brown.shade800,
        ];
        break;

      case 'Tinggi Badan':
        chartTitle = "Sebaran Tinggi Badan";
        rawData = data.tbMap;
        chartColors = [
          Colors.teal.shade300,
          Colors.teal.shade400,
          Colors.teal.shade500,
          Colors.teal.shade700,
        ];
        break;
    }

    // Normalise: remove zero-value entries then fall back to empty-data marker.
    final Map<String, double> chartData = Map.from(rawData)
      ..removeWhere((_, v) => v == 0);

    if (chartData.isEmpty) {
      return ChartConfig(
        title: chartTitle,
        dataMap: const {"Tidak ada data": 1},
        colors: [Colors.grey.shade300],
      );
    }

    return ChartConfig(
      title: chartTitle,
      dataMap: chartData,
      colors: List<dynamic>.from(chartColors)
          .cast<dynamic>()
          .map((c) {
            // chartColors is already List<Color> – cast is safe.
            return c as dynamic;
          })
          .toList()
          .cast(),
    );
  }

  // ─── Private Helpers ────────────────────────────────────────────────────────

  static String _cleanString(dynamic value) {
    if (value == null) return "Tidak Diketahui";
    final s = value.toString().trim();
    return s.isEmpty ? "Tidak Diketahui" : s;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      return double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    }
    return 0.0;
  }

  static int _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}
