//lib\src\login\login_screen.dart
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/version_info_app.dart';
import 'package:aplikasi_diagnosa_gizi/main.dart';

// 1. Ubah menjadi StatefulWidget
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

// 2. Tambahkan SingleTickerProviderStateMixin untuk animasi
class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // 3. Deklarasikan AnimationController dan Animation
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 4. Inisialisasi controller dan animasi
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // Atur durasi fade in
    );

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // 5. Mulai animasi saat halaman dimuat
    _controller.forward();
  }

  @override
  void dispose() {
    // 6. Hapus controller untuk mencegah memory leak
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan ukuran layar untuk penyesuaian responsif
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // Menggunakan warna abu-abu muda untuk background utama
      backgroundColor: const Color(0xFFF5F5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            _buildGreenBackground(screenHeight, screenWidth),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 2),
                    // Kartu putih yang berisi logo dan teks selamat datang
                    _buildLoginCard(context),
                    const SizedBox(height: 40),
                    // Tombol untuk login dengan Google
                    const SizedBox(height: 50),
                    _buildGoogleLoginButton(context),
                    const Spacer(flex: 2),
                    // Teks copyright di bagian bawah
                    _buildCopyrightText(),
                    const SizedBox(height: 8),
                    const VersionInfoWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Method untuk membangun background hijau
  Widget _buildGreenBackground(double screenHeight, double screenWidth) {
    return Positioned(
      top: 0,
      child: Container(
        height: screenHeight * 0.4, // Tinggi background 40% dari layar
        width: screenWidth,
        decoration: const BoxDecoration(
          color: Color(0xFF008C45), // Warna hijau sesuai gambar
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.elliptical(30, 30),
            bottomRight: Radius.elliptical(30, 30),
          ),
        ),
      ),
    );
  }

  // Method untuk membangun kartu login
  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Pastikan path 'assets/logo_rsud.png' sesuai
          Image.asset('assets/images/logo.png', height: 150),
          Text(
            'Selamat Datang!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 5),
          // Menggunakan RichText untuk membuat 'Log In' menjadi tebal
          RichText(
            text: TextSpan(
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              children: const [
                TextSpan(text: 'Silahkan '),
                TextSpan(
                  text: 'Masuk',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' untuk melanjutkan'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method untuk membangun tombol login Google
  Widget _buildGoogleLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ElevatedButton(
              onPressed: () async {
                setState(() {
                  _isLoading = true;
                });

                try {
                  // 1. Panggil fungsi sign-in
                  final userCredential = await _authService.signInWithGoogle();

                  // 2. Cek apakah widget masih ada di tree (best practice)
                  if (!mounted) return;

                  // 3. Jika berhasil (userCredential tidak null), navigasi ke halaman utama
                  if (userCredential != null && userCredential.user != null) {
                    // Ganti '/home' dengan rute halaman utama Anda (misal: HomeScreen())
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                          builder: (context) => const MainScreen()),
                    );
                  } else {
                    // Kasus ini seharusnya tidak terjadi jika pengguna tidak membatalkan,
                    // tapi sebagai pengaman jika proses dibatalkan oleh pengguna.
                    if (!mounted) return;
                    setState(() {
                      _isLoading = false;
                    });
                  }
                } catch (e) {
                  // 4. Jika terjadi error (dari 'throw Exception' di AuthService)
                  if (!mounted) return;

                  // Tampilkan pesan error kepada pengguna
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: Colors.red,
                    ),
                  );
                // Hentikan loading HANYA jika terjadi kegagalan, agar tombol muncul kembali.
                setState(() {
                  _isLoading = false;
                });
                }

              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/images/google_logo.png', height: 30.0),
                  const SizedBox(width: 12),
                  const Text(
                    'Masuk dengan Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
    );
  }

  // Method untuk membangun teks copyright
  Widget _buildCopyrightText() {
    final String currentYear = DateFormat('y').format(DateTime.now());
    return Text(
      '©RSUD Tipe B Prov. SULUT $currentYear',
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
  }
}
