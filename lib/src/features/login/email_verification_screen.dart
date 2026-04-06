// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\login\email_verification_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/login/auth_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/app/main_screen.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/login/login_screen.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({super.key, required this.email});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();

  bool _isChecking = false;
  bool _isResending = false;
  int _resendCooldown = 0; // detik cooldown sebelum bisa kirim ulang
  Timer? _cooldownTimer;
  Timer? _autoCheckTimer;

  @override
  void initState() {
    super.initState();
    // Auto-check setiap 5 detik tanpa perlu user klik manual
    _autoCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkVerification(silent: true),
    );
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _autoCheckTimer?.cancel();
    super.dispose();
  }

  // Cek status verifikasi
  Future<void> _checkVerification({bool silent = false}) async {
    if (_isChecking) return;
    if (!silent) setState(() => _isChecking = true);

    try {
      final isVerified = await _authService.checkEmailVerified();

      if (!mounted) return;

      if (isVerified) {
        _autoCheckTimer?.cancel();
        // Langsung masuk ke MainScreen setelah terverifikasi
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainScreen()),
          (route) => false,
        );
      } else {
        if (!silent) {
          _showSnackBar(
            'Email belum diverifikasi. Cek inbox kamu.',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        _showSnackBar('Gagal mengecek status. Coba lagi.', isError: true);
      }
    } finally {
      if (mounted && !silent) setState(() => _isChecking = false);
    }
  }

  // Kirim ulang email verifikasi dengan cooldown 60 detik
  Future<void> _resendEmail() async {
    if (_isResending || _resendCooldown > 0) return;
    setState(() => _isResending = true);

    try {
      await _authService.resendVerificationEmail();
      if (!mounted) return;

      _showSnackBar('Email verifikasi dikirim ulang ke ${widget.email}');

      // Mulai cooldown 60 detik
      setState(() => _resendCooldown = 60);
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _resendCooldown--);
        if (_resendCooldown <= 0) timer.cancel();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
        'Gagal mengirim ulang. Coba beberapa saat lagi.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _cancelAndBackToLogin() async {
    await _authService.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Colors.red.shade700
            : const Color(0xFF008C45),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              _buildIllustration(),
              const SizedBox(height: 32),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildSubtitle(),
              const SizedBox(height: 40),
              _buildCheckButton(),
              const SizedBox(height: 16),
              _buildResendButton(),
              const SizedBox(height: 32),
              _buildAutoCheckIndicator(),
              const Spacer(),
              _buildBackToLoginLink(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF008C45).withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.mark_email_unread_outlined,
        size: 64,
        color: Color(0xFF008C45),
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Verifikasi Email Kamu',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSubtitle() {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
        children: [
          const TextSpan(text: 'Link verifikasi telah dikirim ke\n'),
          TextSpan(
            text: widget.email,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const TextSpan(
            text:
                '\n\nBuka email tersebut dan klik link verifikasi,'
                ' lalu kembali ke sini.',
          ),
        ],
      ),
    );
  }

  Widget _buildCheckButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton.icon(
        onPressed: _isChecking ? null : () => _checkVerification(),
        icon: _isChecking
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.refresh),
        label: Text(
          _isChecking ? 'Memeriksa...' : 'Saya Sudah Verifikasi',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF008C45),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildResendButton() {
    final bool canResend = _resendCooldown <= 0 && !_isResending;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: canResend ? _resendEmail : null,
        icon: _isResending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Color(0xFF008C45),
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.send_outlined),
        label: Text(
          _resendCooldown > 0
              ? 'Kirim Ulang (${_resendCooldown}s)'
              : 'Kirim Ulang Email',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF008C45),
          disabledForegroundColor: Colors.grey,
          side: BorderSide(
            color: canResend ? const Color(0xFF008C45) : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildAutoCheckIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Memeriksa otomatis setiap 5 detik...',
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildBackToLoginLink() {
    return TextButton(
      onPressed: _cancelAndBackToLogin,
      child: const Text(
        'Kembali ke halaman login',
        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
      ),
    );
  }
}
