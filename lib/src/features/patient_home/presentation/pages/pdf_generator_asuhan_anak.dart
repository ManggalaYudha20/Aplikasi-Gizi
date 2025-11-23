//lib\src\features\patient_home\presentation\pages\pdf_generator_asuhan_anak.dart
import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:intl/date_symbol_data_local.dart';

class PdfGeneratorAsuhanAnak {
  static Future<File> generate(PatientAnak patient) async {
    final pdf = pw.Document();

    await initializeDateFormatting('id_ID', null);

    // 1. Muat gambar logo dari assets
    final sulutLogoData = await rootBundle.load('assets/images/sulut.png');
    final rsLogoData = await rootBundle.load('assets/images/logo.png');
    final sulutLogo = pw.MemoryImage(sulutLogoData.buffer.asUint8List());
    final rsLogo = pw.MemoryImage(rsLogoData.buffer.asUint8List());

   String rawAlergi = patient.alergiMakanan ?? '';
    String dataAlergiLower = rawAlergi.toLowerCase();

    // A. Tentukan Status (Hanya Ya / Tidak)
    String statusAlergiDisplay = (rawAlergi.isEmpty || rawAlergi == 'Tidak') ? 'Tidak' : 'Ya';

    // B. Tentukan Lain-lain (Filter out item checkbox)
    // Daftar kata kunci yang ada di checkbox
    final checkboxKeywords = [
      'telur', 'susu', 'kacang', 'gluten', 'gandum', 'udang', 'ikan', 'hazelnut', 'almond'
    ];

    List<String> otherAllergies = [];
    if (statusAlergiDisplay == 'Ya') {
      // Pecah string database (contoh: "Telur, Udang, Stroberi")
      List<String> items = rawAlergi.split(', ');
      
      for (var item in items) {
        String itemLower = item.toLowerCase();
        bool isCheckboxItem = false;

        // Cek apakah item ini termasuk dalam keyword checkbox
        for (var keyword in checkboxKeywords) {
          if (itemLower.contains(keyword)) {
            isCheckboxItem = true;
            break;
          }
        }

        // Jika BUKAN checkbox item, masukkan ke list 'Lain-lain'
        if (!isCheckboxItem && item.trim().isNotEmpty) {
          otherAllergies.add(item);
        }
      }
    }
    // Gabungkan sisa alergi, jika kosong beri tanda strip
    String detailLainnyaDisplay = otherAllergies.isEmpty ? '-' : otherAllergies.join(', ');
    // -------------------------------------

    // 2. Atur Waktu (WITA) - LOGIKA DIPERBAIKI
    // Langkah 1: Ambil waktu dari database
    final DateTime rawTime = patient.tanggalPemeriksaan;

    // Langkah 2: Pastikan kita mulai dari UTC murni untuk menghindari bias zona waktu HP/Server
    final DateTime utcTime = rawTime.isUtc ? rawTime : rawTime.toUtc();

    // Langkah 3: Tambahkan 8 jam manual untuk menjadi WITA
    // Hasil 'pemeriksaanWita' ini secara teknis masih 'isUtc=true',
    // tapi angkanya sudah digeser agar sesuai jam dinding di WITA.
    final DateTime pemeriksaanWita = utcTime.add(const Duration(hours: 8));

    // 3. Formatter Khusus Indonesia
    // 'HH' (H besar) = Format 24 Jam (00-23) -> Menghasilkan "23:39"
    // 'd-MM-yyyy' = Format Tanggal standar
    final dateFormatIndonesia = DateFormat('d-MM-yyyy / HH:mm', 'id_ID');

    // Helper untuk formatting angka agar tidak error jika null
    String formatNum(num? value, [String unit = '']) {
      if (value == null) return '-';
      // Jika bilangan bulat, tampilkan tanpa desimal, jika desimal tampilkan 2 angka belakang koma
      if (value % 1 == 0) {
        return '${value.toInt()} $unit';
      }
      return '${value.toStringAsFixed(2)} $unit';
    }

    // Helper untuk string null
    String formatString(String? value) {
      if (value == null || value.trim().isEmpty) return '-';
      return value;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.legal,
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) => [
          // --- HEADER ---
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
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    'Provinsi Sulawesi Utara',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  pw.Text(
                    'Jl. Bethesda No. 77, Manado',
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.Container(
                width: 70,
                height: 70,
                child: pw.Image(rsLogo, fit: pw.BoxFit.contain),
              ),
            ],
          ),

          pw.SizedBox(height: 2),
          pw.Divider(),
          pw.SizedBox(height: 2),

          pw.Center(
            child: pw.Text(
              'FORMULIR ASUHAN GIZI ANAK',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
            ),
          ),
          pw.SizedBox(height: 10),

          // --- A. DATA PASIEN ---
          _buildSectionHeader('A. DATA PASIEN'),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildInfoRow(
                  'Nomor RM',
                  ': ${patient.noRM}',
                  'Tanggal/Jam',
                  ': ${dateFormatIndonesia.format(pemeriksaanWita)} WITA',
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
                  ': ${patient.usiaFormatted}',
                ),
                _buildInfoRow(
                  'Diagnosa Medis',
                  ': ${patient.diagnosisMedis}',
                  '', // Placeholder kosong
                  '',
                ),
              ],
            ),
          ),

          // --- B. ASESMEN GIZI ---
          _buildSectionHeader('B. ASESMEN GIZI'),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildAssessmentCategorysatu('Antropometri /AD (Anthropometric Data)', [
                  _buildSymmetricalRow(
                    'BB :',
                    formatNum(patient.beratBadan, 'kg'),
                    'Status (BB/U) :',
                    '${patient.zScoreBBU?.toStringAsFixed(2) ?? '-'} SD (${formatString(patient.statusGiziBBU)})',
                  ),
                  _buildSymmetricalRow(
                    'TB :',
                    formatNum(patient.tinggiBadan, 'cm'),
                    'Status (TB/U) :',
                    '${patient.zScoreTBU?.toStringAsFixed(2) ?? '-'} SD (${formatString(patient.statusGiziTBU)})',
                  ),
                  _buildSymmetricalRow(
                    'LILA :',
                    formatNum(patient.lila, 'cm'), // Mengambil data LILA
                    'Status (BB/TB) :',
                    '${patient.zScoreBBTB?.toStringAsFixed(2) ?? '-'} SD (${formatString(patient.statusGiziBBTB)})',
                  ),
                  _buildSymmetricalRow(
                    'LK :',
                    formatNum(
                      patient.lingkarKepala,
                      'cm',
                    ), // Mengambil data Lingkar Kepala
                    'Status (IMT/U) :',
                    '${patient.zScoreIMTU?.toStringAsFixed(2) ?? '-'} SD (${formatString(patient.statusGiziIMTU)})',
                  ),
                  _buildSymmetricalRow(
                    'BBI :',
                    formatNum(
                      patient.bbi,
                      'kg',
                    ), // Mengambil data Berat Badan Ideal
                    '', // Kosongkan jika tidak ada status LILA/U spesifik
                    '',
                  ),
                ]),
                _buildAssessmentCategorysatu('Biokimia /BD (Biochemical Data)', [
                  _buildAssessmentItemRow(
                    'GDS : ${formatString(patient.biokimiaGDS)}', // Value GDS
                    '',
                    'ENT : ${formatString(patient.biokimiaENT)}', // Value ENT
                    '',
                  ),
                  _buildAssessmentItemRow(
                    'Ureum : ${formatString(patient.biokimiaUreum)}', // Value Ureum
                    '',
                    'HGB : ${formatString(patient.biokimiaHGB)}', // Value HGB
                    '',
                  ),
                ]),
                _buildAssessmentCategorysatu(
                  'Klinik /Fisik /PD (Physical Data)',
                  [
                    _buildAssessmentItemRow(
                      'KU : ${formatString(patient.klinikKU)}',
                      'TD : ${formatString(patient.klinikTD)} mmHg',
                      'R : ${formatString(patient.klinikRR)} x/mnt',
                      'SpO2 : ${formatString(patient.klinikSPO2)} %',
                    ),
                    _buildAssessmentItemRow(
                      'KES : ${formatString(patient.klinikKES)}',
                      'N : ${formatString(patient.klinikNadi)} x/mnt',
                      'SB : ${formatString(patient.klinikSuhu)} °C',
                      '',
                    ),
                  ],
                ),
                _buildAssessmentCategorysatu('Riwayat Gizi /FH (Food History)', [
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Kiri: Alergi Makanan
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'Alergi Makanan :',
                              style: pw.TextStyle(
                                fontSize: 9,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.Text('Status: $statusAlergiDisplay', style: const pw.TextStyle(fontSize: 9)),
                            pw.SizedBox(height: 4),
                            _buildCheckboxRow('Telur', dataAlergiLower.contains('telur')),
                            _buildCheckboxRow('Susu Sapi / Produk turunannya', dataAlergiLower.contains('susu')),
                            _buildCheckboxRow('Kacang Kedelai/Tanah', dataAlergiLower.contains('kacang')),
                            _buildCheckboxRow('Gluten/Gandum', dataAlergiLower.contains('gluten') || dataAlergiLower.contains('gandum')),
                          ],
                        ),
                      ),
                      // Kanan: Pola Makan
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 11),
                            _buildCheckboxRow('Udang', dataAlergiLower.contains('udang')),
                            _buildCheckboxRow('Ikan', dataAlergiLower.contains('ikan')),
                            _buildCheckboxRow('Hazelnuts/Almond', dataAlergiLower.contains('hazelnut') || dataAlergiLower.contains('almond')),

                            _buildInfoRowSatu('Lain-lain / Detail : ', detailLainnyaDisplay),
                          ],
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  _buildInfoRowSatu(
                    'Pola Makan / Asupan (%) : ',
                    formatString(patient.polaMakan),
                  ),
                ]),
                _buildAssessmentCategorysatu('Total Asupan', [
                  _buildTotalIntakeTable(),
                ]),
                _buildAssessmentCategorysatu(
                  'Riwayat Personal /CH (Client History)',
                  [
                    _buildInfoRowSatu(
                      'RPS :',
                      ' ${formatString(patient.riwayatPenyakitSekarang)}',
                    ),
                    _buildInfoRowSatu(
                      'RPD :',
                      ' ${formatString(patient.riwayatPenyakitDahulu)}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- C. DIAGNOSA GIZI ---
          _buildSectionHeader('C. DIAGNOSA GIZI'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: _buildInfoRowSatu(
              'Diagnosa Gizi :',
              ' ${formatString(patient.diagnosaGizi)}',
            ),
          ),

          // --- D. INTERVENSI GIZI ---
          _buildSectionHeader('D. INTERVENSI GIZI'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildAssessmentItemRow(
                  'BM : ${formatString(patient.intervensiBentukMakanan)}',
                  'Jenis Diet : ${formatString(patient.intervensiDiet)}',
                  'Via : ${formatString(patient.intervensiVia)}',
                  '',
                ),
                pw.SizedBox(height: 4),
                _buildInfoRowSatu(
                  'Tujuan Diet :',
                  ' ${formatString(patient.intervensiTujuan)}',
                ),
              ],
            ),
          ),

          // --- E. MONITORING DAN EVALUASI ---
          _buildSectionHeader('E. MONITORING DAN EVALUASI'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildInfoRowSatu(
                  'Asupan Makanan :',
                  ' ${formatString(patient.monevAsupan)}',
                ),
                _buildInfoRowSatu(
                  'Status gizi : BB/U : ',
                  ' ${patient.statusGiziBBU ?? '-'}',
                ),
              ],
            ),
          ),

          // --- FOOTER ---
          pw.SizedBox(height: 10),
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 20),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Tanggal : ${DateFormat('d-M-y').format(pemeriksaanWita)}',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    'Dietisen/ Nutrisionis',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 20),
                  pw.Text(
                    '( ${patient.namaNutrisionis ?? '.............................'} )',
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
      name: 'asuhan_gizi_anak_${patient.namaLengkap}_${patient.noRM}.pdf',
      pdf: pdf,
    );
  }

  static pw.Widget _buildCheckboxRow(String label, bool isChecked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: isChecked
                ? pw.Center(
                    child: pw.Text(
                      'V', // Karakter centang manual
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  )
                : null, // Jika false, kotak kosong
          ),
          pw.SizedBox(width: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildSymmetricalRow(
    String labelLeft,
    String valueLeft,
    String labelRight,
    String valueRight,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        crossAxisAlignment:
            pw.CrossAxisAlignment.start, // Agar rata atas jika teks panjang
        children: [
          // --- BAGIAN KIRI (50% Layar) ---
          pw.Expanded(
            flex: 1,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Label Kiri
                pw.Text(labelLeft, style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(width: 2),
                // Value Kiri (Mengisi sisa ruang di blok kiri)
                pw.Expanded(
                  child: pw.Text(
                    valueLeft,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),

          // Jarak antar blok Kiri dan Kanan
          pw.SizedBox(width: 10),

          // --- BAGIAN KANAN (50% Layar) ---
          pw.Expanded(
            flex: 1,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Label Kanan
                pw.Text(labelRight, style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(width: 2),
                // Value Kanan (Mengisi sisa ruang di blok kanan)
                pw.Expanded(
                  child: pw.Text(
                    valueRight,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalIntakeTable() {
    const headers = ['Zat Gizi', 'Nilai', 'Kebutuhan', '%'];
    const rowLabels = [
      'Energi (kkal)',
      'Protein (gram)',
      'Lemak (gram)',
      'KH (gram)',
    ];

    // Item untuk tabel kanan
    const rightTableItems = ['Energi', 'Protein', 'Cairan'];

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // --- TABEL KIRI (Detail Zat Gizi) ---
          pw.Expanded(
            flex: 5,
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5),
                1: const pw.FlexColumnWidth(1.5),
                2: const pw.FlexColumnWidth(1.5),
                3: const pw.FlexColumnWidth(1.0),
              },
              children: [
                // Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: headers
                      .map((h) => _buildTableCell(h, isHeader: true))
                      .toList(),
                ),
                // Rows
                ...rowLabels.map(
                  (label) => pw.TableRow(
                    children: [
                      _buildTableCell(label),
                      _buildTableCell(''), // Kosong
                      _buildTableCell(''), // Kosong
                      _buildTableCell(''), // Kosong
                    ],
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(width: 8), // Jarak antar tabel
          // --- TABEL KANAN (Ringkasan Kebutuhan) ---
          pw.Expanded(
            flex: 3,
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              // PERBAIKAN: Tambahkan columnWidths agar Expanded di dalam sel bekerja
              columnWidths: {0: const pw.FlexColumnWidth(1)},
              children: [
                // Header Kanan
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Protein Kebutuhan', isHeader: true),
                  ],
                ),
                // Data Rows Kanan (Energi, Protein, Cairan)
                ...rightTableItems.map(
                  (item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 5,
                        ),
                        child: pw.Row(
                          // Align bottom agar titik-titik lurus dengan teks
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              '$item : ',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
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
          pw.Expanded(
            flex: 1,
            child: pw.Text(label1, style: const pw.TextStyle(fontSize: 9)),
          ),
          pw.Expanded(
            flex: 1,
            child: pw.Text(value1, style: const pw.TextStyle(fontSize: 9)),
          ),
          if (label2 != null && value2 != null) ...[
            pw.Expanded(
              flex: 1,
              child: pw.Text(label2, style: const pw.TextStyle(fontSize: 9)),
            ),
            pw.Expanded(
              flex: 1,
              child: pw.Text(value2, style: const pw.TextStyle(fontSize: 9)),
            ),
          ] else ...[
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
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label1, style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Text(value1, style: const pw.TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }

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
          padding: const pw.EdgeInsets.fromLTRB(12, 2, 4, 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: items,
          ),
        ),
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
