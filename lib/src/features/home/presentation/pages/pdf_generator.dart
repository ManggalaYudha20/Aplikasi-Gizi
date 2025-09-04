// lib/src/features/home/presentation/pages/pdf_generator.dart
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/home/data/models/patient_model.dart'; // Impor model pasien

class PdfGenerator {
  static Future<File> generate(Patient patient) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Text('Rumah Sakit Umum Daerah ODSK', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text('Provinsi Sulawesi Utara', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ),
              pw.Center(
                child: pw.Text('Jl. Bethesda no 77 Manado', style: pw.TextStyle(fontSize: 10)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.SizedBox(height: 10),

              // Title
              pw.Center(
                child: pw.Text(
                  'FORMULIR SKRINING GIZI LANJUT',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(
                child: pw.Text(
                  'UNTUK PASIEN DEWASA',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.Center(child: pw.Text('(Diisi oleh Dietisien/Nutrisionis)')),
              pw.SizedBox(height: 20),

              // Patient Info
              _buildInfoRow('No RM', ': ${patient.noRM}'),
              _buildInfoRow('Nama Lengkap', ': ${patient.namaLengkap}'),
              _buildInfoRow('Tanggal Lahir', ': ${patient.tanggalLahirFormatted}'),
              _buildInfoRow('Diagnosis Medis', ': ${patient.diagnosisMedis}'),

              pw.SizedBox(height: 20),

              _buildInfoRow('BB = ${patient.beratBadan} kg', 'TB = ${patient.tinggiBadan} cm', 'IMT = ${patient.imt.toStringAsFixed(1)} kg/m2'),
              pw.SizedBox(height: 10),
              _buildInfoRow('Tinggi Lutut = ... cm', 'LLA = ... cm'),
              pw.SizedBox(height: 20),

              // Scoring Table
              _buildScoringTable(patient),
              pw.SizedBox(height: 20),

              // Interpretation
              pw.Text('Interpretasi :', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
              pw.SizedBox(height: 5),
              _buildInterpretation(patient.totalSkor),

              // Footer
              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text('Tanggal : ${DateFormat('d/M/y').format(patient.tanggalPemeriksaan)}'),
                    pw.SizedBox(height: 40),
                    pw.Text('( Dietisien/Nutrisionis )'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
    return saveDocument(name: 'skrining_gizi_${patient.noRM}.pdf', pdf: pdf);
  }

  static pw.Widget _buildScoringTable(Patient patient) {
    final data = [
      ['1', 'Skor IMT', ''],
      ['', 'IMT > 20 (Obesitas >30)', patient.skorIMT == 0 ? '0' : ''],
      ['', 'IMT 18.5 - 30', patient.skorIMT == 1 ? '1' : ''], // Asumsi dari gambar
      ['', 'IMT < 18.5', patient.skorIMT == 2 ? '2' : ''], // Asumsi
      ['2', 'Skor kehilangan berat badan yang tidak direncanakan 3-6 bulan terakhir', ''],
      ['', 'BB hilang < 5%', patient.skorKehilanganBB == 0 ? '0' :  ''],
      ['', 'BB hilang 5-10%', patient.skorKehilanganBB == 1 ? '1' : ''], // Asumsi
      ['', 'BB hilang > 10%', patient.skorKehilanganBB == 2 ? '2' : ''],
      ['3', 'Skor efek penyakit akut', ''],
      ['', 'Ada asupan nutrisi > 5 hari', patient.skorEfekPenyakit == 0 ? '0' : ''],
      ['', 'Tidak ada asupan nutrisi > 5 hari', patient.skorEfekPenyakit == 2 ? '2' : ''],
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
            pw.Center(child: pw.Text('No', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text('Parameter', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Text('Skor', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
          ],
        ),
        ...data.map((row) => pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(row[0])),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(row[1])),
            pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(row[2]))),
          ],
        )),
         pw.TableRow(
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('')),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Total skor keseluruhan', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
            pw.Center(child: pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(patient.totalSkor.toString(), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)))),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildInterpretation(int score) {
    String text = '';
    if(score == 0) text = 'Skor 0 : Resiko rendah; Ulangi skrining setiap 7 hari atau bila ada tanda-tanda resiko malnutrisi.';
    else if(score == 1) text = 'Skor 1 : Resiko menengah; Bekerjasama dengan tim terapi gizi, Monitoring asupan setiap 3 hari. Jika tidak ada peningkatan, lanjutkan pengkajian dan ulangi skrining setiap 7 hari.';
    else if(score >= 2 && score <= 3) text = 'Skor 2-3 : Resiko tinggi; Bekerjasama dengan tim terapi gizi, mendapatkan asuhan gizi, monitoring asupan setiap 3 hari dan ulangi skrining setiap 7 hari.';
    else if(score >= 4) text = 'Skor >= 4 : Resiko sangat tinggi; Dilaporkan ke Dokter Spesialis Gizi Klinik untuk tindakan lebih lanjut. Dianjurkan melakukan asuhan gizi. Monitoring asupan setiap 3 hari dan ulangi skrining setiap 7 hari.';
    return pw.Text(text);
  }

  static pw.Widget _buildInfoRow(String label1, String value1, [String? label2, String? value2]) {
    return pw.Row(
      children: [
        pw.Expanded(flex: 3, child: pw.Text(label1)),
        pw.Expanded(flex: 4, child: pw.Text(value1)),
        if(label2 != null) pw.Expanded(flex: 2, child: pw.Text(label2)),
        if(value2 != null) pw.Expanded(flex: 3, child: pw.Text(value2)),
      ]
    );
  }

  static Future<File> saveDocument({required String name, required pw.Document pdf}) async {
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