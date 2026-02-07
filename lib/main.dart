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
import 'package:aplikasi_diagnosa_gizi/src/features/account/pages/account_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/statistics_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/services/user_service.dart';
import 'package:firebase_performance/firebase_performance.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GiziQ by RSUD Prov.Sulut',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 0, 148, 68),
        ),
      ),
      locale: const Locale('id', 'ID'),
      supportedLocales: const [Locale('id', 'ID')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

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
            body: Center(child: CircularProgressIndicator()),
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
  int _currentIndex = 0;
  String _userRole = 'tamu';
  bool _isLoading = true;

  // List yang akan diisi secara dinamis berdasarkan role
  List<Widget> _activePages = [];
  List<BottomNavigationBarItem> _activeNavItems = [];

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndSetupMenu();
  }

  // Fungsi baru untuk mengambil role dan setup menu
  Future<void> _fetchUserRoleAndSetupMenu() async {
  // 1. Mulai Trace
  final Trace trace = FirebasePerformance.instance.newTrace('fetch_user_role');
  await trace.start();

  try {
    final userService = UserService(); //
    final role = await userService.getUserRole(); //

    if (mounted) {
      setState(() {
        _userRole = role ?? 'tamu';
        _setupNavigationMenu(); 
        _isLoading = false;
      });
    }
  } finally {
    // 2. Hentikan Trace (selalu di dalam finally agar terekam meski error)
    await trace.stop();
  }
}
  void _setupNavigationMenu() {
    final authService = AuthService();
    final userService = UserService();
    // 1. Definisi SEMUA halaman (Urutan Wajib Sama dengan Nav Items)
    final allPages = [
      NutritionInfoPage(userRole: _userRole), // Index 0: Beranda
      const PatientHomePage(), // Index 1: Daftar Pasien
      const StatisticsPage(), // Index 2: Statistik
      AccountPage(
        authService: authService,
        userService: userService,
      ), // Index 3: Akun
    ];

    // 2. Definisi SEMUA item navbar (Urutan Wajib Sama dengan Pages)
    final allNavItems = [
      const BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
      const BottomNavigationBarItem(
        icon: Icon(Icons.folder_shared),
        label: 'Daftar Pasien',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.pie_chart),
        label: 'Statistik',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profil Akun',
      ),
    ];

    // 3. LOGIKA FILTER
    if (_userRole == 'tamu') {
      // Jika tamu: Hanya ambil Beranda (0) dan Akun (3)
      _activePages = [allPages[0], allPages[3]];
      _activeNavItems = [allNavItems[0], allNavItems[3]];
    } else {
      // Jika admin/ahli_gizi: Ambil semua
      _activePages = allPages;
      _activeNavItems = allNavItems;
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Pastikan index tidak error saat role berubah (misal dari 4 menu jadi 2 menu)
    final safeIndex = _currentIndex >= _activePages.length ? 0 : _currentIndex;

    return Scaffold(
      body: _activePages.isNotEmpty
          ? _activePages[safeIndex]
          : const Center(child: Text("Tidak ada halaman akses")),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: safeIndex,
        onTap: _onTabTapped,
        items: _activeNavItems, // Kirim item yang sudah difilter
      ),
    );
  }
}
