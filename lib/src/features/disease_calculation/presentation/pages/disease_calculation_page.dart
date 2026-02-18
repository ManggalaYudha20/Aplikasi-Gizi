import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'diabetes_calculation_page.dart';
import 'kidney_calculation_page.dart';

/// Model konfigurasi menu penyakit — immutable & type-safe.
/// Seluruh field bersifat final agar aman di-cache sebagai static const List.
@immutable
class _DiseaseMenu {
  final String keyId;
  final String name;
  final String fullName;
  final IconData icon;
  final Color color;
  final Widget Function(String role)? pageBuilder;

  const _DiseaseMenu({
    required this.keyId,
    required this.name,
    required this.fullName,
    required this.icon,
    required this.color,
    this.pageBuilder,
  });
}

class DiseaseCalculationPage extends StatelessWidget {
  final String userRole;

  const DiseaseCalculationPage({super.key, required this.userRole});

  /// OPTIMASI: Dipindah ke static const agar List ini hanya dibuat
  /// SEKALI selama siklus hidup aplikasi, bukan setiap rebuild widget.
  /// PageBuilder berupa closure sehingga tetap lazy — tidak membuat
  /// instance halaman sebelum di-tap.
  static const List<_DiseaseMenu> _menuItems = [
    _DiseaseMenu(
      keyId: 'btn_disease_diabetes',
      name: 'Diabetes',
      fullName: 'Diabetes Melitus',
      icon: Icons.medication,
      color: Colors.blue,
      pageBuilder: _buildDiabetesPage,
    ),
    _DiseaseMenu(
      keyId: 'btn_disease_kidney',
      name: 'Ginjal',
      fullName: 'Ginjal Kronis',
      icon: Icons.water_drop,
      color: Colors.green,
      pageBuilder: _buildKidneyPage,
    ),
    // ─── Tambah penyakit baru di sini ───────────────────────────────────
    // _DiseaseMenu(
    //   keyId: 'btn_disease_heart',
    //   name: 'Jantung',
    //   fullName: 'Jantung Koroner',
    //   icon: Icons.favorite,
    //   color: Colors.red,
    //   pageBuilder: _buildHeartPage,
    // ),
    // ────────────────────────────────────────────────────────────────────
  ];

  // Top-level tearoff — kompatibel dengan const List di atas.
  static Widget _buildDiabetesPage(String role) =>
      DiabetesCalculationPage(userRole: role);
  static Widget _buildKidneyPage(String role) =>
      KidneyCalculationPage(userRole: role);

  @override
  Widget build(BuildContext context) {
    // RESPONSIVE: MediaQuery dihitung sekali di sini, diteruskan ke child
    // melalui parameter agar tidak ada pemanggilan MediaQuery berulang
    // di dalam loop GridView.
    final Size screenSize = MediaQuery.sizeOf(context);
    final double screenWidth = screenSize.width;
    final double screenHeight = screenSize.height;

    // Padding responsif: 8% dari lebar layar (smartphone ~28px, tablet ~61px)
    final double gridPadding = screenWidth * 0.08;

    // childAspectRatio: menjaga proporsi kartu tetap "kotak" di semua ukuran.
    // Rumus: (lebar kolom tersedia) / (tinggi yang diinginkan per kartu)
    // Lebar kolom ≈ (screenWidth - 2*padding - spacing) / 2
    final double colWidth = (screenWidth - gridPadding * 2 - 16) / 2;
    final double cardHeight = screenHeight * 0.22; // ≈22% tinggi layar
    final double childAspectRatio = colWidth / cardHeight;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Hitung Diet Penyakit',
        subtitle: 'Pilih Jenis Diet Penyakit',
      ),
      body: SafeArea(
        child: GridView.builder(
          padding: EdgeInsets.all(gridPadding),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // ✅ Tetap 2 kolom — tidak diubah
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio, // ✅ Dinamis
          ),
          itemCount: _menuItems.length,
          itemBuilder: (context, index) {
            final _DiseaseMenu item = _menuItems[index];
            return _DiseaseMenuCard(
              item: item,
              onTap: () => _handleNavigation(context, item),
            );
          },
        ),
      ),
    );
  }

  /// CLEAN CODE: Logika navigasi terpusat & terpisah dari UI.
  /// Mudah di-debug karena hanya satu titik eksekusi untuk semua menu.
  void _handleNavigation(BuildContext context, _DiseaseMenu item) {
    if (item.pageBuilder == null) {
      _showNotImplementedDialog(context, item);
      return;
    }

    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => item.pageBuilder!(userRole),
        transitionsBuilder: (_, animation, __, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
    );
  }

  void _showNotImplementedDialog(BuildContext context, _DiseaseMenu item) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Penyakit: ${item.name}'),
        content: Text(
          'Navigasi ke halaman ${item.fullName} akan segera diimplementasikan.',
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

/// OPTIMASI: Diextract menjadi widget terpisah agar Flutter dapat
/// melakukan reconciliation (diffing) secara efisien — hanya kartu yang
/// berubah yang akan di-rebuild, bukan seluruh GridView.
class _DiseaseMenuCard extends StatelessWidget {
  final _DiseaseMenu item;
  final VoidCallback onTap;

  const _DiseaseMenuCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // ✅ QA AUTOMATION: Semantics memberikan metadata ke Accessibility Tree.
    // Katalon Object Spy menangkap `identifier` sebagai ID elemen yang stabil.
    return Semantics(
      label: item.fullName, // Label deskriptif untuk screen reader
      identifier: item.keyId, // ← ID konsisten untuk Katalon / Appium
      button: true,
      child: GestureDetector(
        key: ValueKey(item.keyId), // ← Key untuk Flutter Integration Test
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withValues(alpha: 0.1),
                border: Border.all(color: item.color, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4), // 
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 30, color: item.color),
                  const SizedBox(height: 4),
                  Text(
                    item.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12, // 
                      fontWeight: FontWeight.bold,
                      color: item.color, //    warna dari model, bukan hardcode
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                item.fullName,
                textAlign: TextAlign.center,
                // OPTIMASI: TextStyle ini benar-benar const karena tidak bergantung
                //    pada warna dinamis — dikompilasi sekali oleh Flutter engine.
                style: const TextStyle(fontSize: 12, color: Colors.black87),
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
