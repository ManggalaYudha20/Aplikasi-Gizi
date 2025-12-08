import 'dart:io';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import model menu ginjal
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_menu_models.dart';

Future<Uint8List> generateKidneyPdfBytes(
  List<KidneyMealSession> menu,
  String namaPasien,
) async {
  final pdf = pw.Document();

  await initializeDateFormatting('id_ID', null);
  final DateTime now = DateTime.now();
  // Sesuaikan zona waktu jika perlu (WITA +8)
  final DateTime nowWita = now.toUtc().add(const Duration(hours: 8)); 
  final dateStr = "${DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID').format(nowWita)} WITA";

  // Load Gambar Aset (Pastikan path sesuai pubspec.yaml)
  final sulutLogoData = await rootBundle.load('assets/images/sulut.png');
  final rsLogoData = await rootBundle.load('assets/images/logo.png');
  final sulutLogo = pw.MemoryImage(sulutLogoData.buffer.asUint8List());
  final rsLogo = pw.MemoryImage(rsLogoData.buffer.asUint8List());

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.legal,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        // 1. Kop Surat
        _buildHeader(sulutLogo, rsLogo, dateStr),

        pw.SizedBox(height: 20),

        // 2. Judul
        pw.Center(
          child: pw.Text(
            "REKOMENDASI MENU HARIAN DIET GINJAL KRONIS",
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
       
        pw.SizedBox(height: 20),

        // 3. Loop Sesi Makan (Pagi, Siang, Malam)
        ...menu.map((session) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Sesi
              pw.Container(
                color: PdfColors.teal50, // Warna background header
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                child: pw.Text(
                  session.sessionName,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                    color: PdfColors.teal900,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),

              // Tabel Item Makanan
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.all(5),
                // Definisi Kolom
                headers: ['Bahan Makanan', 'Menu Makanan', 'Berat (g)', 'URT'],
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Kategori
                  1: const pw.FlexColumnWidth(3), // Menu
                  2: const pw.FlexColumnWidth(1), // Berat
                  3: const pw.FlexColumnWidth(2), // URT
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                },
                // Mapping Data
                data: session.items.map((item) => [
                  item.categoryLabel,
                  item.foodName,
                  item.weight.toStringAsFixed(0), // Hilangkan desimal jika 0
                  item.urt,
                ]).toList(),
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

// Widget Kop Surat (Sama dengan DM)
pw.Widget _buildHeader(pw.MemoryImage logoSulut, pw.MemoryImage logoRs, String fullDate) {
  return pw.Column(
    children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(width: 50, height: 50, child: pw.Image(logoSulut)),
          pw.SizedBox(width: 15),
          pw.Column(
            children: [
              pw.Text('Rumah Sakit Umum Daerah', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('Provinsi Sulawesi Utara', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
              pw.Text('Jl. Bethesda No. 77, Manado', style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
          pw.SizedBox(width: 15),
          pw.Container(width: 60, height: 60, child: pw.Image(logoRs)),
        ],
      ),
      pw.SizedBox(height: 5),
      pw.Divider(thickness: 2),
      pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text("Dicetak: $fullDate", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
      ),
    ],
  );
}

// Fungsi Utama dipanggil UI
Future<void> saveAndOpenKidneyPdf(List<KidneyMealSession> menu, String namaPasien) async {
  try {
    final bytes = await generateKidneyPdfBytes(menu, namaPasien);
    final output = await getApplicationDocumentsDirectory();
    // Nama file unik
    final fileName = 'Menu_Ginjal_${namaPasien.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  } catch (e) {
    throw Exception("Gagal export PDF: $e");
  }
}