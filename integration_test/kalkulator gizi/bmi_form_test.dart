import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bmi_form_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inisialisasi dummy Firebase untuk test lingkungan
    await Firebase.initializeApp();
  });

  group('Integration Test: Fungsionalitas IMT Form UI', () {
    testWidgets('Alur input data dan perhitungan IMT Normal', (WidgetTester tester) async {
      // 1. Render halaman form
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BmiFormPage(userRole: 'admin'),
          ),
        ),
      );

      // Beri waktu 2 detik agar UI awal selesai dirender (bypass loading picker)
      await tester.pump(const Duration(seconds: 2));

      // 2. Masukkan Berat Badan (misal: 65 kg)
      await tester.enterText(find.byKey(const ValueKey('weightField')), '65');
      await tester.pump(const Duration(seconds: 1));

      // 3. Masukkan Tinggi Badan (misal: 170 cm)
      await tester.enterText(find.byKey(const ValueKey('heightField')), '170');
      await tester.pump(const Duration(seconds: 1));

      // 4. WAJIB TUTUP KEYBOARD SEBELUM LANJUT
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1)); // Tunggu animasi keyboard turun

      // 5. Scroll ke tombol kalkulasi
      final calcButton = find.byIcon(Icons.calculate);
      await tester.ensureVisible(calcButton);
      await tester.pump(const Duration(seconds: 1));

      // 6. Tekan tombol kalkulasi
      await tester.tap(calcButton);
      await tester.pump(const Duration(seconds: 1)); // Tunggu hasil dirender

      // 7. Verifikasi bahwa Result Card muncul
      expect(find.byKey(const ValueKey('bmiResultCard')), findsOneWidget);

      // 8. Verifikasi nilai akhirnya dan kategorinya
      // 65 / (1.7 * 1.7) = 22.49 kg/m²
      expect(find.textContaining('22.49'), findsOneWidget); 
      expect(find.text('Kategori: Normal'), findsOneWidget);
    });
  });
}