// lib/src/features/patient_home/presentation/pages/patient_detail_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/scaffold_with_animated_fab.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/pages/data_form_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/services/share_patient_service.dart';

// ── Services (dipindahkan dari presentation/pages/) ──────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/services/patient_delete_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/services/pdf/pdf_generator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/services/pdf/pdf_generator_asuhan_service.dart';

// ── Widget yang diekstrak ────────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/presentation/widgets/patient_info_row.dart';

class PatientDetailPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  late Patient _currentPatient;
  final SharePatientService _shareService = SharePatientService();

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
  }

  // ── Berbagi Data Pasien ───────────────────────────────────────────────────
  void _showShareDialog(BuildContext context) {
    List<String> selectedUids = [];
    bool isSending = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bagikan ke Nutrisionis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      'Pilih satu atau lebih rekan untuk membagikan salinan data pasien ini.'),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _shareService.getAvailableNutritionists(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(
                              child: Text(
                                  'Tidak ada akun Nutrisionis lain yang ditemukan.'));
                        }

                        final nutritionists = snapshot.data!;
                        return ListView.builder(
                          itemCount: nutritionists.length,
                          itemBuilder: (context, index) {
                            final user = nutritionists[index];
                            final isChecked =
                                selectedUids.contains(user['uid']);
                            return CheckboxListTile(
                              title: Text(user['name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(user['email']),
                              value: isChecked,
                              activeColor: Colors.blue,
                              onChanged: (bool? value) {
                                setModalState(() {
                                  if (value == true) {
                                    selectedUids.add(user['uid']);
                                  } else {
                                    selectedUids.remove(user['uid']);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              isSending ? null : () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (selectedUids.isEmpty || isSending)
                              ? null
                              : () async {
                                  bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title:
                                          const Text('Konfirmasi Pengiriman'),
                                      content: Text(
                                          'Kirim salinan data "${_currentPatient.namaLengkap}" ke ${selectedUids.length} orang?'),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, false),
                                            child: const Text('Batal')),
                                        ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(ctx, true),
                                            child: const Text('Kirim')),
                                      ],
                                    ),
                                  );

                                  if (confirm != true) return;
                                  setModalState(() => isSending = true);

                                  try {
                                    Map<String, dynamic> rawData =
                                        _currentPatient.toMap();
                                    rawData.remove('id');
                                    await _shareService.sendPatientData(
                                      receiverIds: selectedUids,
                                      patientData: rawData,
                                      patientName: _currentPatient.namaLengkap,
                                      patientType: 'dewasa',
                                    );
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Berhasil mengirimkan permintaan berbagi!'),
                                            backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text('Gagal mengirim: $e'),
                                            backgroundColor: Colors.red),
                                      );
                                    }
                                  } finally {
                                    setModalState(() => isSending = false);
                                  }
                                },
                          child: isSending
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text('Kirim'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithAnimatedFab(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: _currentPatient.namaLengkap,
        subtitle: 'Data Lengkap Pasien',
      ),
      floatingActionButton: FormActionButtons(
        singleButtonMode: false,
        submitText: 'Edit',
        resetText: 'Hapus',
        submitIcon: const Icon(Icons.edit, color: Colors.white),
        resetIcon: const Icon(Icons.delete_forever),
        resetButtonColor: Colors.red,
        submitButtonColor: const Color.fromARGB(255, 0, 148, 68),
        onReset: () {
          // ── Menggunakan PatientDeleteService (renamed) ────────────────
          PatientDeleteService.handlePatientDelete(
            context: context,
            patientId: _currentPatient.id,
            patientName: _currentPatient.namaLengkap,
          );
        },
        onSubmit: () async {
          final updatedPatient = await Navigator.push<Patient>(
            context,
            MaterialPageRoute(
              builder: (_) => DataFormPage(patient: _currentPatient),
            ),
          );
          if (updatedPatient != null && mounted) {
            setState(() => _currentPatient = updatedPatient);
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Data Pasien ───────────────────────────────────────────────
            _buildSectionTitle('Data Pasien'),
            PatientInfoRow('No. RM', _currentPatient.noRM),
            PatientInfoRow('Tanggal Lahir', _currentPatient.tanggalLahirFormatted),
            PatientInfoRow('Usia', '${_currentPatient.usia} tahun'),
            PatientInfoRow('Jenis Kelamin', _currentPatient.jenisKelamin),
            PatientInfoRow('Berat Badan', '${_currentPatient.beratBadan} kg'),
            PatientInfoRow(
              'Tinggi Badan',
              '${_currentPatient.tinggiBadan.toStringAsFixed(0)} cm',
            ),
            if (_currentPatient.lila != null)
              PatientInfoRow(
                'Lingkar Lengan Atas (LILA)',
                '${_currentPatient.lila!.toStringAsFixed(1)} cm',
              ),
            if (_currentPatient.tl != null)
              PatientInfoRow(
                'Tinggi Lutut (TL)',
                '${_currentPatient.tl!.toStringAsFixed(1)} cm',
              ),
            PatientInfoRow('Diagnosis Medis', _currentPatient.diagnosisMedis),
            PatientInfoRow('Status Gizi', _currentPatient.statusGizi),

            const SizedBox(height: 16),

            // ── Tombol Berbagi ────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showShareDialog(context),
                icon: const Icon(Icons.share, color: Colors.blue),
                label: const Text(
                  'Bagikan Data Pasien ke Nutrisionis Lain',
                  style: TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            const Divider(height: 20, thickness: 2, color: Colors.green),

            // ── Hasil Perhitungan Gizi ────────────────────────────────────
            _buildSectionTitle('Hasil Kebutuhan Gizi'),
            PatientInfoRow(
              'IMT',
              '${_currentPatient.imt.toStringAsFixed(2)} kg/m²',
              isBold: true,
            ),
            PatientInfoRow(
              'BBI',
              _currentPatient.bbi != 0.0
                  ? '${_currentPatient.bbi.toStringAsFixed(1)} kg'
                  : '-',
              isBold: true,
            ),
            PatientInfoRow(
              'BMR (Harris-Benedict)',
              _currentPatient.bmr != 0.0
                  ? '${_currentPatient.bmr.toStringAsFixed(2)} kkal'
                  : '-',
              isBold: true,
            ),
            PatientInfoRow(
              'TDEE (Total Energi)',
              _currentPatient.tdee != 0.0
                  ? '${_currentPatient.tdee.toStringAsFixed(2)} kkal'
                  : '-',
              isBold: true,
            ),
            PatientInfoRow(
              'Protein (15%)',
              _currentPatient.tdee != 0.0
                  ? '${_currentPatient.kebutuhanProtein.toStringAsFixed(1)} g/hari'
                  : '-',
                  isBold: true,
            ),
            PatientInfoRow(
              'Lemak (25%)',
              _currentPatient.tdee != 0.0
                  ? '${_currentPatient.kebutuhanLemak.toStringAsFixed(1)} g/hari'
                  : '-',
                  isBold: true,
            ),
            PatientInfoRow(
              'Karbohidrat (60%)',
              _currentPatient.tdee != 0.0
                  ? '${_currentPatient.kebutuhanKarbo.toStringAsFixed(1)} g/hari'
                  : '-',
                  isBold: true,
            ),
            PatientInfoRow('Aktivitas', _currentPatient.aktivitas, isBold: true,),

            const Divider(height: 20, thickness: 2, color: Colors.green),

            // ── Skrining Gizi Lanjut ──────────────────────────────────────
            _buildSectionTitle('Skrining Gizi Lanjut'),
            PatientInfoRow('Skor IMT', _currentPatient.skorIMT.toString()),
            PatientInfoRow(
                'Skor Kehilangan BB', _currentPatient.skorKehilanganBB.toString()),
            PatientInfoRow(
                'Skor Efek Penyakit Akut',
                _currentPatient.skorEfekPenyakit.toString()),
            const Divider(),
            PatientInfoRow(
                'Total Skor', _currentPatient.totalSkor.toString(),
                isBold: true),
            PatientInfoRow(
              'Interpretasi',
              _currentPatient.interpretasi,
              isBold: true,
              valueColor: _getInterpretationColor(_currentPatient.interpretasi),
            ),

            const SizedBox(height: 20),

            // ── Tombol PDF Skrining ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final scaffoldContext = ScaffoldMessenger.of(context);
                      try {
                        scaffoldContext.showSnackBar(const SnackBar(
                            content: Text('Membuat File PDF...'),
                            duration: Duration(seconds: 1)));
                        // ── PdfGeneratorService (renamed) ─────────────────
                        final pdfFile =
                            await PdfGeneratorService.generate(_currentPatient);
                        await PdfGeneratorService.openFile(pdfFile);
                        if (!mounted) return;
                        scaffoldContext.showSnackBar(const SnackBar(
                            content: Text('File PDF Berhasil dibuat!'),
                            backgroundColor: Colors.green));
                      } catch (e) {
                        if (!mounted) return;
                        scaffoldContext.showSnackBar(SnackBar(
                            content:
                                Text('File PDF Gagal dibuat: ${e.toString()}'),
                            backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 20),
                        SizedBox(width: 8),
                        Text('Formulir Skrining Gizi'),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            const Divider(height: 20, thickness: 2, color: Colors.green),

            // ── Asesmen & Rencana Asuhan Gizi ─────────────────────────────
            _buildSectionTitle('Asesmen & Rencana Asuhan Gizi'),

            // Riwayat Gizi
            ExpansionTile(
              leading: const Icon(Icons.history_edu_outlined),
              title: const Text('Riwayat Gizi /FH (Food History)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                PatientInfoRow(
                    'Alergi Makanan', _currentPatient.alergiMakanan ?? '-'),
                if (_currentPatient.detailAlergi != null &&
                    _currentPatient.detailAlergi!.isNotEmpty)
                  _buildInfoDisplay(
                    label: 'Detail Alergi',
                    value: _currentPatient.detailAlergi!,
                    emptyValueMessage: 'Tidak ada data Alergi makanan.',
                  ),
                PatientInfoRow(
                  'Pola Makan/Asupan(%)',
                  (_currentPatient.polaMakan != null &&
                          _currentPatient.polaMakan!.isNotEmpty)
                      ? '${_currentPatient.polaMakan}'
                      : '-',
                ),
              ],
            ),

            // Biokimia
            ExpansionTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text('Biokimia /BD \n(Biochemical Data)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                if (_currentPatient.labResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Tidak ada data laboratorium.'),
                  )
                else
                  ..._currentPatient.labResults.entries.map(
                    (entry) =>
                        PatientInfoRow(entry.key, '${entry.value} mg/dL'),
                  ),
              ],
            ),

            // Klinik/Fisik
            ExpansionTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: const Text('Klinik /Fisik /PD \n(Physical Data)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                PatientInfoRow(
                  'Tekanan Darah (TD)',
                  (_currentPatient.klinikTD?.isNotEmpty ?? false)
                      ? '${_currentPatient.klinikTD} mmHg'
                      : '-',
                ),
                PatientInfoRow(
                  'Nadi',
                  (_currentPatient.klinikNadi?.isNotEmpty ?? false)
                      ? '${_currentPatient.klinikNadi} x/menit'
                      : '-',
                ),
                PatientInfoRow(
                  'Suhu Badan (SB)',
                  (_currentPatient.klinikSuhu?.isNotEmpty ?? false)
                      ? '${_currentPatient.klinikSuhu} °C'
                      : '-',
                ),
                PatientInfoRow(
                  'Pernapasan (RR)',
                  (_currentPatient.klinikRR?.isNotEmpty ?? false)
                      ? '${_currentPatient.klinikRR} x/menit'
                      : '-',
                ),
                PatientInfoRow(
                  'Saturasi Oksigen (SpO2)',
                  (_currentPatient.klinikSPO2?.isNotEmpty ?? false)
                      ? '${_currentPatient.klinikSPO2} %'
                      : '-',
                ),
                _buildInfoDisplay(
                    label: 'Keadaan Umum (KU) :',
                    value: _currentPatient.klinikKU,
                    emptyValueMessage: '-'),
                _buildInfoDisplay(
                    label: 'Kesadaran (KES) :',
                    value: _currentPatient.klinikKES,
                    emptyValueMessage: '-'),
              ],
            ),

            // Riwayat Personal
            ExpansionTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Riwayat Personal /CH \n(Client History)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoDisplay(
                    label: 'Riwayat Penyakit Sekarang :',
                    value: _currentPatient.riwayatPenyakitSekarang,
                    emptyValueMessage: '-'),
                _buildInfoDisplay(
                    label: 'Riwayat Penyakit Dahulu :',
                    value: _currentPatient.riwayatPenyakitDahulu,
                    emptyValueMessage: '-'),
                const Divider(),
                PatientInfoRow('Suka Manis',
                    (_currentPatient.sukaManis ?? false) ? 'Ya' : 'Tidak'),
                PatientInfoRow('Suka Asin',
                    (_currentPatient.sukaAsin ?? false) ? 'Ya' : 'Tidak'),
                PatientInfoRow('Makan Berlemak',
                    (_currentPatient.makanBerlemak ?? false) ? 'Ya' : 'Tidak'),
                PatientInfoRow('Jarang Olahraga',
                    (_currentPatient.jarangOlahraga ?? false) ? 'Ya' : 'Tidak'),
              ],
            ),

            // Diagnosis Gizi
            ExpansionTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text('Diagnosa Gizi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding: const EdgeInsets.symmetric(
                  horizontal: 16.0, vertical: 8.0),
              children: [
                _buildInfoDisplay(
                  label: 'Diagnosa Gizi:',
                  value: _currentPatient.diagnosaGizi,
                  emptyValueMessage: 'Tidak ada data diagnosis gizi.',
                ),
              ],
            ),

            // Intervensi
            ExpansionTile(
              leading: const Icon(Icons.food_bank_outlined),
              title: const Text('Intervensi Gizi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoDisplay(
                  label: 'Intervensi Jenis Diet',
                  value: (_currentPatient.intervensiDiet?.isNotEmpty ?? false)
                      ? '${_currentPatient.intervensiDiet}'
                      : '-',
                ),
                PatientInfoRow(
                  'Intervensi Bentuk Makanan',
                  (_currentPatient.intervensiBentukMakanan?.isNotEmpty ??
                          false)
                      ? '${_currentPatient.intervensiBentukMakanan}'
                      : '-',
                ),
                PatientInfoRow(
                  'Intervensi Via',
                  (_currentPatient.intervensiVia?.isNotEmpty ?? false)
                      ? '${_currentPatient.intervensiVia}'
                      : '-',
                ),
                _buildInfoDisplay(
                    label: 'Tujuan Diet :',
                    value: _currentPatient.intervensiTujuan,
                    emptyValueMessage: '-'),
              ],
            ),

            // Monitoring & Evaluasi
            ExpansionTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text('Monitoring dan Evaluasi',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding:
                  const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                PatientInfoRow(
                    'Status Gizi', _currentPatient.statusGizi),
                _buildInfoDisplay(
                    label: 'Indikator Monitoring :',
                    value: _currentPatient.monevIndikator,
                    emptyValueMessage: '-'),
                _buildInfoDisplay(
                    label: 'Asupan Makanan :',
                    value: _currentPatient.monevAsupan,
                    emptyValueMessage: '-'),
                _buildInfoDisplay(
                    label: 'Hasil Lab :',
                    value: _currentPatient.monevHasilLab,
                    emptyValueMessage: '-'),
              ],
            ),

            const SizedBox(height: 20),

            // ── Tombol PDF Asuhan ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final scaffoldContext = ScaffoldMessenger.of(context);
                      try {
                        scaffoldContext.showSnackBar(const SnackBar(
                            content: Text('Membuat File PDF...'),
                            duration: Duration(seconds: 1)));
                        // ── PdfGeneratorAsuhanService (renamed) ───────────
                        final pdfFile =
                            await PdfGeneratorAsuhanService.generate(
                                _currentPatient);
                        await PdfGeneratorAsuhanService.openFile(pdfFile);
                        if (!mounted) return;
                        scaffoldContext.showSnackBar(const SnackBar(
                            content: Text('File PDF Berhasil dibuat!'),
                            backgroundColor: Colors.green));
                      } catch (e) {
                        if (!mounted) return;
                        scaffoldContext.showSnackBar(SnackBar(
                            content:
                                Text('File PDF Gagal dibuat: ${e.toString()}'),
                            backgroundColor: Colors.red));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 20),
                        SizedBox(width: 8),
                        Text('Formulir Asuhan Gizi'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color.fromARGB(255, 0, 148, 68),
        ),
      ),
    );
  }

  /// Menampilkan data multi-baris (label di atas, value di bawah).
  /// Berbeda dari [PatientInfoRow] yang label & value berada dalam satu baris.
  Widget _buildInfoDisplay({
    required String label,
    required String? value,
    String emptyValueMessage = 'Tidak ada data.',
  }) {
    final displayText =
        (value == null || value.isEmpty) ? emptyValueMessage : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: Text(displayText,
                style: const TextStyle(fontSize: 16, color: Colors.black87)),
          ),
        ],
      ),
    );
  }

  Color _getInterpretationColor(String interpretasi) {
    final text = interpretasi.toLowerCase();
    if (text.contains('sangat tinggi')) return Colors.red;
    if (text.contains('tinggi')) return Colors.orange;
    if (text.contains('menengah')) return Colors.amber;
    if (text.contains('rendah')) return const Color.fromARGB(255, 0, 148, 68);
    return Colors.black87;
  }
}