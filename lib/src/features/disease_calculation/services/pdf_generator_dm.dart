// lib/src/features/disease_calculation/services/pdf_generator_dm.dart

import 'dart:io'; // Untuk File operations
import 'package:flutter/services.dart'; // Untuk rootBundle (load font/images)
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart'; // Pindahkan ke sini
import 'package:open_file/open_file.dart'; // Pindahkan ke sini
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/diabetes_meal_planner_service.dart';
import 'package:intl/intl.dart'; // Format Tanggal
import 'package:intl/date_symbol_data_local.dart';

// Fungsi 1: HANYA Menggenerate Bytes (Tetap dipertahankan untuk fleksibilitas)
Future<Uint8List> generateDmPdfBytes(
  List<DmMealSession> menu,
  String namaPasien,
) async {
  final pdf = pw.Document();

  await initializeDateFormatting('id_ID', null);
  final DateTime now = DateTime.now();
  final DateTime nowWita = now.toUtc().add(
    const Duration(hours: 8),
  ); // Sesuaikan zona waktu
  final dateStr =
      "${DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID').format(nowWita)} WITA";

  // 2. Load Gambar untuk Kop Surat
  // Pastikan file ini ada di pubspec.yaml Anda
  final sulutLogoData = await rootBundle.load('assets/images/sulut.png');
  final rsLogoData = await rootBundle.load('assets/images/logo.png');
  final sulutLogo = pw.MemoryImage(sulutLogoData.buffer.asUint8List());
  final rsLogo = pw.MemoryImage(rsLogoData.buffer.asUint8List());

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.legal,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        _buildHeader(sulutLogo, rsLogo, dateStr),

        pw.SizedBox(height: 20),

        pw.Center(
          child: pw.Text(
            "MENU MAKANAN SEHARI DIET DIABETES MELITUS",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
       
        pw.SizedBox(height: 20),

        ...menu.map((session) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Waktu Makan (Pagi/Siang/Malam)
              pw.Container(
                color: PdfColors.grey200,
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(
                  vertical: 5,
                  horizontal: 10,
                ),
                child: pw.Text(
                  session.sessionName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),

              // Tabel Menu
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(
                  color: PdfColors.black, 
                  width: 0.5, // Ketebalan garis
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                ),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.all(5),
                headers: ['Bahan Makanan', 'Menu Makanan', 'Penukar'],
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft, // Kolom Bahan Makanan: Rata Kiri
                  1: pw.Alignment.centerLeft, // Kolom Menu Makanan: Rata Kiri
                  2: pw.Alignment.center,     // Kolom Penukar: Rata Tengah (Center)
                },
                data: session.items
                    .map(
                      (item) => [
                        item.categoryLabel,
                        item.foodName,
                        _formatPdfPortion(item.portion),
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 15),
            ],
          );
        }).toList(),
      ],
    ),
  );

  return pdf.save();
}

pw.Widget _buildHeader(
  pw.MemoryImage logoSulut,
  pw.MemoryImage logoRs,
  String fullDate,
) {
  return pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          // Logo Kiri (Sulut)
          pw.Container(
            width: 50,
            height: 50,
            child: pw.Image(logoSulut, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 10),

          // Teks Tengah
          pw.Column(
            children: [
              pw.Text(
                'Rumah Sakit Umum Daerah',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'Provinsi Sulawesi Utara',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              pw.Text(
                'Jl. Bethesda No. 77, Manado',
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          ),

          pw.SizedBox(width: 10),

          // Logo Kanan (RS)
          pw.Container(
            width: 60,
            height: 60,
            child: pw.Image(logoRs, fit: pw.BoxFit.contain),
          ),
        ],
      ),
      pw.SizedBox(height: 5),
      pw.Divider(thickness: 2, height: 2),
      pw.SizedBox(height: 5),

      // Tanggal Cetak
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          "Dicetak: $fullDate",
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ),
    ],
  );
}

// Fungsi 2: Generate, Simpan, dan Buka File (Fungsi yang akan dipanggil UI)
Future<void> saveAndOpenDmPdf(
  List<DmMealSession> menu,
  String namaPasien,
) async {
  try {
    // 1. Generate Bytes
    final bytes = await generateDmPdfBytes(menu, namaPasien);

    // 2. Dapatkan path directory
    final output = await getApplicationDocumentsDirectory();

    // 3. Buat nama file unik (gunakan timestamp agar tidak bentrok)
    final fileName =
        'Menu_DM_${namaPasien.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');

    // 4. Tulis file
    await file.writeAsBytes(bytes);

    // 5. Buka file menggunakan package open_file
    await OpenFile.open(file.path);
  } catch (e) {
    throw Exception("Gagal membuat atau membuka PDF: $e");
  }
}

String _formatPdfPortion(dynamic value) {
  // Jika value adalah angka (int atau double)
  if (value is num) {
    // Cek apakah angka bulat (contoh: 1.0 % 1 == 0)
    if (value % 1 == 0) {
      return value.toInt().toString(); // Return "1"
    }
    // Jika desimal (contoh: 1.5)
    return value.toString(); // Return "1.5"
  }
  // Jika string (contoh: "S")
  return value.toString();
}
