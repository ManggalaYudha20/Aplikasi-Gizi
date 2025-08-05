import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class DiseaseCalculationPage extends StatelessWidget {
  const DiseaseCalculationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Perhitungan Penyakit',
        subtitle: 'di Aplikasi MyGizi',
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Disease Calculation Screen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}