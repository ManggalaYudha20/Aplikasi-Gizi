// lib\src\features\patient_home\presentation\pages\pdf_generator_anak.dart

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:flutter/services.dart';

class PdfGeneratorAnak {
  static Future<File> generate(PatientAnak patient) async {
    final pdf = pw.Document();

    final sulutLogoData = await rootBundle.load('assets/images/sulut.png');
    final logoData = await rootBundle.load('assets/images/logo.png');

    final sulutLogoImage = pw.MemoryImage(sulutLogoData.buffer.asUint8List());
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Left logo
                  pw.Container(
                    width: 50,
                    height: 50,
                    child: pw.Image(sulutLogoImage, fit: pw.BoxFit.contain),
                  ),
                  pw.SizedBox(width: 10),
                  // Center text
                  pw.Column(
                    children: [
                      pw.Text(
                        'Rumah Sakit Umum Daerah ODSK',
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
                        style: pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),

                  // Right logo
                  pw.Container(
                    width: 70,
                    height: 70,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  ),
                ],
              ),
              pw.Divider(),

              pw.Center(
                child: pw.Text(
                  'FORMULIR SKRINING GIZI UNTUK ANAK',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'Pediatric Yorkhill Malnutrition Score (PYMS)',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(child: pw.Text('(Diisi oleh Dietisien/Nutrisionis)')),
              pw.SizedBox(height: 10),

              _buildInfoRow('No RM', ': ${patient.noRM}', 'Tanggal Lahir',': ${patient.tanggalLahirFormatted}'),
              _buildInfoRow('Nama Lengkap', ': ${patient.namaLengkap}', 'Tgl Periksa',': ${DateFormat('d MMMM y','id_ID').format(patient.tanggalPemeriksaan)}'),
              _buildInfoRow('Jenis Kelamin', ': ${patient.jenisKelamin}', '',''),
            
              pw.SizedBox(height: 5),

              pw.Container(
                decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  mainAxisSize: pw.MainAxisSize.min,
                  children: [
                    _buildInfoRow('Diagnosis Medis', ': ${patient.diagnosisMedis}', ''),
                    pw.SizedBox(height: 5),
                    _buildInfoRow(
                      'BB = ${patient.beratBadan} kg',
                      'BB/U = ${patient.statusGiziBBU ?? '-'}',
                      'IMT = ${(patient.beratBadan / ((patient.tinggiBadan / 100) * (patient.tinggiBadan / 100))).toStringAsFixed(1)} kg/m²',
                    ),
                    pw.SizedBox(height: 5),
                    _buildInfoRow(
                      'TB = ${patient.tinggiBadan.toStringAsFixed(0)} cm',
                      'Usia = ${patient.usiaFormatted}',
                      'IMT/U = ${patient.statusGiziIMTU}',
                    ),
                  ],
                ),
              ),

              _buildScoringTable(patient),
              pw.SizedBox(height: 5),

              pw.Text(
                '*) Penyakit yang beresiko terjadi gangguan gizi diantaranya : dirawat di HCU/ICU, penurunan kesadaran, kegawatan abdomen (pendarahan, ileus, peritonitis, asites massif, tumor intraadomen besar, post operasi), gangguan pernapasan berat, keganasan dengan komplikasi, gagal jantung, gagal ginjal kronik, gagal hati, diabetes melitus, atau kondisi sakit berat lainnya',
              textAlign: pw.TextAlign.justify,
              style : pw.TextStyle(fontSize: 8)
              ),
              pw.SizedBox(height: 5),

              _buildInterpretation(patient.totalPymsScore),

              // Footer
              pw.SizedBox(height: 8),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Tanggal : ${DateFormat('d-M-y').format(patient.tanggalPemeriksaan)}',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'TTD Dietisen/Nutrisionis',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 30),
                    pw.Text(
                      '( ${patient.namaNutrisionis ?? '-'} )',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return saveDocument(
      name: 'skrining_gizi_anak_${patient.namaLengkap}_${patient.noRM}.pdf',
      pdf: pdf,
    );
  }

  static pw.Widget _buildInterpretation(num score) {
    String scoreLabel;
    String riskText;
    String description;

    if (score == 0) {
      scoreLabel = 'Skor 0';
      riskText = 'Tanpa resiko;';
      description = ' perlu dilakukan skrining kembali setelah 1 minggu.';
    } else if (score == 1) {
      scoreLabel = 'Skor 1';
      riskText = 'Resiko rendah;';
      description = ' perlu dilakukan skrining kembali setelah 3 hari.';
    } else {
      scoreLabel = 'Skor >= 2';
      riskText = 'Resiko tinggi;';
      description =
          ' perlu asesmen lebih lanjut oleh dietisen dan/atau dokter divisi gizi.';
    }
    // Menggunakan pw.Row agar formatnya sama dengan _buildInfoRow
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          flex: 3,
          child: pw.Text(
            '$scoreLabel ',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Expanded(
          flex: 14,
          // Menggunakan RichText untuk menggabungkan teks bold dan normal
          child: pw.RichText(
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: ': $riskText',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.TextSpan(text: description),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildScoringTable(PatientAnak patient) {
    final skorAntro = patient.skorAntropometri;
    final skorBB = patient.kehilanganBeratBadan ?? 0;
    final skorMakan = patient.kehilanganNafsuMakan ?? 0;
    final skorSakit = patient.anakSakitBerat ?? 0;
    final total = patient.totalPymsScore;

    final data = [
      ['1', 'Status Antropometri', ''],
      ['', 'BB/TB untuk anak < 5 Tahun', skorAntro == 0 ? '0' : ''],
      ['', 'IMT/U untuk anak >= 5 Tahun', skorAntro >= 2 ? '2' : ''],
      ['2', 'Kehilangan atau penurunan berat badan akhir-akhir ini', ''],
      ['', 'Tidak', skorBB == 0 ? '0' : ''],
      ['', 'Ada', skorBB == 2 ? '2' : ''],
      ['3', 'Asupan makan dalam satu minggu terakhir', ''],
      ['', 'Makan seperti biasa', skorMakan == 0 ? '0' : ''],
      ['', 'Ada penurunan', skorMakan == 1 ? '1' : ''],
      ['', 'Tidak makan / Sangat sedikit', skorMakan == 2 ? '2' : ''],
      ['4', 'Anak sakit berat *)', ''],
      ['', 'Tidak', skorSakit == 0 ? '0' : ''],
      ['', 'Ya', skorSakit == 2 ? '2' : ''],
    ];

    return pw.Table(
      border: pw.TableBorder.all(),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(6),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          children: [
            pw.Center(
              child: pw.Text(
                'No',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Kriteria',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(
              child: pw.Text(
                'Skor',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
          ],
        ),
        ...data.map(
          (row) => pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(row[0]),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(row[1]),
              ),
              pw.Center(
                child: pw.Padding(
                  padding: const pw.EdgeInsets.all(4),
                  child: pw.Text(row[2]),
                ),
              ),
            ],
          ),
        ),
        pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('')),
            pw.Padding(
              padding: const pw.EdgeInsets.all(4),
              child: pw.Text(
                'Total skor keseluruhan',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ),
            pw.Center(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(4),
                child: pw.Text(
                  total.toString(),
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInfoRow(
    String label1,
    String value1, [
    String? label2,
    String? value2,
  ]) {
    return pw.Row(
      children: [
        pw.Expanded(flex: 3, child: pw.Text(label1)),
        pw.Expanded(flex: 4, child: pw.Text(value1)),
        if (label2 != null) pw.Expanded(flex: 2, child: pw.Text(label2)),
        if (value2 != null) pw.Expanded(flex: 3, child: pw.Text(value2)),
      ],
    );
  }

  static Future<File> saveDocument({
    required String name,
    required pw.Document pdf,
  }) async {
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes);
    return file;
  }

  static Future openFile(File file) async {
    final url = file.path;
    await OpenFile.open(url);
  }
}
