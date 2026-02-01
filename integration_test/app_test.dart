// integration_test/app_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Import main app Anda
import 'package:aplikasi_diagnosa_gizi/main.dart' as app;

void main() {
  // Inisialisasi binding untuk integration test
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('verify app starts and shows login screen', (tester) async {
    // Jalankan aplikasi
    app.main();

    // Tunggu aplikasi selesai render
    await tester.pumpAndSettle();

    // Cari widget yang seharusnya muncul, misal teks di Login Screen
    // Sesuaikan dengan teks nyata di LoginScreen Anda
    // Contoh: mencari tombol 'Masuk' atau judul aplikasi
    expect(find.text('Masuk'), findsOneWidget); 
  });
}