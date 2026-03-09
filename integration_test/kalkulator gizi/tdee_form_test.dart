import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/tdee_form_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Bypass koneksi Firebase Patient Picker
    await Firebase.initializeApp();
  });

  group('Integration Test: Fungsionalitas Form TDEE', () {
    testWidgets('Alur input Pria aktivitas ringan & status normal', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TdeeFormPage(userRole: 'admin'),
          ),
        ),
      );

      // Tunggu render halaman awal (bypass loading picker)
      await tester.pump(const Duration(seconds: 2));

      // 1. Input Berat Badan (70 kg) & Tinggi Badan (170 cm)
      await tester.enterText(find.byKey(const ValueKey('weightField')), '70');
      await tester.pump(const Duration(seconds: 1));
      
      await tester.enterText(find.byKey(const ValueKey('heightField')), '170');
      await tester.pump(const Duration(seconds: 1));

      // TUTUP KEYBOARD
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

      // --- TAMBAHAN PENTING ---
      // SCROLL LAYAR SEDIKIT KE BAWAH agar Dropdown Gender benar-benar muncul di tengah
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pump(const Duration(seconds: 1));
      // ------------------------

      // 2. Pilih Gender (Laki-laki)
      await tester.tap(find.byKey(const ValueKey('genderDropdown')));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('Laki-laki').last);
      await tester.pump(const Duration(seconds: 1));

      // 3. Input Usia (25 Tahun)
      await tester.enterText(find.byKey(const ValueKey('ageField')), '25');
      await tester.pump(const Duration(seconds: 1));
      
      // TUTUP KEYBOARD LAGI
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

      // SCROLL LAYAR LAGI agar Dropdown Aktivitas & Stress muncul di tengah layar
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
      await tester.pump(const Duration(seconds: 1));

      // 4. Pilih Faktor Aktivitas (Aktivitas Ringan)
      await tester.tap(find.byKey(const ValueKey('activityDropdown')));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('Aktivitas Ringan').last);
      await tester.pump(const Duration(seconds: 1));

      // 5. Pilih Faktor Stress (Normal)
      await tester.tap(find.byKey(const ValueKey('stressDropdown')));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('Normal').last);
      await tester.pump(const Duration(seconds: 1));

      // SCROLL SAMPAI PALING BAWAH agar tombol Kalkulasi terlihat penuh
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pump(const Duration(seconds: 1));

      // 6. Tekan Hitung
      final calcButton = find.byIcon(Icons.calculate).last;
      await tester.tap(calcButton);
      await tester.pump(const Duration(seconds: 2)); // Tunggu hasil dirender

      // 7. Verifikasi Keberhasilan Rendering Hasil
      expect(find.byKey(const ValueKey('tdeeResultCard')), findsOneWidget);
      
      // Verifikasi Nilai BMR (sekitar 1700.06)
      expect(find.textContaining('1700.06'), findsOneWidget);
      
      // Verifikasi Nilai TDEE (sekitar 2337.58)
      expect(find.textContaining('2337.58'), findsOneWidget);
      
      // Verifikasi munculnya kartu pembagian Makronutrien
      expect(find.textContaining('Karbohidrat (60%)'), findsOneWidget);
    });
  });
}