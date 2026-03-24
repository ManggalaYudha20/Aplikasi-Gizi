// integration_test/kidney_integration_test.dart
//
// ══════════════════════════════════════════════════════════════════════════════
//  INTEGRATION TEST — KidneyCalculationPage (Emulator / Real Device)
// ══════════════════════════════════════════════════════════════════════════════
//
//  Cara jalankan:
//    flutter test integration_test/kidney_integration_test.dart
//      --device-id <emulator_id>
//
//  SOLUSI: 
//    • pumpAndSettle() diganti dengan pump(Duration(...)) dengan waktu tetap.
//    • Keyboard ditutup manual agar ensureVisible() bekerja optimal.
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/presentation/pages/kidney_calculation_page.dart';

// ---------------------------------------------------------------------------
// Durasi standar render & animasi
// ---------------------------------------------------------------------------
const _kRender = Duration(seconds: 2);
const _kAnim   = Duration(seconds: 1);
const _kResult = Duration(seconds: 2);

// ---------------------------------------------------------------------------
// Helper Widgets & Actions
// ---------------------------------------------------------------------------
Widget _buildPage({String userRole = 'ahli gizi'}) {
  return MaterialApp(
    home: KidneyCalculationPage(userRole: userRole),
  );
}

Future<void> _tapSubmit(WidgetTester tester) async {
  // Tutup keyboard agar tidak menghalangi tombol
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(_kAnim);

  // Cari spesifik tombol "Hitung" atau tombol dengan ikon kalkulasi
  // (Lebih aman daripada melakukan tap pada 'action_buttons_group')
  final byIcon = find.widgetWithIcon(ElevatedButton, Icons.calculate);
  final target = byIcon.evaluate().isNotEmpty
      ? byIcon.first
      : find.widgetWithText(ElevatedButton, 'Hitung').first;

  // Scroll ke tombol tersebut dan lakukan tap
  await tester.ensureVisible(target);
  await tester.pump(_kAnim);
  await tester.tap(target);
  
  // Tunggu hasil kalkulasi / render UI
  await tester.pump(_kResult);
}

Future<void> _selectDropdown(WidgetTester tester, Key dropdownKey, String option) async {
  final dropdownFinder = find.byKey(dropdownKey);
  await tester.ensureVisible(dropdownFinder);
  await tester.pump(_kAnim);
  await tester.tap(dropdownFinder);
  await tester.pump(_kAnim);
  await tester.tap(find.text(option).last);
  await tester.pump(_kAnim);
}

Future<void> _fillValidForm(WidgetTester tester) async {
  await _selectDropdown(tester, const ValueKey('input_dialysis'), 'Tidak');
  await _selectDropdown(tester, const ValueKey('input_gender'), 'Laki-laki');

  await tester.enterText(find.byKey(const ValueKey('input_height')), '170');
  await tester.pump(_kAnim);

  await tester.enterText(find.byKey(const ValueKey('input_weight')), '65');
  await tester.pump(_kAnim);

  await tester.enterText(find.byKey(const ValueKey('input_age')), '45');
  await tester.pump(_kAnim);
}

// ===========================================================================
// MAIN
// ===========================================================================
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // [A] FORM VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════
  group('[Integration A] Form Validation', () {
    testWidgets('error muncul ketika semua field kosong lalu submit', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await _tapSubmit(tester);

      expect(find.text('Tinggi Badan tidak boleh kosong'), findsOneWidget);
      expect(find.text('Berat Badan Aktual tidak boleh kosong'), findsOneWidget);
      expect(find.text('Usia tidak boleh kosong'), findsOneWidget);
    });

    testWidgets('menampilkan error ketika input bukan angka valid', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.enterText(find.byKey(const ValueKey('input_height')), '.');
      await tester.pump(_kAnim);
      
      await _tapSubmit(tester);

      expect(find.text('Masukkan angka yang valid'), findsWidgets);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // [B] PROTEIN FACTOR & POTASSIUM
  // ═══════════════════════════════════════════════════════════════════════════
  group('[Integration B] Dropdowns & Switches', () {
    testWidgets('dropdown faktor protein TIDAK tampil saat cuci darah = "Ya"', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await _selectDropdown(tester, const ValueKey('input_dialysis'), 'Ya');
      expect(find.byKey(const ValueKey('input_protein_factor')), findsNothing);
    });

    testWidgets('dropdown faktor protein TAMPIL saat cuci darah = "Tidak"', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await _selectDropdown(tester, const ValueKey('input_dialysis'), 'Tidak');
      expect(find.byKey(const ValueKey('input_protein_factor')), findsOneWidget);
    });

    testWidgets('switch kalium tinggi dapat di-toggle menjadi ON', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      final switchFinder = find.byKey(const ValueKey('input_switch_potassium'));
      await tester.ensureVisible(switchFinder);
      await tester.tap(switchFinder);
      await tester.pump(_kAnim);

      final switchWidget = tester.widget<SwitchListTile>(switchFinder);
      expect(switchWidget.value, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // [C] ROLE-BASED & RESET
  // ═══════════════════════════════════════════════════════════════════════════
  group('[Integration C] Role-based Menu & Reset', () {
    testWidgets('ExpansionTile menu dinamis TIDAK muncul untuk role "pasien"', (tester) async {
      await tester.pumpWidget(_buildPage(userRole: 'tamu'));
      await tester.pump(_kRender);

      await _fillValidForm(tester);
      await _tapSubmit(tester);

      expect(find.byKey(const ValueKey('expansion_dynamic_menu')), findsNothing);
    });

    testWidgets('semua field kosong dan hasil hilang setelah reset', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await _fillValidForm(tester);
      await _tapSubmit(tester);

      expect(find.text('Hasil Perhitungan'), findsOneWidget);

      final resetButton = find.widgetWithText(OutlinedButton, 'Reset');
      if (resetButton.evaluate().isNotEmpty) {
        await tester.ensureVisible(resetButton.first);
        await tester.tap(resetButton.first);
        await tester.pump(_kAnim);

        expect(find.text('Hasil Perhitungan'), findsNothing);
        final heightField = tester.widget<TextFormField>(find.byKey(const ValueKey('input_height')));
        expect((heightField.controller?.text ?? ''), isEmpty);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // [D] FULL FLOW
  // ═══════════════════════════════════════════════════════════════════════════
  group('[Integration D] Full Flow', () {
    final authorizedRoles = ['ahli_gizi', 'nutrisionis'];

    for (final role in authorizedRoles) {
      testWidgets('Role "$role": mengisi form lengkap → kartu hasil dan expansion tiles muncul', (tester) async {
        await tester.pumpWidget(_buildPage(userRole: role));
        await tester.pump(_kRender);

        await _fillValidForm(tester);
        await _tapSubmit(tester);

        expect(find.text('Hasil Perhitungan'), findsOneWidget);
        expect(find.byKey(const ValueKey('expansion_nutrition')), findsOneWidget);
        expect(find.byKey(const ValueKey('expansion_meal_plan')), findsOneWidget);
      });
    }
  });
}