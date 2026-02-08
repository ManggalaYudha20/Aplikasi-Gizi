// lib/src/features/nutrition_info/presentation/pages/nutrition_info_page.dart

import 'package:flutter/material.dart';

// Imports (Dipertahankan sesuai file asli)
import 'package:aplikasi_diagnosa_gizi/src/features/admin/pages/user_management_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/presentation/pages/disease_calculation_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/formula_calculation_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/menu_button.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/about/presentation/pages/about_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/reference_page.dart';

/// Model privat untuk konfigurasi menu agar lebih terstruktur
class _MenuConfig {
  final String id;
  final String label;
  final IconData icon;
  final Widget destinationPage;
  final String semanticsLabel;

  _MenuConfig({
    required this.id,
    required this.label,
    required this.icon,
    required this.destinationPage,
    required this.semanticsLabel,
  });
}

class NutritionInfoPage extends StatelessWidget {
  final String userRole;

  const NutritionInfoPage({super.key, required this.userRole});

  /// 1. Clean Code: Memisahkan data menu dari metode build.
  /// Mengembalikan daftar menu berdasarkan role user.
  List<_MenuConfig> _getMenuItems(BuildContext context) {
    final List<_MenuConfig> items = [
      _MenuConfig(
        id: 'kalkulator_penyakit',
        label: 'Hitung Diet Penyakit',
        icon: Icons.medical_services,
        destinationPage: DiseaseCalculationPage(userRole: userRole),
        semanticsLabel: 'Tombol masuk ke halaman kalkulator penyakit',
      ),
      _MenuConfig(
        id: 'kalkulator_gizi',
        label: 'Kalkulator Gizi',
        icon: Icons.calculate,
        destinationPage: FormulaCalculationPage(userRole: userRole),
        semanticsLabel: 'Tombol masuk ke halaman rumus perhitungan gizi',
      ),
      _MenuConfig(
        id: 'basis_data_makanan',
        label: 'Daftar Makanan',
        icon: Icons.food_bank,
        destinationPage: const FoodListPage(),
        semanticsLabel: 'Tombol masuk ke daftar basis data makanan',
      ),
      _MenuConfig(
        id: 'leaflet_pdf',
        label: 'Leaflet Edukasi Gizi',
        icon: Icons.picture_as_pdf_outlined,
        destinationPage: const LeafletListPage(),
        semanticsLabel: 'Tombol unduh dan lihat leaflet PDF',
      ),
      _MenuConfig(
        id: 'referensi',
        label: 'Referensi',
        icon: Icons.menu_book,
        destinationPage: const ReferencePage(),
        semanticsLabel: 'Tombol masuk ke halaman daftar referensi',
      ),
      _MenuConfig(
        id: 'tentang',
        label: 'Tentang Kami',
        icon: Icons.info_outline,
        destinationPage: const AboutPage(),
        semanticsLabel: 'Tombol masuk ke halaman informasi aplikasi',
      ),
    ];

    // Logika kondisional role (Admin only)
    if (userRole == 'admin') {
      items.add(
        _MenuConfig(
          id: 'manajemen_pengguna',
          label: 'Manajemen Pengguna',
          icon: Icons.manage_accounts_outlined,
          destinationPage: const UserManagementPage(),
          semanticsLabel: 'Tombol masuk ke halaman admin manajemen pengguna',
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems(context);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Beranda', subtitle: ''),
      body: SafeArea(
        child: FadeInTransition(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 2. Responsive Design: Kalkulasi dimensi berdasarkan ukuran layar saat ini
              final screenWidth = constraints.maxWidth;
              
              // Tentukan padding horizontal dinamis (min 16, max 10% lebar layar)
              final double horizontalPadding = (screenWidth * 0.08).clamp(16.0, 64.0);
              
              // Spacing antar grid item
              final double gridSpacing = (screenWidth * 0.04).clamp(10.0, 30.0);

              return Center(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(), // Mencegah bounce berlebih pada konten sedikit
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding, 
                    vertical: 24.0
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Tetap 2 kolom sesuai instruksi
                    crossAxisSpacing: gridSpacing,
                    mainAxisSpacing: gridSpacing,
                    childAspectRatio: 1.0, // Tetap persegi
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];

                    // 3. QA Automation Readiness: Semantics wrapper & ValueKey
                    return Semantics(
                      label: item.semanticsLabel,
                      button: true, // Memberitahu accessibility tools/Katalon bahwa ini tombol
                      enabled: true,
                      identifier: 'btn_${item.id}', // Identifikasi tambahan untuk accessibility
                      child: MenuButton(
                        // Key unik untuk Object Spy (contoh: 'menu_btn_referensi')
                        key: ValueKey('menu_btn_${item.id}'),
                        text: item.label,
                        icon: item.icon,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => item.destinationPage,
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}