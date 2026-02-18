// lib/src/features/statistics/services/statistics_pdf_service.dart

import 'dart:io';
import 'package:flutter/material.dart' show DateTimeRange, debugPrint;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class StatisticsPdfService {
  StatisticsPdfService._(); // prevent instantiation – all methods are static

  // ─── Public API ─────────────────────────────────────────────────────────────

  /// Generates a statistics PDF report and opens it with the device viewer.
  static Future<void> generateAndOpenPdf({
    required String chartTitle,
    required String selectedCategory,
    required Map<String, double> dataMap,
    required int totalPasien,
    Uint8List? chartImageBytes,
    DateTimeRange? dateRange,
  }) async {
    // 1. Prepare locale & assets in parallel for faster startup.
    await initializeDateFormatting('id_ID', null);

    final results = await Future.wait([
      rootBundle.load('assets/images/sulut.png'),
      rootBundle.load('assets/images/logo.png'),
    ]);

    final sulutLogo = pw.MemoryImage(results[0].buffer.asUint8List());
    final rsLogo    = pw.MemoryImage(results[1].buffer.asUint8List());

    final pw.MemoryImage? chartImage =
        chartImageBytes != null ? pw.MemoryImage(chartImageBytes) : null;

    // 2. Timestamps & formatted strings.
    final DateTime nowWita =
        DateTime.now().toUtc().add(const Duration(hours: 8));
    final String printDate =
        "${DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID').format(nowWita)} WITA";
    final String periodLabel = _buildPeriodLabel(dateRange);

    // 3. Build table rows.
    final List<List<String>> tableRows =
        _buildTableRows(dataMap: dataMap);

    // 4. Assemble PDF document.
    final pw.Document pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.legal,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) => [
          _buildHeader(sulutLogo, rsLogo, printDate),
          pw.SizedBox(height: 20),
          _buildReportTitle(chartTitle: chartTitle, periodLabel: periodLabel),
          if (chartImage != null) _buildChartSection(chartImage),
          pw.SizedBox(height: 20),
          _buildTableSection(tableRows),
          pw.SizedBox(height: 20),
          _buildSummaryBox(totalPasien),
          pw.SizedBox(height: 40),
          _buildFooter(nowWita),
        ],
      ),
    );

    // 5. Save & open.
    await _saveAndOpen(pdf);
  }

  // ─── Data Builders ──────────────────────────────────────────────────────────

  static String _buildPeriodLabel(DateTimeRange? dateRange) {
    if (dateRange == null) return "Semua Waktu";
    final String start =
        DateFormat('dd/MM/yyyy').format(dateRange.start);
    final String end = DateFormat('dd/MM/yyyy').format(dateRange.end);
    return "$start – $end";
  }

  /// Converts [dataMap] into a list of [category, count, percentage] rows.
  /// Dummy entries (key == "Tidak ada data") are normalised to zero.
  static List<List<String>> _buildTableRows({
    required Map<String, double> dataMap,
  }) {
    final double total =
        dataMap.values.fold(0, (prev, v) => prev + v);

    return dataMap.entries.map((entry) {
      final bool isDummy = entry.key == "Tidak ada data";
      final String percentage = (!isDummy && total > 0)
          ? "${((entry.value / total) * 100).toStringAsFixed(1)}%"
          : "0%";
      final String count =
          isDummy ? "0 Orang" : "${entry.value.toInt()} Orang";
      return [entry.key, count, percentage];
    }).toList();
  }

  // ─── File I/O ───────────────────────────────────────────────────────────────

  static Future<void> _saveAndOpen(pw.Document pdf) async {
    try {
      final Directory output = await getTemporaryDirectory();
      final String fileName =
          "Statistik_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final File file = File("${output.path}/$fileName");
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      debugPrint("Gagal membuat PDF: $e");
      rethrow; // propagate to UI for SnackBar handling
    }
  }

  // ─── PDF Section Builders ───────────────────────────────────────────────────

  static pw.Widget _buildHeader(
    pw.MemoryImage logoSulut,
    pw.MemoryImage logoRs,
    String printDate,
  ) {
    return pw.Column(
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.center,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Container(
              width: 50,
              height: 50,
              child: pw.Image(logoSulut, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 10),
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
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            "Dicetak: $printDate",
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildReportTitle({
    required String chartTitle,
    required String periodLabel,
  }) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            "LAPORAN STATISTIK",
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              decoration: pw.TextDecoration.underline,
            ),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            "Kategori: $chartTitle",
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.SizedBox(height: 5),
        pw.Center(
          child: pw.Text(
            "Periode: $periodLabel",
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey800),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildChartSection(pw.MemoryImage chartImage) {
    return pw.Container(
      height: 250,
      alignment: pw.Alignment.center,
      child: pw.Image(chartImage, fit: pw.BoxFit.contain),
    );
  }

  static pw.Widget _buildTableSection(List<List<String>> rows) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          "Rincian Data:",
          style:
              pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 5),
        _buildTable(rows),
      ],
    );
  }

  static pw.Widget _buildTable(List<List<String>> rows) {
    return pw.TableHelper.fromTextArray(
      headers: const ['Kategori', 'Jumlah', 'Persentase'],
      data: rows,
      headerStyle: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration:
          const pw.BoxDecoration(color: PdfColors.green700),
      rowDecoration:
          const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(
          horizontal: 10, vertical: 8),
      border: null,
    );
  }

  static pw.Widget _buildSummaryBox(int total) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            "Total Pasien Terdaftar:",
            style: pw.TextStyle(
                fontSize: 14, fontWeight: pw.FontWeight.bold),
          ),
          pw.Text(
            "$total Pasien",
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green800,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(DateTime nowWita) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text('Mengetahui,',
            style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 40),
        pw.Text(
          'Administrator / Ahli Gizi',
          style:
              pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Align(
          alignment: pw.Alignment.centerLeft,
          child: pw.Text(
            "* Dokumen ini digenerate secara otomatis oleh Sistem Aplikasi Diagnosa Gizi.",
            style: const pw.TextStyle(
                fontSize: 8, color: PdfColors.grey600),
          ),
        ),
      ],
    );
  }
}