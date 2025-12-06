// lib/src/shared/widgets/food_filter_sheet.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Pastikan import ini ada
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/food_filter_model.dart';

class FoodFilterSheet extends StatefulWidget {
  final FoodFilterModel currentFilters;
  final VoidCallback onResetPressed;

  const FoodFilterSheet({
    super.key,
    required this.currentFilters,
    required this.onResetPressed,
  });

  @override
  State<FoodFilterSheet> createState() => _FoodFilterSheetState();
}

class _FoodFilterSheetState extends State<FoodFilterSheet> {
  late FoodFilterModel _tempFilters;

  @override
  void initState() {
    super.initState();
    _tempFilters = widget.currentFilters;
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
          const Text(
            'Filter Makanan',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // --- Filter Kelompok Makanan (DropdownSearch) ---
          DropdownSearch<String>(
            items: const [
              "Semua Kelompok Makanan",
              ...[
                'Serealia',
                'Umbi',
                'Kacang',
                'Sayur',
                'Buah',
                'Daging',
                'Ikan dsb',
                'Telur',
                'Susu',
                'Lemak',
                'Gula',
                'Bumbu',
              ],
            ],
            selectedItem:
                _tempFilters.kelompokMakanan ?? "Semua Kelompok Makanan",
            popupProps: PopupProps.menu(
              showSearchBox: false, // Search box dihilangkan
              fit: FlexFit.loose, // Tinggi menyesuaikan konten (tidak full screen)
              constraints: const BoxConstraints(maxHeight: 150), // Batas tinggi agar bisa di-scroll
              
              // Props untuk styling menu dropdown agar terlihat rapi
              menuProps: MenuProps(
                elevation: 4, // Memberikan bayangan agar terlihat 'mengambang' di bawah form
              ),

              // Scrollbar tetap ada
              scrollbarProps: const ScrollbarProps(
                thumbVisibility: true,
                thickness: 6,
                radius: Radius.circular(10),
              ),
            ),
            dropdownDecoratorProps: DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Kelompok Makanan',
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
                // Jika user memilih opsi "Semua...", set value ke null
                final valueToSave = newValue == "Semua Kelompok Makanan"
                    ? null
                    : newValue;
                _tempFilters = FoodFilterModel(
                  kelompokMakanan: valueToSave,
                  mentahOlahan: _tempFilters.mentahOlahan,
                );
              });
            },
          ),

          const SizedBox(height: 16),

          // --- Filter Status Mentah/Olahan (DropdownSearch) ---
          DropdownSearch<String>(
            items: const [
              "Semua Status",
              ...['Tunggal', 'Olahan'],
            ],
            selectedItem: _tempFilters.mentahOlahan ?? "Semua Status",
            popupProps: PopupProps.menu(
              showSearchBox: false,
              fit: FlexFit.loose,
              constraints: const BoxConstraints(maxHeight: 100),
              
              menuProps: MenuProps(
                borderRadius: BorderRadius.circular(12),
                elevation: 4,
                positionCallback: (RenderBox findRenderObject, RenderBox overlay) {
                // Mencari posisi global dari tombol dropdown (form)
                Offset localToGlobal = findRenderObject.localToGlobal(Offset.zero, ancestor: overlay);
                
                // Menentukan tinggi menu sesuai constraints Anda (95)
                // Tambahkan sedikit buffer (misal 5) jika ingin ada jarak
                double menuHeight = 110.0; 

                return RelativeRect.fromLTRB(
                  localToGlobal.dx, // Kiri (sama dengan tombol)
                  localToGlobal.dy - menuHeight, // Atas (Posisi Tombol - Tinggi Menu)
                  overlay.size.width - (localToGlobal.dx + findRenderObject.size.width), // Kanan (sama dengan tombol)
                  overlay.size.height - localToGlobal.dy, // Bawah (diangkur ke Bagian Atas Tombol)
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
                labelText: 'Status (Mentah/Olahan)',
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
                // Jika user memilih opsi "Semua...", set value ke null
                final valueToSave = newValue == "Semua Status"
                    ? null
                    : newValue;
                _tempFilters = FoodFilterModel(
                  kelompokMakanan: _tempFilters.kelompokMakanan,
                  mentahOlahan: valueToSave,
                );
              });
            },
          ),

          const SizedBox(height: 24),

          // --- Tombol Aksi ---
          Row(
            children: [
              TextButton(
                child: const Text('Reset Filter'),
                onPressed: () {
                  setState(() {
                    _tempFilters = FoodFilterModel(); // Reset model ke null
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
