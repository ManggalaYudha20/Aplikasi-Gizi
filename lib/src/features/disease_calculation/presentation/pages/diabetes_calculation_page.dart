import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/diabetes_calculator_service.dart';
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
  final _calculatorService = DiabetesCalculatorService();

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
  String? _hospitalizedStatus;
  double _stressMetabolic = 20.0;

  // Calculation results
  DiabetesCalculationResult? _result;
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

  void _calculateDiabetesNutrition() {
    if (_formKey.currentState!.validate()) {
      final result = _calculatorService.calculate(
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        gender: _selectedGender!,
        activity: _selectedActivity!,
        hospitalizedStatus: _hospitalizedStatus!,
        stressMetabolic: _stressMetabolic,
        bloodSugar: _bloodSugar!,
        bloodPressure: _bloodPressure!,
      );

      setState(() {
        _result = result;
        _generateRecommendation();
      });

      _scrollToResult();
    }
  }

  void _generateRecommendation() {
    if (_result == null) return;

    final calories = _result!.totalCalories.round();
    final age = int.tryParse(_ageController.text) ?? 0;

    String ageCorrectionNote = '';
    if (age > 40 && _result!.ageCorrection > 0) {
      ageCorrectionNote =
          ' - Koreksi usia: -${_result!.ageCorrection.round()} kkal/hari (karena usia > 40 tahun)\n';
    }

    String weightCorrectionNote = '';
    if (_result!.weightCorrection != 0) {
      String correctionType = _result!.weightCorrection > 0 ? '+' : '';
      weightCorrectionNote =
          ' - Koreksi berat badan: $correctionType${_result!.weightCorrection.round()} kkal/hari (karena IMT ${_result!.bmiCategory.toLowerCase()})\n';
    }

    String stressMetabolicNote = '';
    if (_hospitalizedStatus == 'Ya') {
      double stressMetabolicCorrection =
          (_stressMetabolic / 100) * _result!.bmr;
      stressMetabolicNote =
          ' - Koreksi stress metabolik: +${stressMetabolicCorrection.round()} kkal/hari (${_stressMetabolic.round()}%)\n';
    }

    _recommendation =
        '''
Rekomendasi Nutrisi untuk Pasien Diabetes:

Kalori Total: $calories kkal/hari
- Koreksi aktivitas: +${_result!.activityCorrection.round()} kkal/hari ($_selectedActivity)
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
    _ageController.clear();
    _weightController.clear();
    _heightController.clear();
    setState(() {
      _selectedGender = null;
      _selectedActivity = null;
      _bloodSugar = null;
      _bloodPressure = null;
      _hospitalizedStatus = null;
      _stressMetabolic = 20.0;
      _result = null;
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
                    if (value == null || value.isEmpty) return 'Masukkan usia';
                    final age = int.tryParse(value);
                    if (age == null || age < 1 || age > 120) {
                      return 'Masukkan usia yang valid (1-120 tahun)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
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
                  onChanged: (value) => setState(() => _selectedGender = value),
                  validator: (value) =>
                      value == null ? 'Pilih jenis kelamin' : null,
                ),
                const SizedBox(height: 16),
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
                  onChanged: (value) =>
                      setState(() => _selectedActivity = value),
                  validator: (value) =>
                      value == null ? 'Pilih faktor aktivitas' : null,
                ),
                const SizedBox(height: 16),
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
                  onChanged: (value) => setState(() => _bloodSugar = value),
                  validator: (value) =>
                      value == null ? 'Pilih status gula darah' : null,
                ),
                const SizedBox(height: 16),
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
                  onChanged: (value) => setState(() => _bloodPressure = value),
                  validator: (value) =>
                      value == null ? 'Pilih status tekanan darah' : null,
                ),
                const SizedBox(height: 16),
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
                      if (value == 'Tidak') _stressMetabolic = 20.0;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Pilih status rawat inap' : null,
                ),
                const SizedBox(height: 16),
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
                        onChanged: (value) =>
                            setState(() => _stressMetabolic = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 24),
                FormActionButtons(
                  onReset: _resetForm,
                  onSubmit: _calculateDiabetesNutrition,
                ),
                const SizedBox(height: 32),
                if (_result != null) ...[
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
                      ).withValues(alpha: 0.1),
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
                        const Divider(height: 24),
                        const SizedBox(height: 8),
                        _buildNutritionRow(
                          'BB Ideal',
                          '${_result!.bbIdeal.round()} kg',
                        ),
                        _buildNutritionRow(
                          'BMR',
                          '${_result!.bmr.round()} kkal/hari',
                        ),
                        _buildNutritionRow(
                          'Kategori IMT',
                          _result!.bmiCategory,
                        ),
                        _buildNutritionRow(
                          'Koreksi Aktivitas',
                          '+${_result!.activityCorrection.round()} kkal/hari',
                        ),
                        if (_result!.ageCorrection > 0)
                          _buildNutritionRow(
                            'Koreksi Usia',
                            '-${_result!.ageCorrection.round()} kkal/hari',
                          ),
                        if (_result!.weightCorrection != 0)
                          _buildNutritionRow(
                            'Koreksi Berat Badan',
                            '+${_result!.weightCorrection.round()} kkal/hari',
                          ),
                        if (_hospitalizedStatus == 'Ya')
                          _buildNutritionRow(
                            'Koreksi Stress Metabolik',
                            '+${((_stressMetabolic / 100) * _result!.bmr).round()} kkal/hari',
                          ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Total Kalori: ${_result!.totalCalories.round()} kkal/hari',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
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

                  // CONTAINER BARU UNTUK JENIS DIET
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Jenis ${_result!.dietInfo.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        _buildNutritionRow(
                          'Protein',
                          '${_result!.dietInfo.protein} g',
                        ),
                        _buildNutritionRow(
                          'Lemak',
                          '${_result!.dietInfo.fat} g',
                        ),
                        _buildNutritionRow(
                          'Karbohidrat',
                          '${_result!.dietInfo.carbohydrate} g',
                        ),

                        const SizedBox(height: 8),

                        const Text(
                          'Jenis Diet Diabetes Melitus menurut kandungan energi, protein, lemak, dan karbohidrat',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CONTAINER BARU UNTUK STANDAR DIET GOLONGAN BAHAN MAKANAN
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.purple.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Standar Diet (${_result!.foodGroupDiet.calorieLevel})',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ),
                        const Divider(height: 24),
                        _buildNutritionRow(
                          'Nasi atau penukar',
                          '${_formatNumber(_result!.foodGroupDiet.nasiP)} P',
                        ),
                        _buildNutritionRow(
                          'Ikan atau penukar',
                          '${_formatNumber(_result!.foodGroupDiet.ikanP)} P',
                        ),
                        _buildNutritionRow(
                          'Daging atau penukar',
                          '${_formatNumber(_result!.foodGroupDiet.dagingP)} P',
                        ),
                        _buildNutritionRow(
                          'Tempe atau penukar',
                          '${_formatNumber(_result!.foodGroupDiet.tempeP)} P',
                        ),
                        _buildNutritionRow(
                          'Sayuran/penukar A',
                          ' ${_result!.foodGroupDiet.sayuranA}',
                        ),
                        _buildNutritionRow(
                          'Sayuran/penukar B',
                          '${_formatNumber(_result!.foodGroupDiet.sayuranB)} P',
                        ),
                        _buildNutritionRow(
                          'Buah atau penukar',
                          '${_formatNumber(_result!.foodGroupDiet.buah)} P',
                        ),
                        _buildNutritionRow(
                          'Susu atau penukar',
                          '${_formatNumber(_result!.foodGroupDiet.susu)} P',
                        ),
                        _buildNutritionRow(
                          'Minyak atau penukar',
                          '${_formatNumber(_result!.foodGroupDiet.minyak)} P',
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Keterangan : (P = Penukar) (S = Sekehendak) ',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600,),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Jumlah bahan makanan sehari menurut Standar Diet Diabetes Melitus (dalam satuan penukar II)',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  if (_recommendation != null)
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
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper untuk baris nutrisi di kartu diet
  Widget _buildNutritionRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor ?? const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }

  // Helper function to format numbers conditionally
  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }
}
