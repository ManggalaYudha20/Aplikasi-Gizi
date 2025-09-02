import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';

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
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(title: 'IMT', subtitle: 'Indeks Massa Tubuh'),
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
                  'Data Input IMT',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Berat Badan
                TextFormField(
                  controller: _weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Berat Badan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                    suffixText: 'kg',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Berat badan tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tinggi Badan
                TextFormField(
                  controller: _heightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tinggi Badan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                    suffixText: 'cm',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Tinggi badan tidak boleh kosong';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Buttons
                FormActionButtons(onReset: _resetForm, onSubmit: _calculateBMI),

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
                      color: _resultColor!.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _resultColor!,
                      ),
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
                      ).withOpacity(0.1),
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
                        const SizedBox(height: 8),
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
    );
  }
}
