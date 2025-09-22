import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/presentation/pages/disease_calculation_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/formula_calculation_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/menu_button.dart';

class NutritionInfoPage extends StatelessWidget {
  const NutritionInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(150, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Informasi Gizi',
        subtitle: 'di Aplikasi MyGizi',
      ),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Disease Calculation Button
                  MenuButton(
                    text: 'Hitung Gizi\n Penyakit',
                    icon: Icons.medical_services,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DiseaseCalculationPage(),
                        ),
                      );
                    },
                  ),

                  // Food Database Button
                  MenuButton(
                    text: 'Database\nMakanan',
                    icon: Icons.food_bank,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FoodListPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // PDF Leaflets Button
                  MenuButton(
                    text: 'Leaflet\nEdukasi Gizi',
                    icon: Icons.picture_as_pdf,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LeafletListPage(),
                        ),
                      );
                    },
                  ),
                 

                  // Formula Calculation Button
                  MenuButton(
                    text: 'Kalkulator\nGizi',
                    icon: Icons.calculate,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const FormulaCalculationPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              
            ],
          ),
        ),
      ),
    );
  }
}
