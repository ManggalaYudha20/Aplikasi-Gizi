// lib/src/features/home/presentation/pages/data_form_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';

class DataFormPage extends StatefulWidget {
  const DataFormPage({super.key});

  @override
  State<DataFormPage> createState() => _DataFormPageState();
}

class _DataFormPageState extends State<DataFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controllers for form fields
  final _noRMController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _diagnosisMedisController = TextEditingController();
  final _beratBadanController = TextEditingController();
  final _tinggiBadanController = TextEditingController();
  // BARU: Controller untuk berat badan 3-6 bulan lalu
  final _beratBadanDuluController = TextEditingController();

  String? _jenisKelamin;
  String? _aktivitas;
  // BARU: State untuk menyimpan pilihan kehilangan nafsu makan
  String? _kehilanganNafsuMakan;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _noRMController.dispose();
    _namaLengkapController.dispose();
    _tanggalLahirController.dispose();
    _diagnosisMedisController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    // BARU: Dispose controller baru
    _beratBadanDuluController.dispose();
    super.dispose();
  }

  // Fungsi untuk mereset semua field
  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _noRMController.clear();
      _namaLengkapController.clear();
      _tanggalLahirController.clear();
      _diagnosisMedisController.clear();
      _beratBadanController.clear();
      _tinggiBadanController.clear();
      // BARU: Reset field baru
      _beratBadanDuluController.clear();
      _kehilanganNafsuMakan = null;
      _jenisKelamin = null;
      _aktivitas = null;
      _selectedDate = null;
    });
  }

  Future<void> _savePatientData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // --- Pengumpulan Data ---
        final noRM = _noRMController.text;
        final namaLengkap = _namaLengkapController.text;
        final diagnosisMedis = _diagnosisMedisController.text;
        final beratBadan = double.parse(_beratBadanController.text);
        final tinggiBadan = double.parse(_tinggiBadanController.text);
        // BARU: Ambil data berat badan dulu
        final beratBadanDulu = double.tryParse(_beratBadanDuluController.text);

        // --- Perhitungan ---
        final tinggiBadanMeter = tinggiBadan / 100;
        final imt = beratBadan / (tinggiBadanMeter * tinggiBadanMeter);

        // DIUBAH: Logika skor IMT
        final int skorIMT;
        if (imt < 18.5) {
          skorIMT = 2;
        } else if (imt >= 18.5 && imt < 25) {
          skorIMT = 1;
        } else { // imt >= 25
          skorIMT = 0;
        }

        // DIUBAH: Logika perhitungan skor kehilangan BB
        int skorKehilanganBB = 0; // Default skor 0
        if (beratBadanDulu != null && beratBadanDulu > 0) {
          final persentaseKehilangan = ((beratBadanDulu - beratBadan) / beratBadanDulu) * 100;
          if (persentaseKehilangan > 10) {
            skorKehilanganBB = 2;
          } else if (persentaseKehilangan >= 5) {
            skorKehilanganBB = 1;
          }
        }

        // DIUBAH: Logika skor efek penyakit dari input kehilangan nafsu makan
        final skorEfekPenyakit = (_kehilanganNafsuMakan == 'Ya') ? 2 : 0;
        
        final totalSkor = skorIMT + skorKehilanganBB + skorEfekPenyakit;

        // --- Siapkan data untuk Firestore ---
        final patientData = {
          'noRM': noRM,
          'namaLengkap': namaLengkap,
          'tanggalLahir': _selectedDate != null
              ? Timestamp.fromDate(_selectedDate!)
              : null,
          'diagnosisMedis': diagnosisMedis,
          'beratBadan': beratBadan,
          'tinggiBadan': tinggiBadan,
          'jenisKelamin': _jenisKelamin,
          'aktivitas': _aktivitas,
          'imt': imt,
          'skorIMT': skorIMT,
          'skorKehilanganBB': skorKehilanganBB,
          'skorEfekPenyakit': skorEfekPenyakit,
          'totalSkor': totalSkor,
          'tanggalPemeriksaan': Timestamp.now(),
        };

        // --- Kirim ke Firestore ---
        await FirebaseFirestore.instance
            .collection('patients')
            .add(patientData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Data pasien berhasil disimpan!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text = DateFormat('d MMMM y').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Form Data Pasien',
        subtitle: 'Isi data dengan lengkap',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
                const Text(
                  'Input Data Pasien',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
              _buildTextFormField(
                controller: _noRMController,
                label: 'No. Rekam Medis (RM)',
                prefixIcon: const Icon(Icons.medical_information),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _namaLengkapController,
                label: 'Nama Lengkap',
                prefixIcon: const Icon(Icons.person),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _tanggalLahirController,
                label: 'Tanggal Lahir',
                readOnly: true,
                onTap: () => _selectDate(context),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              const SizedBox(height: 16),
              _buildDropdownFormField(
                value: _jenisKelamin,
                prefixIcon: const Icon(Icons.wc),
                label: 'Jenis Kelamin',
                items: ['Laki-laki', 'Perempuan'],
                onChanged: (value) => setState(() => _jenisKelamin = value),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _diagnosisMedisController,
                label: 'Diagnosis Medis',
                prefixIcon: const Icon(Icons.sick),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _beratBadanController,
                label: 'Berat Badan Saat Ini',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.monitor_weight),
                suffixText: 'kg',
              ),
              const SizedBox(height: 16),
              // BARU: Form untuk berat badan terdahulu
              _buildTextFormField(
                controller: _beratBadanDuluController,
                label: 'Berat Badan 3-6 Bulan Lalu',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.history),
                suffixText: 'kg',
                // Validator ini opsional, data tetap bisa disimpan jika kosong
                validator: (value) {
                  if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _tinggiBadanController,
                label: 'Tinggi Badan',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.height),
                suffixText: 'cm',
              ),
              const SizedBox(height: 16),
              // BARU: Dropdown untuk kehilangan nafsu makan
              _buildDropdownFormField(
                prefixIcon: const Icon(Icons.food_bank_outlined),
                value: _kehilanganNafsuMakan,
                label: 'Nafsu Makan / Asupan Berkurang?',
                items: ['Ya', 'Tidak'],
                onChanged: (value) => setState(() => _kehilanganNafsuMakan = value),
              ),
              const SizedBox(height: 16),
              _buildDropdownFormField(
                prefixIcon: const Icon(Icons.directions_run),
                value: _aktivitas,
                label: 'Tingkat Aktivitas',
                items: [
                  'Sangat Jarang',
                  'Ringan',
                  'Sedang',
                  'Berat',
                  'Sangat Aktif',
                ],
                onChanged: (value) => setState(() => _aktivitas = value),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _resetForm,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: const BorderSide(
                          color: Color.fromARGB(255, 0, 148, 68),
                        ),
                      ),
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 0, 148, 68),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePatientData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : const Text(
                              'Simpan',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    VoidCallback? onTap,
    Icon? prefixIcon,
    TextInputType? keyboardType,
    String? suffixText,
    // DIUBAH: Tambahkan parameter validator
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      // DIUBAH: Gunakan validator yang diberikan atau default validator
      validator: validator ?? (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        if (keyboardType == TextInputType.number && double.tryParse(value) == null) {
          return 'Masukkan angka yang valid';
        }
        return null;
      },
    );
  }

  Widget _buildDropdownFormField({
    required String? value,
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required Icon? prefixIcon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
      ),
      items: items.map((String item) {
        return DropdownMenuItem<String>(value: item, child: Text(item));
      }).toList(),
      onChanged: onChanged,
      validator: (value) => value == null ? '$label harus dipilih' : null,
    );
  }
}