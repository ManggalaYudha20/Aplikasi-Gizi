// lib\src\features\patient_home\presentation\pages\data_form_anak_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/login/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/patient_home/data/models/patient_anak_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/scaffold_with_animated_fab.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_validator_utils.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_calculation_helper.dart';
import 'dart:async';

class DataFormAnakPage extends StatefulWidget {
  final PatientAnak? patient;

  const DataFormAnakPage({super.key, this.patient});

  @override
  State<DataFormAnakPage> createState() => _DataFormAnakPageState();
}

class _DataFormAnakPageState extends State<DataFormAnakPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final List<FocusNode> _focusNodes = [];

  final _noRMController = TextEditingController();
  final _namaLengkapController = TextEditingController();
  final _tanggalLahirController = TextEditingController();
  final _jenisKelaminController = TextEditingController();
  final _beratBadanController = TextEditingController();
  final _tinggiBadanController = TextEditingController();
  final _namaNutrisionisController = TextEditingController();
  final _diagnosisMedisController = TextEditingController();
  final _kehilanganBeratBadanController = TextEditingController();
  final _kehilanganNafsuMakanController = TextEditingController();
  final _anakSakitBeratController = TextEditingController();

  DateTime? _selectedDate;

  final Map<String, int> _bbLossMap = {'Tidak': 0, 'Ya': 2};
  final Map<String, int> _appetiteMap = {
    'Makan seperti biasa': 0,
    'Ada penurunan': 1,
    'Tidak makan sama sekali/sedikit': 2,
  };
  final Map<String, int> _sickMap = {'Tidak': 0, 'Ya': 2};

  @override
  void initState() {
    super.initState();
    final controllers = [
      _noRMController,
      _namaLengkapController,
      _tanggalLahirController,
      _jenisKelaminController,
      _beratBadanController,
      _tinggiBadanController,
      _namaNutrisionisController,
      _diagnosisMedisController,
      _kehilanganBeratBadanController,
      _kehilanganNafsuMakanController,
      _anakSakitBeratController,
    ];

    // Buat FocusNode untuk setiap controller
    for (int i = 0; i < controllers.length; i++) {
      _focusNodes.add(FocusNode());
    }

    if (widget.patient != null) {
      _initializeForm(widget.patient!);
    }
  }

  void _initializeForm(PatientAnak patient) {
    _noRMController.text = patient.noRM;
    _namaLengkapController.text = patient.namaLengkap;
    _tanggalLahirController.text = patient.tanggalLahirFormatted;
    _selectedDate = patient.tanggalLahir;
    _jenisKelaminController.text = patient.jenisKelamin;
    _beratBadanController.text = patient.beratBadan.toString();
    _tinggiBadanController.text = patient.tinggiBadan.toString();
    _namaNutrisionisController.text = patient.namaNutrisionis ?? '';
    _diagnosisMedisController.text = patient.diagnosisMedis;
    _kehilanganBeratBadanController.text =
        _getKeyFromValue(_bbLossMap, patient.kehilanganBeratBadan) ?? '';
    _kehilanganNafsuMakanController.text =
        _getKeyFromValue(_appetiteMap, patient.kehilanganNafsuMakan) ?? '';
    _anakSakitBeratController.text =
        _getKeyFromValue(_sickMap, patient.anakSakitBerat) ?? '';
  }

  String? _getKeyFromValue(Map<String, int> map, int? value) {
    if (value == null) return null;
    for (var entry in map.entries) {
      if (entry.value == value) return entry.key;
    }
    return null;
  }

  @override
  void dispose() {
    _noRMController.dispose();
    _namaLengkapController.dispose();
    _tanggalLahirController.dispose();
    _beratBadanController.dispose();
    _tinggiBadanController.dispose();
    _namaNutrisionisController.dispose();
    _jenisKelaminController.dispose();
    _diagnosisMedisController.dispose();
    _kehilanganBeratBadanController.dispose();
    _kehilanganNafsuMakanController.dispose();
    _anakSakitBeratController.dispose();
    // Dispose semua FocusNode
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _noRMController.clear();
      _namaLengkapController.clear();
      _tanggalLahirController.clear();
      _beratBadanController.clear();
      _tinggiBadanController.clear();
      _jenisKelaminController.clear();
      _selectedDate = null;
      _namaNutrisionisController.clear();
      _diagnosisMedisController.clear();
      _kehilanganBeratBadanController.clear();
      _kehilanganNafsuMakanController.clear();
      _anakSakitBeratController.clear();
    });
  }

  // (Pastikan untuk dispose semua controller di @override dispose)

  Future<void> _savePatientAnakData() async {
    if (FormValidatorUtils.validateAndScroll(
      context: context,
      formKey: _formKey,
      focusNodes: _focusNodes,
    )) {
      setState(() => _isLoading = true);

      final User? currentUser = _authService.getCurrentUser();
      if (currentUser == null) {
        // Handle error: user not logged in
        setState(() => _isLoading = false);
        return;
      }

      try {
        final beratBadan = double.parse(_beratBadanController.text);
        final tinggiBadan = double.parse(_tinggiBadanController.text);

        final calculationResult = NutritionCalculationHelper.calculateAll(
          birthDate: _selectedDate!,
          checkDate: DateTime.now(),
          weight: beratBadan,
          height: tinggiBadan,
          gender: _jenisKelaminController.text,
        );

        // Ambil hasil kalkulasi
        final resultBBU = calculationResult['bbPerU'];
        final resultTBU = calculationResult['tbPerU'];
        final resultBBTB = calculationResult['bbPerTB'];
        final resultIMTU = calculationResult['imtPerU'];


        final patientAnakData = {
          'noRM': _noRMController.text,
          'namaLengkap': _namaLengkapController.text,
          'tanggalLahir': Timestamp.fromDate(_selectedDate!),
          'jenisKelamin': _jenisKelaminController.text,
          'beratBadan': beratBadan,
          'tinggiBadan': tinggiBadan,
          'namaNutrisionis': _namaNutrisionisController.text,
          'tanggalPemeriksaan': Timestamp.now(),
          'createdBy': currentUser.uid,
          'tipePasien': 'anak',
          'diagnosisMedis': _diagnosisMedisController.text,
          'kehilanganBeratBadan':
              _bbLossMap[_kehilanganBeratBadanController.text] ?? 0,
          'kehilanganNafsuMakan':
              _appetiteMap[_kehilanganNafsuMakanController.text] ?? 0,
          'anakSakitBerat': _sickMap[_anakSakitBeratController.text] ?? 0,
          'zScoreBB': resultBBU['zScore'], // BB/U
          'statusGiziAnak':
              resultBBU['category'], // Simpan kategori BB/U di field lama ini atau buat baru

          'zScoreTB': resultTBU['zScore'], // TB/U (Stunting check)
          'zScoreBBTB': resultBBTB['zScore'], // BB/TB (Gizi Buruk/Baik check)
          'statusGiziBBTB': resultBBTB['category'],

          'zScoreIMTU': resultIMTU['zScore'], // IMT/U
          'statusGiziIMTU': resultIMTU['category'],
        };

        try {
          // Batas waktu tunggu 3 detik
          const timeoutDuration = Duration(seconds: 3);

          if (widget.patient != null) {
            // Update dengan Timeout
            await FirebaseFirestore.instance
                .collection('patients')
                .doc(widget.patient!.id)
                .update(patientAnakData)
                .timeout(timeoutDuration);
          } else {
            // Create dengan Timeout
            await FirebaseFirestore.instance
                .collection('patients')
                .add(patientAnakData)
                .timeout(timeoutDuration);
          }

          // Jika berhasil online (tidak timeout)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(widget.patient != null
                    ? 'Data pasien anak berhasil diperbarui!'
                    : 'Data pasien anak berhasil disimpan!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } on TimeoutException catch (_) {
          // Jika koneksi lambat/mati, masuk ke sini
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'Mode Offline: Data disimpan lokal dan akan diupload saat ada internet.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }

        final updatedPatientObj = PatientAnak(
          id: widget.patient?.id ?? '', // Gunakan ID lama jika edit
          noRM: _noRMController.text,
          namaLengkap: _namaLengkapController.text,
          tanggalLahir: _selectedDate!,
          jenisKelamin: _jenisKelaminController.text,
          beratBadan: beratBadan,
          tinggiBadan: tinggiBadan,
          tanggalPemeriksaan: widget.patient?.tanggalPemeriksaan ?? DateTime.now(), // Pertahankan tgl asli atau baru
          createdBy: widget.patient?.createdBy ?? currentUser.uid,
          diagnosisMedis: _diagnosisMedisController.text,
          tipePasien: 'anak',
          zScoreBB: resultBBU['zScore'], // BB/U
          statusGiziAnak :
              resultBBU['category'], // Simpan kategori BB/U di field lama ini atau buat baru

          zScoreTB : resultTBU['zScore'], // TB/U (Stunting check)
          zScoreBBTB : resultBBTB['zScore'], // BB/TB (Gizi Buruk/Baik check)
          statusGiziBBTB : resultBBTB['category'],

          zScoreIMTU : resultIMTU['zScore'], // IMT/U
          statusGiziIMTU : resultIMTU['category'],
          
          namaNutrisionis: _namaNutrisionisController.text,
          kehilanganBeratBadan: _bbLossMap[_kehilanganBeratBadanController.text],
          kehilanganNafsuMakan: _appetiteMap[_kehilanganNafsuMakanController.text],
          anakSakitBerat: _sickMap[_anakSakitBeratController.text],
        );

        if (mounted) {
          Navigator.of(context).pop(updatedPatientObj);
        }
      } catch (e) {
        // Catch error selain timeout (misal permission error)
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
      firstDate: DateTime(DateTime.now().year - 18), // Maks 5 tahun lalu
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalLahirController.text = DateFormat(
          'd MMMM y',
          'id_ID',
        ).format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithAnimatedFab(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: widget.patient != null ? 'Edit Data Anak' : 'Tambah Pasien Anak',
        subtitle: 'Isi data dengan lengkap',
      ),
      floatingActionButton: FormActionButtons(
        onReset: _resetForm,
        onSubmit: _savePatientAnakData,
        resetButtonColor: Colors.white, // Background jadi putih
        resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
        submitIcon: widget.patient != null
            ? const Icon(Icons.save, color: Colors.white)
            : const Icon(Icons.add, color: Colors.white),
        submitText: widget.patient != null ? 'Simpan' : 'Tambah',
        isLoading: _isLoading,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Input Data Pasien Anak',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    controller: _noRMController,
                    label: 'No. Rekam Medis (RM)',
                    focusNode: _focusNodes[0],
                    prefixIcon: const Icon(Icons.medical_information),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _namaLengkapController,
                    label: 'Nama Lengkap',
                    focusNode: _focusNodes[1],
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _tanggalLahirController,
                    label: 'Tanggal Lahir',
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    focusNode: _focusNodes[2],
                    prefixIcon: const Icon(Icons.calendar_today),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildCustomDropdown(
                    controller: _jenisKelaminController,
                    label: 'Jenis Kelamin',
                    items: ['Laki-laki', 'Perempuan'],
                    prefixIcon: const Icon(Icons.wc),
                    focusNode: _focusNodes[3],
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Harus dipilih'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _diagnosisMedisController,
                    label: 'Diagnosis Medis',
                    prefixIcon: const Icon(Icons.sick),
                    focusNode: _focusNodes[4],
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _beratBadanController,
                    label: 'Berat Badan',
                    focusNode: _focusNodes[5],
                    prefixIcon: const Icon(Icons.monitor_weight),
                    suffixText: 'kg',
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextFormField(
                    controller: _tinggiBadanController,
                    label: 'Panjang/Tinggi Badan',
                    focusNode: _focusNodes[6],
                    prefixIcon: const Icon(Icons.height),
                    suffixText: 'cm',
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  _buildCustomDropdown(
                    controller: _kehilanganBeratBadanController,
                    label: 'Penurunan berat badan akhir-akhir ini?',
                    prefixIcon: const Icon(Icons.trending_down),
                    items: ['Ya', 'Tidak'],
                    focusNode: _focusNodes[7],
                  ),
                  const SizedBox(height: 16),

                  _buildCustomDropdown(
                    controller: _kehilanganNafsuMakanController,
                    label: 'Ada asupan makan dalam satu minggu terakhir?',
                    prefixIcon: const Icon(Icons.restaurant),
                    items: [
                      'Makan seperti biasa',
                      'Ada penurunan',
                      'Tidak makan sama sekali atau sangat sedikit',
                    ],
                    focusNode: _focusNodes[8],
                  ),
                  const SizedBox(height: 16),

                  _buildCustomDropdown(
                    controller: _anakSakitBeratController,
                    label: 'Anak sakit berat?',
                    prefixIcon: const Icon(Icons.local_hospital),
                    items: ['Ya', 'Tidak'],
                    focusNode: _focusNodes[9],
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _namaNutrisionisController,
                    label: 'Nama Nutrisionis',
                    focusNode: _focusNodes[10],
                    prefixIcon: const Icon(Icons.person),
                    validator: (value) => null,
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Input Data Asuhan Gizi (Opsional)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required FocusNode focusNode,
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
      focusNode: focusNode,
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

  Widget _buildCustomDropdown({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required Icon prefixIcon,
    required FocusNode focusNode,
    //bool showSearch = false,
    void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
        constraints: const BoxConstraints(maxHeight: 240),
      ),
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged:
          onChanged ??
          (String? newValue) {
            setState(() {
              controller.text = newValue ?? '';
            });
          },
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator:
          validator ??
          (value) =>
              (value == null || value.isEmpty) ? '$label harus dipilih' : null,
    );
  }
}
