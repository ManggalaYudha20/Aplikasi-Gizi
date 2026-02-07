import 'package:flutter/material.dart';

/// Mixin untuk menangani logika zooming pada TransformationController.
/// Digunakan pada State kelas yang memiliki InteractiveViewer.
mixin ZoomInteractionMixin<T extends StatefulWidget> on State<T> {
  late final TransformationController transformationController;
  
  TapDownDetails? _doubleTapDetails;
  
  // State lokal untuk memantau apakah sedang di-zoom atau tidak
  bool isZoomed = false;

  @override
  void initState() {
    super.initState();
    transformationController = TransformationController();
    transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    transformationController.removeListener(_onTransformChanged);
    transformationController.dispose();
    super.dispose();
  }

  /// Listener untuk mendeteksi perubahan skala zoom.
  /// setState hanya dipanggil jika status bool berubah (optimasi rebuild).
  void _onTransformChanged() {
    final currentScale = transformationController.value.storage[0];
    // Threshold sedikit di atas 1.0 untuk toleransi presisi float
    final bool currentlyZoomed = currentScale > 1.01;

    if (currentlyZoomed != isZoomed) {
      setState(() {
        isZoomed = currentlyZoomed;
      });
    }
  }

  /// Menyimpan posisi tap terakhir untuk referensi titik zoom.
  void handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  /// Menangani logika animasi zoom in/out saat double tap.
  void handleDoubleTap() {
    if (_doubleTapDetails == null) return;

    if (transformationController.value != Matrix4.identity()) {
      // Jika sedang zoom, reset ke ukuran asli
      transformationController.value = Matrix4.identity();
    } else {
      // Jika ukuran asli, zoom in ke titik yang disentuh
      final position = _doubleTapDetails!.localPosition;
      
      const double targetScale = 2.5;
      // Rumus translasi agar titik tap tetap di tengah saat di-zoom
      final x = -position.dx * (targetScale - 1);
      final y = -position.dy * (targetScale - 1);

      final translationMatrix = Matrix4.translationValues(x, y, 0.0);
      final scaleMatrix = Matrix4.diagonal3Values(targetScale, targetScale, 1.0);
      
      transformationController.value = translationMatrix..multiply(scaleMatrix);
    }
  }
}