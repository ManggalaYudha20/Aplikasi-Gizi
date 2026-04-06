// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\kidney_calculation\services\pdf_generator_kidney.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Import model dari lokasi baru
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_menu_models.dart';

// ---------------------------------------------------------------------------
// Fungsi 1: Generate bytes PDF
// ---------------------------------------------------------------------------
Future<Uint8List> generateKidneyPdfBytes(
  List<KidneyMealSession> menu,
  String namaPasien,
  String? catatan,
) async {
  final pdf = pw.Document();

  await initializeDateFormatting('id_ID', null);
  final nowWita = DateTime.now().toUtc().add(const Duration(hours: 8));
  final dateStr =
      '${DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID').format(nowWita)} WITA';

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.legal,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        // Tanggal cetak
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Dicetak: $dateStr',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(height: 20),

        // Judul
        pw.Center(
          child: pw.Text(
            'REKOMENDASI MENU HARIAN DIET GINJAL KRONIS',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.SizedBox(height: 20),

        // ── Sesi waktu makan ───────────────────────────────────────────────────
        ...menu.map((session) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                color: PdfColors.teal50,
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
                    color: PdfColors.teal900,
                  ),
                ),
              ),
              pw.SizedBox(height: 5),
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellPadding: const pw.EdgeInsets.all(5),
                headers: ['Bahan Makanan', 'Menu Makanan', 'Berat (g)', 'URT'],
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(2),
                },
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerLeft,
                },
                data: session.items
                    .map(
                      (item) => [
                        item.categoryLabel,
                        item.foodName,
                        item.weight.toStringAsFixed(0),
                        item.urt,
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 15),
            ],
          );
        }),

        // ── Catatan tambahan ──────────────────────────────────────────────────
        if (catatan != null && catatan.isNotEmpty) ...[
          pw.Divider(),
          pw.SizedBox(height: 10),
          pw.Text(
            'Catatan Tambahan:',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 5),
          pw.Text(catatan),
        ],
      ],
    ),
  );

  return pdf.save();
}

// ---------------------------------------------------------------------------
// Fungsi 2: Generate, simpan, dan buka file
// ---------------------------------------------------------------------------
Future<void> saveAndOpenKidneyPdf(
  List<KidneyMealSession> menu,
  String namaPasien,
  String? catatan,
) async {
  try {
    final bytes = await generateKidneyPdfBytes(menu, namaPasien, catatan);
    final output = await getApplicationDocumentsDirectory();
    final fileName =
        'Menu_Ginjal_${namaPasien.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  } catch (e) {
    throw Exception('Gagal export PDF: $e');
  }
}
