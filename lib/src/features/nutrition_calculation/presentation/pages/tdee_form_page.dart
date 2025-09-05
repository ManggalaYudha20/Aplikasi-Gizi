import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';

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

  String? _selectedGender;
  String? _selectedActivityFactor;
  String? _selectedStressFactor;
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

    if (_selectedGender == null || weight <= 0 || height <= 0 || age <= 0) {
      return 0;
    }

    // Harris-Benedict equation
    if (_selectedGender == 'Laki-laki') {
      return 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      return 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }
  }

  void calculateTDEE() {
    if (_formKey.currentState!.validate()) {
      final bmr = calculateBMR();
      final activityFactor = activityFactors[_selectedActivityFactor] ?? 1.0;

      double stressFactor = 1.0;

      if (_selectedStressFactor == 'Demam (per 1°C)') {
        final temperature = double.tryParse(_temperatureController.text) ?? 0;
        if (temperature > 37) {
          stressFactor = 1.0 + (0.13 * (temperature - 37));
        }
      } else {
        stressFactor = stressFactors[_selectedStressFactor] ?? 1.0;
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
    setState(() {
      _selectedGender = null;
      _selectedActivityFactor = null;
      _selectedStressFactor = null;
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
                    labelText: 'Usia',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixText: 'tahun',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Usia tidak boleh kosong';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Masukkan angka yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Faktor Aktivitas
                DropdownButtonFormField<String>(
                  value: _selectedActivityFactor,
                  decoration: const InputDecoration(
                    labelText: 'Faktor Aktivitas',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_run),
                  ),
                  items: activityFactors.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.key} (${entry.value})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivityFactor = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih faktor aktivitas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Faktor Stress
                DropdownButtonFormField<String>(
                  value: _selectedStressFactor,
                  decoration: const InputDecoration(
                    labelText: 'Faktor Stress',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.healing),
                  ),
                  items: stressFactors.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text('${entry.key} (${entry.value})'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStressFactor = value;
                      if (value != 'Demam (per 1°C)') {
                        _temperatureController.clear();
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih faktor stress';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Suhu Tubuh (khusus untuk demam)
                if (_selectedStressFactor == 'Demam (per 1°C)')
                  TextFormField(
                    controller: _temperatureController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Suhu Tubuh',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.thermostat),
                      suffixText: '°C',
                    ),
                    validator: (value) {
                      if (_selectedStressFactor == 'Demam (per 1°C)') {
                        if (value == null || value.isEmpty) {
                          return 'Suhu tubuh tidak boleh kosong';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                      }
                      return null;
                    },
                  ),
                if (_selectedStressFactor == 'Demam (per 1°C)')
                  const SizedBox(height: 16),

                // Buttons
                FormActionButtons(onReset: resetForm, onSubmit: calculateTDEE),

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
                      color: const Color(0xFF009444).withOpacity(0.1),
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
