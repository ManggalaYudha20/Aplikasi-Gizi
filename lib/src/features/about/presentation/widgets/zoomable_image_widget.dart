import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/about/presentation/widgets/zoom_interaction_mixin.dart';

/// Widget reusable untuk menampilkan gambar yang bisa di-zoom & pan.
/// Menggunakan [ZoomInteractionMixin] untuk logika interaksinya.
class ZoomableImageWidget extends StatefulWidget {
  final String assetPath;
  final double minScale;
  final double maxScale;

  const ZoomableImageWidget({
    super.key,
    required this.assetPath,
    this.minScale = 1.0,
    this.maxScale = 4.0,
  });

  @override
  State<ZoomableImageWidget> createState() => _ZoomableImageWidgetState();
}

class _ZoomableImageWidgetState extends State<ZoomableImageWidget> 
    with ZoomInteractionMixin {
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return InteractiveViewer(
          transformationController: transformationController,
          // Pan hanya aktif jika gambar sedang di-zoom (UX Standard)
          panEnabled: isZoomed, 
          boundaryMargin: const EdgeInsets.all(20),
          minScale: widget.minScale,
          maxScale: widget.maxScale,
          child: GestureDetector(
            onDoubleTapDown: handleDoubleTapDown,
            onDoubleTap: handleDoubleTap,
            child: Image.asset(
              widget.assetPath,
              fit: BoxFit.fitWidth,
              // Memastikan lebar gambar mengikuti parent
              width: constraints.maxWidth, 
            ),
          ),
        );
      },
    );
  }
}