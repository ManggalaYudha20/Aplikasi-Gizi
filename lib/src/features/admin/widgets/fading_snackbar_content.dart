import 'dart:async'; // Perlu import ini untuk Timer
import 'package:flutter/material.dart';

class FadingSnackBarContent extends StatefulWidget {
  final String message;
  final Color color;
  final Duration totalDuration;
  final Duration fadeDuration;

  const FadingSnackBarContent({
    super.key,
    required this.message,
    required this.color,
    required this.totalDuration,
    required this.fadeDuration,
  });

  @override
  State<FadingSnackBarContent> createState() => _FadingSnackBarContentState();
}

class _FadingSnackBarContentState extends State<FadingSnackBarContent> {
  double _opacity = 1.0;
  Timer? _timer; // Simpan timer agar bisa dibatalkan jika perlu

  @override
  void initState() {
    super.initState();
    // Hitung kapan animasi fade out harus dimulai
    final startFadeTime = widget.totalDuration - widget.fadeDuration;

    _timer = Timer(startFadeTime, () {
      if (mounted) {
        setState(() {
          _opacity = 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // Bersihkan timer saat widget dihancurkan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: widget.fadeDuration,
      curve: Curves.easeOut,
      child: Container(
        // Margin dihapus di sini karena biasanya diatur oleh SnackBar parent,
        // tapi jika ingin padding internal custom, bisa disesuaikan.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          widget.message,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}