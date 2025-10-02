import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';

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

  String? _selectedGender;
  double? _bmrResult;
  String _selectedFormula = 'Mifflin-St Jeor';

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
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

  void _calculateBMR() {
    if (_formKey.currentState!.validate()) {
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      final age = int.parse(_ageController.text);
      
      double bmr;
      
      // Logika perhitungan diperbarui untuk mendukung dua formula
      if (_selectedFormula == 'Harris-Benedict') {
        // Menggunakan formula Harris-Benedict (seperti kode awal Anda)
        if (_selectedGender == 'Laki-laki') {
          // Formula untuk laki-laki: 66.47 + (13.75 × BB) + (5.003 × TB) − (6.755 × U)
          bmr = 66.47 + (13.75 * weight) + (5.003 * height) - (6.755 * age);
        } else {
          // Formula untuk perempuan: 655.1 + (9.563 × BB) + (1.850 × TB) − (4.676 × U)
          bmr = 655.1 + (9.563 * weight) + (1.850 * height) - (4.676 * age);
        }
      } else { 
        // Menggunakan formula Mifflin-St Jeor
        // Formula: (9.99 x BB) + (6.25 x TB) - (4.92 x U) +/- Konstanta
        if (_selectedGender == 'Laki-laki') {
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
      _selectedGender = null;
      _bmrResult = null;
      _selectedFormula = 'Mifflin-St Jeor';
    });
  }

  // Widget untuk menampilkan informasi formula yang dipilih
  Widget _buildFormulaInfo() {
    String formulaName = _selectedFormula;
    String description;
    
    if (formulaName == 'Harris-Benedict') {
      description = 'Menggunakan rumus Harris-Benedict (1919).';
    } else {
      description = 'Menggunakan rumus Mifflin-St Jeor (dianggap lebih akurat untuk populasi modern).';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Text(
        '$formulaName dipilih. $description',
        style: const TextStyle(fontSize: 12, color: Colors.black54),
      ),
    );
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
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                // Pilihan Formula BMR (Widget baru)
                DropdownButtonFormField<String>(
                  value: _selectedFormula,
                  decoration: const InputDecoration(
                    labelText: 'Pilih Formula BMR',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calculate),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Mifflin-St Jeor',
                      child: Text('Mifflin-St Jeor'),
                    ),
                    DropdownMenuItem(
                      value: 'Harris-Benedict',
                      child: Text('Harris-Benedict'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedFormula = value!;
                      _bmrResult = null; // Reset hasil saat formula berubah
                    });
                  },
                ),
                _buildFormulaInfo(), // Menampilkan keterangan formula
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
                
                // Jenis Kelamin
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Jenis Kelamin',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Laki-laki',
                      child: Text('Laki-laki'),
                    ),
                    DropdownMenuItem(
                      value: 'Perempuan',
                      child: Text('Perempuan'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih jenis kelamin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Umur
                TextFormField(
                  controller: _ageController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Umur',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixText: 'tahun',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Umur tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Buttons
                FormActionButtons(onReset: _resetForm, onSubmit: _calculateBMR),

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
                      color: const Color.fromARGB(255, 0, 148, 68).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color.fromARGB(255, 0, 148, 68)),
                    ),
                    child: Column(
                      children: [
                         Text(
                          'Hasil Perhitungan BMR \n($_selectedFormula)',
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
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
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