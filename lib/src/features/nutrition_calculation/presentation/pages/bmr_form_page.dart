//lib\src\features\nutrition_calculation\presentation\pages\bmr_form_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';

class BmrFormPage extends StatefulWidget {
  const BmrFormPage({super.key});

  @override
  State<BmrFormPage> createState() => _BmrFormPageState();
}

class _BmrFormPageState extends State<BmrFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();
  double? _bmrResult;
  final _genderController = TextEditingController();
  final _formulaController = TextEditingController(text: 'Mifflin-St Jeor');

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _scrollController.dispose();
    _genderController.dispose(); // Tambahkan
    _formulaController.dispose();
    super.dispose();
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultCardKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultCardKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _calculateBMR() {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      final age = int.parse(_ageController.text);

      double bmr;

      // Logika perhitungan diperbarui untuk mendukung dua formula
      if (_formulaController.text == 'Harris-Benedict') {
        // Menggunakan formula Harris-Benedict (seperti kode awal Anda)
        if (_genderController.text == 'Laki-laki') {
          // Formula untuk laki-laki: 66.47 + (13.75 × BB) + (5.003 × TB) − (6.755 × U)
          bmr = 66.47 + (13.75 * weight) + (5.003 * height) - (6.755 * age);
        } else {
          // Formula untuk perempuan: 655.1 + (9.563 × BB) + (1.850 × TB) − (4.676 × U)
          bmr = 655.1 + (9.563 * weight) + (1.850 * height) - (4.676 * age);
        }
      } else {
        // Menggunakan formula Mifflin-St Jeor
        // Formula: (9.99 x BB) + (6.25 x TB) - (4.92 x U) +/- Konstanta
        if (_genderController.text == 'Laki-laki') {
          // Pria: (9.99 x BB) + (6.25 x TB) - (4.92 x U) + 5
          bmr = (9.99 * weight) + (6.25 * height) - (4.92 * age) + 5;
        } else {
          // Wanita: (9.99 x BB) + (6.25 x TB) - (4.92 x U) - 161
          bmr = (9.99 * weight) + (6.25 * height) - (4.92 * age) - 161;
        }
      }

      setState(() {
        _bmrResult = bmr;
      });
      _scrollToResult();
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _ageController.clear();
      _genderController.clear();
      _bmrResult = null;
      _formulaController.text = 'Mifflin-St Jeor';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'BMR',
        subtitle: 'Basal Metabolic Rate',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Input Data BMR',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Pilihan Formula BMR 
                _buildCustomDropdown(
                  controller: _formulaController,
                  label: 'Pilih Formula BMR',
                  prefixIcon: const Icon(Icons.calculate),
                  items: const ['Mifflin-St Jeor', 'Harris-Benedict'],
                ),
                _buildFormulaInfo(), // Menampilkan keterangan formula
                const SizedBox(height: 16),

                // Berat Badan
                _buildTextFormField(
                  controller: _weightController,
                  label: 'Berat Badan',
                  prefixIcon: const Icon(Icons.monitor_weight),
                  suffixText: 'kg',
                ),
                const SizedBox(height: 16),

                // Tinggi Badan
                _buildTextFormField(
                  controller: _heightController,
                  label: 'Tinggi Badan',
                  prefixIcon: const Icon(Icons.height),
                  suffixText: 'cm',
                ),
                const SizedBox(height: 16),

                // Jenis Kelamin
                _buildCustomDropdown(
                  controller: _genderController,
                  label: 'Jenis Kelamin',
                  prefixIcon: const Icon(Icons.wc),
                  items: const ['Laki-laki', 'Perempuan'],
                ),
                const SizedBox(height: 16),

                // Umur
                _buildTextFormField(
                  controller: _ageController,
                  label: 'Umur',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixText: 'tahun',
                ),
                const SizedBox(height: 32),

                // Buttons
                FormActionButtons(
                  onReset: _resetForm,
                  onSubmit: _calculateBMR,
                  resetButtonColor: Colors.white, // Background jadi putih
                  resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                  submitIcon: const Icon(Icons.calculate, color: Colors.white),
                ),
                const SizedBox(height: 32),

                // Result
                if (_bmrResult != null) ...[
                  Container(
                    key: _resultCardKey,
                    child: const Column(
                      children: [Divider(), SizedBox(height: 32)],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        0,
                        148,
                        68,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color.fromARGB(255, 0, 148, 68),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Hasil Perhitungan BMR \n(${_formulaController.text})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_bmrResult!.toStringAsFixed(2)} kkal/hari',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Basal Metabolic Rate (BMR) adalah jumlah kalori yang dibutuhkan tubuh untuk fungsi dasar saat istirahat.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }

  // Tambahkan metode ini di dalam class _BmrFormPageState
  Widget _buildCustomDropdown({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required Icon prefixIcon,
    String? Function(String?)? validator,
  }) {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Tidak ada pencarian untuk form ini
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
      onChanged: (String? newValue) {
        setState(() {
          controller.text = newValue ?? '';
          // Reset hasil BMR jika nilai dropdown berubah
          if (label == 'Pilih Formula BMR' || label == 'Jenis Kelamin') {
            _bmrResult = null;
          }
        });
      },
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator:
          validator ??
          (value) {
            if (value == null || value.isEmpty) {
              return '$label harus dipilih';
            }
            return null;
          },
    );
  }

  // Widget untuk menampilkan informasi formula yang dipilih
  Widget _buildFormulaInfo() {
    String formulaName = _formulaController.text;
    String description;

    if (formulaName == 'Harris-Benedict') {
      description = 'Menggunakan rumus Harris-Benedict (1919).';
    } else {
      description =
          'Menggunakan rumus Mifflin-St Jeor (dianggap lebih akurat untuk populasi modern).';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        '$formulaName dipilih. $description',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
  }

  // Tambahkan metode ini di dalam class _BmrFormPageState
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        if (double.tryParse(value) == null) {
          return 'Masukkan angka yang valid';
        }
        return null;
      },
    );
  }
}
