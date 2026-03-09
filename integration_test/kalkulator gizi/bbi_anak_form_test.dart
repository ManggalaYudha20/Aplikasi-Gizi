import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bbi_anak_form_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inisialisasi dummy Firebase untuk test
    await Firebase.initializeApp();
  });

  group('Integration Test: Fungsionalitas BBI Anak Form UI', () {
    testWidgets('Alur input kategori 1-6 Tahun dan perhitungan BBI', (WidgetTester tester) async {
      // 1. Render halaman form
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            // Dibungkus Scaffold tambahan jika diperlukan, atau langsung panggil page
            body: BbiAnakFormPage(userRole: 'admin'),
          ),
        ),
      );

      // Beri waktu 2 detik agar UI awal selesai dirender (mengabaikan loading Firebase)
      await tester.pump(const Duration(seconds: 2));

      // 2. Buka Dropdown kategori dan pilih "1 - 6 Tahun"
      await tester.tap(find.byKey(const ValueKey('categoryDropdown')));
      await tester.pump(const Duration(seconds: 1)); // Tunggu dropdown muncul
      
      await tester.tap(find.text('1 - 6 Tahun').last);
      await tester.pump(const Duration(seconds: 1)); // Tunggu dropdown tertutup

      // 3. Masukkan usia (misal: 4 tahun)
      await tester.enterText(find.byKey(const ValueKey('ageField')), '4');
      await tester.pump(const Duration(seconds: 1)); // Tunggu teks masuk

      // 4. Tutup keyboard agar tombol kalkulasi tidak tertutup (penting untuk device kecil)
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

      // 5. Scroll sedikit ke bawah jika tombol tidak terlihat di layar
      await tester.ensureVisible(find.byIcon(Icons.calculate));
      await tester.pump(const Duration(seconds: 1));

      // 6. Tekan tombol kalkulasi
      await tester.tap(find.byIcon(Icons.calculate));
      await tester.pump(const Duration(seconds: 1)); // Tunggu hasil dirender

      // 7. Verifikasi bahwa Result Card muncul
      expect(find.byKey(const ValueKey('bbiAnakResultCard')), findsOneWidget);

      // 8. Verifikasi nilai akhirnya (Rumus: (2 * 4) + 8 = 16.00)
      expect(find.text('16.00 kg'), findsOneWidget);
    });
  });
}