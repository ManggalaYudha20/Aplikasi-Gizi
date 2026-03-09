import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/pages/bmr_form_page.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inisialisasi dummy Firebase
    await Firebase.initializeApp();
  });

  group('Integration Test: Fungsionalitas Form BMR', () {
    testWidgets('Alur input data pria dan perhitungan BMR Mifflin', (WidgetTester tester) async {
      // 1. Render halaman form
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BmrFormPage(userRole: 'admin'),
          ),
        ),
      );

      // Bypass loading picker
      await tester.pump(const Duration(seconds: 2));

      // (Catatan: _formulaController sudah default ke "Mifflin-St Jeor")

      // 2. Masukkan Berat Badan (misal: 70 kg)
      await tester.enterText(find.byKey(const ValueKey('weightField')), '70');
      await tester.pump(const Duration(seconds: 1));

      // 3. Masukkan Tinggi Badan (misal: 175 cm)
      await tester.enterText(find.byKey(const ValueKey('heightField')), '175');
      await tester.pump(const Duration(seconds: 1));

      // 4. WAJIB TUTUP KEYBOARD sebelum akses dropdown
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

      // 5. Buka Dropdown Jenis Kelamin
      final genderDropdown = find.byKey(const ValueKey('genderDropdown'));
      await tester.ensureVisible(genderDropdown);
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(genderDropdown);
      await tester.pump(const Duration(seconds: 1));
      
      // Pilih "Laki-laki"
      await tester.tap(find.text('Laki-laki').last);
      await tester.pump(const Duration(seconds: 1));

      // 6. Masukkan Umur (misal: 25 tahun)
      final ageField = find.byKey(const ValueKey('ageField'));
      await tester.ensureVisible(ageField);
      await tester.pump(const Duration(seconds: 1));
      
      await tester.enterText(ageField, '25');
      await tester.pump(const Duration(seconds: 1));

      // WAJIB TUTUP KEYBOARD LAGI
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump(const Duration(seconds: 1));

    // 7. Tekan tombol kalkulasi
      // Tambahkan .last karena ada dua ikon kalkulator di halaman ini
      final calcButton = find.byIcon(Icons.calculate).last; 
      
      await tester.ensureVisible(calcButton);
      await tester.pump(const Duration(seconds: 1));
      
      await tester.tap(calcButton);
      await tester.pump(const Duration(seconds: 1));

      // 8. Verifikasi Result Card
      expect(find.byKey(const ValueKey('bmrResultCard')), findsOneWidget);

      // 9. Verifikasi nilai akhirnya (70kg, 175cm, 25thn, Pria, Mifflin = 1675.05)
      expect(find.textContaining('1675.05'), findsOneWidget);
    });
  });
}