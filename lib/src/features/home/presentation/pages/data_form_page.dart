// lib/src/features/home/presentation/pages/data_form_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/home/data/models/patient_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/scaffold_with_animated_fab.dart';

class DataFormPage extends StatefulWidget {
  final Patient? patient; // Optional patient for editing

  const DataFormPage({super.key, this.patient});

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
  final _lilaController = TextEditingController();
  final _tlController = TextEditingController();
  String? _jenisKelamin;
  String? _aktivitas;
  // BARU: State untuk menyimpan pilihan kehilangan nafsu makan
  String? _kehilanganNafsuMakan;
  DateTime? _selectedDate;
  // BARU: Controllers untuk Asuhan Gizi
  String? _alergiMakanan = 'Tidak';
  final _detailAlergiController = TextEditingController();
  final _polaMakanController = TextEditingController();
  final _biokimiaGDSController = TextEditingController();
  final _biokimiaUreumController = TextEditingController();
  final _biokimiaHGBController = TextEditingController();
  final _biokimiaENTController = TextEditingController();
  final _klinikTDController = TextEditingController();
  final _klinikKUController = TextEditingController();
  final _klinikKESController = TextEditingController();
  final _klinikNadiController = TextEditingController();
  final _klinikSuhuController = TextEditingController();
  final _klinikRRController = TextEditingController();
  final _klinikSPO2Controller = TextEditingController();
  final _riwayatPenyakitSekarangController = TextEditingController();
  final _riwayatPenyakitDahuluController = TextEditingController();
  final _diagnosaGiziController = TextEditingController();
  final _intervensiDietController = TextEditingController();
  final _intervensiBentukMakananController = TextEditingController();
  final _intervensiViaController = TextEditingController();
  final _intervensiTujuanController = TextEditingController();
  final _monevAsupanController = TextEditingController();
  final _namaNutrisionisController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize form with existing patient data if provided
    if (widget.patient != null) {
      _initializeFormWithPatientData();
    }
  }

  void _initializeFormWithPatientData() {
    final patient = widget.patient!;
    _noRMController.text = patient.noRM;
    _namaLengkapController.text = patient.namaLengkap;
    _tanggalLahirController.text = patient.tanggalLahirFormatted;
    _diagnosisMedisController.text = patient.diagnosisMedis;
    _beratBadanController.text = patient.beratBadan.toString();
    _tinggiBadanController.text = patient.tinggiBadan.toString();
    _jenisKelamin = patient.jenisKelamin;
    _aktivitas = patient.aktivitas;
    _selectedDate = patient.tanggalLahir;
    // Perbaikan: LILA dan TL harus diambil dari model juga
    if (patient.lila != null) {
      _lilaController.text = patient.lila.toString();
    }
    if (patient.tl != null) {
      _tlController.text = patient.tl.toString();
    }
    // Note: We don't have beratBadanDulu and kehilanganNafsuMakan in Patient model
    // These fields will remain empty for editing

    // BARU: Inisialisasi data asuhan gizi
    _alergiMakanan = patient.alergiMakanan;
    _detailAlergiController.text = patient.detailAlergi ?? '';
    _polaMakanController.text = patient.polaMakan ?? '';
    _biokimiaGDSController.text = patient.biokimiaGDS ?? '';
    _biokimiaUreumController.text = patient.biokimiaUreum ?? '';
    _biokimiaHGBController.text = patient.biokimiaHGB ?? '';
    _klinikTDController.text = patient.klinikTD ?? '';
    _klinikNadiController.text = patient.klinikNadi ?? '';
    _klinikSuhuController.text = patient.klinikSuhu ?? '';
    _klinikRRController.text = patient.klinikRR ?? '';
    _riwayatPenyakitSekarangController.text =
        patient.riwayatPenyakitSekarang ?? '';
    _riwayatPenyakitDahuluController.text = patient.riwayatPenyakitDahulu ?? '';
    _diagnosaGiziController.text = patient.diagnosaGizi ?? '';
    _intervensiDietController.text = patient.intervensiDiet ?? '';
    _intervensiBentukMakananController.text =
        patient.intervensiBentukMakanan ?? '';
    _intervensiViaController.text = patient.intervensiVia ?? '';
    _intervensiTujuanController.text = patient.intervensiTujuan ?? '';
    _monevAsupanController.text = patient.monevAsupan ?? '';
    _biokimiaENTController.text = patient.biokimiaENT ?? '';
    _klinikKUController.text = patient.klinikKU ?? '';
    _klinikKESController.text = patient.klinikKES ?? '';
    _klinikSPO2Controller.text = patient.klinikSPO2 ?? '';
    _namaNutrisionisController.text = patient.namaNutrisionis ?? '';
  }

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
    _lilaController.dispose();
    _tlController.dispose();
    // BARU: Dispose controllers asuhan gizi
    _detailAlergiController.dispose();
    _polaMakanController.dispose();
    _biokimiaGDSController.dispose();
    _biokimiaUreumController.dispose();
    _biokimiaHGBController.dispose();
    _klinikTDController.dispose();
    _klinikNadiController.dispose();
    _klinikSuhuController.dispose();
    _klinikRRController.dispose();
    _riwayatPenyakitSekarangController.dispose();
    _riwayatPenyakitDahuluController.dispose();
    _diagnosaGiziController.dispose();
    _intervensiDietController.dispose();
    _intervensiBentukMakananController.dispose();
    _intervensiViaController.dispose();
    _intervensiTujuanController.dispose();
    _monevAsupanController.dispose();
    _biokimiaENTController.dispose();
    _klinikKUController.dispose();
    _klinikKESController.dispose();
    _klinikSPO2Controller.dispose();
    _namaNutrisionisController.dispose();
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
      _lilaController.clear();
      _tlController.clear();
      _kehilanganNafsuMakan = null;
      _jenisKelamin = null;
      _aktivitas = null;
      _selectedDate = null;
      _alergiMakanan = null;
      _detailAlergiController.clear();
      _polaMakanController.clear();
      _biokimiaGDSController.clear();
      _biokimiaUreumController.clear();
      _biokimiaHGBController.clear();
      _klinikTDController.clear();
      _klinikNadiController.clear();
      _klinikSuhuController.clear();
      _klinikRRController.clear();
      _riwayatPenyakitSekarangController.clear();
      _riwayatPenyakitDahuluController.clear();
      _diagnosaGiziController.clear();
      _intervensiDietController.clear();
      _intervensiBentukMakananController.clear();
      _intervensiViaController.clear();
      _intervensiTujuanController.clear();
      _monevAsupanController.clear();
      _biokimiaENTController.clear();
      _klinikKUController.clear();
      _klinikKESController.clear();
      _klinikSPO2Controller.clear();
      _namaNutrisionisController.clear();
    });
  }

  int _calculateAgeInYears(DateTime? birthDate) {
    if (birthDate == null) return 0;
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  Future<void> _savePatientData() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // --- Pengumpulan Data ---
        final noRM = _noRMController.text;
        final namaLengkap = _namaLengkapController.text;
        final diagnosisMedis = _diagnosisMedisController.text;
        // BARU: Ambil data berat badan dulu
        final beratBadanDulu = double.tryParse(_beratBadanDuluController.text);
        final usia = _calculateAgeInYears(_selectedDate);

        double? beratBadan;
        double? tinggiBadan;

        // BARU: Logika untuk menentukan BB dan TB
        if (_beratBadanController.text.isNotEmpty) {
          beratBadan = double.parse(_beratBadanController.text);
        } else if (_lilaController.text.isNotEmpty) {
          final lila = double.parse(_lilaController.text);
          // Menggunakan rumus yang disederhanakan sesuai permintaan
          beratBadan = (2.81 * lila) - 18.6;
        }

        if (_tinggiBadanController.text.isNotEmpty) {
          tinggiBadan = double.parse(_tinggiBadanController.text);
        } else if (_tlController.text.isNotEmpty &&
            _jenisKelamin != null &&
            usia > 0) {
          // Gunakan rumus estimasi TB dari TL jika TB tidak ada
          final tl = double.parse(_tlController.text);
          if (_jenisKelamin == 'Laki-laki') {
            tinggiBadan = (2.02 * tl) - (0.04 * usia) + 64.19;
          } else {
            tinggiBadan = (1.83 * tl) - (0.24 * usia) + 84.88;
          }
        }

        // Final check to ensure we have both values
        if (beratBadan == null || tinggiBadan == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tinggi dan Berat badan tidak boleh kosong.'),
                backgroundColor: Colors.red,
              ),
            );
            setState(() => _isLoading = false);
          }
          return;
        }

        // --- Perhitungan ---
        final tinggiBadanMeter = tinggiBadan / 100;
        final imt = beratBadan / (tinggiBadanMeter * tinggiBadanMeter);

        // DIUBAH: Logika skor IMT
        final int skorIMT;
        if (imt < 18.5) {
          skorIMT = 2;
        } else if (imt >= 18.5 && imt < 25) {
          skorIMT = 1;
        } else {
          // imt >= 25
          skorIMT = 0;
        }

        // BARU: Logika untuk menentukan Status Gizi berdasarkan IMT
        String statusGizi;
        if (imt < 18.5) {
          statusGizi = 'Gizi Kurang (Underweight)';
        } else if (imt >= 18.5 && imt <= 24.9) {
          statusGizi = 'Gizi Baik (Normal)';
        } else if (imt >= 25 && imt <= 29.9) {
          statusGizi = 'Gizi Lebih (Overweight)';
        } else {
          // imt >= 30
          statusGizi = 'Obesitas';
        }

        // DIUBAH: Logika perhitungan skor kehilangan BB
        int skorKehilanganBB = 0; // Default skor 0
        if (beratBadanDulu != null && beratBadanDulu > 0) {
          final persentaseKehilangan =
              ((beratBadanDulu - beratBadan) / beratBadanDulu) * 100;
          if (persentaseKehilangan > 10) {
            skorKehilanganBB = 2;
          } else if (persentaseKehilangan >= 5) {
            skorKehilanganBB = 1;
          }
        }

        // DIUBAH: Logika skor efek penyakit dari input kehilangan nafsu makan
        final skorEfekPenyakit = (_kehilanganNafsuMakan == 'Ya') ? 0 : 2;

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
          'lila': double.tryParse(
            _lilaController.text,
          ), // BARU: Simpan LILA ke Firestore
          'tl': double.tryParse(_tlController.text),
          // BARU: Data Asuhan Gizi
          'alergiMakanan': _alergiMakanan,
          'detailAlergi': _detailAlergiController.text,
          'polaMakan': _polaMakanController.text,
          'biokimiaGDS': _biokimiaGDSController.text,
          'biokimiaUreum': _biokimiaUreumController.text,
          'biokimiaHGB': _biokimiaHGBController.text,
          'klinikTD': _klinikTDController.text,
          'klinikNadi': _klinikNadiController.text,
          'klinikSuhu': _klinikSuhuController.text,
          'klinikRR': _klinikRRController.text,
          'riwayatPenyakitSekarang': _riwayatPenyakitSekarangController.text,
          'riwayatPenyakitDahulu': _riwayatPenyakitDahuluController.text,
          'diagnosaGizi': _diagnosaGiziController.text,
          'intervensiDiet': _intervensiDietController.text,
          'intervensiBentukMakanan': _intervensiBentukMakananController.text,
          'intervensiVia': _intervensiViaController.text,
          'intervensiTujuan': _intervensiTujuanController.text,
          'monevAsupan': _monevAsupanController.text,
          'monevStatusGizi': statusGizi,
          'biokimiaENT': _biokimiaENTController.text,
          'klinikKU': _klinikKUController.text,
          'klinikKES': _klinikKESController.text,
          'klinikSPO2': _klinikSPO2Controller.text,
          'namaNutrisionis': _namaNutrisionisController.text,
        };

        // --- Kirim ke Firestore ---
        if (widget.patient != null) {
          // Update existing patient
          await FirebaseFirestore.instance
              .collection('patients')
              .doc(widget.patient!.id)
              .update(patientData);
        } else {
          // Create new patient
          await FirebaseFirestore.instance
              .collection('patients')
              .add(patientData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.patient != null
                    ? 'Data pasien berhasil diperbarui!'
                    : 'Data pasien berhasil disimpan!',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Create updated patient object to return
          final updatedPatient = Patient(
            id: widget.patient?.id ?? '', // Will be empty for new patients
            noRM: noRM,
            namaLengkap: namaLengkap,
            tanggalLahir: _selectedDate ?? DateTime.now(),
            diagnosisMedis: diagnosisMedis,
            beratBadan: beratBadan,
            tinggiBadan: tinggiBadan,
            jenisKelamin: _jenisKelamin ?? 'Laki-laki',
            aktivitas: _aktivitas ?? 'Sangat Jarang',
            imt: imt,
            skorIMT: skorIMT,
            skorKehilanganBB: skorKehilanganBB,
            skorEfekPenyakit: skorEfekPenyakit,
            totalSkor: totalSkor,
            tanggalPemeriksaan: DateTime.now(),
            lila: double.tryParse(_lilaController.text),
            tl: double.tryParse(_tlController.text),

            // ✨ PENAMBAHAN KODE PENTING ADA DI SINI ✨
            // Memasukkan semua data asuhan gizi ke objek yang dikembalikan
            alergiMakanan: _alergiMakanan,
            detailAlergi: _detailAlergiController.text,
            polaMakan: _polaMakanController.text,
            biokimiaGDS: _biokimiaGDSController.text,
            biokimiaUreum: _biokimiaUreumController.text,
            biokimiaHGB: _biokimiaHGBController.text,
            klinikTD: _klinikTDController.text,
            klinikNadi: _klinikNadiController.text,
            klinikSuhu: _klinikSuhuController.text,
            klinikRR: _klinikRRController.text,
            riwayatPenyakitSekarang: _riwayatPenyakitSekarangController.text,
            riwayatPenyakitDahulu: _riwayatPenyakitDahuluController.text,
            diagnosaGizi: _diagnosaGiziController.text,
            intervensiDiet: _intervensiDietController.text,
            intervensiBentukMakanan: _intervensiBentukMakananController.text,
            intervensiVia: _intervensiViaController.text,
            intervensiTujuan: _intervensiTujuanController.text,
            monevAsupan: _monevAsupanController.text,
            monevStatusGizi: statusGizi,
            biokimiaENT: _biokimiaENTController.text,
            klinikKU: _klinikKUController.text,
            klinikKES: _klinikKESController.text,
            klinikSPO2: _klinikSPO2Controller.text,
            namaNutrisionis: _namaNutrisionisController.text,
          );

          // Navigate back to previous screen with updated patient data
          Navigator.of(context).pop(updatedPatient);
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
    return ScaffoldWithAnimatedFab(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: widget.patient != null
            ? 'Edit Data Pasien'
            : 'Form Pasien Dewasa',
        subtitle: widget.patient != null
            ? 'Perbarui data pasien'
            : 'Isi data dengan lengkap',
      ),
      floatingActionButton: FormActionButtons(
        onReset: _resetForm,
        onSubmit: _savePatientData,
        resetButtonColor: Colors.white, // Background jadi putih
        resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
        submitText: widget.patient != null ? 'Perbarui' : 'Simpan',
        isLoading: _isLoading,
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Izinkan kosong jika menggunakan LILA
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // BARU: Form untuk LILA
              _buildTextFormField(
                controller: _lilaController,
                label: 'Lingkar Lengan Atas (LILA)',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.fitness_center),
                suffixText: 'cm',
                validator: (value) {
                  if (_beratBadanController.text.isEmpty &&
                      (value == null || value.isEmpty)) {
                    return 'LILA tidak boleh kosong jika BB tidak diisi';
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
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
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Field untuk Tinggi Badan normal
              _buildTextFormField(
                controller: _tinggiBadanController,
                label: 'Tinggi Badan',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.height),
                suffixText: 'cm',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return null; // Izinkan kosong jika menggunakan TL
                  }
                  if (double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // BARU: Form untuk Tinggi Lutut
              _buildTextFormField(
                controller: _tlController,
                label: 'Tinggi Lutut (TL)',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.accessibility),
                suffixText: 'cm',
                validator: (value) {
                  if (_tinggiBadanController.text.isEmpty &&
                      (value == null || value.isEmpty)) {
                    return 'TL tidak boleh kosong jika Tinggi Badan tidak diisi';
                  }
                  if (value != null &&
                      value.isNotEmpty &&
                      double.tryParse(value) == null) {
                    return 'Masukkan angka yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // BARU: Dropdown untuk kehilangan nafsu makan
              _buildDropdownFormField(
                prefixIcon: const Icon(Icons.food_bank_outlined),
                value: _kehilanganNafsuMakan,
                label: 'Ada asupan nutrisi > 5 hari?',
                items: ['Ya', 'Tidak Ada'],
                onChanged: (value) =>
                    setState(() => _kehilanganNafsuMakan = value),
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

              const SizedBox(height: 24),
              const Text(
                'Input Data Asuhan Gizi (Opsional)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              // Gunakan Column untuk mengelompokkan widget
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownFormField(
                    value: _alergiMakanan,
                    prefixIcon: const Icon(Icons.no_food),
                    label: 'Alergi Makanan',
                    items: ['Ya', 'Tidak'],
                    onChanged: (value) {
                      setState(() {
                        _alergiMakanan = value;
                        // Opsional: bersihkan field detail jika pengguna memilih 'Tidak'
                        if (value == 'Tidak') {
                          _detailAlergiController.clear();
                        }
                      });
                    },
                  ),

                  if (_alergiMakanan == 'Ya')
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 16.0,
                      ), // Beri jarak atas
                      child: _buildTextFormField(
                        controller: _detailAlergiController,
                        label: 'Jika Ya, sebutkan alerginya',
                        prefixIcon: const Icon(Icons.description),
                        validator: (value) {
                          // Anda bisa membuatnya wajib diisi jika 'Ya' dipilih
                          if (value == null || value.isEmpty) {
                            return 'Detail alergi tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _polaMakanController,
                label: 'Pola Makan / Asupan',
                prefixIcon: const Icon(Icons.restaurant),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _biokimiaGDSController,
                label: 'Biokimia: GDS',
                prefixIcon: const Icon(Icons.science),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _biokimiaUreumController,
                label: 'Biokimia: Ureum',
                prefixIcon: const Icon(Icons.science),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _biokimiaHGBController,
                label: 'Biokimia: HGB',
                prefixIcon: const Icon(Icons.science),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _biokimiaENTController,
                label: 'Biokimia: ENT',
                prefixIcon: const Icon(Icons.science),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _klinikTDController,
                label: 'Tekanan Darah (TD)',
                prefixIcon: const Icon(Icons.favorite),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _klinikNadiController,
                label: 'Nadi (N)',
                prefixIcon: const Icon(Icons.monitor_heart),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _klinikSuhuController,
                label: 'Suhu Badan (SB)',
                prefixIcon: const Icon(Icons.thermostat),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _klinikRRController,
                label: 'Pernapasan (RR)',
                prefixIcon: const Icon(Icons.air),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _klinikKUController,
                label: 'Keadaan Umum (KU)',
                prefixIcon: const Icon(Icons.monitor_heart),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _klinikKESController,
                label: 'Kesadaran (KES)',
                prefixIcon: const Icon(Icons.monitor_heart),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _klinikSPO2Controller,
                label: 'Saturasi Oksigen (SpO2)',
                prefixIcon: const Icon(Icons.air),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _riwayatPenyakitSekarangController,
                label: 'Riwayat Penyakit Sekarang (RPS)',
                prefixIcon: const Icon(Icons.history_edu),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _riwayatPenyakitDahuluController,
                label: 'Riwayat Penyakit Dahulu (RPD)',
                prefixIcon: const Icon(Icons.history),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _diagnosaGiziController,
                label: 'Diagnosa Gizi',
                prefixIcon: const Icon(Icons.medical_services),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _intervensiDietController,
                label: 'Intervensi: Diet',
                prefixIcon: const Icon(Icons.food_bank),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _intervensiBentukMakananController,
                label: 'Intervensi: Bentuk Makanan',
                prefixIcon: const Icon(Icons.fastfood),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _intervensiViaController,
                label: 'Intervensi: Via',
                prefixIcon: const Icon(Icons.route),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _intervensiTujuanController,
                label: 'Intervensi: Tujuan',
                prefixIcon: const Icon(Icons.flag),
                validator: (value) => null, // Opsional
              ),
              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _monevAsupanController,
                label: 'Monitoring: Asupan',
                prefixIcon: const Icon(Icons.monitor),
                validator: (value) => null, // Opsional
              ),

              const SizedBox(height: 16),
              _buildTextFormField(
                controller: _namaNutrisionisController,
                label: 'Nama Nutrisionis',
                prefixIcon: const Icon(Icons.person),
                validator: (value) => null, // Opsional
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
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return '$label tidak boleh kosong';
            }
            if (keyboardType == TextInputType.number &&
                double.tryParse(value) == null) {
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
