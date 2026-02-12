import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'diabetes_calculation_page.dart';
import 'kidney_calculation_page.dart';

/// Model konfigurasi menu penyakit
/// Memudahkan penambahan menu baru dan mendukung testing ID
class _DiseaseMenu {
  final String keyId;      // ID Unik untuk QA Automation
  final String name;       // Nama singkat (icon label)
  final String fullName;   // Nama lengkap (bawah icon)
  final IconData icon;
  final Color color;
  final Widget Function(String role)? pageBuilder; // Builder halaman tujuan

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

  const DiseaseCalculationPage({
    super.key,
    required this.userRole, 
  });

  // Data Menu didefinisikan sebagai List Model agar Type-Safe dan Terstruktur
  List<_DiseaseMenu> get _menuItems => [
        _DiseaseMenu(
          keyId: 'btn_disease_diabetes', // Key unik untuk testing
          name: 'Diabetes',
          fullName: 'Diabetes Melitus',
          icon: Icons.medication,
          color: Colors.blue,
          pageBuilder: (role) => DiabetesCalculationPage(userRole: role),
        ),
        _DiseaseMenu(
          keyId: 'btn_disease_kidney', // Key unik untuk testing
          name: 'Ginjal',
          fullName: 'Ginjal Kronis',
          icon: Icons.water_drop,
          color: Colors.green,
          pageBuilder: (role) => KidneyCalculationPage(userRole: role),
        ),
        // Contoh jika ingin menambah penyakit baru di masa depan:
        /*
        _DiseaseMenu(
          keyId: 'btn_disease_jantung',
          name: 'Jantung',
          fullName: 'Jantung Koroner',
          icon: Icons.favorite,
          color: Colors.red,
          pageBuilder: (role) => HeartCalculationPage(userRole: role),
        ),
        */
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Hitung Diet Penyakit',
        subtitle: 'Pilih Jenis Diet Penyakit',
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16.0), // Padding agar tidak mepet layar
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return _buildMenuCard(context, item);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, _DiseaseMenu item) {
    // 1. Semantics untuk Automation Tool agar bisa membaca label tombol
    return Semantics(
      label: item.fullName,
      identifier: item.keyId, // Identifier untuk iOS Accessibility / Appium
      button: true,
      child: GestureDetector(
        // 2. Key Unik untuk Automation (Flutter Driver / Integration Test)
        key: ValueKey(item.keyId),
        onTap: () => _handleNavigation(context, item),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10), // Menyesuaikan spacing agar seimbang
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: item.color.withValues(alpha:0.1), // Menggunakan withOpacity agar kompatibel
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

  // Logic Navigation yang Refactored (Dynamic)
  void _handleNavigation(BuildContext context, _DiseaseMenu item) {
    if (item.pageBuilder != null) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              item.pageBuilder!(userRole),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Animasi Slide seperti pada kode asli
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            );
          },
        ),
      );
    } else {
      // Fallback jika halaman belum diimplementasikan
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Penyakit: ${item.name}'),
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