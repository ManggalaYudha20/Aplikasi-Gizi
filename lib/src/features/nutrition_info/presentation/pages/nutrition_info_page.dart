import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class NutritionInfoPage extends StatelessWidget {
  const NutritionInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Info Gizi',
        subtitle: 'di aplikasi my gizi',
      ),
      body: const Center(
        child: Text(
          'Info Gizi Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}