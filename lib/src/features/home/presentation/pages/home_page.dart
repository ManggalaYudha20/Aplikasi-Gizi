import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(56, 217, 217, 217),
      appBar: const CustomAppBar(
        title: 'Selamat Datang',
        subtitle: 'di Aplikasi MyGizi',
      ),
      body: const SafeArea(
        child: Center(
          child: Text(
            'Beranda Screen',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}