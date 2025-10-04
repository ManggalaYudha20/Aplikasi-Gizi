// lib/src/shared/widgets/scaffold_with_animated_fab.dart

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Sebuah Scaffold yang secara otomatis menampilkan dan menyembunyikan
/// sebuah widget (biasanya tombol aksi) berdasarkan arah scroll.
class ScaffoldWithAnimatedFab extends StatefulWidget {
  final Widget body;
  final Widget floatingActionButton;
  final PreferredSizeWidget? appBar;
  final Color? backgroundColor;

  const ScaffoldWithAnimatedFab({
    super.key,
    required this.body,
    required this.floatingActionButton,
    this.appBar,
    this.backgroundColor,
  });

  @override
  State<ScaffoldWithAnimatedFab> createState() => _ScaffoldWithAnimatedFabState();
}

class _ScaffoldWithAnimatedFabState extends State<ScaffoldWithAnimatedFab> {
  late final ScrollController _scrollController;
  bool _isButtonVisible = true;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
  }

  // Ganti dengan method yang baru ini
  void _scrollListener() {
    // Cek jika scroll berada di paling bawah halaman
    final isAtBottom = _scrollController.position.pixels >= _scrollController.position.maxScrollExtent;

    // Logika untuk menyembunyikan tombol saat scroll ke bawah
    if (_scrollController.position.userScrollDirection == ScrollDirection.reverse) {
      if (_isButtonVisible && !isAtBottom) { // Tambahkan kondisi !isAtBottom
        setState(() => _isButtonVisible = false);
      }
    }

    // Logika untuk menampilkan tombol saat scroll ke atas ATAU saat di paling bawah
    if (_scrollController.position.userScrollDirection == ScrollDirection.forward || isAtBottom) {
      if (!_isButtonVisible) {
        setState(() => _isButtonVisible = true);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.appBar,
      backgroundColor: widget.backgroundColor,
      body: Stack(
        children: [
          // 1. Konten utama yang bisa di-scroll
          SingleChildScrollView(
            controller: _scrollController,
            // Menambahkan padding bawah agar tidak tertutup tombol
            padding: const EdgeInsets.only(bottom: 100.0),
            child: widget.body,
          ),

          // 2. Tombol Aksi Floating Beranimasi
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            bottom: _isButtonVisible ? 16.0 : -100.0, // Posisi tombol
            left: 16.0,
            right: 16.0,
            child: widget.floatingActionButton,
          ),
        ],
      ),
    );
  }
}