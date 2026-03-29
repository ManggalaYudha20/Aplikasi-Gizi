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
import 'package:aplikasi_diagnosa_gizi/src/features/reference/presentation/pages/reference_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/consultation/presentation/pages/consultation_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/adult_quick_calc_page.dart';

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

    if (userRole == 'admin' ||
        userRole == 'ahli_gizi' ||
        userRole == 'nutrisionis') {
      // Sisipkan di urutan paling awal (index 0) agar posisinya tetap di atas kiri
      items.insert(
        0,
        _MenuConfig(
          id: 'kalkulator_penyakit',
          label: 'Hitung Diet Penyakit',
          icon: Icons.medical_services,
          destinationPage: DiseaseCalculationPage(userRole: userRole),
          semanticsLabel: 'Tombol masuk ke halaman kalkulator penyakit',
        ),
      );
    }

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
        _MenuConfig(
          id: 'konsultasi',
          label: 'Konsultasi Gizi',
          icon: Icons.person_2,
          destinationPage: const ConsultationPage(),
          semanticsLabel: 'Tombol masuk ke halaman konsultasi gizi',
        ),
      ]);
    }

    return items;
  }

  // WIDGET BARU: Banner Hitung Cepat
  Widget _buildQuickCalcBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              const Icon(Icons.add, color: Colors.blue, size: 24),
              const SizedBox(width: 8),
              Text(
                'Hitung Kebutuhan Gizi',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Tombol Pilihan
          Row(
            children: [
              // Card Dewasa
              Expanded(
                child: _buildQuickCalcCard(
                  title: 'Dewasa',
                  icon: Icons
                      .face, // Ganti ke Image.asset('path/gambar.png') jika ada ilustrasi
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
              const SizedBox(width: 12),
              // Card Anak
              Expanded(
                child: _buildQuickCalcCard(
                  title: 'Anak',
                  icon: Icons
                      .child_care, // Ganti ke Image.asset('path/gambar.png') jika ada ilustrasi
                  iconColor: Colors.green[300]!,
                  bgColor: Colors.green[50]!,
                  buttonColor: Colors.green,
                  onTap: () {
                    // TODO: Tambahkan navigasi ke Hitung Cepat Anak
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Menuju Kalkulator Anak...'),
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

  // WIDGET BARU: Item Card untuk Dewasa / Anak
  Widget _buildQuickCalcCard({
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
              const SizedBox(height: 16),
              // Ilustrasi
              Icon(icon, size: 50, color: iconColor),
              const SizedBox(height: 8),
              // Judul
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: buttonColor.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(height: 16),
              // Tombol bawah
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right,
                      color: Colors.white,
                      size: 18,
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
                      child: _buildQuickCalcBanner(context),
                    ),

                    // Grid Menu yang sudah ada sebelumnya
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Scroll sudah di-handle oleh SingleChildScrollView
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                        vertical: 24.0,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(screenWidth),
                        crossAxisSpacing: gridSpacing,
                        mainAxisSpacing: gridSpacing,
                        childAspectRatio: 1.0,
                      ),
                      itemCount: menuItems.length,
                      itemBuilder: (context, index) {
                        final item = menuItems[index];

                        return Semantics(
                          label: item.semanticsLabel,
                          button: true,
                          enabled: true,
                          identifier: 'btn_${item.id}',
                          child: MenuButton(
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
