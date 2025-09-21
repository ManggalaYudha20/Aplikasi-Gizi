import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';

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

  String? _selectedGender;
  Map<String, dynamic>? _calculationResult;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageYearsController.dispose();
    _ageMonthsController.dispose();
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

  void _calculateIMTU() {
    if (_formKey.currentState!.validate()) {
      setState(() {
      });

      final weight = double.tryParse(_weightController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0;
      final ageYears = int.tryParse(_ageYearsController.text) ?? 0;
      final ageMonths = int.tryParse(_ageMonthsController.text) ?? 0;
      final gender = _selectedGender;

      if (gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih jenis kelamin terlebih dahulu')),
        );
        setState(() {
        });
        return;
      }

      // Validate age range (5-18 years)
      final totalMonths = (ageYears * 12) + ageMonths;
      if (totalMonths < 60 || totalMonths > 216) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usia harus antara 5-18 tahun')),
        );
        setState(() {
          
        });
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
    if (category.contains('gizi buruk') || category.contains('severely wasted')) {
      return Colors.red;
    } else if (category.contains('gizi kurang') || category.contains('wasted')) {
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
    setState(() {
      _selectedGender = null;
      _calculationResult = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(title: 'IMT/U', subtitle: 'Usia 5-18 Tahun'),
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
                  'Input Data IMT/U  5-18 Tahun',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                // Age Input
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageYearsController,
                        decoration: const InputDecoration(
                          labelText: 'Tahun',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                          suffixText: 'tahun',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan tahun';
                          }
                          final years = int.tryParse(value);
                          if (years == null || years < 5 || years > 18) {
                            return '5-18 tahun';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _ageMonthsController,
                        decoration: const InputDecoration(
                          labelText: 'Bulan',
                          border: OutlineInputBorder(),
                          suffixText: 'bulan',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Masukkan bulan';
                          }
                          final months = int.tryParse(value);
                          if (months == null || months < 0 || months > 11) {
                            return '0-11 bulan';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Gender Selection
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

                // Weight Input
                TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Berat Badan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_weight),
                    suffixText: 'kg',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan berat badan';
                    }
                    final weight = double.tryParse(value);
                    if (weight == null || weight <= 0) {
                      return 'Masukkan berat yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Height Input
                TextFormField(
                  controller: _heightController,
                  decoration: const InputDecoration(
                    labelText: 'Tinggi Badan',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.height),
                    suffixText: 'cm',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan tinggi badan';
                    }
                    final height = double.tryParse(value);
                    if (height == null || height <= 0) {
                      return 'Masukkan tinggi yang valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Buttons
                FormActionButtons(onReset: _resetForm, onSubmit: _calculateIMTU),

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
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                const Text(
                  'Z-Score: ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,color: Color(0xFF9E9E9E),),
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
}
