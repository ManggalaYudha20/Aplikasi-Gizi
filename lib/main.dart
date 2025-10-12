//lib\main.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/bottom_navbar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/home/presentation/pages/home_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_info/presentation/pages/nutrition_info_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/about/presentation/pages/about_page.dart';
import 'package:aplikasi_diagnosa_gizi/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aplikasi_diagnosa_gizi/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Future<FirebaseApp> _initialization = Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RSUD MyGizi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 148, 68),
        ),
      ),
      home: FutureBuilder(
        future: _initialization,
        builder: (context, snapshot) {
          // Jika proses inisialisasi selesai dan berhasil
          if (snapshot.connectionState == ConnectionState.done) {
            // Cek jika ada error
            if (snapshot.hasError) {
              // Tampilkan halaman error jika inisialisasi gagal
              return const Scaffold(
                body: Center(child: Text('Gagal terhubung ke server')),
              );
            }
            // Arahkan ke LoginScreen jika berhasil
            return const LoginScreen();
          }

          // Tampilkan loading indicator selama proses inisialisasi
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 1;

  final List<Widget> _screens = const [
    HomePage(),
    NutritionInfoPage(),
    AboutPage(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
