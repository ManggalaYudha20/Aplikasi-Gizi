import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bmi_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bmr_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/tdee_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bbi_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/nutrition_status_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/imtu_form_page.dart';

class FormulaCalculationPage extends StatelessWidget {
  const FormulaCalculationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> formulas = [
      {
        'name': 'IMT',
        'fullName': 'Indeks Massa Tubuh',
        'icon': Icons.calculate,
        'color': Colors.blue,
        'route': '/imt-form',
      },
      {
        'name': 'BMR',
        'fullName': 'Basal Metabolic Rate',
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
        'route': '/bmr-form',
      },
      {
        'name': 'TDEE',
        'fullName': 'Total Daily\nEnergy Expenditure',
        'icon': Icons.battery_charging_full,
        'color': Colors.purple,
        'route': '/tee-form',
      },

      {
        'name': 'BBI',
        'fullName': 'Berat Badan Ideal\n (Usia > 18 Tahun)',
        'icon': Icons.monitor_weight,
        'color': Colors.green,
        'route': '/bbi-form',
      },
      
      {
        'name': 'Status Gizi',
        'fullName': 'Status Gizi\n (Usia 0-60 Bulan)',
        'icon': Icons.child_care,
        'color': Colors.red,
        'route': '/statusgizi-form',
      },
      
      {
        'name': 'IMT/U',
        'fullName': 'Indeks Massa Tubuh\nBerdasarkan Usia (5-18 Tahun)',
        'icon': Icons.calculate,
        'color': Colors.brown,
        'route': '/imtu-form',
      },
      
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Kalkulator Gizi',
        subtitle: 'di Aplikasi MyGizi',
      ),
      body: SafeArea(
        child: Column(
          
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 1,
                ),
                itemCount: formulas.length,
                itemBuilder: (context, index) {
                  final formula = formulas[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to respective form page
                      _navigateToFormulaForm(
                        context,
                        formula['route'],
                        formula['fullName'],
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: formula['color'].withOpacity(0.1),
                            border: Border.all(
                              color: formula['color'],
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: formula['color'].withOpacity(0.3),
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
                                  formula['icon'],
                                  size: 30,
                                  color: formula['color'],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formula['name'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: formula['color'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formula['fullName'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToFormulaForm(
    BuildContext context,
    String route,
    String title,
  ) {
    if (route == '/imt-form') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
            const BmiFormPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
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
    } else if (route == '/bmr-form') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
            const BmrFormPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
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
    } else if (route == '/tee-form') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
            const TdeeFormPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
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
    } else if (route == '/bbi-form') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
            const BbiFormPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
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
    } else if (route == '/statusgizi-form') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
            const NutritionStatusFormPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
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
    } else if (route == '/imtu-form') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
            const IMTUFormPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
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
      // For other routes, show dialog (placeholder)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Formula: $title'),
          content: Text(
            'Navigasi ke halaman input untuk $title akan diimplementasikan.',
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
