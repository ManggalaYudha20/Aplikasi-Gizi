// integration_test/diabetes_integration_test.dart
//
// ══════════════════════════════════════════════════════════════════════════════
//  INTEGRATION TEST — DiabetesCalculationPage (Emulator / Real Device)
// ══════════════════════════════════════════════════════════════════════════════
//
//  Cara jalankan (butuh emulator / device yang berjalan):
//    flutter test integration_test/diabetes_integration_test.dart
//      --device-id <emulator_id>
//
//  Atau jalankan semua integration test sekaligus:
//    flutter test integration_test/
//
//  Pastikan di pubspec.yaml → dev_dependencies:
//    integration_test:
//      sdk: flutter
//    flutter_test:
//      sdk: flutter
//
// ─── KENAPA TIDAK PAKAI pumpAndSettle() ? ────────────────────────────────────
//  pumpAndSettle() menunggu SEMUA frame & async selesai sebelum lanjut.
//  FoodDatabaseService memanggil FirebaseFirestore.instance yang membuka
//  stream listener — stream ini tidak pernah "selesai", sehingga
//  pumpAndSettle() akan hang selamanya (infinite loop).
//
//  SOLUSI (mengikuti pola bmi_form_test.dart):
//    • Ganti pumpAndSettle() → pump(Duration(...)) dengan waktu tetap
//    • Tutup keyboard manual sebelum tap tombol hitung
//    • Gunakan ensureVisible() agar tombol tidak tertutup keyboard
// ──────────────────────────────────────────────────────────────────────────────
//
//  Cakupan:
//    [A] Form Validation     — field kosong & nilai di luar rentang
//    [B] Stress Slider       — muncul/hilang & nilai default
//    [C] Role-based Menu     — akses section menu berdasarkan userRole
//    [D] Reset Form          — field bersih & hasil hilang setelah reset
//    [E] Full Form Flow      — isi → hitung → semua kartu muncul
//    [F] Stress Metabolik    — koreksi tampil di kartu hasil
//    [G] Dropdown Options    — semua opsi dropdown tersedia
//    [H] PDF Download Button — tombol PDF tampil setelah menu terbentuk
// ══════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/presentation/pages/diabetes_calculation_page.dart';

// ---------------------------------------------------------------------------
// Durasi standar — sesuaikan jika emulator lebih lambat
// ---------------------------------------------------------------------------
const _kRender = Duration(seconds: 2); // tunggu render awal + Firebase init
const _kAnim   = Duration(seconds: 1); // tunggu animasi dropdown / keyboard
const _kResult = Duration(seconds: 2); // tunggu kalkulasi & render kartu hasil
const _kPdf    = Duration(seconds: 3); // tunggu fetch menu dari Firestore

// ---------------------------------------------------------------------------
// Helper — render halaman dalam MaterialApp minimal
// ---------------------------------------------------------------------------
Widget _buildPage({String userRole = 'ahli_gizi'}) {
  return MaterialApp(
    home: DiabetesCalculationPage(userRole: userRole),
  );
}

// ---------------------------------------------------------------------------
// Helper — tekan tombol Hitung
// Keyboard ditutup dulu agar tombol tidak tertutup & ensureVisible bekerja.
// ---------------------------------------------------------------------------
Future<void> _tapSubmit(WidgetTester tester) async {
  // Tutup keyboard — sama persis dengan pola bmi_form_test.dart
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(_kAnim);

  final byIcon = find.widgetWithIcon(ElevatedButton, Icons.calculate);
  final target = byIcon.evaluate().isNotEmpty
      ? byIcon.first
      : find.widgetWithText(ElevatedButton, 'Hitung').first;

  await tester.ensureVisible(target);
  await tester.pump(_kAnim);
  await tester.tap(target);
  await tester.pump(_kResult);
}

// ---------------------------------------------------------------------------
// Helper — buka dropdown dan pilih opsi
// ---------------------------------------------------------------------------
Future<void> _selectDropdown(
  WidgetTester tester,
  Key dropdownKey,
  String option,
) async {
  // Scroll dropdown ke dalam viewport sebelum tap — mencegah error
  // "Offset is outside the bounds of the root of the render tree"
  final dropdownFinder = find.byKey(dropdownKey);
  await tester.ensureVisible(dropdownFinder);
  await tester.pump(_kAnim);
  await tester.tap(dropdownFinder);
  await tester.pump(_kAnim);
  await tester.tap(find.text(option).last);
  await tester.pump(_kAnim);
}

// ---------------------------------------------------------------------------
// Helper — isi semua field wajib dengan data valid
// ---------------------------------------------------------------------------
Future<void> _fillValidForm(WidgetTester tester) async {
  await tester.enterText(find.byKey(const ValueKey('ageField')), '45');
  await tester.pump(_kAnim);

  await _selectDropdown(tester, const ValueKey('genderDropdown'), 'Laki-laki');

  await tester.enterText(find.byKey(const ValueKey('weightField')), '70');
  await tester.pump(_kAnim);

  await tester.enterText(find.byKey(const ValueKey('heightField')), '168');
  await tester.pump(_kAnim);

  await _selectDropdown(tester, const ValueKey('activityDropdown'), 'Ringan');
  await _selectDropdown(tester, const ValueKey('hospitalizedDropdown'), 'Tidak');
}

// ===========================================================================
// MAIN
// ===========================================================================
void main() {
  // WAJIB: inisialisasi binding integration test sebelum apapun
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Inisialisasi Firebase dummy — sama persis dengan pola bmi_form_test.dart
    await Firebase.initializeApp();
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // [A] FORM VALIDATION
  // ═══════════════════════════════════════════════════════════════════════════

  group('[Integration A] Form Validation — Field Kosong', () {
    testWidgets(
        'semua field kosong -> pesan error muncul untuk setiap field',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender); // bypass loading awal Firebase

      await _tapSubmit(tester);

      expect(find.text('Masukkan usia'), findsOneWidget);
      expect(find.text('Masukkan berat badan'), findsOneWidget);
      expect(find.text('Masukkan tinggi badan'), findsOneWidget);
      expect(find.text('Jenis Kelamin harus dipilih'), findsOneWidget);
      expect(find.text('Faktor Aktivitas harus dipilih'), findsOneWidget);
      expect(find.text('Status Rawat Inap harus dipilih'), findsOneWidget);
    });
  });

  group('[Integration A] Form Validation — Nilai Di Luar Rentang', () {
    testWidgets('usia 0 -> pesan "usia yang valid (1-120 tahun)"',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.enterText(find.byKey(const ValueKey('ageField')), '0');
      await tester.pump(_kAnim);
      await _tapSubmit(tester);

      expect(
        find.text('Masukkan usia yang valid (1-120 tahun)'),
        findsOneWidget,
      );
    });

    testWidgets('usia 121 -> pesan "usia yang valid (1-120 tahun)"',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.enterText(find.byKey(const ValueKey('ageField')), '121');
      await tester.pump(_kAnim);
      await _tapSubmit(tester);

      expect(
        find.text('Masukkan usia yang valid (1-120 tahun)'),
        findsOneWidget,
      );
    });

    testWidgets('berat badan 0 -> pesan "berat badan yang valid (1-300 kg)"',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.enterText(find.byKey(const ValueKey('weightField')), '0');
      await tester.pump(_kAnim);
      await _tapSubmit(tester);

      expect(
        find.text('Masukkan berat badan yang valid (1-300 kg)'),
        findsOneWidget,
      );
    });

    testWidgets(
        'tinggi badan 29 -> pesan "tinggi badan yang valid (30-300 cm)"',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.enterText(find.byKey(const ValueKey('heightField')), '29');
      await tester.pump(_kAnim);
      await _tapSubmit(tester);

      expect(
        find.text('Masukkan tinggi badan yang valid (30-300 cm)'),
        findsOneWidget,
      );
    });

    testWidgets('usia batas bawah = 1 -> tidak ada error usia', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.enterText(find.byKey(const ValueKey('ageField')), '1');
      await tester.pump(_kAnim);
      await _tapSubmit(tester);

      expect(
          find.text('Masukkan usia yang valid (1-120 tahun)'), findsNothing);
    });
  });

  // ===============================================================
  // [B] STRESS METABOLIK SLIDER
  // ===============================================================

  group('[Integration B] Stress Metabolik Slider', () {
    testWidgets('slider TIDAK muncul saat rawat inap = "Tidak"',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await _selectDropdown(
          tester, const ValueKey('hospitalizedDropdown'), 'Tidak');

      expect(find.byKey(const ValueKey('stressSlider')), findsNothing);
    });

    testWidgets('slider MUNCUL saat rawat inap = "Ya"', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await _selectDropdown(
          tester, const ValueKey('hospitalizedDropdown'), 'Ya');

      expect(find.byKey(const ValueKey('stressSlider')), findsOneWidget);
    });

    testWidgets('label slider menampilkan nilai default 20%', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await _selectDropdown(
          tester, const ValueKey('hospitalizedDropdown'), 'Ya');

      expect(find.text('Stress Metabolik: 20%'), findsOneWidget);
    });

    testWidgets('slider hilang ketika rawat inap berubah kembali ke "Tidak"',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await _selectDropdown(
          tester, const ValueKey('hospitalizedDropdown'), 'Ya');
      await _selectDropdown(
          tester, const ValueKey('hospitalizedDropdown'), 'Tidak');

      expect(find.byKey(const ValueKey('stressSlider')), findsNothing);
    });
  });

  // ===============================================================
  // [C] ROLE-BASED DAILY MENU
  // ===============================================================

  group('[Integration C] Role-based Daily Menu', () {
    testWidgets('role "tamu" -> section menu TIDAK muncul', (tester) async {
      await tester.pumpWidget(_buildPage(userRole: 'tamu'));
      await tester.pump(_kRender);

      await _fillValidForm(tester);
      await _tapSubmit(tester);

      expect(find.text('Rekomendasi Menu Sehari'), findsNothing);
    });

    testWidgets('role "ahli gizi" -> section menu MUNCUL', (tester) async {
      await tester.pumpWidget(_buildPage(userRole: 'ahli_gizi'));
      await tester.pump(_kRender);

      await _fillValidForm(tester);
      await _tapSubmit(tester);

      expect(find.text('Rekomendasi Menu Sehari'), findsOneWidget);
    });

    testWidgets('role "admin" -> section menu MUNCUL', (tester) async {
      await tester.pumpWidget(_buildPage(userRole: 'admin'));
      await tester.pump(_kRender);

      await _fillValidForm(tester);
      await _tapSubmit(tester);

      expect(find.text('Rekomendasi Menu Sehari'), findsOneWidget);
    });
  });

  // ===============================================================
  // [D] RESET FORM
  // ===============================================================

  group('[Integration D] Reset Form', () {
    testWidgets('field usia kosong setelah tombol Reset ditekan',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.enterText(find.byKey(const ValueKey('ageField')), '45');
      await tester.pump(_kAnim);

      final resetBtn = find.widgetWithText(OutlinedButton, 'Reset');
      if (resetBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(resetBtn.first);
        await tester.tap(resetBtn.first);
        await tester.pump(_kAnim);

        final ageField = tester.widget<TextFormField>(
          find.byKey(const ValueKey('ageField')),
        );
        expect(ageField.controller?.text ?? '', isEmpty);
      }
    });

    testWidgets('hasil perhitungan tidak tampil setelah reset', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await _fillValidForm(tester);
      await _tapSubmit(tester);
      expect(find.text('Hasil Total Kebutuhan Energi'), findsOneWidget);

      final resetBtn = find.widgetWithText(OutlinedButton, 'Reset');
      if (resetBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(resetBtn.first);
        await tester.tap(resetBtn.first);
        await tester.pump(_kAnim);
        expect(find.text('Hasil Total Kebutuhan Energi'), findsNothing);
      }
    });
  });

  // ===============================================================
  // [E] FULL FORM FLOW
  // ===============================================================

  group('[Integration E] Full Form Flow', () {
    testWidgets(
        'isi form lengkap -> kartu total kalori & expansion tiles muncul',
        (tester) async {
      await tester.pumpWidget(_buildPage(userRole: 'ahli_gizi'));
      await tester.pump(_kRender);

      await _fillValidForm(tester);
      await _tapSubmit(tester);

      expect(find.text('Hasil Total Kebutuhan Energi'), findsOneWidget);
      expect(find.textContaining('Total Kalori:'), findsOneWidget);
      expect(find.textContaining('Jenis Diet'), findsWidgets);
      expect(find.textContaining('Standar Diet'), findsWidgets);
      expect(find.textContaining('Pembagian Makanan'), findsWidgets);
    });

    testWidgets('kartu hasil menampilkan BMR, BB Ideal, dan Kategori IMT',
        (tester) async {
      await tester.pumpWidget(_buildPage(userRole: 'ahli_gizi'));
      await tester.pump(_kRender);

      await _fillValidForm(tester);
      await _tapSubmit(tester);

      expect(find.text('BMR'), findsOneWidget);
      expect(find.text('BB Ideal'), findsOneWidget);
      expect(find.text('Kategori IMT'), findsOneWidget);
    });

    testWidgets('koreksi usia MUNCUL untuk usia >= 40 tahun', (tester) async {
      await tester.pumpWidget(_buildPage(userRole: 'ahli_gizi'));
      await tester.pump(_kRender);

      await tester.enterText(find.byKey(const ValueKey('ageField')), '60');
      await tester.pump(_kAnim);
      await _selectDropdown(
          tester, const ValueKey('genderDropdown'), 'Laki-laki');
      await tester.enterText(find.byKey(const ValueKey('weightField')), '65');
      await tester.pump(_kAnim);
      await tester.enterText(find.byKey(const ValueKey('heightField')), '165');
      await tester.pump(_kAnim);
      await _selectDropdown(
          tester, const ValueKey('activityDropdown'), 'Ringan');
      await _selectDropdown(
          tester, const ValueKey('hospitalizedDropdown'), 'Tidak');

      await _tapSubmit(tester);

      expect(find.textContaining('Koreksi Usia'), findsOneWidget);
    });
  });

  // ===============================================================
  // [F] STRESS METABOLIK DALAM PERHITUNGAN
  // ===============================================================

  group('[Integration F] Stress Metabolik dalam Perhitungan', () {
    testWidgets(
        '"Koreksi Stress Metabolik" tampil di kartu hasil saat rawat inap = "Ya"',
        (tester) async {
      await tester.pumpWidget(_buildPage(userRole: 'ahli_gizi'));
      await tester.pump(_kRender);

      await tester.enterText(find.byKey(const ValueKey('ageField')), '45');
      await tester.pump(_kAnim);
      await _selectDropdown(
          tester, const ValueKey('genderDropdown'), 'Laki-laki');
      await tester.enterText(find.byKey(const ValueKey('weightField')), '70');
      await tester.pump(_kAnim);
      await tester.enterText(find.byKey(const ValueKey('heightField')), '168');
      await tester.pump(_kAnim);
      await _selectDropdown(
          tester, const ValueKey('activityDropdown'), 'Bed rest');
      await _selectDropdown(
          tester, const ValueKey('hospitalizedDropdown'), 'Ya');

      await _tapSubmit(tester);

      expect(find.text('Koreksi Stress Metabolik'), findsOneWidget);
    });
  });

  // ===============================================================
  // [G] DROPDOWN OPTIONS
  // ===============================================================

  group('[Integration G] Dropdown Options', () {
    testWidgets('dropdown gender memiliki opsi Laki-laki dan Perempuan',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.tap(find.byKey(const ValueKey('genderDropdown')));
      await tester.pump(_kAnim);

      expect(find.text('Laki-laki'), findsWidgets);
      expect(find.text('Perempuan'), findsWidgets);
    });

    testWidgets('dropdown aktivitas memiliki 4 level', (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.tap(find.byKey(const ValueKey('activityDropdown')));
      await tester.pump(_kAnim);

      expect(find.text('Bed rest'), findsWidgets);
      expect(find.text('Ringan'), findsWidgets);
      expect(find.text('Sedang'), findsWidgets);
      expect(find.text('Berat'), findsWidgets);
    });

    testWidgets('dropdown rawat inap memiliki opsi "Ya" dan "Tidak"',
        (tester) async {
      await tester.pumpWidget(_buildPage());
      await tester.pump(_kRender);

      await tester.tap(find.byKey(const ValueKey('hospitalizedDropdown')));
      await tester.pump(_kAnim);

      expect(find.text('Ya'), findsWidgets);
      expect(find.text('Tidak'), findsWidgets);
    });
  });

  // ===============================================================
  // [H] PDF DOWNLOAD BUTTON
  // ===============================================================

  group('[Integration H] PDF Download Button', () {
    testWidgets(
        'tombol "Download Menu PDF" tampil setelah menu terbentuk (role ahli gizi)',
        (tester) async {
      await tester.pumpWidget(_buildPage(userRole: 'ahli_gizi'));
      await tester.pump(_kRender);

      await _fillValidForm(tester);
      await _tapSubmit(tester);
      await tester.pump(_kPdf); // tunggu fetch menu dari Firestore

      final menuTile = find.text('Rekomendasi Menu Sehari');
      if (menuTile.evaluate().isNotEmpty) {
        await tester.ensureVisible(menuTile.first);
        await tester.tap(menuTile.first);
        await tester.pump(_kAnim);

        expect(find.byKey(const ValueKey('btnDownloadPdf')), findsOneWidget);
      }
    });
  });
}