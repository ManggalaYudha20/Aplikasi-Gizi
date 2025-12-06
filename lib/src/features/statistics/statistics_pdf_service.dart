// lib/src/features/statistics/services/statistics_pdf_service.dart

import 'dart:io';
import 'package:intl/intl.dart'; // Pastikan import ini ada untuk format tanggal
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/services.dart';

class StatisticsPdfService {
  /// Fungsi utama untuk generate dan membuka PDF
  static Future<void> generateAndOpenPdf({
    required String chartTitle,
    required String selectedCategory,
    required Map<String, double> dataMap,
    required int totalPasien,
    Uint8List? chartImageBytes,
  }) async {
    final pdf = pw.Document();

    // 1. Siapkan Data
    await initializeDateFormatting('id_ID', null);

    final sulutLogoData = await rootBundle.load('assets/images/sulut.png');
    final rsLogoData = await rootBundle.load('assets/images/logo.png');
    final sulutLogo = pw.MemoryImage(sulutLogoData.buffer.asUint8List());
    final rsLogo = pw.MemoryImage(rsLogoData.buffer.asUint8List());

    pw.MemoryImage? chartImage;
    if (chartImageBytes != null) {
      chartImage = pw.MemoryImage(chartImageBytes);
    }

    final DateTime now = DateTime.now();
    final DateTime nowWita = now.toUtc().add(const Duration(hours: 8));
    
    // 3. Gunakan locale 'id_ID' agar nama bulan/hari dalam Bahasa Indonesia
    // DateTime.now() secara default sudah mengambil jam lokal device pengguna
    final dateStr = "${DateFormat('EEEE, dd MMMM yyyy, HH:mm', 'id_ID').format(nowWita)} WITA";
    
    // Hitung total nilai data untuk persentase
    double totalDataValue = dataMap.values.fold(0, (prev, element) => prev + element);

    // Persiapan data tabel (Header + Isi)
    final List<List<String>> tableData = [
      ['Kategori', 'Jumlah', 'Persentase'], // Header Tabel
    ];

    dataMap.forEach((key, value) {
      // Cek apakah ini data dummy (yang disuntikkan UI agar chart tidak crash)
      bool isDummy = key == "Tidak ada data";

      // 1. Tentukan Persentase
      // Jika dummy, paksa "0%". Jika tidak, hitung normal.
      final percentage = (totalDataValue > 0 && !isDummy)
          ? "${((value / totalDataValue) * 100).toStringAsFixed(1)}%"
          : "0%";
      
      // 2. Tentukan Jumlah Orang
      // Jika dummy, paksa "0 Orang". Jika tidak, ambil value aslinya.
      final countStr = isDummy 
          ? "0 Orang" 
          : "${value.toInt()} Orang";

      tableData.add([key, countStr, percentage]);
    });

    // 2. Buat Halaman PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.legal,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return [_buildHeader(sulutLogo, rsLogo, dateStr),
            
            pw.SizedBox(height: 20),
            
            // Judul Laporan Spesifik
            pw.Center(
              child: pw.Text(
                "LAPORAN STATISTIK",
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline),
              ),
            ),
             pw.SizedBox(height: 5),
            pw.Center(
              child: pw.Text(
                "Kategori: $chartTitle",
                style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
              ),
            ),

            if (chartImage != null)
              pw.Container(
                height: 250, // Sesuaikan tinggi gambar di PDF
                alignment: pw.Alignment.center,
                child: pw.Image(chartImage, fit: pw.BoxFit.contain),
              ),

            
            pw.SizedBox(height: 20),
            pw.Text(
              "Rincian Data:",
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 5),
            
            _buildTable(tableData),
            pw.SizedBox(height: 20),
            _buildSummary(totalPasien),
            
            pw.SizedBox(height: 40),
            _buildFooter(nowWita),
          ];
        },
      ),
    );

    // 3. Simpan File ke Penyimpanan Lokal
    try {
      final output = await getTemporaryDirectory();
      // Nama file unik berdasarkan waktu
      final fileName = "Statistik_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File("${output.path}/$fileName");
      
      await file.writeAsBytes(await pdf.save());

      // 4. Buka File menggunakan package open_file
      await OpenFile.open(file.path);
    } catch (e) {
      // Error handling sederhana, biasanya dilempar ke UI
      print("Gagal membuat PDF: $e");
    }
  }

  // --- Widget Helper PDF ---

  static pw.Widget _buildHeader(pw.MemoryImage logoSulut, pw.MemoryImage logoRs, String fullDate) {
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
                    fontSize: 12, // Sedikit diperbesar agar jelas
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
              width: 60, // Sedikit disesuaikan
              height: 60,
              child: pw.Image(logoRs, fit: pw.BoxFit.contain),
            ),
          ],
        ),
        pw.SizedBox(height: 5),
        pw.Divider(thickness: 2, height: 2), // Garis ganda untuk kesan kop surat
        pw.SizedBox(height: 5),
        
        // Menampilkan Tanggal Cetak di kanan atas (di bawah garis)
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text("Dicetak: $fullDate", style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
        ),
      ],
    );
  }

  static pw.Widget _buildSummary(int total) {
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
          pw.Text("Total Pasien Terdaftar:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.Text("$total Pasien", style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(List<List<String>> data) {
    return pw.TableHelper.fromTextArray(
      headers: data[0],
      data: data.sublist(1),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.centerRight,
        2: pw.Alignment.centerRight,
      },
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: null,
    );
  }

 static pw.Widget _buildFooter(DateTime date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        pw.Text(
          'Mengetahui,',
          style: const pw.TextStyle(fontSize: 10),
        ),
        pw.SizedBox(height: 40), // Ruang tanda tangan
        pw.Text(
          'Administrator / Ahli Gizi',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Align(
           alignment: pw.Alignment.centerLeft,
           child: pw.Text(
            "* Dokumen ini digenerate secara otomatis oleh Sistem Aplikasi Diagnosa Gizi.",
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        )
      ],
    );
  }
}