// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\statistics\data\models\chart_data_model.dart

import 'package:flutter/material.dart';

// ─── Enums ─────────────────────────────────────────────────────────────────────

enum DateFilterType { all, thisWeek, thisMonth, thisYear, custom }

// ─── Chart Config ──────────────────────────────────────────────────────────────

/// Holds the resolved chart title, display-ready data map, and colour palette
/// for a single selected category.
class ChartConfig {
  const ChartConfig({
    required this.title,
    required this.dataMap,
    required this.colors,
  });

  final String title;

  /// Key → count (already filtered and cleaned; never empty – falls back to
  /// `{"Tidak ada data": 1}` with a grey colour when there is nothing to show).
  final Map<String, double> dataMap;

  final List<Color> colors;

  /// Convenience: the raw sum of all values.
  double get total => dataMap.values.fold(0, (prev, v) => prev + v);
}

// ─── Aggregated Patient Data ───────────────────────────────────────────────────

/// Immutable snapshot of all patient statistics computed from a list of
/// Firestore documents.  Produced by [StatisticsFetchService.aggregatePatientData].
class AggregatedPatientData {
  const AggregatedPatientData({
    required this.totalDewasa,
    required this.totalAnak,
    required this.totalLaki,
    required this.totalPerempuan,
    required this.statusGiziMap,
    required this.statusGiziAnakBBUMap,
    required this.diagnosisMap,
    required this.usiaMap,
    required this.bbMap,
    required this.tbMap,
  });

  final int totalDewasa;
  final int totalAnak;
  final int totalLaki;
  final int totalPerempuan;

  /// Status gizi for adult (dewasa) patients.
  final Map<String, double> statusGiziMap;

  /// Status gizi anak – BB/U axis.
  final Map<String, double> statusGiziAnakBBUMap;

  /// Medical diagnosis distribution (top-5 + "Lainnya" bucketing is applied
  /// later in [StatisticsFetchService.buildChartConfig]).
  final Map<String, double> diagnosisMap;

  /// Age-range buckets.
  final Map<String, double> usiaMap;

  /// Weight (berat badan) buckets.
  final Map<String, double> bbMap;

  /// Height (tinggi badan) buckets.
  final Map<String, double> tbMap;
}

// ─── User Stats ────────────────────────────────────────────────────────────────

/// Role distribution fetched from the `users` Firestore collection.
/// Only visible to admin users.
class UserStats {
  const UserStats({required this.totalUsers, required this.roleCounts});

  final int totalUsers;

  /// Keys: `'admin'`, `'ahli_gizi'`, `'tamu'`.
  final Map<String, int> roleCounts;
}
