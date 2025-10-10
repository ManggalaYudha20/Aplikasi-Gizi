import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/home/data/models/patient_model.dart';

class PdfGeneratorAsuhan {
  static Future<File> generate(Patient patient) async {
    final pdf = pw.Document();

    // Muat gambar logo dari assets
    final sulutLogoData = await rootBundle.load('assets/images/sulut.png');
    final rsLogoData = await rootBundle.load('assets/images/logo.png');
    final sulutLogo = pw.MemoryImage(sulutLogoData.buffer.asUint8List());
    final rsLogo = pw.MemoryImage(rsLogoData.buffer.asUint8List());
    // Mendefinisikan ukuran F4 (210mm x 330mm)
    //const f4Format = PdfPageFormat(210 * PdfPageFormat.mm, 330 * PdfPageFormat.mm);

    // FUNGSI BARU UNTUK MEMBUAT BARIS HEADER YANG DIGABUNG
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) => [
          // HEADER
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 50,
                height: 50,
                child: pw.Image(sulutLogo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 10),
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
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),

              pw.Container(
                width: 50,
                height: 50,
                child: pw.Image(rsLogo, fit: pw.BoxFit.contain),
              ),
            ],
          ),

          pw.SizedBox(height: 5),
          pw.Divider(),
          pw.SizedBox(height: 5),

          pw.Center(
            child: pw.Text(
              'FORMULIR ASUHAN GIZI',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
            ),
          ),
          pw.SizedBox(height: 20),

          // A. DATA PASIEN
          _buildSectionHeader('A. DATA PASIEN'),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildInfoRow(
                  'Nomor RM',
                  ': ${patient.noRM}',
                  'Tanggal/Jam',
                  ':  ${DateFormat('d-M-y / HH:mm WITA').format(patient.tanggalPemeriksaan)}',
                ),
                _buildInfoRow(
                  'Nama Lengkap',
                  ': ${patient.namaLengkap}',
                  'Jenis Kelamin',
                  ': ${patient.jenisKelamin}',
                ),
                _buildInfoRow(
                  'Tanggal Lahir',
                  ': ${patient.tanggalLahirFormatted}',
                  'Usia',
                  ': ${patient.usia} tahun',
                ),
                _buildInfoRow(
                  'Diagnosa Medis',
                  ': ${patient.diagnosisMedis}',
                  '',
                  '',
                ),
              ],
            ),
          ),

          // B. ASESMEN GIZI
          _buildSectionHeader('B. ASESMEN GIZI'),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildAssessmentCategorysatu(
                  'Riwayat Gizi /FH (Food History)',
                  [
                  _buildInfoRowSatu('Alergi Makanan', ': ${patient.alergiMakanan ?? '-'}'),
                  if (patient.alergiMakanan == 'Ya')
                  _buildInfoRowSatu('Jika Jawaban Ya, Sebutkan :', ' ${patient.detailAlergi ?? ''}'),
                  pw.SizedBox(height: 10),
                  _buildInfoRowSatu('Pola Makan / Asupan (%) :', ' ${patient.polaMakan ?? '-'}'),
                  ],
                ),
                _buildAssessmentCategorysatu(
                  'Biokimia /BD (Biochemical Data)',
                  [
                    _buildAssessmentItemRow(
                      'GDS : ${patient.biokimiaGDS ?? '-'} mg/dl',
                      '',
                      'ENT : ${patient.biokimiaENT ?? '-'}',
                      '',
                    ),
                    _buildAssessmentItemRow(
                      'Ureum : ${patient.biokimiaUreum ?? '-'} mg/dl',
                      '',
                      'HGB : ${patient.biokimiaHGB ?? '-'}',
                      '',
                    ),
                  ],
                ),
                _buildAssessmentCategorysatu(
                  'Antropometri /AD (Anthropometric Data)',
                  [
                    _buildAssessmentItemRow(
                      'BB : ${patient.beratBadan} kg',
                      'IMT : ${patient.imt.toStringAsFixed(2)}',
                      'Usia : ${patient.usia} tahun',
                      '',
                    ),
                    _buildAssessmentItemRow(
                      'TB : ${patient.tinggiBadan.toStringAsFixed(0)} cm',
                      'BBI : ${patient.bbi.toStringAsFixed(1)} kg',
                      '',
                      '',
                    ),
                  ],
                ),
                _buildAssessmentCategorysatu(
                  'Klinik /Fisik /PD (Physical Data)',
                  [
                    _buildAssessmentItemRow(
                      'KU : ${patient.klinikKU ?? '-'}',
                      'TD : ${patient.klinikTD ?? '-'} mmHg',
                      'R : ${patient.klinikRR ?? '-'} x/mnt',
                      'SpO2 : ${patient.klinikSPO2 ?? '-'}%',
                    ),
                    _buildAssessmentItemRow(
                      'KES : ${patient.klinikKES ?? '-'}',
                      'N : ${patient.klinikNadi ?? '-'} x/mnt',
                      'SB : ${patient.klinikSuhu ?? '-'} °C',
                      '',
                    ),
                  ],
                ),
                _buildAssessmentCategorysatu(
                  'Riwayat Personal /CH (Client History)',
                  [
                    _buildInfoRowSatu('RPS :', ' ${patient.riwayatPenyakitSekarang ?? '-'}'),
                    _buildInfoRowSatu('RPD :', ' ${patient.riwayatPenyakitDahulu ?? '-'}'),
                  ],
                ),
              ],
            ),
          ),

          // C, D, E
          _buildSectionHeader('C. DIAGNOSA GIZI'),
          pw.Container(
            width: double.infinity, // <-- Tambahkan ini agar container mengisi lebar
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: _buildInfoRowSatu(
              'N1/NC/NB :',
              ' ${patient.diagnosaGizi ?? '-'} ',
            ),
          ),

          _buildSectionHeader('D. INTERVENSI GIZI'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildAssessmentItemRow(
                  'Energi : ${patient.tdee.toStringAsFixed(0)} kkal',
                  'Protein : ${((15/100) * patient.tdee / 4).toStringAsFixed(0)} gram',
                  'Lemak : ${((25/100) * patient.tdee / 9).toStringAsFixed(0)} gram',
                  'Karbohidrat : ${((60/100) * patient.tdee / 4).toStringAsFixed(0)} gram',
                ),
                _buildAssessmentItemRow(
                  'BM : ${patient.intervensiBentukMakanan ?? '-'}',
                  'Diet : ${patient.intervensiDiet ?? '-'}',
                  'Via : ${patient.intervensiVia ?? '-'}',
                  '',
                ),
                _buildInfoRowSatu(
                  'Tujuan :',
                  ' ${patient.intervensiTujuan ?? '-'} ',
                ),
              ],
            ),
          ),

          _buildSectionHeader('E. MONITORING DAN EVALUASI'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildInfoRowSatu(
                  'Asupan :',
                  ' ${patient.monevAsupan ?? '-'} ',
                ),
                _buildInfoRowSatu('Status gizi :', ' ${patient.monevStatusGizi ?? '-'} '),
              ],
            ),
          ),
          // Footer
          // Footer
          pw.Spacer(),
          pw.Padding(
            padding: const pw.EdgeInsets.only(
              right: 50,
            ), // <-- Tambahkan padding di sini
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Tanggal : ${DateFormat('d-M-y').format(patient.tanggalPemeriksaan)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    'Dietisen/ Nutrisionis',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 25),
                  pw.Text(
                    '( ${patient.namaNutrisionis ?? '-'} )',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    return saveDocument(
      name: 'asuhan_gizi_${patient.namaLengkap}_${patient.noRM}.pdf',
      pdf: pdf,
    );
  }

  static pw.Widget _buildInfoRow(
    String label1,
    String value1, [
    String? label2,
    String? value2,
  ]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(
            flex: 2,
            child: pw.Text(label1, style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(value1, style: const pw.TextStyle(fontSize: 9)),
          ),
          if (label2 != null)
            pw.Expanded(
              flex: 2,
              child: pw.Text(label2, style: const pw.TextStyle(fontSize: 9)),
            ),
          if (value2 != null)
            pw.Expanded(
              flex: 3,
              child: pw.Text(value2, style: const pw.TextStyle(fontSize: 9)),
            ),
        ],
      ),
    );
  }

  // Ganti fungsi lama dengan yang ini
  static pw.Widget _buildAssessmentItemRow(
    String label1,
    String value1, [
    String? label2,
    String? value2,
  ]) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        children: [
          // Pasangan Label & Nilai Pertama
          pw.Expanded(
            flex: 1, // Alokasi ruang untuk label pertama
            child: pw.Text(label1, style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.Expanded(
            flex: 1, // Alokasi ruang untuk nilai pertama
            child: pw.Text(value1, style: const pw.TextStyle(fontSize: 9)),
          ),

          // Pasangan Label & Nilai Kedua (hanya jika ada)
          if (label2 != null && value2 != null) ...[
            pw.Expanded(
              flex: 1, // Alokasi ruang untuk label kedua
              child: pw.Text(label2, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Expanded(
              flex: 1, // Alokasi ruang untuk nilai kedua
              child: pw.Text(value2, style: const pw.TextStyle(fontSize: 9)),
            ),
          ] else ...[
            // Jika tidak ada pasangan kedua, tambahkan spacer agar tetap rata
            pw.Expanded(flex: 2, child: pw.Container()),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRowSatu(String label1, String value1) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start, // <-- PENTING: Agar rata atas
      children: [
        // Label tidak perlu diubah
        pw.Text(label1, style: const pw.TextStyle(fontSize: 9)),

        // Hapus SizedBox, karena Expanded akan menangani ruang
        
        // Bungkus nilai dengan Expanded
        pw.Expanded(
          child: pw.Text(
            value1,
            style: const pw.TextStyle(fontSize: 9),
            // softWrap: true, // Ini adalah default, tapi bisa ditulis eksplisit
          ),
        ),
      ],
    ),
  );
}

  // Fungsi bantuan untuk membuat header seksi
  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
        color: PdfColors.grey300,
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      ),
    );
  }

  // **PERUBAHAN 1**: Fungsi ini sekarang menerima List<pw.Widget>
  static pw.Widget _buildAssessmentCategorysatu(
    String title,
    List<pw.Widget> items,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(width: 0.5)),
          ),
          padding: const pw.EdgeInsets.fromLTRB(4, 4, 4, 2),
          child: pw.Text(
            title,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(
            12,
            2,
            4,
            4,
          ), // Diberi indentasi
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: items, // Langsung gunakan list widget di sini
          ),
        ),
      ],
    );
  }
  
  // --- Fungsi Bantuan untuk Simpan dan Buka File (Sama seperti pdf_generator.dart) ---
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
