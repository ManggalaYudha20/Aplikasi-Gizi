// lib/src/shared/widgets/patient_filter_form.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Import package
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_filter_model.dart';

class PatientFilterSheet extends StatefulWidget {
  final PatientFilterModel currentFilters;
  final VoidCallback onResetPressed;

  const PatientFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onResetPressed,
  });

  @override
  State<PatientFilterSheet> createState() => _PatientFilterSheetState();
}

class _PatientFilterSheetState extends State<PatientFilterSheet> {
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
        _tempFilters = PatientFilterModel(
          statusGizi: _tempFilters.statusGizi,
          ageGroup: _tempFilters.ageGroup,
          isCompleted: _tempFilters.isCompleted,
          dateRange: picked,
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

  // Helper untuk menentukan label status penyelesaian dari nilai boolean
  String _getCompletionLabel(bool? val) {
    if (val == true) return 'Selesai';
    if (val == false) return 'Belum Selesai';
    return 'Semua Status';
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

          // --- Filter Status Penyelesaian (DropdownSearch) ---
          DropdownSearch<String>(
            items: const ['Semua Status', 'Selesai', 'Belum Selesai'],
            selectedItem: _getCompletionLabel(_tempFilters.isCompleted),
            popupProps: PopupProps.menu(
              showSearchBox: false,
              fit: FlexFit.loose,
              constraints: const BoxConstraints(maxHeight: 180),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                // Logika posisi DI BAWAH form
                positionCallback: (RenderBox findRenderObject, RenderBox overlay) {
                  Offset localToGlobal = findRenderObject.localToGlobal(Offset.zero, ancestor: overlay);
                  return RelativeRect.fromLTRB(
                    localToGlobal.dx,
                    localToGlobal.dy + findRenderObject.size.height, // Mulai dari bawah tombol
                    overlay.size.width - (localToGlobal.dx + findRenderObject.size.width),
                    0, // Biarkan memanjang ke bawah
                  );
                },
              ),
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Status Penyelesaian',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
            onChanged: (String? newValue) {
              bool? newStatus;
              if (newValue == 'Selesai') {
                newStatus = true;
              } else if (newValue == 'Belum Selesai') {
                newStatus = false;
              } else {
                newStatus = null; // Semua Status
              }

              setState(() {
                _tempFilters = PatientFilterModel(
                  statusGizi: _tempFilters.statusGizi,
                  dateRange: _tempFilters.dateRange,
                  ageGroup: _tempFilters.ageGroup,
                  isCompleted: newStatus,
                );
              });
            },
          ),
          
          const SizedBox(height: 16),

          // --- Filter Status Gizi (DropdownSearch) ---
          DropdownSearch<String>(
            items: const [
              'Semua Status Gizi',
              'Gizi Kurang (Underweight)',
              'Gizi Baik (Normal)',
              'Gizi Lebih (Overweight)',
              'Obesitas'
            ],
            selectedItem: _tempFilters.statusGizi ?? 'Semua Status Gizi',
            popupProps: PopupProps.menu(
              showSearchBox: false,
              fit: FlexFit.loose,
              constraints: const BoxConstraints(maxHeight: 200),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                // Logika posisi DI BAWAH form
                positionCallback: (RenderBox findRenderObject, RenderBox overlay) {
                  Offset localToGlobal = findRenderObject.localToGlobal(Offset.zero, ancestor: overlay);
                  return RelativeRect.fromLTRB(
                    localToGlobal.dx,
                    localToGlobal.dy + findRenderObject.size.height,
                    overlay.size.width - (localToGlobal.dx + findRenderObject.size.width),
                    0,
                  );
                },
              ),
              scrollbarProps: const ScrollbarProps(thumbVisibility: true, thickness: 6, radius: Radius.circular(10)),
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Status Gizi',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
            onChanged: (String? newValue) {
              setState(() {
                final valueToSave = newValue == 'Semua Status Gizi' ? null : newValue;
                _tempFilters = PatientFilterModel(
                  statusGizi: valueToSave,
                  dateRange: _tempFilters.dateRange,
                  ageGroup: _tempFilters.ageGroup,
                  isCompleted: _tempFilters.isCompleted,
                );
              });
            },
          ),

          const SizedBox(height: 16),

          // --- Filter Kelompok Usia (DropdownSearch) ---
          DropdownSearch<String>(
            items: [
              'Semua Kelompok Usia',
              PatientFilterModel.ageAnak,
              PatientFilterModel.ageDewasa,
              PatientFilterModel.ageLansia,
            ],
            selectedItem: _tempFilters.ageGroup ?? 'Semua Kelompok Usia',
            popupProps: PopupProps.menu(
              showSearchBox: false,
              fit: FlexFit.loose,
              constraints: const BoxConstraints(maxHeight: 170),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                // Logika posisi DI BAWAH form
                positionCallback: (RenderBox findRenderObject, RenderBox overlay) {
                  Offset localToGlobal = findRenderObject.localToGlobal(Offset.zero, ancestor: overlay);
                  return RelativeRect.fromLTRB(
                    localToGlobal.dx,
                    localToGlobal.dy + findRenderObject.size.height,
                    overlay.size.width - (localToGlobal.dx + findRenderObject.size.width),
                    0,
                  );
                },
              ),
              scrollbarProps: const ScrollbarProps(
                thumbVisibility: true,
                thickness: 6,
                radius: Radius.circular(10),
              ),
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Kelompok Usia',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
            onChanged: (String? newValue) {
              setState(() {
                final valueToSave = newValue == 'Semua Kelompok Usia' ? null : newValue;
                _tempFilters = PatientFilterModel(
                  statusGizi: _tempFilters.statusGizi,
                  dateRange: _tempFilters.dateRange,
                  ageGroup: valueToSave,
                  isCompleted: _tempFilters.isCompleted,
                );
              });
            },
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
                  setState(() {
                    _tempFilters = PatientFilterModel();
                  });
                  widget.onResetPressed();
                },
              ),
              const Spacer(),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Terapkan Filter'),
                onPressed: () {
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