import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';

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

  String? _selectedGender;
  Map<String, dynamic>? _calculationResult;
  bool _isLoading = false;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageYearsController.dispose();
    _ageMonthsController.dispose();
    super.dispose();
  }

  void _calculateIMTU() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
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
          _isLoading = false;
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
          _isLoading = false;
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
        _isLoading = false;
      });
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
    if (zScore <= 2) return 'Berisiko gizi lebih';
    if (zScore <= 3) return 'Gizi lebih (overweight)';
    return 'Obesitas (obese)';
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
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gender Selection
                const Text(
                  'Jenis Kelamin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Laki-laki'),
                        value: 'Laki-laki',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Perempuan'),
                        value: 'Perempuan',
                        groupValue: _selectedGender,
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Age Input
                const Text(
                  'Usia',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _ageYearsController,
                        decoration: const InputDecoration(
                          labelText: 'Tahun',
                          border: OutlineInputBorder(),
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
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetForm,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: const BorderSide(
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculateIMTU,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: const Color.fromARGB(
                            255,
                            0,
                            148,
                            68,
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Hitung',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

                // Results
                if (_calculationResult != null) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Hasil Perhitungan',
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Color.fromARGB(
            255, 0, 148, 68
          ), // Warna border (disamakan dengan warna teks)
          width: 2.0,
        ),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 148, 68),
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
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  data['zScore']?.toStringAsFixed(2) ?? '-',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 148, 68),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Text(
                  'Kategori: ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Text(
                    data['category'] ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 148, 68),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
