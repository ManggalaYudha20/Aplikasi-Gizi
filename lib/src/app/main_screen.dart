// lib/src/app/main_screen.dart
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/bottom_navbar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/patient_home_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_info/presentation/pages/nutrition_info_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/account/pages/account_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/statistics/statistics_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/services/user_service.dart';
import 'package:firebase_performance/firebase_performance.dart';

/// Breakpoint sederhana — layar ≥ 600 dp dianggap tablet / landscape.
const double _kTabletBreakpoint = 600;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  String _userRole = 'tamu';
  bool _isLoading = true;

  // Service dibuat sekali — tidak perlu dibuat ulang tiap build/setState
  final _authService = AuthService();
  final _userService = UserService();

  List<Widget> _activePages = [];
  List<BottomNavigationBarItem> _activeNavItems = [];

  @override
  void initState() {
    super.initState();
    _fetchUserRoleAndSetupMenu();
  }

  Future<void> _fetchUserRoleAndSetupMenu() async {
    // Firebase Performance Trace — logika tidak diubah
    final Trace trace =
        FirebasePerformance.instance.newTrace('fetch_user_role');
    await trace.start();

    try {
      final role = await _userService.getUserRole();

      if (mounted) {
        setState(() {
          _userRole = role ?? 'tamu';
          _setupNavigationMenu();
          _isLoading = false;
        });
      }
    } finally {
      await trace.stop();
    }
  }

  void _setupNavigationMenu() {
    // Halaman & item didefinisikan di sini (tidak berubah dari semula)
    final allPages = <Widget>[
      NutritionInfoPage(userRole: _userRole), // 0 — Beranda
      const PatientHomePage(),                // 1 — Daftar Pasien
      const StatisticsPage(),                 // 2 — Statistik
      AccountPage(
        authService: _authService,
        userService: _userService,
      ),                                      // 3 — Akun
    ];

    const allNavItems = <BottomNavigationBarItem>[
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
      BottomNavigationBarItem(
        icon: Icon(Icons.folder_shared),
        label: 'Daftar Pasien',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.pie_chart),
        label: 'Statistik',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Profil Akun',
      ),
    ];

    // Filter berdasarkan role — logika tidak diubah
    if (_userRole == 'tamu') {
      _activePages = [allPages[0], allPages[3]];
      _activeNavItems = [allNavItems[0], allNavItems[3]];
    } else {
      _activePages = List<Widget>.from(allPages);
      _activeNavItems = List<BottomNavigationBarItem>.from(allNavItems);
    }
  }

  void _onTabTapped(int index) {
    // Hindari setState kalau index tidak berubah
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Guard: pastikan index valid setelah perubahan role
    final safeIndex =
        _currentIndex >= _activePages.length ? 0 : _currentIndex;

    // LayoutBuilder → deteksi lebar layar untuk tata-letak responsif
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth >= _kTabletBreakpoint;

        if (isTablet) {
          // ── Tablet / landscape ──────────────────────────────────────────
          // Gunakan NavigationRail di sisi kiri + konten di kanan.
          // Tata letak halaman konten TIDAK berubah sama sekali.
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: safeIndex,
                    onDestinationSelected: _onTabTapped,
                    // Tampilkan label di bawah icon pada tablet
                    labelType: NavigationRailLabelType.all,
                    destinations: _activeNavItems
                        .map(
                          (item) => NavigationRailDestination(
                            icon: item.icon,
                            label: Text(item.label ?? ''),
                          ),
                        )
                        .toList(),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  // Expanded agar konten mengisi sisa lebar layar
                  Expanded(
                    child: _activePages.isNotEmpty
                        ? _activePages[safeIndex]
                        : const Center(child: Text('Tidak ada halaman akses')),
                  ),
                ],
              ),
            ),
          );
        }

        // ── Ponsel / portrait ────────────────────────────────────────────
        // Tata letak asli dengan BottomNavigationBar tidak berubah.
        return Scaffold(
          body: _activePages.isNotEmpty
              ? _activePages[safeIndex]
              : const Center(child: Text('Tidak ada halaman akses')),
          bottomNavigationBar: CustomBottomNavBar(
            currentIndex: safeIndex,
            onTap: _onTabTapped,
            items: _activeNavItems,
          ),
        );
      },
    );
  }
}