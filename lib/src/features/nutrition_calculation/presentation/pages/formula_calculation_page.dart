import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

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
        'name': 'Harris\nBenedict',
        'fullName': 'Harris Benedict',
        'icon': Icons.person,
        'color': Colors.green,
        'route': '/harris-benedict-form',
      },
      {
        'name': 'BMR',
        'fullName': 'Basal Metabolic Rate',
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
        'route': '/bmr-form',
      },
      {
        'name': 'TEE',
        'fullName': 'Total Energy Expenditure',
        'icon': Icons.battery_charging_full,
        'color': Colors.purple,
        'route': '/tee-form',
      },
      {
        'name': 'Protein',
        'fullName': 'Kebutuhan Protein',
        'icon': Icons.egg,
        'color': Colors.red,
        'route': '/protein-form',
      },
      {
        'name': 'Lemak',
        'fullName': 'Kebutuhan Lemak',
        'icon': Icons.water_drop,
        'color': Colors.brown,
        'route': '/fat-form',
      },
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Perhitungan Formula',
        subtitle: 'di Aplikasi MyGizi',
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Pilih Formula Perhitungan',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
    
              const SizedBox(height: 30),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1,
                  ),
                  itemCount: formulas.length,
                  itemBuilder: (context, index) {
                    final formula = formulas[index];
                    return GestureDetector(
                      onTap: () {
                        // Navigate to respective form page
                        _navigateToFormulaForm(context, formula['route'], formula['fullName']);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
      ),
    );
  }

  void _navigateToFormulaForm(BuildContext context, String route, String title) {
    // For now, show a dialog with the formula name
    // In a real app, you would navigate to specific form pages
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Formula: $title'),
        content: Text('Navigasi ke halaman input untuk $title akan diimplementasikan.'),
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