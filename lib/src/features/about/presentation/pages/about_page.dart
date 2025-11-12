//lib\src\features\about\presentation\pages\about_page.dart

import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  // --- PERUBAHAN 2: Buat TransformationController ---
  late final TransformationController _transformationController;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    // Jangan lupa dispose controller untuk menghindari memory leak
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Tentang Kami',
        subtitle: 'Profil Rumah Sakit',
      ),
      body: SafeArea(
        child: FadeInTransition(
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 1.0, // Skala zoom minimum
                        maxScale: 5.0, // Skala zoom maksimum (bisa diatur)
                        child: GestureDetector(
                          onDoubleTap: () {
                            setState(() {
                              _transformationController.value =
                                  Matrix4.identity();
                            });
                          },
                          child: Image.asset(
                            'assets/images/about.png',
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
