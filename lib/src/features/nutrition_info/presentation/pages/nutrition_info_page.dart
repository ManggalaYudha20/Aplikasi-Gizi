import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class NutritionInfoPage extends StatelessWidget {
  const NutritionInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(56, 217, 217, 217),
      appBar: const CustomAppBar(
        title: 'Informasi Gizi',
        subtitle: 'di Aplikasi MyGizi',
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Info Gizi Screen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}