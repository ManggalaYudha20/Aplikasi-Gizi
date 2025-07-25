import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Tentang Kami',
        subtitle: 'di Aplikasi MyGizi',
      ),
      body: const Center(
        child: Text(
          'Tentang Kami Screen',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}