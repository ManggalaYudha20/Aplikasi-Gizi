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

  String? _jenisKelamin;
  String? _aktivitas;
  DateTime? _selectedDate;

  @override
  void dispose() {
    _noRMController.dispose();
    _namaLengkapController.dispose();
    _tanggalLahirController.dispose();
    _diagnosisMedisController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    super.dispose();
  }

  // Fungsi baru untuk mereset semua field
  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _noRMController.clear();
      _namaLengkapController.clear();
      _tanggalLahirController.clear();
      _diagnosisMedisController.clear();
      _beratBadanController.clear();
      _tinggiBadanController.clear();
      _jenisKelamin = null;
      _aktivitas = null;
      _selectedDate = null;
    });
  }

  Future<void> _savePatientData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // --- Data Collection ---
        final noRM = _noRMController.text;
        final namaLengkap = _namaLengkapController.text;
        final diagnosisMedis = _diagnosisMedisController.text;
        final beratBadan = double.parse(_beratBadanController.text);
        final tinggiBadan = double.parse(_tinggiBadanController.text);

        // --- Calculations ---
        final tinggiBadanMeter = tinggiBadan / 100;
        final imt = beratBadan / (tinggiBadanMeter * tinggiBadanMeter);

        // Asumsi skor default, sesuaikan jika ada logika inputnya
        final skorIMT = (imt < 18.5 || imt > 25) ? 1 : 0;
        const skorKehilanganBB = 0; // Contoh, perlu inputan lebih lanjut
        const skorEfekPenyakit = 1; // Contoh, perlu inputan lebih lanjut
        final totalSkor = skorIMT + skorKehilanganBB + skorEfekPenyakit;

        // --- Prepare data for Firestore ---
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
          'tanggalPemeriksaan': Timestamp.now(), // Store the current time
        };

        // --- Send to Firestore ---
        await FirebaseFirestore.instance
            .collection('patients')
            .add(patientData);

        // --- Show Success and Navigate Back ---
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
        // --- Show Error ---
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
      appBar: const CustomAppBar(
        title: 'Form Data Pasien',
        subtitle: 'Isi data dengan lengkap',
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                prefixIcon: Icon(Icons.wc),
                label: 'Jenis Kelamin',
                items: ['Laki-laki', 'Perempuan'],
                onChanged: (value) => setState(() => _jenisKelamin = value),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _diagnosisMedisController,
                label: 'Diagnosis Medis',
                prefixIcon: Icon(Icons.sick),
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _beratBadanController,
                label: 'Berat Badan',
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.monitor_weight),
                suffixText: 'kg',
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _tinggiBadanController,
                label: 'Tinggi Badan',
                keyboardType: TextInputType.number,
                prefixIcon: Icon(Icons.height),
                suffixText: 'cm',
              ),
              const SizedBox(height: 16),
              _buildDropdownFormField(
                prefixIcon: Icon(Icons.directions_run),
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
              // --- Tombol Reset dan Simpan ---
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
    Icon? suffixIcon,
    TextInputType? keyboardType,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
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
        border: OutlineInputBorder(),
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
