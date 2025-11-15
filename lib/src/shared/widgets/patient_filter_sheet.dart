// lib/src/shared/widgets/patient_filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_filter_model.dart';

class PatientFilterSheet extends StatefulWidget {
  final PatientFilterModel currentFilters;

  const PatientFilterSheet({
    super.key,
    required this.currentFilters,
  });

  @override
  State<PatientFilterSheet> createState() => _PatientFilterSheetState();
}

class _PatientFilterSheetState extends State<PatientFilterSheet> {
  // State sementara untuk modal, diinisialisasi dari filter aktif
  late PatientFilterModel _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.currentFilters;
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _tempFilters.dateRange,
    );
    if (picked != null) {
      setState(() {
        // Ganti 'copyWith' dengan ini
        _tempFilters = PatientFilterModel(
          statusGizi: _tempFilters.statusGizi,
          ageGroup: _tempFilters.ageGroup,
          dateRange: picked, // Nilai baru
        );
      });
    }
  }

  String _formatDateRange(DateTimeRange? range) {
    if (range == null) {
      return 'Semua Tanggal';
    }
    final format = DateFormat('dd MMM yyyy', 'id_ID');
    return '${format.format(range.start)} - ${format.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter Pasien', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // --- Filter Status Gizi ---
          DropdownButtonFormField<String>(
            initialValue: _tempFilters.statusGizi, // Sudah benar
            hint: const Text('Semua Status Gizi'),
            isExpanded: true,
            items: ['Gizi Kurang (Underweight)', 'Gizi Baik (Normal)', 'Gizi Lebih (Overweight)', 'Obesitas']
                .map((String status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                // --- PERBAIKAN LOGIKA STATE ---
                // Jangan gunakan copyWith, agar bisa di-set ke null
                _tempFilters = PatientFilterModel(
                  statusGizi: newValue, // Nilai baru
                  dateRange: _tempFilters.dateRange, // Nilai lama
                  ageGroup: _tempFilters.ageGroup, // Nilai lama
                );
              });
            },
            decoration: InputDecoration(
              labelText: 'Status Gizi',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // --- Filter Kelompok Usia ---
          DropdownButtonFormField<String>(
            initialValue: _tempFilters.ageGroup, // Sudah benar
            hint: const Text('Semua Kelompok Usia'),
            isExpanded: true,
            items: [
              PatientFilterModel.ageAnak,
              PatientFilterModel.ageDewasa,
              PatientFilterModel.ageLansia,
            ].map((String group) {
              return DropdownMenuItem<String>(
                value: group,
                child: Text(group),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                // --- PERBAIKAN LOGIKA STATE ---
                _tempFilters = PatientFilterModel(
                  statusGizi: _tempFilters.statusGizi, // Nilai lama
                  dateRange: _tempFilters.dateRange, // Nilai lama
                  ageGroup: newValue, // Nilai baru
                );
              });
            },
            decoration: InputDecoration(
              labelText: 'Kelompok Usia',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),

          // --- Filter Tanggal ---
          Text('Tanggal Pemeriksaan', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          InkWell(
            onTap: () => _selectDateRange(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 20),
                  const SizedBox(width: 10),
                  Text(_formatDateRange(_tempFilters.dateRange)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- Tombol Aksi ---
          Row(
            children: [
              TextButton(
                child: const Text('Reset Filter'),
                onPressed: () {
                  // Kirim balik filter kosong
                  Navigator.pop(context, PatientFilterModel());
                },
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 148, 68), // Warna hijau Anda
                  foregroundColor: Colors.white,
                ),
                child: const Text('Terapkan Filter'),
                onPressed: () {
                  // Kirim balik filter yang sudah diisi
                  Navigator.pop(context, _tempFilters);
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}