//lib\src\features\nutrition_calculation\presentation\pages\bmi_form_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

class BmiFormPage extends StatefulWidget {
  const BmiFormPage({super.key});

  @override
  State<BmiFormPage> createState() => _BmiFormPageState();
}

class _BmiFormPageState extends State<BmiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();

  double? _bmiResult;
  String? _bmiCategory;
  Color? _resultColor;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _scrollController.dispose();
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

  void _calculateBMI() {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text);
      final height =
          double.parse(_heightController.text) / 100; // Convert cm to m

      final bmi = weight / (height * height);

      String category;
      if (bmi < 18.5) {
        category = 'Kurus';
        _resultColor = Colors.red;
      } else if (bmi >= 18.5 && bmi < 25) {
        category = 'Normal';
        _resultColor = Color.fromARGB(255, 0, 148, 68);
      } else if (bmi >= 25 && bmi < 30) {
        category = 'Gemuk';
        _resultColor = Colors.orange;
      } else {
        category = 'Obesitas';
        _resultColor = Colors.red;
      }

      setState(() {
        _bmiResult = bmi;
        _bmiCategory = category;
        _resultColor = _resultColor;
      });
      _scrollToResult();
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _bmiResult = null;
      _bmiCategory = null;
      _resultColor = null;
      _patientPickerKey.currentState?.resetSelection();
    });
  }

  void _fillDataFromPatient(double weight, double height, String gender, DateTime dob) {
    setState(() {
      _weightController.text = weight.toString();
      _heightController.text = height.toString();
      // Jika nanti ada field Umur atau Gender di form ini, bisa diisi juga disini
      
      // Reset hasil perhitungan sebelumnya agar user menekan tombol hitung ulang
      _bmiResult = null;
      _bmiCategory = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(title: 'IMT', subtitle: 'Indeks Massa Tubuh'),
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
                PatientPickerWidget(
                    key: _patientPickerKey,
                    onPatientSelected: _fillDataFromPatient,
                  ),
                  
                  const SizedBox(height: 10), // Sedikit jarak
                  const Divider(),
                  
                const SizedBox(height: 20),
                const Text(
                  'Input Data IMT',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

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
                const SizedBox(height: 32),

                // Buttons
                FormActionButtons(
                  onReset: _resetForm,
                  onSubmit: _calculateBMI,
                  resetButtonColor: Colors.white, // Background jadi putih
                  resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                  submitIcon: const Icon(Icons.calculate, color: Colors.white),
                ),

                const SizedBox(height: 32),

                // Result
                if (_bmiResult != null) ...[
                  Container(
                    key: _resultCardKey,
                    child: const Column(
                      children: [Divider(), SizedBox(height: 32)],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _resultColor!.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _resultColor!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Hasil Perhitungan IMT',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _resultColor!,
                          ),
                        ),
                        const SizedBox(height: 8),

                        Text(
                          '${_bmiResult!.toStringAsFixed(2)} kg/m²',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _resultColor!,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Kategori: $_bmiCategory',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _resultColor!,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Indeks Massa Tubuh (IMT) adalah ukuran untuk mengevaluasi berat badan ideal berdasarkan tinggi badan.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        174,
                        174,
                        174,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color.fromARGB(255, 0, 0, 0),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Kategori Indeks Massa Tubuh\nMenurut WHO',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const Divider(height: 8),
                        const SizedBox(height: 15),
                        Text(
                          'Berat Badan Kurang (Underweight): < 18,5\n'
                          'Kurus Parah (Severe thinness): < 16,0\n'
                          'Kurus Sedang (Moderate thinness) 16,0 - 16,9\n'
                          'Kurus Ringan (Mild thinness): 17,0 - 18,4\n\n'
                          'Berat Badan Normal (Normal range): 18,5 - 24,9 \n\n'
                          'Berat Badan Berlebih (Overweight): ≥ 25,0\n\n'
                          'Pre-obesitas (Pre-obese) 25,0 - 29,9\n'
                          'Obesitas (Obese): ≥ 30,0\n'
                          'Obesitas Kelas I :30,0 - 34,9\n'
                          'Obesitas Kelas II: 35,0 - 39,9\n'
                          'Obesitas Kelas III: (Ekstrem): ≥ 40,0',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.normal,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'sumber menurut WHO',
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

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    int maxLength = 5,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // Batasi panjang karakter agar tidak overflow/error database
        LengthLimitingTextInputFormatter(maxLength),
        // Opsional: Filter agar hanya angka dan titik (untuk desimal) yang bisa diketik
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
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
