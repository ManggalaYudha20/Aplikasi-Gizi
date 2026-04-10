// lib/src/features/admin/widgets/user_filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/models/user_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/admin/models/user_filter_model.dart';

class UserFilterSheet extends StatefulWidget {
  final UserFilterModel currentFilters;
  final VoidCallback onResetPressed;

  const UserFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onResetPressed,
  });

  @override
  State<UserFilterSheet> createState() => _UserFilterSheetState();
}

class _UserFilterSheetState extends State<UserFilterSheet> {
  late UserFilterModel _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.currentFilters;
  }

  // Mendapatkan daftar role tanpa opsi 'unknown'
  List<UserRole> get _availableRoles {
    return UserRole.values
        .where((r) => r != UserRole.unknown && r != UserRole.ahliGizi)
        .toList();
  }

  // Helper untuk menampilkan label yang dipilih
  String _getSelectedRoleLabel() {
    if (_tempFilters.role == null) return 'Semua Role';
    return _tempFilters.role!.label;
  }

  @override
  Widget build(BuildContext context) {
    // Menyiapkan item string untuk dropdown
    List<String> dropdownItems = ['Semua Role'];
    dropdownItems.addAll(_availableRoles.map((r) => r.label));

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
          const Text(
            'Filter Pengguna',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // --- Filter Role (DropdownSearch) ---
          DropdownSearch<String>(
            items: dropdownItems,
            selectedItem: _getSelectedRoleLabel(),
            popupProps: PopupProps.menu(
              showSearchBox: false,
              fit: FlexFit.loose,
              constraints: const BoxConstraints(maxHeight: 200),
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
              ),
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Role Pengguna',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
              ),
            ),
            onChanged: (String? newValue) {
              setState(() {
                if (newValue == 'Semua Role' || newValue == null) {
                  _tempFilters = UserFilterModel(role: null);
                } else {
                  // Cari UserRole yang labelnya cocok dengan newValue
                  final selectedRole = _availableRoles.firstWhere(
                    (r) => r.label == newValue,
                  );
                  _tempFilters = UserFilterModel(role: selectedRole);
                }
              });
            },
          ),

          const SizedBox(height: 32),

          // --- Tombol Aksi ---
          Row(
            children: [
              TextButton(
                child: const Text('Reset Filter'),
                onPressed: () {
                  setState(() {
                    _tempFilters = UserFilterModel(role: null);
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
          ),
        ],
      ),
    );
  }
}
