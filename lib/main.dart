//lib\main.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/bottom_navbar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/patient_home_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_info/presentation/pages/nutrition_info_page.dart';
import 'package:aplikasi_diagnosa_gizi/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/login_screen.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account/account_page.dart';

void main() async {
  // Pastikan Flutter binding sudah siap
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: const AuthWrapper(),
    );
  }
}

// WIDGET BARU: Untuk mengecek status otentikasi
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    return StreamBuilder<User?>(
      // Dengarkan perubahan status auth dari AuthService
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Selama proses pengecekan, tampilkan loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Jika snapshot memiliki data (user tidak null), berarti sudah login
        if (snapshot.hasData) {
          return const MainScreen();
        }
        
        // Jika tidak ada data, arahkan ke halaman login
        return const LoginScreen();
      },
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
    PatientHomePage(),
    NutritionInfoPage(),
    AccountPage(),
  ];

   // 2. TAMBAHKAN initState
  @override
  void initState() {
    super.initState();
    // `addPostFrameCallback` akan menjalankan kode ini setelah frame pertama selesai dirender.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 3. SECARA PROGRAMATIS PINDAH KE INDEKS 1
      // Ini adalah cara yang aman untuk mengatur state awal yang non-default.
      setState(() {
        _currentIndex = 1;
      });
    });
  }

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
