//lib\src\features\nutrition_calculation\presentation\pages\nutrition_status_form_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

class NutritionStatusFormPage extends StatefulWidget {
  final String userRole; 

  const NutritionStatusFormPage({
    super.key,
    required this.userRole, // Wajib
  });

  @override
  State<NutritionStatusFormPage> createState() =>
      _NutritionStatusFormPageState();
}

class _NutritionStatusFormPageState extends State<NutritionStatusFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();
  final _birthDateController = TextEditingController();
  final _measurementDateController = TextEditingController();
  final _genderController = TextEditingController();
  DateTime? _birthDate;
  DateTime? _measurementDate;
  int? _ageInMonths;
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();

  Map<String, dynamic>? _calculationResults;

  @override
  void initState() {
    super.initState();
    // Default tanggal pengukuran ke hari ini
    initializeDateFormatting('id_ID', null).then((_) {
      if (mounted) {
        setState(() {
          _measurementDate = DateTime.now();
          // Gunakan 'id_ID'
          _measurementDateController.text = 
              DateFormat('dd MMMM yyyy', 'id_ID').format(_measurementDate!);
        });
      }
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _scrollController.dispose();
    _birthDateController.dispose();
    _measurementDateController.dispose();
    _genderController.dispose();
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

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: isBirthDate 
          ? (_birthDate ?? DateTime.now()) 
          : (_measurementDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        String formattedDate = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
        if (isBirthDate) {
          _birthDate = picked;
          _birthDateController.text = formattedDate;
        } else {
          _measurementDate = picked;
          _measurementDateController.text = formattedDate;
        }
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
        gender: _genderController.text,
      );

      setState(() {
        _calculationResults = results;
      });
      _scrollToResult();
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

  Map<String, dynamic> _calculateWeightForAge(
    int age,
    double weight,
    String gender,
  ) {
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

  Map<String, dynamic> _calculateHeightForAge(
    int age,
    double height,
    String gender,
  ) {
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

  Map<String, dynamic> _calculateWeightForHeight(
    double height,
    double weight,
    String gender,
  ) {
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

  Color _getWeightForAgeColor(String category) {
    if (category.contains('sangat kurang') ||
        category.contains('severely underweight')) {
      return Colors.red;
    } else if (category.contains('kurang') ||
        category.contains('underweight')) {
      return Colors.orange;
    } else if (category.contains('normal')) {
      return Color.fromARGB(255, 0, 148, 68);
    } else {
      return Colors.red;
    }
  }

  String _getHeightForAgeCategory(double zScore) {
    if (zScore < -3) return 'Sangat pendek (severely stunted)';
    if (zScore < -2) return 'Pendek (stunted)';
    if (zScore <= 3) return 'Normal';
    return 'Tinggi';
  }

  Color _getHeightForAgeColor(String category) {
    if (category.contains('Sangat pendek') ||
        category.contains('severely stunted')) {
      return Colors.red;
    } else if (category.contains('Pendek') || category.contains('stunted')) {
      return Colors.orange;
    } else if (category.contains('Normal')) {
      return Color.fromARGB(255, 0, 148, 68);
    } else {
      return Colors.red;
    }
  }

  String _getBMIForAgeCategory(double zScore) {
    if (zScore < -3) return 'Gizi buruk (severely wasted)';
    if (zScore < -2) return 'Gizi kurang (wasted)';
    if (zScore <= 1) return 'Gizi baik (normal)';
    if (zScore <= 2) return 'Berisiko gizi lebih';
    if (zScore <= 3) return 'Gizi lebih (overweight)';
    return 'Obesitas (obese)';
  }

  Color _getBMIForAgeColor(String category) {
    if (category.contains('Gizi buruk') ||
        category.contains('severely wasted')) {
      return Colors.red;
    } else if (category.contains('Gizi kurang') ||
        category.contains('wasted') ||
        category.contains('Berisiko gizi lebih')) {
      return Colors.orange;
    } else if (category.contains('Gizi baik') || category.contains('normal')) {
      return Color.fromARGB(255, 0, 148, 68);
    } else {
      return Colors.red;
    }
  }

  String _getWeightForHeightCategory(double zScore) {
    if (zScore < -3) return 'Gizi buruk (severely wasted)';
    if (zScore < -2) return 'Gizi kurang (wasted)';
    if (zScore <= 1) return 'Gizi baik (normal)';
    if (zScore <= 2) return 'Berisiko gizi lebih';
    if (zScore <= 3) return 'Gizi lebih (overweight)';
    return 'Obesitas (obese)';
  }

  Color _getWeightForHeightColor(String category) {
    if (category.contains('Gizi buruk') ||
        category.contains('severely wasted')) {
      return Colors.red;
    } else if (category.contains('Gizi kurang') ||
        category.contains('wasted') ||
        category.contains('Berisiko gizi lebih')) {
      return Colors.orange;
    } else if (category.contains('Gizi baik') || category.contains('normal')) {
      return Color.fromARGB(255, 0, 148, 68);
    } else {
      return Colors.red;
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _birthDate = null;
      _measurementDate = DateTime.now();
      // Format ulang tanggal pengukuran saat reset
      _measurementDateController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(_measurementDate!);
      _birthDateController.clear();
      _weightController.clear();
      _heightController.clear();
      _genderController.clear();
      _ageInMonths = null;
      _calculationResults = null;
      _patientPickerKey.currentState?.resetSelection();
    });
  }

  void _fillDataFromPatient(double weight, double height, String gender, DateTime dob) {
    setState(() {
      _weightController.text = weight.toString();
      _heightController.text = height.toString();
      
      // 1. Set Tanggal Lahir
      _birthDate = dob;
      _birthDateController.text = DateFormat('dd MMMM yyyy','id_ID').format(dob);
      
      // 2. Set Tanggal Ukur (Default Hari Ini)
      _measurementDate = DateTime.now();
      _measurementDateController.text = DateFormat('dd MMMM yyyy','id_ID').format(_measurementDate!);

      // 3. Hitung Usia Otomatis
      _calculateAgeInMonths();

      // 4. Normalisasi Gender
      String incomingGender = gender.toLowerCase();
      String normalizedGender = '';

      if (incomingGender.contains('laki') || incomingGender.contains('pria') || incomingGender == 'l') {
        normalizedGender = 'Laki-laki';
      } else if (incomingGender.contains('perempuan') || incomingGender.contains('wanita') || incomingGender == 'p') {
        normalizedGender = 'Perempuan';
      } else {
        normalizedGender = gender;
      }
      _genderController.text = normalizedGender;
      
      // Reset hasil perhitungan sebelumnya
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
                    userRole: widget.userRole,
                  ),
                const SizedBox(height: 20),
                const Text(
                  'Input Data Status Gizi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Tanggal Lahir
                _buildDatePickerField(
                  controller: _birthDateController,
                  label: 'Tanggal Lahir',
                  onTap: () => _selectDate(context, true),
                ),
                const SizedBox(height: 16),

                // Tanggal Pengukuran
                _buildDatePickerField(
                  controller: _measurementDateController,
                  label: 'Tanggal Pengukuran',
                  onTap: () => _selectDate(context, false),
                ),
                const SizedBox(height: 16),

                // Usia dalam bulan
                if (_ageInMonths != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
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
                _buildCustomDropdown(
                  controller: _genderController,
                  label: 'Jenis Kelamin',
                  prefixIcon: const Icon(Icons.wc),
                  items: ['Laki-laki', 'Perempuan'],
                ),
                const SizedBox(height: 16),

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
                  onSubmit: _calculateNutritionStatus,
                  resetButtonColor: Colors.white, // Background jadi putih
                  resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                  submitIcon: const Icon(Icons.calculate, color: Colors.white),
                ),

                const SizedBox(height: 32),

                // Results
                if (_calculationResults != null) ...[
                  Container(
                    key: _resultCardKey,
                    child: const Column(
                      children: [Divider(), SizedBox(height: 32)],
                    ),
                  ),

                  const Text(
                    'Hasil Status Gizi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    additionalInfo:
                        'IMT: ${_calculationResults!['bmi']?.toStringAsFixed(2)} kg/m²',
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

  Widget _buildResultCard({
    required String title,
    required Map<String, dynamic> data,
    String? additionalInfo,
  }) {
    // Determine which color function to use based on the title
    Color resultColor = Color.fromARGB(255, 0, 148, 68); // Default color
    if (title.contains('BB/U')) {
      resultColor = _getWeightForAgeColor(data['category'] ?? '');
    } else if (title.contains('TB/U')) {
      resultColor = _getHeightForAgeColor(data['category'] ?? '');
    } else if (title.contains('IMT/U')) {
      resultColor = _getBMIForAgeColor(data['category'] ?? '');
    } else if (title.contains('BB/TB')) {
      resultColor = _getWeightForHeightColor(data['category'] ?? '');
    }

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
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Z-Score: ${data['zScore']?.toStringAsFixed(2) ?? '-'}',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 4),
          Text(
            'Kategori: ${data['category'] ?? '-'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: resultColor,
            ),
          ),
          if (additionalInfo != null) ...[
            const SizedBox(height: 4),
            Text(
              additionalInfo,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
          ],
        ],
      ),
    );
  }

  // 1. Widget untuk Input Teks (BB & TB)
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

  // 2. Widget untuk Dropdown (Jenis Kelamin)
  Widget _buildCustomDropdown({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required Icon prefixIcon,
  }) {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: false, // Tidak ada pencarian untuk form ini
        fit: FlexFit.loose,
        constraints: const BoxConstraints(maxHeight: 240),
      ),
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged: (String? newValue) {
        setState(() {
          controller.text = newValue ?? '';
        });
      },
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (value) =>
          (value == null || value.isEmpty) ? '$label harus dipilih' : null,
    );
  }

  // 3. Widget untuk Pemilih Tanggal
  Widget _buildDatePickerField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    );
  }
}
