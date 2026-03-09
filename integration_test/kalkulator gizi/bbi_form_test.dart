import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bbi_form_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inisialisasi dummy Firebase untuk test lingkungan
    await Firebase.initializeApp();
  });

  group('Integration Test: Fungsionalitas BBI Dewasa Form UI', () {
    testWidgets('Alur input data pria dan perhitungan BBI', (WidgetTester tester) async {
      // 1. Render halaman form
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BbiFormPage(userRole: 'admin'),
          ),
        ),
      );

      // Beri waktu 2 detik agar UI awal selesai dirender (bypass loading picker)
      await tester.pump(const Duration(seconds: 2));

      // 2. Masukkan Tinggi Badan (misal: 170 cm)
      await tester.enterText(find.byKey(const ValueKey('heightField')), '170');
      await tester.pump(const Duration(seconds: 1)); 

     // 3. WAJIB TUTUP KEYBOARD SEBELUM LANJUT
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1)); // Tunggu animasi keyboard turun

      // 4. Pastikan Dropdown terlihat di layar (scroll jika perlu)
      final dropdownFinder = find.byKey(const ValueKey('genderDropdown'));
      await tester.ensureVisible(dropdownFinder);
      await tester.pump(const Duration(seconds: 1));

      // 5. Buka Dropdown Jenis Kelamin
      await tester.tap(dropdownFinder);
      await tester.pump(const Duration(seconds: 1)); // Tunggu popup menu muncul
      
      // Pilih "Laki-laki"
      await tester.tap(find.text('Laki-laki').last);
      await tester.pump(const Duration(seconds: 1)); // Tunggu dropdown tertutup

      // 6. Scroll ke tombol kalkulasi
      final calcButton = find.byIcon(Icons.calculate);
      await tester.ensureVisible(calcButton);
      await tester.pump(const Duration(seconds: 1));

      // 7. Tekan tombol kalkulasi
      await tester.tap(calcButton);
      await tester.pump(const Duration(seconds: 1)); // Tunggu hasil dirender

      // 8. Verifikasi bahwa Result Card muncul
      expect(find.byKey(const ValueKey('bbiResultCard')), findsOneWidget);

      // 9. Verifikasi nilai akhirnya (Rumus: (170 - 100) * 0.90 = 63.00)
      expect(find.text('63.00 kg'), findsOneWidget);
    });
  });
}