//lib\src\features\home\presentation\pages\patient_detail_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_model.dart';
import 'pdf_generator.dart';
import 'patient_delete_logic.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'data_form_page.dart';
import 'pdf_generator_asuhan.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/scaffold_with_animated_fab.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/services/share_patient_service.dart'; // Sesuaikan path-nya

class PatientDetailPage extends StatefulWidget {
  final Patient patient;

  const PatientDetailPage({super.key, required this.patient});

  @override
  State<PatientDetailPage> createState() => _PatientDetailPageState();
}

class _PatientDetailPageState extends State<PatientDetailPage> {
  late Patient _currentPatient;
  final SharePatientService _shareService = SharePatientService();

  // Fungsi memunculkan Bottom Sheet untuk berbagi
  void _showShareDialog(BuildContext context) {
    List<String> selectedUids = []; // Menyimpan UID penerima yang dicentang
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
              height: MediaQuery.of(context).size.height * 0.6, // 60% tinggi layar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bagikan ke Nutrisionis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Pilih satu atau lebih rekan untuk membagikan salinan data pasien ini.'),
                  const Divider(),
                  
                  // Daftar Nutrisionis
                  Expanded(
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: _shareService.getAvailableNutritionists(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Error: ${snapshot.error}'));
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return const Center(child: Text('Tidak ada akun Nutrisionis lain yang ditemukan.'));
                        }

                        final nutritionists = snapshot.data!;
                        return ListView.builder(
                          itemCount: nutritionists.length,
                          itemBuilder: (context, index) {
                            final user = nutritionists[index];
                            final isChecked = selectedUids.contains(user['uid']);

                            return CheckboxListTile(
                              title: Text(user['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
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

                  // Tombol Aksi
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isSending ? null : () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (selectedUids.isEmpty || isSending)
                              ? null
                              : () async {
                                  // Munculkan konfirmasi akhir
                                  bool? confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text('Konfirmasi Pengiriman'),
                                      content: Text('Kirim salinan data "${_currentPatient.namaLengkap}" ke ${selectedUids.length} orang?'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Kirim')),
                                      ],
                                    ),
                                  );

                                  if (confirm != true) return;

                                  setModalState(() => isSending = true);

                                  try {
                                    // Ambil raw data dari model menggunakan toMap()
                                    Map<String, dynamic> rawData = _currentPatient.toMap();
                                    // Hapus field ID agar saat di-import nanti dapat ID baru
                                    rawData.remove('id'); 
                                    
                                    // Karena toMap() mungkin mengubah tanggal menjadi String, pastikan formatnya aman untuk dikirim
                                    await _shareService.sendPatientData(
                                      receiverIds: selectedUids,
                                      patientData: rawData,
                                      patientName: _currentPatient.namaLengkap,
                                      patientType: 'dewasa',
                                    );

                                    if (context.mounted) {
                                      Navigator.pop(context); // Tutup bottom sheet
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Berhasil mengirimkan permintaan berbagi!'), backgroundColor: Colors.green),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Gagal mengirim: $e'), backgroundColor: Colors.red),
                                      );
                                    }
                                  } finally {
                                    setModalState(() => isSending = false);
                                  }
                                },
                          child: isSending
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
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
  void initState() {
    super.initState();
    _currentPatient = widget.patient;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithAnimatedFab(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: _currentPatient.namaLengkap,
        subtitle: 'Data Lengkap Pasien',
      ),
      // 1. Definisikan Tombol Aksi
      floatingActionButton: FormActionButtons(
        singleButtonMode: false,
        submitText: 'Edit',
        resetText: 'Hapus',
        submitIcon: const Icon(Icons.edit, color: Colors.white),
        resetIcon: const Icon(Icons.delete_forever),
        resetButtonColor: Colors.red, // Background jadi putih
        //resetForegroundColor: Colors.white,
        submitButtonColor: const Color.fromARGB(255, 0, 148, 68),
        onReset: () {
          PatientDeleteLogic.handlePatientDelete(
            context: context,
            patientId: _currentPatient.id, // <-- PERBAIKAN
            patientName: _currentPatient.namaLengkap, // <-- PERBAIKAN
          );
        },
        onSubmit: () async {
          final updatedPatient = await Navigator.push<Patient>(
            context,
            MaterialPageRoute(
              builder: (context) => DataFormPage(patient: _currentPatient),
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
            // --- Bagian Data Pasien ---
            _buildSectionTitle('Data Pasien'),
            _buildInfoRow('No. RM', _currentPatient.noRM),
            _buildInfoRow(
              'Tanggal Lahir',
              _currentPatient.tanggalLahirFormatted,
            ),
            _buildInfoRow('Usia', '${_currentPatient.usia} tahun'),
            _buildInfoRow('Jenis Kelamin', _currentPatient.jenisKelamin),
            _buildInfoRow('Berat Badan', '${_currentPatient.beratBadan} kg'),
            _buildInfoRow(
              'Tinggi Badan',
              '${_currentPatient.tinggiBadan.toStringAsFixed(0)} cm',
            ),
            if (_currentPatient.lila != null)
              _buildInfoRow(
                'Lingkar Lengan Atas (LILA)',
                '${_currentPatient.lila!.toStringAsFixed(1)} cm',
              ),
            if (_currentPatient.tl != null)
              _buildInfoRow(
                'Tinggi Lutut (TL)',
                '${_currentPatient.tl!.toStringAsFixed(1)} cm',
              ),
            _buildInfoRow('Diagnosis Medis', _currentPatient.diagnosisMedis),
            _buildInfoRow('Status Gizi', _currentPatient.statusGizi),

            const SizedBox(height: 16), // Spasi atas tombol
            // --- TOMBOL BERBAGI BARU ---
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showShareDialog(context),
                icon: const Icon(Icons.share, color: Colors.blue),
                label: const Text(
                  'Bagikan Data Pasien ke Nutrisionis Lain',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.blue),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),

            const Divider(height: 20, thickness: 2, color: Colors.green),

            // --- Bagian Hasil Perhitungan Gizi ---
            _buildSectionTitle('Hasil Perhitungan Gizi'),
            _buildInfoRow(
              'IMT (Indeks Massa Tubuh)',
              '${_currentPatient.imt.toStringAsFixed(2)} kg/m²',
              isBold: true,
            ),
            _buildInfoRow(
              'BBI (Berat Badan Ideal)',
              _currentPatient.bbi != 0.0
                  ? '${_currentPatient.bbi.toStringAsFixed(1)} kg'
                  : '-',
              isBold: true,
            ),
            _buildInfoRow(
              'BMR (Kebutuhan Kalori Basal)',
              _currentPatient.bmr != 0.0
                  ? '${_currentPatient.bmr.toStringAsFixed(2)} kkal'
                  : '-',
              isBold: true,
            ),
            _buildInfoRow(
              'TDEE (Total Kebutuhan Energi)',
              _currentPatient.tdee != 0.0
                  ? '${_currentPatient.tdee.toStringAsFixed(2)} kkal'
                  : '-',
              isBold: true,
            ),
            _buildInfoRow('Aktivitas', _currentPatient.aktivitas),

            const Divider(height: 20, thickness: 2, color: Colors.green),

            // --- Bagian Skrining Gizi Lanjut ---
            _buildSectionTitle('Skrining Gizi Lanjut'),
            _buildInfoRow('Skor IMT', _currentPatient.skorIMT.toString()),
            _buildInfoRow(
              'Skor Kehilangan BB',
              _currentPatient.skorKehilanganBB.toString(),
            ),
            _buildInfoRow(
              'Skor Efek Penyakit Akut',
              _currentPatient.skorEfekPenyakit.toString(),
            ),
            const Divider(),
            _buildInfoRow(
              'Total Skor',
              _currentPatient.totalSkor.toString(),
              isBold: true,
            ),
            _buildInfoRow(
              'Interpretasi',
              _currentPatient.interpretasi,
              isBold: true,
              valueColor: _getInterpretationColor(_currentPatient.interpretasi),
            ),

            const SizedBox(height: 20),

            // --- Tombol Aksi ---
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

                        final pdfFile = await PdfGenerator.generate(
                          _currentPatient,
                        );

                        await PdfGenerator.openFile(pdfFile);

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
                        Text('Formulir Skrining Gizi'),
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
                _buildInfoRow(
                  'Alergi Makanan',
                  _currentPatient.alergiMakanan ?? '-',
                ),
                if (_currentPatient.detailAlergi != null &&
                    _currentPatient.detailAlergi!.isNotEmpty)
                  _buildInfoDisplay(
                    label: 'Detail Alergi',
                    value: _currentPatient.detailAlergi!,
                    emptyValueMessage: 'Tidak ada data Alergi makanan.',
                  ),
                _buildInfoRow(
                  'Pola Makan/Asupan(%)',
                  (_currentPatient.polaMakan != null &&
                          _currentPatient.polaMakan!.isNotEmpty)
                      ? '${_currentPatient.polaMakan}'
                      : '-',
                ),
              ],
            ),
            // Kategori 2: Data Biokimia
            ExpansionTile(
              leading: const Icon(Icons.science_outlined),
              title: const Text(
                'Biokimia /BD \n(Biochemical Data)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                if (_currentPatient.labResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Tidak ada data laboratorium.'),
                  )
                else
                  // Loop Map untuk menampilkan semua data lab yang tersimpan
                  ..._currentPatient.labResults.entries.map((entry) {
                    return _buildInfoRow(
                      entry.key, // Key (misal: "GDS")
                      '${entry.value} mg/dL', // Value (misal: "120"), default unit mg/dL
                    );
                  }),
              ],
            ),
            // Kategori 3: Data Klinis/Fisik
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
            // Kategori 4: Riwayat Personal
            ExpansionTile(
              leading: const Icon(Icons.person_outline),
              title: const Text(
                'Riwayat Personal /CH \n(Client History)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoDisplay(
                  label: 'Riwayat Penyakit Sekarang :',
                  value: _currentPatient.riwayatPenyakitSekarang,
                  emptyValueMessage: '-',
                ),
                _buildInfoDisplay(
                  label: 'Riwayat Penyakit Dahulu :',
                  value: _currentPatient.riwayatPenyakitDahulu,
                  emptyValueMessage: '-',
                ),
                const Divider(), // Pemisah visual antara riwayat penyakit dan kebiasaan
                // Implementasi Data Kebiasaan Baru
                _buildInfoRow(
                  'Suka Manis',
                  (_currentPatient.sukaManis ?? false) ? 'Ya' : 'Tidak',
                ),
                _buildInfoRow(
                  'Suka Asin',
                  (_currentPatient.sukaAsin ?? false) ? 'Ya' : 'Tidak',
                ),
                _buildInfoRow(
                  'Makan Berlemak',
                  (_currentPatient.makanBerlemak ?? false) ? 'Ya' : 'Tidak',
                ),
                _buildInfoRow(
                  'Jarang Olahraga',
                  (_currentPatient.jarangOlahraga ?? false) ? 'Ya' : 'Tidak',
                ),
              ],
            ),
            // Kategori 5: Diagnosis Gizi
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

            // Kategori 6: Rencana Intervensi Gizi
            ExpansionTile(
              leading: const Icon(Icons.food_bank_outlined),
              title: const Text(
                'Intervensi Gizi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoDisplay(
                  label: 'Intervensi Jenis Diet',
                  value:
                      (_currentPatient.intervensiDiet != null &&
                          _currentPatient.intervensiDiet!.isNotEmpty)
                      ? '${_currentPatient.intervensiDiet}'
                      : '-',
                ),
                _buildInfoRow(
                  'Intervensi Bentuk Makanan',
                  (_currentPatient.intervensiBentukMakanan != null &&
                          _currentPatient.intervensiBentukMakanan!.isNotEmpty)
                      ? '${_currentPatient.intervensiBentukMakanan}'
                      : '-',
                ),
                _buildInfoRow(
                  'Intervensi Via',
                  (_currentPatient.intervensiVia != null &&
                          _currentPatient.intervensiVia!.isNotEmpty)
                      ? '${_currentPatient.intervensiVia}'
                      : '-',
                ),
                _buildInfoDisplay(
                  label: 'Tujuan Diet :',
                  value: _currentPatient.intervensiTujuan,
                  emptyValueMessage: '-',
                ),
              ],
            ),
            // Kategori 7: Monitoring & Evaluasi
            ExpansionTile(
              leading: const Icon(Icons.analytics_outlined),
              title: const Text(
                'Monitoring dan Evaluasi',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              childrenPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                _buildInfoRow('Status Gizi', _currentPatient.statusGizi),
                _buildInfoDisplay(
                  label: 'Indikator Monitoring :',
                  value: _currentPatient.monevIndikator,
                  emptyValueMessage: '-',
                ),
                _buildInfoDisplay(
                  label: 'Asupan Makanan :',
                  value: _currentPatient.monevAsupan,
                  emptyValueMessage: '-',
                ),
                _buildInfoDisplay(
                  label: 'Hasil Lab :',
                  value: _currentPatient.monevHasilLab,
                  emptyValueMessage: '-',
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

                        final pdfFile = await PdfGeneratorAsuhan.generate(
                          _currentPatient,
                        );

                        await PdfGeneratorAsuhan.openFile(pdfFile);

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

  // Letakkan ini di dalam class _PatientDetailPageState

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

  Color _getInterpretationColor(String interpretasi) {
    final text = interpretasi.toLowerCase();

    // Urutan pengecekan penting (cek 'sangat tinggi' sebelum 'tinggi')
    if (text.contains('sangat tinggi')) {
      return Colors.red;
    } else if (text.contains('tinggi')) {
      return Colors.orange;
    } else if (text.contains('menengah')) {
      return Colors.amber;
    } else if (text.contains('rendah')) {
      return const Color.fromARGB(255, 0, 148, 68); // Hijau
    }

    return Colors.black87;
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
        crossAxisAlignment:
            CrossAxisAlignment.start, // Tambahkan ini agar teks rata atas
        children: [
          Expanded(
            flex: 2, // Mengambil porsi ruang untuk label
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 16), // Jarak antara label dan value
          Expanded(
            flex: 3, // Mengambil porsi ruang lebih besar untuk value
            child: Text(
              value,
              textAlign: TextAlign.right, // Teks rata kanan
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
