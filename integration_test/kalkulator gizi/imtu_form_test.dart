import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/imtu_form_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inisialisasi dummy Firebase untuk test lingkungan
    await Firebase.initializeApp();
  });

  group('Integration Test: Fungsionalitas Form IMT/U', () {
    testWidgets('Alur input data Anak Laki-laki 5 Tahun 1 Bulan', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: IMTUFormPage(userRole: 'admin'),
          ),
        ),
      );

      // Bypass loading picker
      await tester.pump(const Duration(seconds: 2));

      // 1. Input Usia (5 Tahun, 1 Bulan)
      await tester.enterText(find.byKey(const ValueKey('ageYearField')), '5');
      await tester.pump(const Duration(seconds: 1));
      
      await tester.enterText(find.byKey(const ValueKey('ageMonthField')), '1');
      await tester.pump(const Duration(seconds: 1));

      // 2. WAJIB TUTUP KEYBOARD SEBELUM SCROLL / DROPDOWN
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

      // 3. Scroll layar sedikit ke bawah agar dropdown aman diklik
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pump(const Duration(seconds: 1));

      // 4. Pilih Gender
      final genderDropdown = find.byKey(const ValueKey('genderDropdown'));
      await tester.tap(genderDropdown);
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('Laki-laki').last);
      await tester.pump(const Duration(seconds: 1));

      // 5. Input BB & TB (20 kg, 110 cm)
      await tester.enterText(find.byKey(const ValueKey('weightField')), '20');
      await tester.pump(const Duration(seconds: 1));
      
      await tester.enterText(find.byKey(const ValueKey('heightField')), '110');
      await tester.pump(const Duration(seconds: 1));

      // 6. TUTUP KEYBOARD LAGI SEBELUM TOMBOL KALKULASI
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

      // 7. PAKSA SCROLL JAUH KE BAWAH agar tombol kalkulasi benar-benar di tengah layar
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pump(const Duration(seconds: 1));

      // 8. Tekan Kalkulasi
      final calcButton = find.byIcon(Icons.calculate).last;
      await tester.tap(calcButton);
      await tester.pump(const Duration(seconds: 2)); // Tunggu rendering hasil

      // 9. Verifikasi Result Card
      expect(find.byKey(const ValueKey('imtuResultCard')), findsOneWidget);
      
      // 10. Verifikasi nilai akhirnya (Sesuai dengan unit test kita)
      // BMI = 16.53, Z-Score = 0.95, Kategori = Gizi baik
      expect(find.textContaining('16.53'), findsOneWidget); 
      expect(find.textContaining('0.95'), findsOneWidget); 
      expect(find.textContaining('Gizi baik'), findsOneWidget);
    });
  });
}