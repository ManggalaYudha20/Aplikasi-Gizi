//lib\src\features\about\presentation\pages\about_page.dart

import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

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
                    Image.asset(
                      'assets/images/about.png',
                      fit: BoxFit.contain,
                      width: double.infinity,
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
