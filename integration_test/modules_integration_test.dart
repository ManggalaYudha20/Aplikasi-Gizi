import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Dibutuhkan jika ingin mendeteksi DropdownSearch

// Ganti dengan path main.dart dari aplikasi Anda
import 'package:aplikasi_diagnosa_gizi/main.dart' as app; 

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pengujian Integrasi End-to-End Modul Utama', () {

    // Fungsi helper untuk bypass login menggunakan Email
    Future<void> ensureLoggedIn(WidgetTester tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      final loginButton = find.widgetWithText(ElevatedButton, 'Masuk');
      if (loginButton.evaluate().isNotEmpty) {
        final emailField = find.widgetWithIcon(TextField, Icons.email);
        final passwordField = find.widgetWithIcon(TextField, Icons.lock);

        await tester.enterText(emailField, 'rsudtipebprovsulut@gmail.com'); 
        await tester.enterText(passwordField, 'rsud12345');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        await tester.tap(loginButton);
        await tester.pumpAndSettle(const Duration(seconds: 5));
      }
    }

    testWidgets('1. Modul UI (Form Tambah Pasien) -> Modul Perhitungan -> Firebase (patients)', (tester) async {
      app.main();
      await ensureLoggedIn(tester);

      // 1. Pastikan berada di tab Daftar Pasien
      final tabDaftarPasien = find.text('Daftar Pasien');
      if (tabDaftarPasien.evaluate().isNotEmpty) {
        await tester.tap(tabDaftarPasien.last);
        await tester.pumpAndSettle();
      }

      // 2. Buka SpeedDial (Tombol Tambah/FAB)
      final fabAdd = find.byIcon(Icons.add).last;
      await tester.tap(fabAdd);
      await tester.pumpAndSettle(); 

      // 3. Pilih Opsi "Pasien Dewasa"
      final btnDewasa = find.text('Pasien Dewasa');
      await tester.tap(btnDewasa);
      await tester.pumpAndSettle(); 

      // 4. Isi Form Teks Normal
      await tester.enterText(find.widgetWithText(TextFormField, 'No. Rekam Medis (RM)'), 'RM-TEST-01');
      await tester.enterText(find.widgetWithText(TextFormField, 'Nama Lengkap'), 'Pasien Testing');

      // Mengisi Tanggal Lahir (Bypass perbedaan bahasa OK / OKE)
      await tester.tap(find.widgetWithText(TextFormField, 'Tanggal Lahir'));
      await tester.pumpAndSettle();
      
      final okButton = find.text('OK');
      final okeButton = find.text('OKE');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
      } else if (okeButton.evaluate().isNotEmpty) {
        await tester.tap(okeButton);
      } else {
        await tester.tap(find.byType(TextButton).last);
      }
      await tester.pumpAndSettle();

      // --- PERBAIKAN: Interaksi DropdownSearch ---

      // Jenis Kelamin
      final dropdownJK = find.widgetWithText(DropdownSearch<String>, 'Jenis Kelamin').last;
      await tester.ensureVisible(dropdownJK);
      await tester.tap(dropdownJK);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laki-laki').last);
      await tester.pumpAndSettle();

      // Diagnosis Medis (Ini TextFormField biasa, bisa di-enterText)
      final fieldDiagnosis = find.widgetWithText(TextFormField, 'Diagnosis Medis');
      await tester.ensureVisible(fieldDiagnosis);
      await tester.enterText(fieldDiagnosis, 'Diabetes Melitus');

      // Isi Berat Badan & Tinggi Badan
      await tester.enterText(find.widgetWithText(TextFormField, 'Berat Badan Saat Ini'), '65');
      await tester.enterText(find.widgetWithText(TextFormField, 'Tinggi Badan'), '170');

      // Dropdown: Asupan nutrisi
      final dropdownAsupan = find.widgetWithText(DropdownSearch<String>, 'Ada asupan nutrisi > 5 hari?').last;
      await tester.ensureVisible(dropdownAsupan);
      await tester.tap(dropdownAsupan);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ya').last);
      await tester.pumpAndSettle();

      // Dropdown: Tingkat Aktivitas
      final dropdownAktivitas = find.widgetWithText(DropdownSearch<String>, 'Tingkat Aktivitas').last;
      await tester.ensureVisible(dropdownAktivitas);
      await tester.tap(dropdownAktivitas);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sangat Jarang').last);
      await tester.pumpAndSettle();

      // Dropdown: Faktor Stres / Kondisi Klinis
      final dropdownStres = find.widgetWithText(DropdownSearch<String>, 'Faktor Stres / Kondisi Klinis').last;
      await tester.ensureVisible(dropdownStres);
      await tester.tap(dropdownStres);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Normal').last);
      await tester.pumpAndSettle();

      // Tutup keyboard
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // 5. Scroll ke tombol Tambah dan Tekan
      final btnTambah = find.text('Tambah'); 
      await tester.ensureVisible(btnTambah); // Wajib di-scroll karena ada di bagian paling bawah
      await tester.tap(btnTambah);
      
      // Tunggu proses penyimpanan ke Firebase
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // 6. Verifikasi Data berhasil dibuat
      expect(find.text('Pasien Testing'), findsWidgets);
    });

    testWidgets('2. Modul Database Firebase (food_items) -> Modul UI (Detail Makanan)', (tester) async {
      app.main();
      await ensureLoggedIn(tester);

      final tabBeranda = find.text('Beranda');
      if (tabBeranda.evaluate().isNotEmpty) {
        await tester.tap(tabBeranda.first);
        await tester.pumpAndSettle();
      }

      // 2. Scroll cerdas menggunakan ensureVisible
      final menuMakanan = find.text('Daftar Makanan');
      await tester.ensureVisible(menuMakanan); // Ini akan otomatis men-scroll layar jika off-screen
      await tester.pumpAndSettle(); 

      // 3. Klik menu tersebut
      await tester.tap(menuMakanan);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // 4. Tap salah satu item makanan
      // (Diubah menjadi find.byType(Card) karena aplikasi menggunakan FoodNutritionCard)
      final foodItem = find.byType(Card).first; 
      await tester.tap(foodItem);
      await tester.pumpAndSettle();

      // 5. Verifikasi
      expect(find.text('Informasi Gizi'), findsOneWidget);
    });

    testWidgets('3. Modul Database Firebase (leaflets) -> Modul Penampil PDF (PDF Viewer)', (tester) async {
      app.main();
      await ensureLoggedIn(tester);

      final tabBeranda = find.text('Beranda');
      if (tabBeranda.evaluate().isNotEmpty) {
        await tester.tap(tabBeranda.first);
        await tester.pumpAndSettle();
      }

      // 2. Scroll cerdas ke menu Leaflet
      final menuLeaflet = find.text('Leaflet Edukasi Gizi');
      await tester.ensureVisible(menuLeaflet);
      await tester.pumpAndSettle(); 

      // 3. Klik menu tersebut
      await tester.tap(menuLeaflet);
      await tester.pumpAndSettle(const Duration(seconds: 4));

      // --- PERBAIKAN: Validasi Judul Dinamis ---
      // Ambil Card leaflet pertama
      final firstLeafletCard = find.byType(Card).first;
      
      // Baca teks judul dari Card pertama tersebut sebelum diklik
      final titleWidgetFinder = find.descendant(of: firstLeafletCard, matching: find.byType(Text)).first;
      final dynamicTitleText = tester.widget<Text>(titleWidgetFinder).data;

      // 4. Tap Card leaflet tersebut 
      await tester.tap(firstLeafletCard);
      
      // Paksa framework menunggu 5 detik secara absolut untuk loading PDF
      await tester.pump(const Duration(seconds: 5));

      // 5. Verifikasi bahwa judul dinamis dari Card tadi muncul di layar PDF (biasanya di AppBar)
      expect(find.text(dynamicTitleText!), findsWidgets, 
        reason: 'Judul Leaflet ($dynamicTitleText) harus muncul di dalam PDF Viewer');

      // 6. Klik tombol "Back" untuk kembali dengan rapi
      final backButton = find.byTooltip('Back');
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }
    });
    testWidgets('4. Modul Database Firebase (users) -> Modul UI (Manajemen Pengguna)', (tester) async {
      app.main();
      await ensureLoggedIn(tester);

      // 1. PENTING: Navigasi ke tab Akun/Profil di Navbar bawah terlebih dahulu
      final tabAkun = find.text('Akun');
      if (tabAkun.evaluate().isNotEmpty) {
        await tester.tap(tabAkun.last);
      } else {
        // Fallback jika namanya Profil
        final tabProfil = find.text('Profil');
        if (tabProfil.evaluate().isNotEmpty) await tester.tap(tabProfil.last);
      }
      await tester.pumpAndSettle();

      // 2. Navigasi ke menu Manajemen Pengguna
      final menuAdmin = find.text('Manajemen Pengguna');
      await tester.ensureVisible(menuAdmin);
      await tester.tap(menuAdmin);
      
      await tester.pumpAndSettle(const Duration(seconds: 3));


      expect(find.byIcon(Icons.person), findsWidgets);
    });
  });
}