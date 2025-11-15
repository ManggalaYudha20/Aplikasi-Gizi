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
  late final TransformationController _transformationController;
  TapDownDetails? _doubleTapDetails;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final currentScale = _transformationController.value.storage[0];

    final isZoomed = currentScale > 1.01;

    if (isZoomed != _isZoomed) {
      setState(() {
        _isZoomed = isZoomed;
      });
    }
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_doubleTapDetails == null) return;

    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      const double scale = 2.5;
      final x = -position.dx * (scale - 1);
      final y = -position.dy * (scale - 1);

      final translationMatrix = Matrix4.translationValues(x, y, 0.0);
      final scaleMatrix = Matrix4.diagonal3Values(scale, scale, 1.0);
      _transformationController.value = translationMatrix..multiply(scaleMatrix);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Tentang Kami',
        subtitle: 'Profil Rumah Sakit',
      ),

      body: FadeInTransition(
        child: SingleChildScrollView(
          child: InteractiveViewer(
            transformationController: _transformationController,
            
            panEnabled: _isZoomed, 
            
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 1.0, 
            maxScale: 4.0,            
            
            child: GestureDetector(
              onDoubleTapDown: _handleDoubleTapDown,
              onDoubleTap: _handleDoubleTap,
              
              child: Image.asset(
                'assets/images/about.png',
                fit: BoxFit.fitWidth,
                width: MediaQuery.of(context).size.width, 
              ),
            ),
          ),
        ),
      ),
    );
  }
}