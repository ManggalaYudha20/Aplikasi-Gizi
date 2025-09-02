import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';

class DiabetesCalculationPage extends StatefulWidget {
  const DiabetesCalculationPage({super.key});

  @override
  State<DiabetesCalculationPage> createState() =>
      _DiabetesCalculationPageState();
}

class _DiabetesCalculationPageState extends State<DiabetesCalculationPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();

  // Form fields
  String? _selectedGender;
  String? _selectedActivity;
  String? _bloodSugar;
  String? _bloodPressure;
  String? _hospitalizedStatus; // Changed from bool to String for dropdown
  double _stressMetabolic = 20.0; // Default 20%

  // Calculation results
  double? _bbIdeal;
  double? _bmr;
  double? _totalCalories;
  double? _ageCorrection;
  double? _activityCorrection;
  double? _weightCorrection;
  String? _bmiCategory;
  String? _recommendation;

  final List<String> _genders = ['Laki-laki', 'Perempuan'];
  final List<String> _activityLevels = [
    'Bed rest',
    'Ringan',
    'Sedang',
    'Berat',
  ];
  final List<String> _bloodSugarOptions = ['Terkendali', 'Tidak terkendali'];
  final List<String> _bloodPressureOptions = ['Normal', 'Tinggi'];

  @override
  void dispose() {
    _ageController.dispose();
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

  double _calculateBBIdeal(double height, String gender) {
    // Rumus BB Ideal:
    // (TB-100)-10% jika TB Laki-laki ≥ 160cm dan TB perempuan ≥ 150cm
    // (TB-100) jika TB laki-laki < 160cm dan TB Perempuan < 150cm

    double bbIdeal;

    if (gender == 'Laki-laki') {
      if (height >= 160) {
        bbIdeal = (height - 100) * 0.9; // (TB-100)-10%
      } else {
        bbIdeal = height - 100; // (TB-100)
      }
    } else {
      // Perempuan
      if (height >= 150) {
        bbIdeal = (height - 100) * 0.9; // (TB-100)-10%
      } else {
        bbIdeal = height - 100; // (TB-100)
      }
    }

    return bbIdeal;
  }

  String _calculateBMICategory(double weight, double height) {
    double bmi = weight / ((height / 100) * (height / 100));

    if (bmi < 18.5) {
      return 'Kurang';
    } else if (bmi >= 18.5 && bmi < 23) {
      return 'Normal';
    } else if (bmi >= 23 && bmi < 25) {
      return 'Lebih';
    } else {
      return 'Gemuk';
    }
  }

  double _calculateWeightCorrection(String bmiCategory, double bmr) {
    // 3. Menghitung Koreksi
    // c. Berat Badan (Abaikan jika hasil kategori IMT normal)
    // kategori x kalori basal = (-/+) kalori
    // gemuk ; (-) 20%
    // Lebih : (-) 10%
    // Kurang : (+) 20%

    if (bmiCategory == 'Normal') {
      return 0;
    }

    switch (bmiCategory) {
      case 'Gemuk':
        return -0.2 * bmr; // (-) 20%
      case 'Lebih':
        return -0.1 * bmr; // (-) 10%
      case 'Kurang':
        return 0.2 * bmr; // (+) 20%
      default:
        return 0;
    }
  }

  void _calculateDiabetesNutrition() {
    if (_formKey.currentState!.validate()) {
      final age = int.parse(_ageController.text);
      final weight = double.parse(_weightController.text);
      final height = double.parse(_heightController.text);

      // Calculate BB Ideal
      _bbIdeal = _calculateBBIdeal(height, _selectedGender!);

      // Calculate BMI Category
      _bmiCategory = _calculateBMICategory(weight, height);

      // Calculate BMR based on gender and BB Ideal
      if (_selectedGender == 'Laki-laki') {
        _bmr = _bbIdeal! * 30;
      } else {
        _bmr = _bbIdeal! * 25;
      }

      // 3. Menghitung Koreksi
      // b. Aktifitas
      double activityFactor = 0; // Default
      switch (_selectedActivity) {
        case 'Bed rest':
          activityFactor = 0.1;
          break;
        case 'Ringan':
          activityFactor = 0.2;
          break;
        case 'Sedang':
          activityFactor = 0.3;
          break;
        case 'Berat':
          activityFactor = 0.4;
          break;
      }

      // Calculate activity correction: faktor aktivitas x kalori basal = (+) kalori
      _activityCorrection = activityFactor * _bmr!;

      // Calculate weight correction based on BMI category
      _weightCorrection = _calculateWeightCorrection(_bmiCategory!, _bmr!);

      // Calculate total calories with activity correction
      _totalCalories = _bmr! + _activityCorrection! + _weightCorrection!;

      // Calculate age correction (3. Menghitung Koreksi)
      _ageCorrection = 0;
      if (age > 40) {
        _ageCorrection = _bmr! * 0.05; // -5% x kalori basal
        _totalCalories = _totalCalories! - _ageCorrection!;
      }

      // 3. Menghitung Koreksi
      // d. Stress Metabolik (abaikan jika bukan pasien rawat inap)
      // stress metabolik (10-40%) x kalori basal = (+) kalori
      double stressMetabolicCorrection = 0;
      if (_hospitalizedStatus == 'Ya') {
        stressMetabolicCorrection = (_stressMetabolic / 100) * _bmr!;
        _totalCalories = _totalCalories! + stressMetabolicCorrection;
      }

      // Adjust for blood sugar and pressure conditions
      if (_bloodSugar == 'Tidak terkendali') {
        _totalCalories =
            _totalCalories! * 0.9; // Reduce 10% for uncontrolled diabetes
      }

      if (_bloodPressure == 'Tinggi') {
        _totalCalories =
            _totalCalories! * 0.95; // Reduce 5% for high blood pressure
      }

      // Generate recommendation
      _generateRecommendation();

      setState(() {});
      _scrollToResult();
    }
  }

  void _generateRecommendation() {
    if (_totalCalories == null) return;

    final calories = _totalCalories!.round();
    final age = int.tryParse(_ageController.text) ?? 0;

    String ageCorrectionNote = '';
    if (age > 40 && _ageCorrection != null && _ageCorrection! > 0) {
      ageCorrectionNote =
          '''
- Koreksi usia: -${_ageCorrection!.round()} kkal/hari (karena usia > 40 tahun)
''';
    }

    String weightCorrectionNote = '';
    if (_weightCorrection != null && _weightCorrection! != 0) {
      String correctionType = _weightCorrection! > 0 ? '+' : '';
      weightCorrectionNote =
          '''
- Koreksi berat badan: $correctionType${_weightCorrection!.round()} kkal/hari (karena IMT ${_bmiCategory!.toLowerCase()})
''';
    }

    String stressMetabolicNote = '';
    if (_hospitalizedStatus == 'Ya') {
      double stressMetabolicCorrection = (_stressMetabolic / 100) * _bmr!;
      stressMetabolicNote =
          '''
- Koreksi stress metabolik: +${stressMetabolicCorrection.round()} kkal/hari (${_stressMetabolic.round()}%)
''';
    }

    _recommendation =
        '''
Rekomendasi Nutrisi untuk Pasien Diabetes:

Kalori Total: $calories kkal/hari
- Koreksi aktivitas: +${_activityCorrection!.round()} kkal/hari ($_selectedActivity)
$ageCorrectionNote$weightCorrectionNote$stressMetabolicNote
Distribusi Makronutrien:
- Karbohidrat: ${(calories * 0.45).round()} - ${(calories * 0.65).round()} kkal (${(calories * 0.45 / 4).round()} - ${(calories * 0.65 / 4).round()}g)
- Protein: ${(calories * 0.15).round()} - ${(calories * 0.20).round()} kkal (${(calories * 0.15 / 4).round()} - ${(calories * 0.20 / 4).round()}g)
- Lemak: ${(calories * 0.20).round()} - ${(calories * 0.35).round()} kkal (${(calories * 0.20 / 9).round()} - ${(calories * 0.35 / 9).round()}g)

Catatan:
- Pilih karbohidrat kompleks (nasi merah, gandum, umbi-umbian)
- Batasi konsumsi gula sederhana
- Konsumsi serat 25-30g per hari
- Minum air putih minimal 8 gelas per hari
- Lakukan pemantauan gula darah secara rutin
''';
  }

  void _resetForm() {
    _formKey.currentState?.reset();

    // Reset all controllers
    _ageController.clear();
    _weightController.clear();
    _heightController.clear();

    // Reset all form fields
    setState(() {
      _selectedGender = null;
      _selectedActivity = null;
      _bloodSugar = null;
      _bloodPressure = null;
      _hospitalizedStatus = null;
      _stressMetabolic = 20.0;

      // Reset calculation results
      _bbIdeal = null;
      _bmr = null;
      _totalCalories = null;
      _ageCorrection = null;
      _activityCorrection = null;
      _weightCorrection = null;
      _bmiCategory = null;
      _recommendation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Diabetes Melitus',
        subtitle: 'di Aplikasi MyGizi',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Data Input Diabetes Melitus',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Usia
                TextFormField(
                  controller: _ageController,
                  decoration: const InputDecoration(
                    labelText: 'Usia',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                    suffixText: 'tahun',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Masukkan usia';
                    }
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Masukkan usia yang valid (1-120 tahun)';
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
                  items: _genders.map((gender) {
                    return DropdownMenuItem(value: gender, child: Text(gender));
                  }).toList(),
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
                    if (weight == null || weight < 1 || weight > 300) {
                      return 'Masukkan berat badan yang valid (1-300 kg)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tinggi Badan
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
                    if (height == null || height < 30 || height > 300) {
                      return 'Masukkan tinggi badan yang valid (30-300 cm)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Faktor Aktivitas
                DropdownButtonFormField<String>(
                  value: _selectedActivity,
                  decoration: const InputDecoration(
                    labelText: 'Faktor Aktivitas',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.directions_run),
                  ),
                  items: _activityLevels.map((activity) {
                    return DropdownMenuItem(
                      value: activity,
                      child: Text(activity),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActivity = value;
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

                // Gula Darah
                DropdownButtonFormField<String>(
                  value: _bloodSugar,
                  decoration: const InputDecoration(
                    labelText: 'Gula Darah',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bloodtype),
                  ),
                  items: _bloodSugarOptions.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _bloodSugar = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih status gula darah';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Tekanan Darah
                DropdownButtonFormField<String>(
                  value: _bloodPressure,
                  decoration: const InputDecoration(
                    labelText: 'Tekanan Darah',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.monitor_heart),
                  ),
                  items: _bloodPressureOptions.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _bloodPressure = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih status tekanan darah';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Pasien Rawat Inap
                DropdownButtonFormField<String>(
                  value: _hospitalizedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status Rawat Inap',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.bed),
                  ),
                  items: ['Ya', 'Tidak'].map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _hospitalizedStatus = value;
                      // Reset stress metabolik to default when not hospitalized
                      if (value == 'Tidak') {
                        _stressMetabolic = 20.0;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Pilih status rawat inap';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Stress Metabolik - Only show if hospitalized
                if (_hospitalizedStatus == 'Ya') ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stress Metabolik: ${_stressMetabolic.round()}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Slider(
                        value: _stressMetabolic,
                        min: 10,
                        max: 40,
                        divisions: 30,
                        label: '${_stressMetabolic.round()}%',
                        onChanged: (value) {
                          setState(() {
                            _stressMetabolic = value;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                const SizedBox(height: 24),

                // Calculate Button
                FormActionButtons(onReset: _resetForm, onSubmit: _calculateDiabetesNutrition),

                const SizedBox(height: 32),

                // Results
                if (_bbIdeal != null &&
                    _bmr != null &&
                    _totalCalories != null) ...[

                  Container(
                    key: _resultCardKey, 
                    child: const Column(
                      children: [Divider(), SizedBox(height: 32)],
                    ),
                  ),
                  
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(
                        255,
                        0,
                        148,
                        68,
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color.fromARGB(255, 0, 148, 68),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Center(
                          child: Text(
                            'Hasil Total Kebutuhan Energi',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 0, 148, 68),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'BB Ideal: ${_bbIdeal!.round()} kg',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 0, 148, 68),
                            ),
                        ),
                        Text(
                          'BMR: ${_bmr!.round()} kkal/hari',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 0, 148, 68),
                            ),
                        ),
                        Text(
                          'Kategori IMT: $_bmiCategory',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 0, 148, 68),
                            ),
                        ),
                        Text(
                          'Koreksi Aktivitas: +${_activityCorrection!.round()} kkal/hari',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                        if (_ageCorrection != null && _ageCorrection! > 0) ...[
                          Text(
                            'Koreksi Usia: -${_ageCorrection!.round()} kkal/hari',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 0, 148, 68),
                            ),
                          ),
                        ],
                        if (_weightCorrection != null &&
                            _weightCorrection! != 0) ...[
                          Text(
                            'Koreksi Berat Badan: ${_weightCorrection!.round()} kkal/hari',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: _weightCorrection! > 0
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ],
                        if (_hospitalizedStatus == 'Ya') ...[
                          Text(
                            'Koreksi Stress Metabolik: +${((_stressMetabolic / 100) * _bmr!).round()} kkal/hari',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Color.fromARGB(255, 0, 148, 68),
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Total Kalori: ${_totalCalories!.round()} kkal/hari',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Color.fromARGB(255, 0, 148, 68),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        const Text(
                          'Total kebutuhan energi digunakan untuk mengetahui jenis diet Diabetes Melitus',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_recommendation != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rekomendasi:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _recommendation!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
