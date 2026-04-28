// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\menu_beranda\presentation\pages\nutrition_info_page.dart

import 'package:flutter/material.dart';

// Imports (Dipertahankan sesuai file asli)
import 'package:aplikasi_diagnosa_gizi/src/features/admin/pages/user_management_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/formula_calculation_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/menu_button.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/about/presentation/pages/about_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/presentation/pages/reference_page.dart';
//import 'package:aplikasi_diagnosa_gizi/src/features/consultation/presentation/pages/consultation_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/adult_quick_calc_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/child_quick_calc_page.dart';

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

  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) return 4; // Desktop lebar / Windows besar
    if (screenWidth >= 800) return 3; // Tablet landscape / Windows kecil
    return 2; // Mobile (default)
  }

  /// 1. Clean Code: Memisahkan data menu dari metode build.
  /// Mengembalikan daftar menu berdasarkan role user.
  List<_MenuConfig> _getMenuItems(BuildContext context) {
    final List<_MenuConfig> items = [
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
    ];
    // Logika kondisional role (Admin only)
    if (userRole == 'admin') {
      items.addAll([
        _MenuConfig(
          id: 'manajemen_pengguna',
          label: 'Manajemen Pengguna',
          icon: Icons.manage_accounts_outlined,
          destinationPage: const UserManagementPage(),
          semanticsLabel: 'Tombol masuk ke halaman admin manajemen pengguna',
        ),
        /*_MenuConfig(
          id: 'konsultasi',
          label: 'Konsultasi Gizi',
          icon: Icons.medical_information,
          destinationPage: const ConsultationPage(),
          semanticsLabel: 'Tombol masuk ke halaman konsultasi gizi',
        ),*/
      ]);
    }

    items.addAll([
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
    ]);

    return items;
  }

  // Fungsi pembantu untuk membuat ukuran dinamis
  double _responsiveSize(double sw, {required double base}) {
    if (sw <= 360) return base * 0.90;
    if (sw >= 800) return base * 1.25;
    if (sw >= 600) return base * 1.15;
    return base;
  }

  // WIDGET BARU: Banner Hitung Cepat (Ditambahkan parameter screenWidth)
  Widget _buildQuickCalcBanner(BuildContext context, double screenWidth) {
    return Container(
      padding: EdgeInsets.all(_responsiveSize(screenWidth, base: 16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF009444), // Warna hijau tema aplikasi
          width: 1.5, // Ketebalan garis border
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.add,
                color: Color(0xFF009444),
                size: _responsiveSize(screenWidth, base: 24),
              ),
              SizedBox(width: _responsiveSize(screenWidth, base: 8)),
              Text(
                'Hitung Kebutuhan Gizi',
                style: TextStyle(
                  fontSize: _responsiveSize(screenWidth, base: 18),
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          SizedBox(height: _responsiveSize(screenWidth, base: 16)),
          // Tombol Pilihan
          Row(
            children: [
              // Card Dewasa
              Expanded(
                child: _buildQuickCalcCard(
                  screenWidth: screenWidth,
                  title: 'Dewasa',
                  icon: Icons.face,
                  iconColor: Colors.blue[300]!,
                  bgColor: Colors.blue[50]!,
                  buttonColor: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdultQuickCalcPage(),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: _responsiveSize(screenWidth, base: 12)),
              // Card Anak
              Expanded(
                child: _buildQuickCalcCard(
                  screenWidth: screenWidth,
                  title: 'Anak',
                  icon: Icons.child_care,
                  iconColor: Colors.green[300]!,
                  bgColor: Colors.green[50]!,
                  buttonColor: Colors.green,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChildQuickCalcPage(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // WIDGET BARU: Item Card untuk Dewasa / Anak (Ditambahkan parameter screenWidth)
  Widget _buildQuickCalcCard({
    required double screenWidth,
    required String title,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color buttonColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Column(
            children: [
              SizedBox(height: _responsiveSize(screenWidth, base: 16)),
              // Ilustrasi
              Icon(
                icon,
                size: _responsiveSize(screenWidth, base: 50),
                color: iconColor,
              ),
              SizedBox(height: _responsiveSize(screenWidth, base: 8)),
              // Judul
              Text(
                title,
                style: TextStyle(
                  fontSize: _responsiveSize(screenWidth, base: 16),
                  fontWeight: FontWeight.bold,
                  color: buttonColor.withValues(alpha: 0.8),
                ),
              ),
              SizedBox(height: _responsiveSize(screenWidth, base: 16)),
              // Tombol bawah
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  vertical: _responsiveSize(screenWidth, base: 10),
                ),
                decoration: BoxDecoration(
                  color: buttonColor,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: _responsiveSize(screenWidth, base: 14),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: _responsiveSize(screenWidth, base: 4)),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: _responsiveSize(screenWidth, base: 18),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET BARU: Menu melebar (full-width) dengan icon di kiri
  Widget _buildWideMenuButton(
    BuildContext context,
    _MenuConfig item,
    double screenWidth,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF009444),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item.destinationPage),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(_responsiveSize(screenWidth, base: 16)),
            child: Row(
              children: [
                // Icon di sebelah kiri
                Container(
                  padding: EdgeInsets.all(
                    _responsiveSize(screenWidth, base: 12),
                  ),

                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: _responsiveSize(screenWidth, base: 28),
                  ),
                ),
                SizedBox(width: _responsiveSize(screenWidth, base: 16)),
                // Label Teks
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: _responsiveSize(screenWidth, base: 16),
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Icon panah (opsional, untuk indikasi bisa di-klik)
                Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                  size: _responsiveSize(screenWidth, base: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = _getMenuItems(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'Beranda', subtitle: ''),
      body: SafeArea(
        child: FadeInTransition(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 2. Responsive Design: Kalkulasi dimensi berdasarkan ukuran layar saat ini
              final screenWidth = constraints.maxWidth;

              // Tentukan padding horizontal dinamis (min 16, max 10% lebar layar)
              final double horizontalPadding = (screenWidth * 0.08).clamp(
                16.0,
                64.0,
              );

              // Spacing antar grid item
              final double gridSpacing = (screenWidth * 0.04).clamp(10.0, 30.0);
              // --- LOGIKA PEMISAHAN MENU ---
              int crossAxisCount = _getCrossAxisCount(screenWidth);

              // Mencari tahu apakah ada menu yang "sisa" (tidak pas masuk ke kolom genap)
              int remainder = menuItems.length % crossAxisCount;

              // Jumlah item yang pas dimasukkan ke grid
              int gridItemCount = menuItems.length - remainder;
              List<_MenuConfig> gridItems = menuItems.sublist(0, gridItemCount);
              List<_MenuConfig> wideItems = menuItems.sublist(gridItemCount);

              // PERUBAHAN: Membungkus dengan SingleChildScrollView & Column
              return SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // Widget Banner Hitung Cepat yang ditambahkan
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        horizontalPadding,
                        24.0,
                        horizontalPadding,
                        0,
                      ),
                      // PERUBAHAN: Mengirimkan screenWidth ke dalam banner
                      child: _buildQuickCalcBanner(context, screenWidth),
                    ),

                    if (gridItems.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          24.0,
                          horizontalPadding,
                          12.0,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: gridSpacing,
                          mainAxisSpacing: gridSpacing,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: gridItems.length,
                        itemBuilder: (context, index) {
                          final item = gridItems[index];
                          return Semantics(
                            label: item.semanticsLabel,
                            button: true,
                            enabled: true,
                            identifier: 'btn_${item.id}',
                            child: MenuButton(
                              // Ini tetap menggunakan custom widget bawaan Anda
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

                    // 2. Render List Item yang Sisa (Ganjil) agar melebar di bawah Grid
                    if (wideItems.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          gridItems.isNotEmpty
                              ? 0
                              : 24.0, // Sesuaikan padding jika grid kosong
                          horizontalPadding,
                          24.0,
                        ),
                        child: Column(
                          children: wideItems.map((item) {
                            return Semantics(
                              label: item.semanticsLabel,
                              button: true,
                              enabled: true,
                              child: _buildWideMenuButton(
                                context,
                                item,
                                screenWidth,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
