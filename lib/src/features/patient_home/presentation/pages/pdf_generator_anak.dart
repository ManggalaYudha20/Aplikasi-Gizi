// lib\src\features\patient_home\presentation\pages\pdf_generator_anak.dart

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';

class PdfGeneratorAnak {
  static Future<File> generate(PatientAnak patient) async {
    final pdf = pw.Document();
    
    // (Muat logo seperti di pdf_generator.dart)
    // ...

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // (Tambahkan Header Kop Surat seperti di pdf_generator.dart)
              // ...
              
              pw.Center(
                child: pw.Text(
                  'FORMULIR SKRINING GIZI ANAK (0-5 TAHUN)',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 15),

              // ...
              // Tampilkan semua data dari model PatientAnak
              // ...
              
              pw.Text('Status Gizi: ${patient.statusGiziAnak ?? '-'}'),
              pw.Text('Z-Score BB/U: ${patient.zScoreBB?.toStringAsFixed(2) ?? '-'}'),
              pw.Text('Z-Score TB/U: ${patient.zScoreTB?.toStringAsFixed(2) ?? '-'}'),

              // ... (Tanda tangan nutrisionis)
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

  // (Copy/paste saveDocument dan openFile dari pdf_generator.dart)
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