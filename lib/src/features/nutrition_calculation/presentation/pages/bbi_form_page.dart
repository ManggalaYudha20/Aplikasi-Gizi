import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';

class BbiFormPage extends StatefulWidget {
  const BbiFormPage({super.key});

  @override
  State<BbiFormPage> createState() => _BbiFormPageState();
}

class _BbiFormPageState extends State<BbiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();

  String? _selectedGender;
  double? _bbiResult;

  @override
  void dispose() {
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

  void _calculateBBI() {
    if (_formKey.currentState!.validate()) {
      final height = double.parse(_heightController.text);
      
      double bbi;
      
      if (_selectedGender == 'Laki-laki') {
        // Formula untuk laki-laki: [tinggi badan (cm) - 100] - [(tinggi badan (cm) - 100) × 10%]
        bbi = (height - 100) - ((height - 100) * 0.10);
      } else {
        // Formula untuk perempuan: [tinggi badan (cm) - 100] - [(tinggi badan (cm) - 100) × 15%]
        bbi = (height - 100) - ((height - 100) * 0.15);
      }
      
      setState(() {
        _bbiResult = bbi;
      });
      _scrollToResult();
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _heightController.clear();
      _selectedGender = null;
      _bbiResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'BBI',
        subtitle: 'Berat Badan Ideal',
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
                  'Input Data BBI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
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
                const SizedBox(height: 32),
                
                // Buttons
                FormActionButtons(onReset: _resetForm, onSubmit: _calculateBBI),
                const SizedBox(height: 32),
                
                // Result
                if (_bbiResult != null) ...[

                  Container(
                    key: _resultCardKey, 
                    child: const Column(
                      children: [Divider(), SizedBox(height: 32)],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 148, 68).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color.fromARGB(255, 0, 148, 68)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Hasil Perhitungan BBI',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_bbiResult!.toStringAsFixed(2)} kg',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Berat Badan Ideal (BBI) adalah berat badan yang dianggap optimal untuk tinggi badan dan jenis kelamin.',
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