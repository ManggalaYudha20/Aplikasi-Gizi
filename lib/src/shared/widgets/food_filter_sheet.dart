// lib\src\shared\widgets\food_filter_sheet.dart

import 'package:flutter/material.dart';
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

  final List<String> _kelompokItems = const [
    'Serealia', 'Umbi', 'Kacang', 'Sayur', 'Buah', 'Daging', 
    'Ikan dsb', 'Telur', 'Susu', 'Lemak', 'Gula', 'Bumbu'
  ];
  
  // Saya perbaiki 'Tunggu' kembali ke 'Tunggal'
  final List<String> _statusItems = const ['Tunggal', 'Olahan']; 

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
          const Text('Filter Makanan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),

          // --- Filter Kelompok Makanan ---
          DropdownButtonFormField<String>(
            initialValue: _tempFilters.kelompokMakanan,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Kelompok Makanan',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua Kelompok Makanan'),
              ),
              // Hapus .toList() dari sini
              ..._kelompokItems.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }), 
            ],
            onChanged: (newValue) {
              setState(() {
                _tempFilters = FoodFilterModel(
                  kelompokMakanan: newValue, 
                  mentahOlahan: _tempFilters.mentahOlahan, 
                );
              });
            },
          ),
          
          const SizedBox(height: 16),

          // --- Filter Status Mentah/Olahan ---
          DropdownButtonFormField<String>(
            initialValue: _tempFilters.mentahOlahan,
            isExpanded: true,
             decoration: InputDecoration(
              labelText: 'Status (Mentah/Olahan)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua Status'),
              ),
              // Hapus .toList() dari sini
              ..._statusItems.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }),
            ],
            onChanged: (newValue) {
              setState(() {
                _tempFilters = FoodFilterModel(
                  kelompokMakanan: _tempFilters.kelompokMakanan, 
                  mentahOlahan: newValue, 
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
                    _tempFilters = FoodFilterModel(); 
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