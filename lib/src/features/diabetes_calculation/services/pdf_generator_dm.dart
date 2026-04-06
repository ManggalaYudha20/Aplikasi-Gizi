// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\diabetes_calculation\services\pdf_generator_dm.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

// Import dari lokasi model baru — tidak lagi dari service
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/dm_meal_session_model.dart';

// ---------------------------------------------------------------------------
// Fungsi 1: Generate bytes PDF (fleksibel, bisa dipakai untuk share/preview)
// ---------------------------------------------------------------------------
Future<Uint8List> generateDmPdfBytes(
  List<DmMealSession> menu,
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
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Dicetak: $dateStr',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
        ),
        pw.SizedBox(height: 20),
        pw.Center(
          child: pw.Text(
            'MENU MAKANAN SEHARI DIET DIABETES MELITUS',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 20),

        // ── Sesi waktu makan ─────────────────────────────────────────────────
        ...menu.map((session) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
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
              pw.TableHelper.fromTextArray(
                context: context,
                border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
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
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.center,
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
        }),

        // ── Catatan tambahan ─────────────────────────────────────────────────
        if (catatan != null && catatan.isNotEmpty) ...[
          pw.SizedBox(height: 20),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: pw.BorderRadius.circular(4),
              color: PdfColors.grey100,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Catatan Tambahan:',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(catatan, style: const pw.TextStyle(fontSize: 10)),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  return pdf.save();
}

// ---------------------------------------------------------------------------
// Fungsi 2: Generate, simpan, dan buka file (dipanggil langsung dari UI)
// ---------------------------------------------------------------------------
Future<void> saveAndOpenDmPdf(
  List<DmMealSession> menu,
  String namaPasien,
  String? catatan,
) async {
  try {
    final bytes = await generateDmPdfBytes(menu, namaPasien, catatan);
    final output = await getApplicationDocumentsDirectory();
    final fileName =
        'Menu_DM_${namaPasien.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(bytes);
    await OpenFile.open(file.path);
  } catch (e) {
    throw Exception('Gagal membuat atau membuka PDF: $e');
  }
}

// ---------------------------------------------------------------------------
// Helper privat
// ---------------------------------------------------------------------------
String _formatPdfPortion(dynamic value) {
  if (value is num) {
    return value % 1 == 0 ? value.toInt().toString() : value.toString();
  }
  return value.toString();
}
