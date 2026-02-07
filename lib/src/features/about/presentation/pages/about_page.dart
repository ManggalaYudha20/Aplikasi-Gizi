import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/fade_in_transition.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/about/presentation/widgets/zoomable_image_widget.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  // Konfigurasi Konstanta (Clean Configuration)
  static const String _pageTitle = 'Tentang Kami';
  static const String _pageSubtitle = 'Profil Rumah Sakit';
  static const String _aboutImageAsset = 'assets/images/about.png';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: _pageTitle,
        subtitle: _pageSubtitle,
      ),
      body: const FadeInTransition(
        child: SingleChildScrollView(
          // Menggunakan widget yang sudah di-abstraksi
          child: ZoomableImageWidget(
            assetPath: _aboutImageAsset,
          ),
        ),
      ),
    );
  }
}