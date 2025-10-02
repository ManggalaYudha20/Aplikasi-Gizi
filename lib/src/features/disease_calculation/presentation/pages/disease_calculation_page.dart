import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'diabetes_calculation_page.dart';
import 'kidney_calculation_page.dart';

class DiseaseCalculationPage extends StatelessWidget {
  const DiseaseCalculationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> diseases = [
      {
        'name': 'Diabetes',
        'fullName': 'Diabetes Melitus',
        'icon': Icons.medication,
        'color': Colors.blue,
        'route': '/diabetes-form',
      },
      {
        'name': 'Ginjal',
        'fullName': 'Ginjal Kronis',
        'icon': Icons.water_drop,
        'color': Colors.green,
        'route': '/kidney-form',
      },
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Hitung Gizi Penyakit',
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
                itemCount: diseases.length,
                itemBuilder: (context, index) {
                  final disease = diseases[index];
                  return GestureDetector(
                    onTap: () {
                      // Navigate to respective form page
                      _navigateToDiseaseForm(
                        context,
                        disease['route'],
                        disease['fullName'],
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
                            color: disease['color'].withOpacity(0.1),
                            border: Border.all(
                              color: disease['color'],
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: disease['color'].withOpacity(0.3),
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
                                  disease['icon'],
                                  size: 30,
                                  color: disease['color'],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  disease['name'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: disease['color'],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          disease['fullName'],
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

  void _navigateToDiseaseForm(
    BuildContext context,
    String route,
    String title,
  ) {
    if (route == '/diabetes-form') {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const DiabetesCalculationPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
    } else if (route == '/kidney-form') { // <-- TAMBAHKAN KONDISI INI
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const KidneyCalculationPage(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
      // For other diseases, show dialog for now
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Penyakit: $title'),
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