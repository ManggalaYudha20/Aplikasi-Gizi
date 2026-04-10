// lib/src/features/statistics/services/date_filter_logic.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/data/models/chart_data_model.dart';

class DateFilterLogic {
  /// Callback untuk menyuruh halaman utama melakukan setState & update data Firebase
  final VoidCallback onUpdate;

  DateFilterLogic({required this.onUpdate});

  DateTime referenceDate = DateTime.now();
  DateFilterType selectedFilterType = DateFilterType.all;
  DateTimeRange? selectedDateRange;
  String filterLabel = "Semua Waktu";

  void shiftDate(int direction) {
    if (selectedFilterType == DateFilterType.thisMonth) {
      referenceDate = DateTime(
        referenceDate.year,
        referenceDate.month + direction,
        1,
      );
    } else if (selectedFilterType == DateFilterType.thisWeek) {
      referenceDate = referenceDate.add(Duration(days: 7 * direction));
    } else if (selectedFilterType == DateFilterType.thisYear) {
      referenceDate = DateTime(referenceDate.year + direction, 1, 1);
    }
    _applyDateFilter();
  }

  // Tambahkan BuildContext sebagai parameter karena kita butuh memunculkan popup
  Future<void> handleDateFilter(
    BuildContext context,
    DateFilterType type,
  ) async {
    if (type == DateFilterType.custom) {
      final DateTime now = DateTime.now();
      final DateTimeRange? picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2023),
        lastDate: now,
        initialDateRange: selectedDateRange,
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF009444),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        ),
      );
      if (picked == null) return; // user cancelled
      selectedDateRange = picked;
    }

    selectedFilterType = type;
    // Reset reference ke hari ini setiap kali ganti tipe filter (kecuali custom)
    if (type != DateFilterType.custom) {
      referenceDate = DateTime.now();
    }
    _applyDateFilter();
  }

  void _applyDateFilter() {
    DateTime ref = referenceDate;
    DateTime? start;
    DateTime? end;
    String label = "Semua Waktu";

    switch (selectedFilterType) {
      case DateFilterType.thisWeek:
        start = DateTime(ref.year, ref.month, ref.day - (ref.weekday - 1));
        end = start.add(const Duration(days: 6));
        label = "${start.day}/${start.month} - ${end.day}/${end.month}";
        break;
      case DateFilterType.thisMonth:
        start = DateTime(ref.year, ref.month, 1);
        end = DateTime(ref.year, ref.month + 1, 0); // Hari terakhir
        const List<String> months = [
          "Jan",
          "Feb",
          "Mar",
          "Apr",
          "Mei",
          "Jun",
          "Jul",
          "Ags",
          "Sep",
          "Okt",
          "Nov",
          "Des",
        ];
        label = "${months[start.month - 1]} ${start.year}";
        break;
      case DateFilterType.thisYear:
        start = DateTime(ref.year, 1, 1);
        end = DateTime(ref.year, 12, 31);
        label = "${start.year}";
        break;
      case DateFilterType.custom:
        if (selectedDateRange != null) {
          start = selectedDateRange!.start;
          end = selectedDateRange!.end;
          label = "${start.day}/${start.month} - ${end.day}/${end.month}";
        } else {
          label = "Pilih Tanggal";
        }
        break;
      case DateFilterType.all:
        start = null;
        end = null;
        label = "Semua Waktu";
        break;
    }

    filterLabel = label;
    selectedDateRange = (start != null && end != null)
        ? DateTimeRange(
            start: start,
            end: DateTime(end.year, end.month, end.day, 23, 59, 59),
          )
        : null;

    // Panggil callback agar halaman utama ter-update
    onUpdate();
  }
}
