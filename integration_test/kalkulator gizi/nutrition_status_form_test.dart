import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
// 1. Tambahkan import untuk lokalisasi
import 'package:flutter_localizations/flutter_localizations.dart'; 
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/nutrition_status_form_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Dummy inisialisasi Firebase untuk bypass Patient Picker
    await Firebase.initializeApp();
  });

  group('Integration Test: Fungsionalitas Form Status Gizi (0-60 Bulan)', () {
    testWidgets('Alur input Bayi Baru Lahir (0 Bulan) dan Perhitungan', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          // 2. Tambahkan delegasi lokalisasi agar DatePicker bahasa Indonesia bisa berjalan
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: [
            Locale('id', 'ID'), // Dukungan bahasa Indonesia
            Locale('en', 'US'), // Fallback bahasa Inggris
          ],
          home: Scaffold(
            body: NutritionStatusFormPage(userRole: 'admin'),
          ),
        ),
      );

      // Tunggu render awal
      await tester.pump(const Duration(seconds: 2));

      // 1. Pilih Tanggal Lahir
     final birthDateField = find.byKey(const ValueKey('birthDateField'));
      await tester.ensureVisible(birthDateField);
      await tester.tap(birthDateField);
      
      // GANTI pumpAndSettle dengan pump(Duration) agar tidak stuck menunggu animasi
      await tester.pump(const Duration(seconds: 2)); 
      
      // Cari TextButton TERAKHIR (tombol konfirmasi/OK) yang ADA DI DALAM Dialog kalender
      final okButton = find.descendant(
        of: find.byType(Dialog), 
        matching: find.byType(TextButton),
      ).last;

      await tester.tap(okButton);
      await tester.pump(const Duration(seconds: 2));

      // 2. Verifikasi UI memunculkan label usia "0 bulan"
      expect(find.byKey(const ValueKey('ageDisplay')), findsOneWidget);

      // 3. Scroll sedikit agar Dropdown Gender terlihat
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pump(const Duration(seconds: 1));

      // 4. Pilih Jenis Kelamin (Laki-laki)
      await tester.tap(find.byKey(const ValueKey('genderDropdown')));
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(find.text('Laki-laki').last);
      await tester.pump(const Duration(seconds: 1));

      // 5. Input Berat Badan & Tinggi Badan (Data Median Usia 0 Bulan)
      await tester.enterText(find.byKey(const ValueKey('weightField')), '3.3');
      await tester.pump(const Duration(seconds: 1));
      
      await tester.enterText(find.byKey(const ValueKey('heightField')), '50.0');
      await tester.pump(const Duration(seconds: 1));

      // 6. WAJIB TUTUP KEYBOARD
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

      // 7. PAKSA SCROLL JAUH KE BAWAH agar tombol kalkulasi benar-benar aman ditekan
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pump(const Duration(seconds: 1));

      // 8. Tekan Kalkulasi
      final calcButton = find.byIcon(Icons.calculate).last;
      await tester.tap(calcButton);
      await tester.pump(const Duration(seconds: 2)); // Tunggu hasil dirender

      // 9. Verifikasi seluruh 4 Kartu Hasil muncul
      expect(find.byKey(const ValueKey('resultCard_bbPerU')), findsOneWidget);
      expect(find.byKey(const ValueKey('resultCard_tbPerU')), findsOneWidget);
      expect(find.byKey(const ValueKey('resultCard_bbPerTb')), findsOneWidget);
      expect(find.byKey(const ValueKey('resultCard_imtPerU')), findsOneWidget);
      
      // 10. Verifikasi Z-Score BB/U bernilai 0.00 (Normal)
      expect(find.textContaining('Z-Score: 0.00'), findsWidgets); 
      expect(find.textContaining('Normal'), findsWidgets);
    });
  });
}