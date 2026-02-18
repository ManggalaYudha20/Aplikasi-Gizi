// lib/src/features/nutrition_calculation/presentation/pages/formula_calculation_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

// Imports Halaman Form
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bmi_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bmr_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/tdee_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bbi_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/nutrition_status_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/imtu_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bbi_anak_form_page.dart';

/// Model konfigurasi menu formula — immutable & type-safe.
/// Menggunakan 'final' untuk properti agar bisa menjadi compile-time constant.
@immutable
class _FormulaMenu {
  final String keyId;      // ID Unik untuk QA Automation (Katalon/Appium)
  final String name;       // Nama singkat (Label Icon)
  final String fullName;   // Nama lengkap (Label Bawah)
  final IconData icon;
  final Color color;
  final Widget Function(String role)? pageBuilder;

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

  // ---------------------------------------------------------------------------
  // STATIC BUILDERS
  // Diperlukan agar List _menuItems bisa bersifat 'static const'.
  // Teknik ini mencegah alokasi memori berulang untuk closure anonim.
  // ---------------------------------------------------------------------------
  static Widget _buildBmiPage(String role) => BmiFormPage(userRole: role);
  static Widget _buildBmrPage(String role) => BmrFormPage(userRole: role);
  static Widget _buildTdeePage(String role) => TdeeFormPage(userRole: role);
  static Widget _buildBbiPage(String role) => BbiFormPage(userRole: role);
  static Widget _buildBbiAnakPage(String role) => BbiAnakFormPage(userRole: role);
  static Widget _buildStatusGiziPage(String role) => NutritionStatusFormPage(userRole: role);
  static Widget _buildImtuPage(String role) => IMTUFormPage(userRole: role);

  /// DATA MENU (Single Source of Truth)
  /// Dideklarasikan sebagai 'static const' untuk optimasi memori maksimal.
  /// List ini hanya dibuat satu kali saat aplikasi dijalankan.
  static const List<_FormulaMenu> _menuItems = [
    _FormulaMenu(
      keyId: 'btn_calc_imt',
      name: 'IMT',
      fullName: 'Indeks Massa Tubuh',
      icon: Icons.calculate,
      color: Colors.blue,
      pageBuilder: _buildBmiPage,
    ),
    _FormulaMenu(
      keyId: 'btn_calc_bmr',
      name: 'BMR',
      fullName: 'Basal Metabolic Rate',
      icon: Icons.local_fire_department,
      color: Colors.orange,
      pageBuilder: _buildBmrPage,
    ),
    _FormulaMenu(
      keyId: 'btn_calc_tdee',
      name: 'TDEE',
      fullName: 'Total Daily\nEnergy Expenditure',
      icon: Icons.battery_charging_full,
      color: Colors.purple,
      pageBuilder: _buildTdeePage,
    ),
    _FormulaMenu(
      keyId: 'btn_calc_bbi',
      name: 'BBI',
      fullName: 'Berat Badan Ideal\n(Usia > 12 Tahun)',
      icon: Icons.monitor_weight,
      color: Colors.green,
      pageBuilder: _buildBbiPage,
    ),
    _FormulaMenu(
      keyId: 'btn_calc_bbi_anak',
      name: 'BBI Anak',
      fullName: 'Berat Badan Ideal\n(0 - 12 Tahun)',
      icon: Icons.monitor_weight,
      color: Colors.pinkAccent,
      pageBuilder: _buildBbiAnakPage,
    ),
    _FormulaMenu(
      keyId: 'btn_calc_status_gizi',
      name: 'Status Gizi',
      fullName: 'Status Gizi\n(Usia 0-60 Bulan)',
      icon: Icons.child_care,
      color: Colors.red,
      pageBuilder: _buildStatusGiziPage,
    ),
    _FormulaMenu(
      keyId: 'btn_calc_imtu',
      name: 'IMT/U',
      fullName: 'IMT Berdasarkan Usia\n (5-18 Tahun)',
      icon: Icons.calculate,
      color: Colors.brown,
      pageBuilder: _buildImtuPage,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // RESPONSIVE CALCULATION
    // Menghitung dimensi layar sekali saja di sini.
    final Size screenSize = MediaQuery.sizeOf(context);
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Konsistensi Visual: Menggunakan logika padding yang sama dengan Disease Page
    // Padding 8% dari lebar layar agar konsisten di HP kecil maupun Tablet
    final double gridPadding = screenWidth * 0.08;

    // Menghitung Aspect Ratio agar kartu tetap proporsional
    // Rumus: (Lebar Layar - Padding Kiri Kanan - Spasi Tengah) / 2 Kolom
    final double colWidth = (screenWidth - (gridPadding * 2) - 16) / 2;
    // Tinggi kartu ditargetkan sekitar 22% dari tinggi layar
    final double cardHeight = screenHeight * 0.22; 
    
    // Mencegah division by zero atau nilai negatif pada layar sangat kecil
    final double childAspectRatio = (cardHeight > 0) ? (colWidth / cardHeight) : 1.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Kalkulator Gizi',
        subtitle: 'Pilih Jenis Kalkulator',
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: EdgeInsets.all(gridPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // Tetap 2 kolom sesuai request
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio, // Dinamis
          ),
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            final _FormulaMenu item = _menuItems[index];
            return _FormulaMenuCard(
              item: item,
              onTap: () => _handleNavigation(context, item),
            );
          },
        ),
      ),
    );
  }

  /// Centralized Navigation Logic
  void _handleNavigation(BuildContext context, _FormulaMenu item) {
    if (item.pageBuilder == null) {
      _showNotImplementedDialog(context, item);
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => item.pageBuilder!(userRole),
        transitionsBuilder: (_, animation, __, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _showNotImplementedDialog(BuildContext context, _FormulaMenu item) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Formula: ${item.name}'),
        content: Text(
          'Navigasi ke halaman ${item.fullName} belum tersedia.',
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

/// Widget Menu yang Diekstrak untuk Performance & Readability
/// Membantu Flutter Engine melakukan diffing widget tree lebih cepat.
class _FormulaMenuCard extends StatelessWidget {
  final _FormulaMenu item;
  final VoidCallback onTap;

  const _FormulaMenuCard({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // QA & AUTOMATION LAYER
    // Semantics: Memberikan data ke Accessibility Service (TalkBack/Switch Access)
    // dan Testing Tools (Katalon/Appium).
    return Semantics(
      label: "Navigasi ke Kalkulator ${item.name}", // Label deskriptif untuk Screen Reader
      identifier: item.keyId, // ID Stabil untuk Katalon Object Spy
      button: true,
      child: GestureDetector(
        // Key: Penting untuk Flutter Integration Test (Flutter Driver)
        key: ValueKey(item.keyId), 
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            // Ikon Lingkaran
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Menggunakan withValues (Flutter 3.27+) sesuai referensi Anda
                color: item.color.withValues(alpha: 0.1),
                border: Border.all(
                  color: item.color,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.3),
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
            // Teks Nama Lengkap
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
}