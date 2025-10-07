import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';

class TdeeFormPage extends StatefulWidget {
  const TdeeFormPage({super.key});

  @override
  State<TdeeFormPage> createState() => _TdeeFormPageState();
}

class _TdeeFormPageState extends State<TdeeFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _temperatureController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();
  final _genderController = TextEditingController();
  final _activityFactorController = TextEditingController();
  final _stressFactorController = TextEditingController();
  double? _calculatedTdee;
  double? _calculatedBmr;

  // Activity factors
  final Map<String, double> activityFactors = {
    'Sangat Jarang': 1.2,
    'Aktivitas Ringan': 1.375,
    'Aktivitas Sedang': 1.55,
    'Aktivitas Berat': 1.725,
    'Sangat Aktif': 1.9,
  };

  // Stress factors
  final Map<String, double> stressFactors = {
    'Normal': 1.0,
    'Demam (per 1°C)': 0.13,
    'Peritonitis': 1.35,
    'Cedera Jaringan Lunak Ringan': 1.14,
    'Cedera Jaringan Lunak Berat': 1.37,
    'Patah Tulang Multiple Ringan': 1.2,
    'Patah Tulang Multiple Berat': 1.35,
    'Sepsis Ringan': 1.4,
    'Sepsis Berat': 1.8,
    'Luka Bakar 0-20%': 1.25,
    'Luka Bakar 20-40%': 1.675,
    'Luka Bakar 40-100%': 1.95,
    'Puasa': 0.7,
    'Payah Gagal Jantung Ringan': 1.3,
    'Payah Gagal Jantung Berat': 1.5,
    'Kanker': 1.3,
  };

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _temperatureController.dispose();
    _scrollController.dispose();
    _genderController.dispose();
    _activityFactorController.dispose();
    _stressFactorController.dispose();
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

  double calculateBMR() {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final age = int.tryParse(_ageController.text) ?? 0;

    if (_genderController.text.isEmpty ||
        weight <= 0 ||
        height <= 0 ||
        age <= 0) {
      return 0;
    }

    // Harris-Benedict equation
    if (_genderController.text == 'Laki-laki') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  void calculateTDEE() {
    if (_formKey.currentState!.validate()) {
      final bmr = calculateBMR();
      final activityFactor =
          activityFactors[_activityFactorController.text] ?? 1.0;

      double stressFactor = 1.0;

      if (_stressFactorController.text == 'Demam (per 1°C)') {
        final temperature = double.tryParse(_temperatureController.text) ?? 0;
        if (temperature > 37) {
          stressFactor = 1.0 + (0.13 * (temperature - 37));
        }
      } else {
        stressFactor = stressFactors[_stressFactorController.text] ?? 1.0;
      }

      final tdee = bmr * activityFactor * stressFactor;

      setState(() {
        _calculatedBmr = bmr;
        _calculatedTdee = tdee;
      });
      _scrollToResult();
    }
  }

  void resetForm() {
    _formKey.currentState?.reset();
    _weightController.clear();
    _heightController.clear();
    _ageController.clear();
    _temperatureController.clear();
    _genderController.clear();
    _activityFactorController.clear();
    _stressFactorController.clear();
    setState(() {
      _calculatedTdee = null;
      _calculatedBmr = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'TDEE',
        subtitle: 'Total Daily Energy Expenditure',
      ),
      body: SafeArea(
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
                  'Input Data TDEE',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                _buildTextFormField(
                  controller: _weightController,
                  label: 'Berat Badan',
                  prefixIcon: const Icon(Icons.monitor_weight),
                  suffixText: 'kg',
                ),
                const SizedBox(height: 16),

                _buildTextFormField(
                  controller: _heightController,
                  label: 'Tinggi Badan',
                  prefixIcon: const Icon(Icons.height),
                  suffixText: 'cm',
                ),
                const SizedBox(height: 16),

                _buildCustomDropdown(
                  controller: _genderController,
                  label: 'Jenis Kelamin',
                  prefixIcon: const Icon(Icons.wc),
                  items: ['Laki-laki', 'Perempuan'],
                ),
                const SizedBox(height: 16),

                _buildTextFormField(
                  controller: _ageController,
                  label: 'Usia',
                  prefixIcon: const Icon(Icons.calendar_today),
                  suffixText: 'tahun',
                ),
                const SizedBox(height: 16),

                _buildCustomDropdown(
                  controller: _activityFactorController,
                  label: 'Faktor Aktivitas',
                  prefixIcon: const Icon(Icons.directions_run),
                  items: activityFactors.keys.toList(),
                ),
                const SizedBox(height: 16),

                _buildCustomDropdown(
                  controller: _stressFactorController,
                  label: 'Faktor Stress',
                  prefixIcon: const Icon(Icons.healing),
                  items: stressFactors.keys.toList(),
                  onChanged: (value) {
                    setState(() {
                      _stressFactorController.text = value ?? '';
                      if (value != 'Demam (per 1°C)') {
                        _temperatureController.clear();
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Suhu Tubuh (muncul kondisional)
                if (_stressFactorController.text == 'Demam (per 1°C)')
                  _buildTextFormField(
                    controller: _temperatureController,
                    label: 'Suhu Tubuh',
                    prefixIcon: const Icon(Icons.thermostat),
                    suffixText: '°C',
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Suhu tidak boleh kosong';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                if (_stressFactorController.text == 'Demam (per 1°C)')
                  const SizedBox(height: 16),

                // Buttons
                FormActionButtons(
                  onReset: resetForm,
                  onSubmit: calculateTDEE,
                  resetButtonColor: Colors.white, // Background jadi putih
                  resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                  submitIcon: const Icon(Icons.calculate, color: Colors.white),
                ),

                const SizedBox(height: 32),

                // Results
                if (_calculatedTdee != null) ...[
                  Container(
                    key: _resultCardKey,
                    child: const Column(
                      children: [Divider(), SizedBox(height: 32)],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF009444)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Hasil Perhitungan TDEE',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'BMR: ${_calculatedBmr?.toStringAsFixed(2) ?? '0'} kkal/hari',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'TDEE: ${_calculatedTdee?.toStringAsFixed(2) ?? '0'} kkal/hari',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF009444),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'TDEE adalah perkiraan jumlah total kalori yang dibakar oleh tubuh dalam satu hari (24 jam).',
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
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    String? Function(String?)? validator,
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
      validator:
          validator ??
          (value) {
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

  Widget _buildCustomDropdown({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required Icon prefixIcon,
    bool showSearch = false,
    void Function(String?)? onChanged,
  }) {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: showSearch,
        constraints: const BoxConstraints(
          maxHeight: 240, // Batasi tinggi menu
        ),
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Cari...",
          ),
        ),
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
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label harus dipilih';
        }
        return null;
      },
    );
  }
}
