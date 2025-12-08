// lib/src/features/patient_home/presentation/pages/patient_anak_detail_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/scaffold_with_animated_fab.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'data_form_anak_page.dart'; // Import form anak
import 'patient_delete_logic.dart'; // Import logika hapus
import 'pdf_generator_anak.dart'; // Import PDF generator anak
import 'pdf_generator_asuhan_anak.dart';

class PatientAnakDetailPage extends StatefulWidget {
  final PatientAnak patient;

  const PatientAnakDetailPage({super.key, required this.patient});

  @override
  State<PatientAnakDetailPage> createState() => _PatientAnakDetailPageState();
}

class _PatientAnakDetailPageState extends State<PatientAnakDetailPage> {
  late PatientAnak _currentPatient;

  @override
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithAnimatedFab(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: _currentPatient.namaLengkap,
        subtitle: 'Data Lengkap Pasien Anak',
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
          // Panggilan ini sekarang sudah benar karena PatientDeleteLogic
          // sudah di-refactor untuk menerima ID dan Nama
          PatientDeleteLogic.handlePatientDelete(
            context: context,
            patientId: _currentPatient.id, // Berikan ID
            patientName: _currentPatient.namaLengkap,
          );
        },
        onSubmit: () async {
          // Navigasi ke form EDIT anak
          final updatedPatient = await Navigator.push<PatientAnak>(
            context,
            MaterialPageRoute(
              builder: (context) => DataFormAnakPage(patient: _currentPatient),
            ),
          );

          if (updatedPatient != null && mounted) {
            setState(() {
              _currentPatient = updatedPatient;
            });
          }
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Data Pasien Anak'),
            _buildInfoRow('No. RM', _currentPatient.noRM),
            _buildInfoRow(
              'Tanggal Lahir',
              _currentPatient.tanggalLahirFormatted,
            ),
            _buildInfoRow('Usia', _currentPatient.usiaFormatted),
            _buildInfoRow('Jenis Kelamin', _currentPatient.jenisKelamin),
            _buildInfoRow(
              'Diagnosis Medis',
              '${_currentPatient.diagnosisMedis} ',
            ),
            _buildInfoRow('Berat Badan', '${_currentPatient.beratBadan} kg'),
            _buildInfoRow(
              'Panjang/Tinggi Badan',
              '${_currentPatient.tinggiBadan.toStringAsFixed(0)} cm',
            ),
            if (_currentPatient.lila != null)
              _buildInfoRow('LILA', '${_currentPatient.lila} cm'),
            if (_currentPatient.lingkarKepala != null)
              _buildInfoRow(
                'Lingkar Kepala (LK)',
                '${_currentPatient.lingkarKepala} cm',
              ),
            _buildInfoRow(
              'Berat Badan Ideal',
              '${_currentPatient.bbi?.toString() ?? ""} kg', // Mengambil langsung dari database
            ),
            const Divider(height: 20, thickness: 2, color: Colors.green),

            _buildSectionTitle('Hasil Status Gizi Anak'),
            // --- 1. BB/U ---
            _buildStatusGiziItem(
              title: 'Berat Badan menurut Umur (BB/U)',
              zScore: _currentPatient.zScoreBBU,
              // Gunakan statusGiziAnak jika itu untuk BB/U, atau sesuaikan
              category: _currentPatient.statusGiziBBU,
            ),

            // --- 2. TB/U ---
            _buildStatusGiziItem(
              title: 'Tinggi Badan menurut Umur (TB/U)',
              zScore: _currentPatient.zScoreTBU,
              category: _currentPatient.statusGiziTBU,
            ),

            // --- 3. BB/TB ---
            _buildStatusGiziItem(
              title: 'Berat Badan menurut Tinggi Badan (BB/TB)',
              zScore: _currentPatient.zScoreBBTB,
              category: _currentPatient.statusGiziBBTB,
            ),

            // --- 4. IMT/U ---
            _buildStatusGiziItem(
              title: 'Indeks Massa Tubuh menurut Umur (IMT/U)',
              zScore: _currentPatient.zScoreIMTU,
              category: _currentPatient.statusGiziIMTU,
            ),
            const Divider(height: 20, thickness: 2, color: Colors.green),

            _buildSectionTitle('Skrining Gizi Lanjut'),
            _buildInfoRow(
              'Skor Status Antropometri',
              '${_currentPatient.skorAntropometri}',
            ),
            _buildInfoRow(
              'Skor Kehilangan Berat Badan',
              _currentPatient.kehilanganBeratBadan == 2 ? '2' : '0',
            ),
            _buildInfoRow(
              'Skor Asupan Makanan',
              '${_currentPatient.kehilanganNafsuMakan ?? 0}',
            ),
            _buildInfoRow(
              'Skor Penyakit Berat',
              _currentPatient.anakSakitBerat == 2 ? '2' : '0',
            ),
            const Divider(),
            _buildInfoRow(
              'Total Skor',
              '${_currentPatient.totalPymsScore}',
              isBold: true,
            ),
            _buildInfoRow(
              'Interpretasi',
              _currentPatient.pymsInterpretation,
              isBold: true,
              valueColor: _currentPatient.totalPymsScore >= 2
                  ? Colors.red
                  : Colors.green,
            ),

            const SizedBox(height: 20),

            // Tombol Cetak PDF Anak
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final scaffoldContext = ScaffoldMessenger.of(context);
                      try {
                        scaffoldContext.showSnackBar(
                          const SnackBar(
                            content: Text('Membuat File PDF...'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        final pdfFile = await PdfGeneratorAnak.generate(
                          _currentPatient,
                        );

                        await PdfGeneratorAnak.openFile(pdfFile);

                        if (!mounted) return;
                        scaffoldContext.showSnackBar(
                          const SnackBar(
                            content: Text('File PDF Berhasil dibuat!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        scaffoldContext.showSnackBar(
                          SnackBar(
                            content: Text(
                              'File PDF Gagal dibuat: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 20),
                        SizedBox(width: 8),
                        Text('Formulir Skrining Gizi Anak'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Divider(height: 20, thickness: 2, color: Colors.green),

            _buildSectionTitle('Asesmen & Rencana Asuhan Gizi'),
            // Kategori 1: Riwayat Gizi & Personal
            ExpansionTile(
              leading: const Icon(Icons.history_edu_outlined),
              title: const Text(
                'Riwayat Gizi /FH (Food History)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoDisplay(
                  label: 'Alergi Makanan',
                  value: _currentPatient.alergiMakanan ?? '-',
                ),
                _buildInfoDisplay(
                  label: 'Pola Makan / Asupan',
                  value: _currentPatient.polaMakan,
                ),
              ],
            ),
            // 2. Biokimia
            ExpansionTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text(
                'Biokimia /BD \n(Biochemical Data)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoRow(
                  'GDS',
                  // Gunakan string interpolation untuk menggabungkan nilai dan satuan
                  (_currentPatient.biokimiaGDS != null &&
                          _currentPatient.biokimiaGDS!.isNotEmpty)
                      ? '${_currentPatient.biokimiaGDS} mg/dL'
                      : '-',
                ),
                _buildInfoRow(
                  'Ureum',
                  (_currentPatient.biokimiaUreum != null &&
                          _currentPatient.biokimiaUreum!.isNotEmpty)
                      ? '${_currentPatient.biokimiaUreum} mg/dL'
                      : '-',
                ),
                _buildInfoRow(
                  'HGB',
                  (_currentPatient.biokimiaHGB != null &&
                          _currentPatient.biokimiaHGB!.isNotEmpty)
                      ? '${_currentPatient.biokimiaHGB} g/dL'
                      : '-',
                ),
                _buildInfoRow(
                  'ENT',
                  (_currentPatient.biokimiaENT != null &&
                          _currentPatient.biokimiaENT!.isNotEmpty)
                      ? '${_currentPatient.biokimiaENT} g/dL' // Satuan untuk ENT bisa bervariasi, sesuaikan jika perlu
                      : '-',
                ),
              ],
            ),

            // 3. Klinik/Fisik
            ExpansionTile(
              leading: const Icon(Icons.monitor_heart_outlined),
              title: const Text(
                'Klinik /Fisik /PD \n(Physical Data)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoRow(
                  'Tekanan Darah (TD)',
                  (_currentPatient.klinikTD != null &&
                          _currentPatient.klinikTD!.isNotEmpty)
                      ? '${_currentPatient.klinikTD} mmHg'
                      : '-',
                ),
                _buildInfoRow(
                  'Nadi',
                  (_currentPatient.klinikNadi != null &&
                          _currentPatient.klinikNadi!.isNotEmpty)
                      ? '${_currentPatient.klinikNadi} x/menit'
                      : '-',
                ),
                _buildInfoRow(
                  'Suhu Badan (SB)',
                  (_currentPatient.klinikSuhu != null &&
                          _currentPatient.klinikSuhu!.isNotEmpty)
                      ? '${_currentPatient.klinikSuhu} °C'
                      : '-',
                ),
                _buildInfoRow(
                  'Pernapasan (RR)',
                  (_currentPatient.klinikRR != null &&
                          _currentPatient.klinikRR!.isNotEmpty)
                      ? '${_currentPatient.klinikRR} x/menit'
                      : '-',
                ),
                _buildInfoRow(
                  'Saturasi Oksigen (SpO2)',
                  (_currentPatient.klinikSPO2 != null &&
                          _currentPatient.klinikSPO2!.isNotEmpty)
                      ? '${_currentPatient.klinikSPO2} %'
                      : '-',
                ),
                _buildInfoDisplay(
                  label: 'Keadaan Umum (KU) :',
                  value: _currentPatient.klinikKU,
                  emptyValueMessage: '-',
                ),
                _buildInfoDisplay(
                  label: 'Kesadaran (KES) :',
                  value: _currentPatient.klinikKES,
                  emptyValueMessage: '-',
                ),
              ],
            ),

            ExpansionTile(
              leading: const Icon(Icons.person_outline),
              title: const Text(
                'Riwayat Personal /CH \n(Client History)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoDisplay(
                  label: 'Riwayat Penyakit Sekarang (RPS)',
                  value: _currentPatient.riwayatPenyakitSekarang,
                ),
                _buildInfoDisplay(
                  label: 'Riwayat Penyakit Dahulu (RPD)',
                  value: _currentPatient.riwayatPenyakitDahulu,
                ),
              ],
            ),

            // 4. Diagnosis Gizi
            ExpansionTile(
              leading: const Icon(Icons.medical_services_outlined),
              title: const Text(
                'Diagnosa Gizi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              children: [
                _buildInfoDisplay(
                  label: 'Diagnosa Gizi:',
                  value: _currentPatient.diagnosaGizi,
                  emptyValueMessage: 'Tidak ada data diagnosis gizi.',
                ),
              ],
            ),

            // 5. Intervensi
            ExpansionTile(
              leading: const Icon(Icons.food_bank_outlined),
              title: const Text(
                'Intervensi Gizi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoRow(
                  'Jenis Diet',
                  _currentPatient.intervensiDiet ?? '-',
                ),
                _buildInfoRow(
                  'Bentuk Makanan (BM)',
                  _currentPatient.intervensiBentukMakanan ?? '-',
                ),
                _buildInfoRow(
                  'Tujuan Diet',
                  _currentPatient.intervensiTujuan ?? '-',
                ),
                _buildInfoRow('Via', _currentPatient.intervensiVia ?? '-'),
              ],
            ),

            // 6. Monev
            ExpansionTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text(
                'Monitoring dan Evaluasi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoDisplay(
                  label: 'Status Gizi BB/U :',
                  value: _currentPatient.statusGiziBBU,
                ),
                _buildInfoDisplay(
                  label: 'Asupan Makanan :',
                  value: _currentPatient.monevAsupan,
                ),
              ],
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final scaffoldContext = ScaffoldMessenger.of(context);

                      try {
                        scaffoldContext.showSnackBar(
                          const SnackBar(
                            content: Text('Membuat File PDF...'),
                            duration: Duration(seconds: 1),
                          ),
                        );

                        final pdfFile = await PdfGeneratorAsuhanAnak.generate(
                          _currentPatient,
                        );

                        await PdfGeneratorAsuhanAnak.openFile(pdfFile);

                        if (!mounted) return;
                        scaffoldContext.showSnackBar(
                          const SnackBar(
                            content: Text('File PDF Berhasil dibuat!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        if (!mounted) return;
                        scaffoldContext.showSnackBar(
                          SnackBar(
                            content: Text(
                              'File PDF Gagal dibuat: ${e.toString()}',
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf, size: 20),
                        SizedBox(width: 8),
                        Text('Formulir Asuhan Gizi Anak'),
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

  Widget _buildInfoDisplay({
    required String label,
    required String? value,
    String emptyValueMessage = 'Tidak ada data.',
  }) {
    // Tampilkan pesan default jika nilai null atau kosong
    final displayText = (value == null || value.isEmpty)
        ? emptyValueMessage
        : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Label
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          const SizedBox(height: 6), // Jarak antara label dan nilai
          // 2. Nilai (Value)
          SizedBox(
            width: double.infinity,
            child: Text(
              displayText,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGiziItem({
    required String title,
    required double? zScore,
    required String? category,
  }) {
    // Logika Warna Sederhana
    Color statusColor = Colors.red;
    if (category != null) {
      if (category.toLowerCase().contains('baik') ||
          category.toLowerCase().contains('normal')) {
        statusColor = Colors.green;
      } else if (category.toLowerCase().contains('kurang') ||
          category.toLowerCase().contains('buruk') ||
          category.toLowerCase().contains('pendek') ||
          category.toLowerCase().contains('sangat pendek') ||
          category.toLowerCase().contains('gizi buruk')) {
        statusColor = Colors.red;
      } else if (category.toLowerCase().contains('lebih') ||
          category.toLowerCase().contains('resiko')) {
        statusColor = Colors.orange;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Keterangan / Judul
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 2. Z-Score
              Row(
                children: [
                  const Text(
                    'Z-Score: ',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    zScore?.toStringAsFixed(2) ?? '-',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),

              // 3. Kategori (Badge Berwarna)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  category ?? 'Belum ada data',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // (Copy/paste _buildSectionTitle dan _buildInfoRow dari patient_detail_page.dart)
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

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
