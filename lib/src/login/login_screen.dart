// lib/src/login/login_screen.dart

import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/version_info_app.dart';
import 'package:aplikasi_diagnosa_gizi/main.dart';

// Tips: Kumpulkan path asset di satu tempat agar jika file dipindah, cukup ubah di sini
class _Assets {
  static const logoRsud = 'assets/images/logo.png';
  static const googleLogo = 'assets/images/google_logo.png';
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  
  // Services
  final AuthService _authService = AuthService(); // Idealnya di-inject via Provider/GetIt

  // Controllers
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  // State
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    // Prevent double tap
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithGoogle();

      if (!mounted) return;

      if (userCredential?.user != null) {
        // Navigasi sukses
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      } else {
        // User cancel (biasanya null)
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      
      _showErrorSnackBar("Gagal Masuk: ${e.toString()}");
      setState(() => _isLoading = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        key: const Key('login_error_snackbar'),
        content: Text(message),
        backgroundColor: Colors.red.shade700, // Warna lebih solid untuk error
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context); // Lebih efisien daripada MediaQuery.of(context).size di Flutter terbaru

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Stack(
          children: [
            _buildGreenBackground(size),
            
            // LayoutBuilder + SingleScrollView + IntrinsicHeight
            // Pattern terbaik untuk form center dengan sticky footer yang aman keyboard
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Spacer(flex: 2),
                              _buildLoginCard(context),
                              
                              const SizedBox(height: 90), // Digabung agar widget tree lebih dangkal
                              
                              _buildGoogleLoginButton(),
                              
                              const Spacer(flex: 2),
                              _buildCopyrightText(),
                              const SizedBox(height: 8),
                              const VersionInfoWidget(),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreenBackground(Size size) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: size.height * 0.4,
        decoration: const BoxDecoration(
          color: Color(0xFF008C45),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.elliptical(30, 30),
            bottomRight: Radius.elliptical(30, 30),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0), // Padding sedikit diperbesar agar lebih lega
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Kompatibilitas aman
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: "Logo Rumah Sakit",
            image: true,
            child: Image.asset(
              _Assets.logoRsud, // Menggunakan konstanta asset
              key: const Key('login_logo_rsud'),
              height: 150,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 50), // Fallback aman
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Selamat Datang!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
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

  Widget _buildGoogleLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                key: Key('login_loading_indicator'),
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF008C45)),
              ),
            )
          : Semantics(
              label: "Tombol Masuk dengan Google",
              button: true,
              enabled: true,
              child: ElevatedButton(
                key: const Key('login_button_google'),
                onPressed: _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      _Assets.googleLogo,
                      height: 24.0, // Ukuran logo google standar biasanya 24dp
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Masuk dengan Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600, // Sedikit lebih tebal agar terbaca
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCopyrightText() {
    final String currentYear = DateFormat('y').format(DateTime.now());
    return Text(
      '©RSUD Tipe B Prov. SULUT $currentYear',
      key: const Key('login_copyright_text'),
      style: const TextStyle(color: Colors.grey, fontSize: 12),
    );
  }
}