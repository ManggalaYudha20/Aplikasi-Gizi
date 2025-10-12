// lib/src/shared/widgets/fade_in_transition.dart

import 'package:flutter/material.dart';

class FadeInTransition extends StatefulWidget {
  // Widget yang akan kita animasikan
  final Widget child;
  // Durasi animasi, bisa diatur saat memanggil widget ini
  final Duration duration;

  const FadeInTransition({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 600), // Durasi default 600ms
  });

  @override
  State<FadeInTransition> createState() => _FadeInTransitionState();
}

class _FadeInTransitionState extends State<FadeInTransition>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration, // Menggunakan durasi dari properti widget
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Terapkan animasi pada widget 'child' yang diberikan
    return FadeTransition(
      opacity: _fadeAnimation,
      child: widget.child,
    );
  }
}