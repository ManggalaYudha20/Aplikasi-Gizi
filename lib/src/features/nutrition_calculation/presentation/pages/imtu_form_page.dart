//lib\src\features\nutrition_calculation\presentation\pages\imtu_form_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';

class IMTUFormPage extends StatefulWidget {
  const IMTUFormPage({super.key});

  @override
  State<IMTUFormPage> createState() => _IMTUFormPageState();
}

class _IMTUFormPageState extends State<IMTUFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageYearsController = TextEditingController();
  final _ageMonthsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();
  final _genderController = TextEditingController();
  Map<String, dynamic>? _calculationResult;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageYearsController.dispose();
    _ageMonthsController.dispose();
    _scrollController.dispose();
    _genderController.dispose();
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

  void _calculateIMTU() {
    if (_formKey.currentState!.validate()) {
      setState(() {});

      final weight = double.tryParse(_weightController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0;
      final ageYears = int.tryParse(_ageYearsController.text) ?? 0;
      final ageMonths = int.tryParse(_ageMonthsController.text) ?? 0;
      final gender = _genderController.text;

      if (gender.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jenis kelamin terlebih dahulu')),
        );
        setState(() {});
        return;
      }

      // Validate age range (5-18 years)
      final totalMonths = (ageYears * 12) + ageMonths;
      if (totalMonths < 60 || totalMonths > 216) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usia harus antara 5-18 tahun')),
        );
        setState(() {});
        return;
      }

      // Calculate BMI
      final bmi = weight / ((height / 100) * (height / 100));

      // Calculate IMT/U z-score
      final result = _calculateIMTUZScore(
        ageYears: ageYears,
        ageMonths: ageMonths,
        bmi: bmi,
        gender: gender,
      );

      setState(() {
        _calculationResult = result;
      });
      _scrollToResult();
    }
  }

  Map<String, dynamic> _calculateIMTUZScore({
    required int ageYears,
    required int ageMonths,
    required double bmi,
    required String gender,
  }) {
    try {
      final ageKey = '$ageYears-$ageMonths';
      final percentiles = gender == 'Laki-laki'
          ? NutritionStatusData.imtUBoys5To18[ageKey]
          : NutritionStatusData.imtUGirls5To18[ageKey];

      if (percentiles == null) {
        return {
          'zScore': null,
          'category': 'Data referensi tidak tersedia untuk usia ini',
          'bmi': bmi,
          'ageKey': ageKey,
        };
      }

      final median = percentiles[3];
      final sd = percentiles[4] - median;
      final zScore = (bmi - median) / sd;

      return {
        'zScore': zScore,
        'category': _getIMTUCategory(zScore),
        'bmi': bmi,
        'ageKey': ageKey,
      };
    } catch (e) {
      return {
        'zScore': null,
        'category': 'Error dalam perhitungan',
        'bmi': bmi,
        'ageKey': '$ageYears-$ageMonths',
      };
    }
  }

  String _getIMTUCategory(double zScore) {
    if (zScore < -3) return 'Gizi buruk (severely wasted)';
    if (zScore < -2) return 'Gizi kurang (wasted)';
    if (zScore <= 1) return 'Gizi baik (normal)';
    if (zScore <= 2) return 'Gizi lebih (overweight)';
    return 'Obesitas (obese)';
  }

  Color _getIMTUColor(String category) {
    if (category.contains('gizi buruk') ||
        category.contains('severely wasted')) {
      return Colors.red;
    } else if (category.contains('gizi kurang') ||
        category.contains('wasted')) {
      return Colors.orange;
    } else if (category.contains('gizi baik') || category.contains('normal')) {
      return const Color.fromARGB(255, 0, 148, 68);
    } else {
      return Colors.red;
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _weightController.clear();
    _heightController.clear();
    _ageYearsController.clear();
    _ageMonthsController.clear();
    _genderController.clear();
    setState(() {
      _calculationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(title: 'IMT/U', subtitle: 'Usia 5-18 Tahun'),
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
                  'Input Data IMT/U  5-18 Tahun',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                // Age Input
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextFormField(
                        controller: _ageYearsController,
                        label: 'Tahun',
                        prefixIcon: const Icon(Icons.calendar_today),
                        suffixText: 'tahun',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Masukkan tahun';
                          final years = int.tryParse(value);
                          if (years == null || years < 5 || years > 18) return '5-18 tahun';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextFormField(
                        controller: _ageMonthsController,
                        label: 'Bulan',
                        suffixText: 'bulan',
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Masukkan bulan';
                          final months = int.tryParse(value);
                          if (months == null || months < 0 || months > 11) return '0-11 bulan';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gender Selection
                _buildCustomDropdown(
                  controller: _genderController,
                  label: 'Jenis Kelamin',
                  prefixIcon: const Icon(Icons.wc),
                  items: ['Laki-laki', 'Perempuan'],
                ),
                const SizedBox(height: 16),

                // Weight Input
                _buildTextFormField(
                  controller: _weightController,
                  label: 'Berat Badan',
                  prefixIcon: const Icon(Icons.monitor_weight),
                  suffixText: 'kg',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Masukkan berat badan';
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) return 'Masukkan berat yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Height Input
                _buildTextFormField(
                  controller: _heightController,
                  label: 'Tinggi Badan',
                  prefixIcon: const Icon(Icons.height),
                  suffixText: 'cm',
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Masukkan tinggi badan';
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) return 'Masukkan tinggi yang valid';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Buttons
                FormActionButtons(
                  onReset: _resetForm,
                  onSubmit: _calculateIMTU,
                  resetButtonColor: Colors.white, // Background jadi putih
                  resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                  submitIcon: const Icon(Icons.calculate, color: Colors.white),
                ),

                const SizedBox(height: 32),

                // Results
                if (_calculationResult != null) ...[
                  Container(
                    key: _resultCardKey,
                    child: const Column(
                      children: [Divider(), SizedBox(height: 32)],
                    ),
                  ),

                  const Text(
                    'Hasil IMT Berdasarkan Usia 5-18 Tahun',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  // IMT/U Result
                  _buildResultCard(
                    title: 'Indeks Massa Tubuh menurut Umur (IMT/U)',
                    data: _calculationResult!,
                    additionalInfo:
                        'IMT: ${_calculationResult!['bmi']?.toStringAsFixed(2) ?? '-'} kg/m²',
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

  Widget _buildResultCard({
    required String title,
    required Map<String, dynamic> data,
    String? additionalInfo,
  }) {
    // Determine color based on category
    Color resultColor = _getIMTUColor(data['category'] ?? '');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: resultColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: resultColor, width: 2.0),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 12),
          if (additionalInfo != null) ...[
            Text(
              additionalInfo,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              const Text(
                'Z-Score: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              Text(
                data['zScore']?.toStringAsFixed(2) ?? '-',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Kategori: ',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
              ),
              Expanded(
                child: Text(
                  data['category'] ?? '-',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: resultColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 1. Widget untuk Input Teks
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String suffixText,
    Icon? prefixIcon,
    required String? Function(String?) validator,
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
      validator: validator,
    );
  }

  // 2. Widget untuk Dropdown
  Widget _buildCustomDropdown({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required Icon prefixIcon,
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
        });
      },
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (value) =>
          (value == null || value.isEmpty) ? '$label harus dipilih' : null,
    );
  }
}
