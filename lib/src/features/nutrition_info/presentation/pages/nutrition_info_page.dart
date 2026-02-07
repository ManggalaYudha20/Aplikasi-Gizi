//lib\src\features\nutrition_info\presentation\pages\nutrition_info_page.dart

import 'package:aplikasi_diagnosa_gizi/src/features/admin/pages/user_management_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/presentation/pages/disease_calculation_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/formula_calculation_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/menu_button.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/about/presentation/pages/about_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/reference_page.dart';

class NutritionInfoPage extends StatelessWidget {
  final String userRole;

 const NutritionInfoPage({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'text': 'Hitung Diet\nPenyakit',
        'icon': Icons.medical_services,
        'page': DiseaseCalculationPage(userRole: userRole),
      },
      {
        'text': 'Daftar\nMakanan',
        'icon': Icons.food_bank,
        'page': const FoodListPage(),
      },
      {
        'text': 'Leaflet\nEdukasi Gizi',
        'icon': Icons.picture_as_pdf,
        'page': const LeafletListPage(),
      },
      {
        'text': 'Kalkulator\nGizi',
        'icon': Icons.calculate,
        'page': FormulaCalculationPage(userRole: userRole),
      },
      {
        'text': 'Tentang\n Kami',
        'icon': Icons.info,
        'page': const AboutPage(),
      },
      {
        'text': 'Referensi',
        'icon': Icons.menu_book,
        'page': const ReferencePage(),
      },
    ];

    if (userRole == 'admin') {
      menuItems.add({
        'text': 'Manajemen\n Pengguna',
        'icon': Icons.manage_accounts, // Icon yang sesuai
        'page': const UserManagementPage(),
      });
    }

    return Scaffold(
      backgroundColor: const Color.fromARGB(150, 255, 255, 255),
      appBar: const CustomAppBar(title: 'Beranda', subtitle: ''),
      body: SafeArea(
        child: FadeInTransition(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: GridView.builder(
                // Padding di sekitar grid
                shrinkWrap: true,
                padding: const EdgeInsets.all(24.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Menampilkan 2 item per baris
                  crossAxisSpacing: 20, // Jarak horizontal antar item
                  mainAxisSpacing: 20, // Jarak vertikal antar item
                  childAspectRatio: 1.0, // Membuat item berbentuk persegi
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return MenuButton(
                    text: item['text'] as String,
                    icon: item['icon'] as IconData,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => item['page'] as Widget,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
