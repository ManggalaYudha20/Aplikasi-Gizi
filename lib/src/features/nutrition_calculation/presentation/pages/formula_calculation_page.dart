// lib/src/features/nutrition_calculation/presentation/pages/formula_calculation_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

// Imports Halaman Form
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bmi_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bmr_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/tdee_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bbi_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/nutrition_status_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/imtu_form_page.dart'; // Pastikan nama classnya benar (IMTUFormPage vs ImtuFormPage)
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bbi_anak_form_page.dart';

/// Model untuk konfigurasi menu kalkulator
/// Memudahkan penambahan menu baru tanpa merubah logika UI
class _FormulaMenu {
  final String keyId;      // ID Unik untuk QA Automation
  final String name;       // Nama singkat (icon label)
  final String fullName;   // Nama lengkap (bawah icon)
  final IconData icon;
  final Color color;
  final Widget Function(String role)? pageBuilder; // Builder halaman tujuan

  const _FormulaMenu({
    required this.keyId,
    required this.name,
    required this.fullName,
    required this.icon,
    required this.color,
    this.pageBuilder,
  });
}

class FormulaCalculationPage extends StatelessWidget {
  final String userRole;

  const FormulaCalculationPage({
    super.key,
    required this.userRole,
  });

  // Data Menu didefinisikan sebagai List Model agar Type-Safe
  List<_FormulaMenu> get _menuItems => [
        _FormulaMenu(
          keyId: 'btn_calc_imt', // Key untuk QA
          name: 'IMT',
          fullName: 'Indeks Massa Tubuh',
          icon: Icons.calculate,
          color: Colors.blue,
          pageBuilder: (role) => BmiFormPage(userRole: role),
        ),
        _FormulaMenu(
          keyId: 'btn_calc_bmr',
          name: 'BMR',
          fullName: 'Basal Metabolic Rate',
          icon: Icons.local_fire_department,
          color: Colors.orange,
          pageBuilder: (role) => BmrFormPage(userRole: role),
        ),
        _FormulaMenu(
          keyId: 'btn_calc_tdee',
          name: 'TDEE',
          fullName: 'Total Daily\nEnergy Expenditure',
          icon: Icons.battery_charging_full,
          color: Colors.purple,
          pageBuilder: (role) => TdeeFormPage(userRole: role),
        ),
        _FormulaMenu(
          keyId: 'btn_calc_bbi',
          name: 'BBI',
          fullName: 'Berat Badan Ideal\n (Usia > 12 Tahun)',
          icon: Icons.monitor_weight,
          color: Colors.green,
          pageBuilder: (role) => BbiFormPage(userRole: role),
        ),
        _FormulaMenu(
          keyId: 'btn_calc_bbi_anak',
          name: 'BBI Anak',
          fullName: 'Berat Badan Ideal\n (0 - 12 Tahun)',
          icon: Icons.monitor_weight,
          color: Colors.pinkAccent,
          pageBuilder: (role) => BbiAnakFormPage(userRole: role),
        ),
        _FormulaMenu(
          keyId: 'btn_calc_status_gizi',
          name: 'Status Gizi',
          fullName: 'Status Gizi\n (Usia 0-60 Bulan)',
          icon: Icons.child_care,
          color: Colors.red,
          pageBuilder: (role) => NutritionStatusFormPage(userRole: role),
        ),
        // Catatan: Pastikan nama class IMTUFormPage sesuai dengan import Anda
        _FormulaMenu(
          keyId: 'btn_calc_imtu',
          name: 'IMT/U',
          fullName: 'Indeks Massa Tubuh\nBerdasarkan Usia (5-18 Tahun)',
          icon: Icons.calculate,
          color: Colors.brown,
          // Jika nama classnya IMTUFormPage gunakan ini, jika ImtuFormPage sesuaikan
          pageBuilder: (role) => IMTUFormPage(userRole: role), 
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Kalkulator Gizi',
        subtitle: 'Pilih Jenis Kalkulator',
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(16.0), // Tambahkan padding agar rapi
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16, // Sedikit diperlebar agar tidak terlalu rapat
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            final item = _menuItems[index];
            return _buildMenuCard(context, item);
          },
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, _FormulaMenu item) {
    // 1. Semantics untuk Automation Tool (Katalon/Appium) agar bisa membaca label tombol
    return Semantics(
      label: item.fullName.replaceAll('\n', ' '), // Baca nama lengkap tanpa baris baru
      identifier: item.keyId, // Identifier untuk iOS Accessibility
      button: true,
      child: GestureDetector(
        // 2. Key Unik untuk Automation (Flutter Driver / Integration Test)
        key: ValueKey(item.keyId), 
        onTap: () => _handleNavigation(context, item),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // Menggunakan Container dekoratif yang sama dengan kode asli
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withValues(alpha:0.1),
                border: Border.all(
                  color: item.color,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha:0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item.icon,
                      size: 30,
                      color: item.color,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Text Nama Lengkap
            Expanded(
              child: Text(
                item.fullName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Logic Navigation yang Refactored (DRY - Don't Repeat Yourself)
  // Menghapus if-else panjang dan menggantinya dengan logika dinamis
  void _handleNavigation(BuildContext context, _FormulaMenu item) {
    if (item.pageBuilder != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              item.pageBuilder!(userRole),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0); // Slide dari kanan
            const end = Offset.zero;
            const curve = Curves.easeInOut;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      // Fallback jika halaman belum diimplementasikan
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Formula: ${item.name}'),
          content: Text(
            'Navigasi ke halaman input untuk ${item.fullName} akan diimplementasikan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}