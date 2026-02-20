// lib/src/features/patient_home/presentation/pages/pdf_generator_asuhan_anak.dart

import 'dart:io';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';
import 'package:intl/date_symbol_data_local.dart';

class PdfGeneratorAsuhanAnak {
  // ─── Keyword alergi yang ditampilkan sebagai checkbox di formulir ───────────
  static const _checkboxAllergyKeywords = [
    'telur', 'susu', 'kacang', 'gluten', 'gandum', 'udang', 'ikan',
    'hazelnut', 'almond',
  ];

  // ─── Format angka: tanpa desimal jika bulat, 2 desimal jika pecahan ─────────
  static String _formatNum(num? value, [String unit = '']) {
    if (value == null) return '-';
    final formatted =
        value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
    return unit.isEmpty ? formatted : '$formatted $unit';
  }

  // ─── Format string: kembalikan '-' jika null atau kosong ────────────────────
  static String _formatString(String? value) =>
      (value == null || value.trim().isEmpty) ? '-' : value;

  // ─── Konversi waktu database ke WITA (UTC+8) ─────────────────────────────────
  // Database menyimpan waktu dalam UTC; kita shift +8 jam secara manual
  // agar angkanya sesuai jam dinding WITA tanpa bergantung timezone device.
  static DateTime _toWita(DateTime raw) {
    final utc = raw.isUtc ? raw : raw.toUtc();
    return utc.add(const Duration(hours: 8));
  }

  // ─── Pisahkan alergi "lain-lain" (di luar item checkbox) ────────────────────
  static List<String> _extractOtherAllergies(String rawAlergi) {
    if (rawAlergi.isEmpty || rawAlergi == 'Tidak') return [];
    return rawAlergi.split(', ').where((item) {
      final lower = item.toLowerCase();
      return item.trim().isNotEmpty &&
          !_checkboxAllergyKeywords.any((kw) => lower.contains(kw));
    }).toList();
  }

  // ─── Hitung total bulan antara dua tanggal (tanggalLahir → tanggalUkur) ─────
  static int _totalBulan(DateTime lahir, DateTime ukur) {
    int years  = ukur.year  - lahir.year;
    int months = ukur.month - lahir.month;
    if (ukur.day < lahir.day) months--;
    if (months < 0) { years--; months += 12; }
    return (years * 12) + months;
  }

  // ─── Kategori z-score IMT/U (berlaku untuk 5-18 tahun) ───────────────────
  static String _imtuCategory(double zScore) {
    if (zScore < -3) return 'Gizi buruk';
    if (zScore < -2) return 'Gizi kurang';
    if (zScore <= 1) return 'Gizi baik';
    if (zScore <= 2) return 'Gizi lebih';
    return 'Obesitas (obese)';
  }

  // ─── Hitung Z-score & kategori IMT/U 5-18 tahun ──────────────────────────
  /// Mengembalikan map dengan kunci 'zScore' (double?) dan 'category' (String).
  static Map<String, dynamic> _computeIMTU5To18({
    required int    ageYears,
    required int    ageMonths,
    required double bmi,
    required String gender,
  }) {
    final String ageKey    = '$ageYears-$ageMonths';
    final bool   isMale    = gender.toLowerCase().contains('laki') ||
                              gender.toLowerCase().contains('pria') ||
                              gender.toLowerCase() == 'l';
    final List<double>? ref = isMale
        ? NutritionStatusData.imtUBoys5To18[ageKey]
        : NutritionStatusData.imtUGirls5To18[ageKey];

    if (ref == null) {
      return {
        'zScore'  : null,
        'category': 'Data referensi tidak tersedia',
        'bmi'     : bmi,
      };
    }

    try {
      final double median = ref[3];
      // SD positif = selisih median ke +1SD; SD negatif = median ke -1SD
      final double sdPos  = ref[4] - median;
      final double sdNeg  = median - ref[2];
      final double sd     = bmi >= median ? sdPos : sdNeg;
      final double zScore = (bmi - median) / sd;
      return {
        'zScore'  : zScore,
        'category': _imtuCategory(zScore),
        'bmi'     : bmi,
      };
    } catch (_) {
      return {
        'zScore'  : null,
        'category': 'Error perhitungan',
        'bmi'     : bmi,
      };
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  static Future<File> generate(PatientAnak patient) async {
    await initializeDateFormatting('id_ID', null);

    final sulutLogo = pw.MemoryImage(
      (await rootBundle.load('assets/images/sulut.png')).buffer.asUint8List(),
    );
    final rsLogo = pw.MemoryImage(
      (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List(),
    );

    final rawAlergi = patient.alergiMakanan ?? '';
    final dataAlergiLower = rawAlergi.toLowerCase();
    final statusAlergiDisplay =
        (rawAlergi.isEmpty || rawAlergi == 'Tidak') ? 'Tidak' : 'Ya';
    final otherAllergies = _extractOtherAllergies(rawAlergi);
    final detailLainnyaDisplay =
        otherAllergies.isEmpty ? '-' : otherAllergies.join(', ');

    final pemeriksaanWita = _toWita(patient.tanggalPemeriksaan);
    final dateTimeFormatter = DateFormat('d-MM-yyyy / HH:mm', 'id_ID');
    final dateOnlyFormatter = DateFormat('d-M-y');

    final rdaResult = patient.hitungKebutuhanGizi();

    // ── Deteksi kelompok usia ────────────────────────────────────────────────
    // Gunakan tanggal pemeriksaan sebagai titik ukur (sudah dikonversi ke WITA).
    final int    totalBulanUsia = _totalBulan(patient.tanggalLahir, pemeriksaanWita);
    final bool   isOlderThan5  = totalBulanUsia > 60;

    // Untuk pasien > 5 tahun, hitung IMT/U dengan tabel 5-18 tahun.
    Map<String, dynamic>? imtu5to18Result;
    if (isOlderThan5) {
      final int ageYears  = totalBulanUsia ~/ 12;
      final int ageMonths = totalBulanUsia  % 12;
      final num bb    = patient.beratBadan;
      final num tb    = patient.tinggiBadan;
      // Karena bb dan tb tidak mungkin null, kita cukup cek tb > 0 untuk mencegah error division by zero
      if (tb > 0) {
        final double bmi = bb / ((tb / 100) * (tb / 100));
        imtu5to18Result  = _computeIMTU5To18(
          ageYears : ageYears,
          ageMonths: ageMonths,
          bmi      : bmi,
          // FIX Baris 157: Hapus '?? \'\'' karena jenisKelamin sudah pasti tidak null
          gender   : patient.jenisKelamin, 
        );
      }
    }

    // Ambil teks status gizi yang akan dipakai di bagian Monev.
    // Pasien ≤ 5 th → BB/U; Pasien > 5 th → IMT/U 5-18 tahun.
    final String monevStatusLabel = isOlderThan5
        ? 'Status gizi : IMT/U (5-18 th) : '
        : 'Status gizi : BB/U : ';
    final String monevStatusValue = isOlderThan5
        ? _formatString(imtu5to18Result?['category'] as String?)
        : _formatString(patient.statusGiziBBU);

    // ── Build IMT/U display text untuk bagian Antropometri ───────────────────
    final String imtuDisplayText = isOlderThan5
        ? () {
            final z = imtu5to18Result?['zScore'] as double?;
            final c = imtu5to18Result?['category'] as String? ?? '-';
            return z != null ? '${z.toStringAsFixed(2)} SD ($c)' : c;
          }()
        : '${patient.zScoreIMTU?.toStringAsFixed(2) ?? '-'} SD (${_formatString(patient.statusGiziIMTU)})';

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.legal.copyWith(height: 1200),
        margin: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        build: (pw.Context context) => [
          // ── HEADER ──────────────────────────────────────────────────────────
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
                    'Rumah Sakit Umum Daerah',
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

          // ── A. DATA PASIEN ───────────────────────────────────────────────────
          _buildSectionHeader('A. DATA PASIEN'),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildInfoRow(
                  'Nomor RM',
                  ': ${patient.noRM}',
                  'Tanggal/Jam',
                  ': ${dateTimeFormatter.format(pemeriksaanWita)} WITA',
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
                  '',
                  '',
                ),
              ],
            ),
          ),

          // ── B. ASESMEN GIZI ──────────────────────────────────────────────────
          _buildSectionHeader('B. ASESMEN GIZI'),
          pw.Container(
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildAssessmentCategory(
                  'Antropometri /AD (Anthropometric Data)',
                  [
                    // ── Baris BB — selalu tampil ──────────────────────────
                    _buildSymmetricalRow(
                      'BB :',
                      _formatNum(patient.beratBadan, 'kg'),
                      // Pasien > 5 th: BB/U tidak relevan, tampilkan IMT/U
                      isOlderThan5 ? 'Status (IMT/U) :' : 'Status (BB/U) :',
                      isOlderThan5
                          ? imtuDisplayText
                          : '${patient.zScoreBBU?.toStringAsFixed(2) ?? '-'} SD (${_formatString(patient.statusGiziBBU)})',
                    ),

                    // ── Baris PB — hanya untuk ≤ 5 tahun ─────────────────
                    if (!isOlderThan5)
                      _buildSymmetricalRow(
                        'PB :',
                        _formatNum(patient.tinggiBadan, 'cm'),
                        'Status (PB/U) :',
                        '${patient.zScoreTBU?.toStringAsFixed(2) ?? '-'} SD (${_formatString(patient.statusGiziTBU)})',
                      ),

                    // ── Baris LILA — selalu tampil; Status BB/PB hanya ≤ 5 th
                    _buildSymmetricalRow(
                      isOlderThan5 ? 'TB :' : 'LILA :',
                      isOlderThan5
                          ? _formatNum(patient.tinggiBadan, 'cm')
                          : _formatNum(patient.lila, 'cm'),
                      isOlderThan5 ? '' : 'Status (BB/PB) :',
                      isOlderThan5
                          ? ''
                          : '${patient.zScoreBBTB?.toStringAsFixed(2) ?? '-'} SD (${_formatString(patient.statusGiziBBTB)})',
                    ),

                    // ── Baris LILA (hanya > 5 th, diletakkan di baris ke-3)
                    if (isOlderThan5)
                      _buildSymmetricalRow(
                        'LILA :',
                        _formatNum(patient.lila, 'cm'),
                        '',
                        '',
                      ),

                    // ── Baris LK — selalu tampil; IMT/U (0-60) hanya ≤ 5 th
                    _buildSymmetricalRow(
                      'LK :',
                      _formatNum(patient.lingkarKepala, 'cm'),
                      isOlderThan5 ? '' : 'Status (IMT/U) :',
                      isOlderThan5
                          ? ''
                          : '${patient.zScoreIMTU?.toStringAsFixed(2) ?? '-'} SD (${_formatString(patient.statusGiziIMTU)})',
                    ),

                    // ── Baris BBI — selalu tampil ─────────────────────────
                    _buildSymmetricalRow(
                      'BBI :',
                      _formatNum(patient.bbi, 'kg'),
                      '',
                      '',
                    ),
                  ],
                ),

                _buildAssessmentCategory(
                  'Biokimia /BD (Biochemical Data)',
                  [
                    if (patient.labResults.isEmpty)
                      pw.Text('-', style: const pw.TextStyle(fontSize: 9))
                    else
                      for (var i = 0; i < patient.labResults.length; i += 4)
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(vertical: 2),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              _buildCompactLabItem(patient.labResults, i),
                              _buildCompactLabItem(patient.labResults, i + 1),
                              _buildCompactLabItem(patient.labResults, i + 2),
                              _buildCompactLabItem(patient.labResults, i + 3),
                            ],
                          ),
                        ),
                  ],
                ),

                _buildAssessmentCategory(
                  'Klinik /Fisik /PD (Physical Data)',
                  [
                    _buildAssessmentItemRow(
                      'KU : ${_formatString(patient.klinikKU)}',
                      'TD : ${_formatString(patient.klinikTD)} mmHg',
                      'R : ${_formatString(patient.klinikRR)} x/mnt',
                      'SpO2 : ${_formatString(patient.klinikSPO2)} %',
                    ),
                    _buildAssessmentItemRow(
                      'KES : ${_formatString(patient.klinikKES)}',
                      'N : ${_formatString(patient.klinikNadi)} x/mnt',
                      'SB : ${_formatString(patient.klinikSuhu)} °C',
                      '',
                    ),
                  ],
                ),

                _buildAssessmentCategory(
                  'Riwayat Gizi /FH (Food History)',
                  [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
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
                              pw.Text(
                                'Status: $statusAlergiDisplay',
                                style: const pw.TextStyle(fontSize: 9),
                              ),
                              pw.SizedBox(height: 4),
                              _buildCheckboxRow(
                                  'Telur', dataAlergiLower.contains('telur')),
                              _buildCheckboxRow(
                                  'Susu Sapi / Produk turunannya',
                                  dataAlergiLower.contains('susu')),
                              _buildCheckboxRow(
                                  'Kacang Kedelai/Tanah',
                                  dataAlergiLower.contains('kacang')),
                              _buildCheckboxRow(
                                  'Gluten/Gandum',
                                  dataAlergiLower.contains('gluten') ||
                                      dataAlergiLower.contains('gandum')),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(height: 11),
                              _buildCheckboxRow(
                                  'Udang', dataAlergiLower.contains('udang')),
                              _buildCheckboxRow(
                                  'Ikan', dataAlergiLower.contains('ikan')),
                              _buildCheckboxRow(
                                  'Hazelnuts/Almond',
                                  dataAlergiLower.contains('hazelnut') ||
                                      dataAlergiLower.contains('almond')),
                              _buildSingleLabelRow(
                                  'Lain-lain / Detail : ',
                                  detailLainnyaDisplay),
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 3),
                    _buildSingleLabelRow(
                      'Pola Makan / Asupan (%) : ',
                      _formatString(patient.polaMakan),
                    ),
                  ],
                ),

                _buildAssessmentCategory(
                  'Total Asupan',
                  [_buildTotalIntakeTable(rdaResult)],
                ),

                _buildAssessmentCategory(
                  'Riwayat Personal /CH (Client History)',
                  [
                    _buildSingleLabelRow(
                      'RPS :',
                      ' ${_formatString(patient.riwayatPenyakitSekarang)}',
                    ),
                    _buildSingleLabelRow(
                      'RPD :',
                      ' ${_formatString(patient.riwayatPenyakitDahulu)}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── C. DIAGNOSA GIZI ─────────────────────────────────────────────────
          _buildSectionHeader('C. DIAGNOSA GIZI'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: _buildSingleLabelRow(
              '',
              ' ${_formatString(patient.diagnosaGizi)}',
            ),
          ),

          // ── D. INTERVENSI GIZI ───────────────────────────────────────────────
          _buildSectionHeader('D. INTERVENSI GIZI'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildAssessmentItemRow(
                  'BM : ${_formatString(patient.intervensiBentukMakanan)}',
                  'Via : ${_formatString(patient.intervensiVia)}',
                  '',
                ),
                pw.SizedBox(height: 4),
                _buildSingleLabelRow(
                  'Jenis Diet :',
                  ' ${_formatString(patient.intervensiDiet)}',
                ),
                _buildSingleLabelRow(
                  'Tujuan Diet :',
                  ' ${_formatString(patient.intervensiTujuan)}',
                ),
              ],
            ),
          ),

          // ── E. MONITORING DAN EVALUASI ───────────────────────────────────────
          _buildSectionHeader('E. MONITORING DAN EVALUASI'),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(4),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5)),
            child: pw.Column(
              children: [
                _buildSingleLabelRow(
                  'Indikator Monitoring :',
                  ' ${_formatString(patient.monevIndikator)}',
                ),
                _buildSingleLabelRow(
                  'Asupan Makanan :',
                  ' ${_formatString(patient.monevAsupan)}',
                ),
                // Status gizi: BB/U untuk ≤ 5 th, IMT/U 5-18 th untuk > 5 th
                _buildSingleLabelRow(
                  monevStatusLabel,
                  ' $monevStatusValue',
                ),
                _buildSingleLabelRow(
                  _formatString(patient.monevHasilLab),
                  '',
                ),
              ],
            ),
          ),

          // ── FOOTER / TANDA TANGAN ────────────────────────────────────────────
          pw.SizedBox(height: 10),
          pw.Padding(
            padding: const pw.EdgeInsets.only(right: 20),
            child: pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text(
                    'Tanggal : ${dateOnlyFormatter.format(pemeriksaanWita)}',
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

  // ── WIDGET HELPERS ──────────────────────────────────────────────────────────

  static pw.Widget _buildCompactLabItem(Map<String, dynamic> data, int index) {
    if (index >= data.length) {
      return pw.Expanded(flex: 1, child: pw.Container());
    }
    final key = data.keys.elementAt(index);
    final value = data.values.elementAt(index);
    return pw.Expanded(
      flex: 1,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(right: 4),
        child: pw.Text(
          '$key : $value',
          style: const pw.TextStyle(fontSize: 8),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign? align,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        textAlign: align ?? (isHeader ? pw.TextAlign.center : pw.TextAlign.left),
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Baris dua kolom info: [label | value | label | value]
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

  /// Baris empat kolom seimbang untuk data klinis/asesmen
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
          ] else
            pw.Expanded(flex: 2, child: pw.Container()),
        ],
      ),
    );
  }

  /// Baris label + nilai yang mengisi sisa lebar (untuk teks panjang / multiline)
  static pw.Widget _buildSingleLabelRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 9)),
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

  /// Sub-header kategori di dalam container asesmen beserta daftar widget-nya
  static pw.Widget _buildAssessmentCategory(
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

  /// Baris dua kolom seimbang: kiri [label + value] / kanan [label + value]
  static pw.Widget _buildSymmetricalRow(
    String labelLeft,
    String valueLeft,
    String labelRight,
    String valueRight,
  ) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 1,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(labelLeft, style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(width: 2),
                pw.Expanded(
                  child: pw.Text(
                    valueLeft,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          pw.Expanded(
            flex: 1,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(labelRight, style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(width: 2),
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
                      'V',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  )
                : null,
          ),
          pw.SizedBox(width: 4),
          pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalIntakeTable(Map<String, double> rda) {
    const headers = ['Zat Gizi', 'Nilai', 'Kebutuhan', '%'];
    const rowLabels = [
      'Energi (kkal)',
      'Protein (gram)',
      'Lemak (gram)',
      'KH (gram)',
    ];

    final energiTotal = rda['energi'] ?? 0;
    final proteinGram = rda['protein'] ?? 0;
    final lemakGram = rda['lemak'] ?? 0;
    final karboGram = rda['karbo'] ?? 0;

    // Hitung persentase kontribusi makronutrien terhadap total energi.
    // Energi: protein & karbo = 4 kkal/g, lemak = 9 kkal/g.
    final String pctEnergi;
    final String pctProtein;
    final String pctLemak;
    final String pctKarbo;

    if (energiTotal > 0) {
      pctEnergi = '100 %';
      pctProtein =
          '${((proteinGram * 4 / energiTotal) * 100).toStringAsFixed(0)} %';
      pctLemak =
          '${((lemakGram * 9 / energiTotal) * 100).toStringAsFixed(0)} %';
      pctKarbo =
          '${((karboGram * 4 / energiTotal) * 100).toStringAsFixed(0)} %';
    } else {
      pctEnergi = pctProtein = pctLemak = pctKarbo = '-';
    }

    final needs = [
      energiTotal.toStringAsFixed(0),
      proteinGram.toStringAsFixed(1),
      lemakGram.toStringAsFixed(1),
      karboGram.toStringAsFixed(1),
    ];

    final percentages = [pctEnergi, pctProtein, pctLemak, pctKarbo];

    final rightTableItems = [
      {'label': 'Energi', 'value': '${energiTotal.toStringAsFixed(0)} kkal'},
      {'label': 'Protein', 'value': '${proteinGram.toStringAsFixed(1)} gram'},
      {
        'label': 'Cairan',
        'value': '${(rda['cairan'] ?? 0).toStringAsFixed(0)} ml'
      },
    ];

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 4, bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Tabel kiri: detail zat gizi
          pw.Expanded(
            flex: 5,
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(1.5),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(1.5),
                3: pw.FlexColumnWidth(1.2),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                  children: headers
                      .map((h) => _buildTableCell(h, isHeader: true))
                      .toList(),
                ),
                for (int i = 0; i < rowLabels.length; i++)
                  pw.TableRow(
                    children: [
                      _buildTableCell(rowLabels[i]),
                      _buildTableCell(''),
                      _buildTableCell(needs[i],
                          align: pw.TextAlign.center),
                      _buildTableCell(percentages[i],
                          align: pw.TextAlign.center),
                    ],
                  ),
              ],
            ),
          ),

          pw.SizedBox(width: 8),

          // Tabel kanan: ringkasan kebutuhan
          pw.Expanded(
            flex: 3,
            child: pw.Table(
              border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
              columnWidths: const {0: pw.FlexColumnWidth(1)},
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('Ringkasan Kebutuhan', isHeader: true),
                  ],
                ),
                ...rightTableItems.map(
                  (item) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 4, vertical: 5),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              '${item['label']} : ',
                              style: const pw.TextStyle(fontSize: 9),
                            ),
                            pw.Expanded(
                              child: pw.Text(
                                item['value']!,
                                style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.right,
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
          ),
        ],
      ),
    );
  }

  // ── FILE I/O ────────────────────────────────────────────────────────────────

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

  static Future<void> openFile(File file) async {
    await OpenFile.open(file.path);
  }
}