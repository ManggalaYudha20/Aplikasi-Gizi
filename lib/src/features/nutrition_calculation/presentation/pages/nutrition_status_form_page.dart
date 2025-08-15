import 'dart:math';
import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';
import 'package:intl/intl.dart';

class NutritionStatusFormPage extends StatefulWidget {
  const NutritionStatusFormPage({super.key});

  @override
  State<NutritionStatusFormPage> createState() => _NutritionStatusFormPageState();
}

class _NutritionStatusFormPageState extends State<NutritionStatusFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  DateTime? _birthDate;
  DateTime? _measurementDate;
  String? _selectedGender;
  
  int? _ageInMonths;
  Map<String, dynamic>? _calculationResults;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isBirthDate) {
          _birthDate = picked;
        } else {
          _measurementDate = picked;
        }
        
        // Calculate age in months if both dates are selected
        if (_birthDate != null && _measurementDate != null) {
          _calculateAgeInMonths();
        }
      });
    }
  }

  void _calculateAgeInMonths() {
    if (_birthDate != null && _measurementDate != null) {
      final difference = _measurementDate!.difference(_birthDate!);
      final days = difference.inDays;
      _ageInMonths = (days / 30.44).round(); // Average days per month
      
      // Validate age range (0-60 months)
      if (_ageInMonths! < 0 || _ageInMonths! > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Usia anak harus antara 0-60 bulan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _calculateNutritionStatus() {
    if (_formKey.currentState!.validate()) {
      if (_ageInMonths == null || _ageInMonths! < 0 || _ageInMonths! > 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pastikan usia anak antara 0-60 bulan'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);
      
      // Calculate nutrition status based on WHO standards
      final results = _calculateWHOStandards(
        ageInMonths: _ageInMonths!,
        weight: weight,
        height: height,
        gender: _selectedGender!,
      );
      
      setState(() {
        _calculationResults = results;
      });
    }
  }

  Map<String, dynamic> _calculateWHOStandards({
    required int ageInMonths,
    required double weight,
    required double height,
    required String gender,
  }) {
    // Calculate all nutrition indicators using WHO reference data
    
    // BB/U (Weight for Age)
    final bbPerU = _calculateWeightForAge(ageInMonths, weight, gender);
    
    // PB/U or TB/U (Length/Height for Age)
    final tbPerU = _calculateHeightForAge(ageInMonths, height, gender);
    
    // BB/PB or BB/TB (Weight for Length/Height)
    final bbPerTB = _calculateWeightForHeight(height, weight, gender);
    
    // IMT/U (BMI for Age)
    final bmi = weight / ((height / 100) * (height / 100));
    final imtPerU = _calculateBMIForAge(ageInMonths, bmi, gender);
    
    return {
      'bbPerU': bbPerU,
      'tbPerU': tbPerU,
      'bbPerTB': bbPerTB,
      'imtPerU': imtPerU,
      'bmi': bmi,
      'ageInMonths': ageInMonths,
    };
  }

  Map<String, dynamic> _calculateWeightForAge(int age, double weight, String gender) {
    try {
      final referenceData = gender == 'Laki-laki'
          ? NutritionStatusData.bbUBoys
          : NutritionStatusData.bbUGirls;
      
      if (!referenceData.containsKey(age)) {
        return {
          'zScore': null,
          'category': 'Data referensi tidak tersedia untuk usia ini',
          'value': weight,
        };
      }
      
      final percentiles = referenceData[age]!;
      final median = percentiles[3];
      final sd = percentiles[4] - median;
      final zScore = (weight - median) / sd;
      
      return {
        'zScore': zScore,
        'category': _getWeightForAgeCategory(zScore),
        'value': weight,
      };
    } catch (e) {
      return {
        'zScore': null,
        'category': 'Error dalam perhitungan',
        'value': weight,
      };
    }
  }

  Map<String, dynamic> _calculateHeightForAge(int age, double height, String gender) {
    try {
      final referenceData = gender == 'Laki-laki'
          ? NutritionStatusData.pbTbUBoys
          : NutritionStatusData.pbTbUGirls;
      
      if (!referenceData.containsKey(age)) {
        return {
          'zScore': null,
          'category': 'Data referensi tidak tersedia untuk usia ini',
          'value': height,
        };
      }
      
      final percentiles = referenceData[age]!;
      final median = percentiles[3];
      final sd = percentiles[4] - median;
      final zScore = (height - median) / sd;
      
      return {
        'zScore': zScore,
        'category': _getHeightForAgeCategory(zScore),
        'value': height,
      };
    } catch (e) {
      return {
        'zScore': null,
        'category': 'Error dalam perhitungan',
        'value': height,
      };
    }
  }

  Map<String, dynamic> _calculateWeightForHeight(double height, double weight, String gender) {
    try {
      final referenceData = gender == 'Laki-laki'
          ? NutritionStatusData.bbPbTbUBoys
          : NutritionStatusData.bbPbTbUGirls;
      
      // Find the closest height in the reference data
      double closestHeight = referenceData.keys.first;
      double minDifference = (height - closestHeight).abs();
      
      for (final h in referenceData.keys) {
        final difference = (height - h).abs();
        if (difference < minDifference) {
          minDifference = difference;
          closestHeight = h;
        }
      }
      
      // Allow interpolation for heights within 1cm of reference
      if (minDifference > 1.0) {
        return {
          'zScore': null,
          'category': 'Data referensi tidak tersedia untuk tinggi ini',
          'value': weight,
        };
      }
      
      final percentiles = referenceData[closestHeight]!;
      final median = percentiles[3];
      final sd = percentiles[4] - median;
      final zScore = (weight - median) / sd;
      
      return {
        'zScore': zScore,
        'category': _getWeightForHeightCategory(zScore),
        'value': weight,
      };
    } catch (e) {
      return {
        'zScore': null,
        'category': 'Error dalam perhitungan',
        'value': weight,
      };
    }
  }

  Map<String, dynamic> _calculateBMIForAge(int age, double bmi, String gender) {
    try {
      final referenceData = gender == 'Laki-laki'
          ? NutritionStatusData.imtUBoys
          : NutritionStatusData.imtUGirls;
      
      if (!referenceData.containsKey(age)) {
        return {
          'zScore': null,
          'category': 'Data referensi tidak tersedia untuk usia ini',
          'value': bmi,
        };
      }
      
      final percentiles = referenceData[age]!;
      final median = percentiles[3];
      final sd = percentiles[4] - median;
      final zScore = (bmi - median) / sd;
      
      return {
        'zScore': zScore,
        'category': _getBMIForAgeCategory(zScore),
        'value': bmi,
      };
    } catch (e) {
      return {
        'zScore': null,
        'category': 'Error dalam perhitungan',
        'value': bmi,
      };
    }
  }

  String _getWeightForAgeCategory(double zScore) {
    if (zScore < -3) return 'Berat badan sangat kurang (severely underweight)';
    if (zScore < -2) return 'Berat badan kurang (underweight)';
    if (zScore <= 1) return 'Berat badan normal';
    return 'Risiko Berat badan lebih';
  }

  String _getHeightForAgeCategory(double zScore) {
    if (zScore < -3) return 'Sangat pendek (severely stunted)';
    if (zScore < -2) return 'Pendek (stunted)';
    if (zScore <= 3) return 'Normal';
    return 'Tinggi';
  }

  String _getBMIForAgeCategory(double zScore) {
    if (zScore < -3) return 'Gizi buruk (severely wasted)';
    if (zScore < -2) return 'Gizi kurang (wasted)';
    if (zScore <= 1) return 'Gizi baik (normal)';
    if (zScore <= 2) return 'Berisiko gizi lebih';
    if (zScore <= 3) return 'Gizi lebih (overweight)';
    return 'Obesitas (obese)';
  }

  String _getWeightForHeightCategory(double zScore) {
    if (zScore < -3) return 'Gizi buruk (severely wasted)';
    if (zScore < -2) return 'Gizi kurang (wasted)';
    if (zScore <= 1) return 'Gizi baik (normal)';
    if (zScore <= 2) return 'Berisiko gizi lebih';
    if (zScore <= 3) return 'Gizi lebih (overweight)';
    return 'Obesitas (obese)';
  }

  void _resetForm() {
    setState(() {
      _birthDate = null;
      _measurementDate = null;
      _weightController.clear();
      _heightController.clear();
      _selectedGender = null;
      _ageInMonths = null;
      _calculationResults = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Status Gizi Anak',
        subtitle: 'Usia 0-60 Bulan',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Data Input Status Gizi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Tanggal Lahir
                ListTile(
                  title: const Text('Tanggal Lahir'),
                  subtitle: Text(
                    _birthDate != null 
                      ? DateFormat('dd/MM/yyyy').format(_birthDate!)
                      : 'Pilih tanggal lahir',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, true),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _birthDate == null ? Colors.grey : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Tanggal Pengukuran
                ListTile(
                  title: const Text('Tanggal Pengukuran'),
                  subtitle: Text(
                    _measurementDate != null 
                      ? DateFormat('dd/MM/yyyy').format(_measurementDate!)
                      : 'Pilih tanggal pengukuran',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () => _selectDate(context, false),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: _measurementDate == null ? Colors.grey : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Usia dalam bulan
                if (_ageInMonths != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Text(
                      'Usia: $_ageInMonths bulan',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
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
                          side: const BorderSide(color: Color.fromARGB(255, 0, 148, 68)),
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
                        onPressed: _calculateNutritionStatus,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: const Color.fromARGB(255, 0, 148, 68),
                        ),
                        child: const Text(
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
                const SizedBox(height: 32),
                
                // Results
                if (_calculationResults != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Hasil Status Gizi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // BB/U
                  _buildResultCard(
                    title: 'Berat Badan menurut Umur (BB/U)',
                    data: _calculationResults!['bbPerU'],
                  ),
                  const SizedBox(height: 12),
                  
                  // TB/U
                  _buildResultCard(
                    title: 'Tinggi Badan menurut Umur (TB/U)',
                    data: _calculationResults!['tbPerU'],
                  ),
                  const SizedBox(height: 12),
                  
                  // BB/TB
                  _buildResultCard(
                    title: 'Berat Badan menurut Tinggi Badan (BB/TB)',
                    data: _calculationResults!['bbPerTB'],
                  ),
                  const SizedBox(height: 12),
                  
                  // IMT/U
                  _buildResultCard(
                    title: 'Indeks Massa Tubuh menurut Umur (IMT/U)',
                    data: _calculationResults!['imtPerU'],
                    additionalInfo: 'IMT: ${_calculationResults!['bmi']?.toStringAsFixed(2)} kg/m²',
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Z-Score: ${data['zScore']?.toStringAsFixed(2) ?? '-'}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kategori: ${data['category'] ?? '-'}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 148, 68),
            ),
          ),
          if (additionalInfo != null) ...[
            const SizedBox(height: 4),
            Text(
              additionalInfo,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}