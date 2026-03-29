// lib/src/features/nutrition_calculation/presentation/pages/adult_quick_calc_page.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/responsive_number_field.dart';

// Service Imports
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bmi_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bmr_tdee_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bbi_calculator_service.dart';

class _Keys {
  const _Keys._();
  static const weightField = ValueKey('qc_weightField');
  static const heightField = ValueKey('qc_heightField');
  static const ageField = ValueKey('qc_ageField');
  static const activityDropdown = ValueKey('qc_activityDropdown');
  static const stressDropdown = ValueKey('qc_stressDropdown');
  static const tempField = ValueKey('qc_tempField');
  static const btnReset = ValueKey('qc_btnReset');
}

class _Str {
  const _Str._();
  static const appBarTitle = 'Hitung Cepat Dewasa';
  static const appBarSubtitle = 'Kalkulasi Gizi Komprehensif';
  static const sectionTitle = 'Input Data Pasien';

  static const weightLabel = 'Berat Badan';
  static const weightUnit = 'kg';
  static const heightLabel = 'Tinggi Badan';
  static const heightUnit = 'cm';
  static const ageLabel = 'Usia';
  static const ageUnit = 'tahun';
  static const activityLabel = 'Faktor Aktivitas';
  static const stressLabel = 'Faktor Stress';
  static const tempLabel = 'Suhu Tubuh';
  static const tempUnit = '°C';
}

const _kBrandGreen = Color(0xFF009444);
const _kMaleColor = Color(0xFF2563EB); // Biru untuk Pria
const _kFemaleColor = Color(0xFFDB2777); // Pink untuk Wanita

// Kelas pembantu untuk menampung hasil kalkulasi per gender
class _GenderCalcResult {
  final BmiResult bmiResult;
  final double bbi;
  final double bmrHarris;
  final double bmrMifflin;
  final TdeeResult tdeeResult;

  _GenderCalcResult({
    required this.bmiResult,
    required this.bbi,
    required this.bmrHarris,
    required this.bmrMifflin,
    required this.tdeeResult,
  });
}

class AdultQuickCalcPage extends StatefulWidget {
  const AdultQuickCalcPage({super.key});

  @override
  State<AdultQuickCalcPage> createState() => _AdultQuickCalcPageState();
}

class _AdultQuickCalcPageState extends State<AdultQuickCalcPage> {
  // ── Controllers ───────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _activityFactorController = TextEditingController();
  final _stressFactorController = TextEditingController();

  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();

  // ── State ─────────────────────────────────────────────────────────────────
  _GenderCalcResult? _maleResult;
  _GenderCalcResult? _femaleResult;

  bool get _isFeverSelected =>
      _stressFactorController.text == BmrTdeeCalculatorService.feverKey;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _temperatureController.dispose();
    _activityFactorController.dispose();
    _stressFactorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────────────────────────
  void _calculateAll() {
    if (!_formKey.currentState!.validate()) return;

    final double weight = double.parse(_weightController.text);
    final double height = double.parse(_heightController.text);
    final int age = int.parse(_ageController.text);
    final double temp =
        double.tryParse(_temperatureController.text) ??
        BmrTdeeCalculatorService.normalBodyTemperature;

    final activity = _activityFactorController.text;
    final stress = _stressFactorController.text;

    // Kalkulasi General (Sama untuk pria & wanita)
    final bmiRes = BmiCalculatorService.calculateAndClassify(
      weightKg: weight,
      heightCm: height,
    );

    setState(() {
      // 1. Kalkulasi Pria
      _maleResult = _GenderCalcResult(
        bmiResult: bmiRes,
        bbi: BbiCalculatorService.calculateAdult(
          heightCm: height,
          isMale: true,
        ),
        bmrHarris: BmrTdeeCalculatorService.calculateBmrByFormula(
          weightKg: weight,
          heightCm: height,
          ageYears: age,
          isMale: true,
          formula: BmrTdeeCalculatorService.formulaHarris,
        ),
        bmrMifflin: BmrTdeeCalculatorService.calculateBmrByFormula(
          weightKg: weight,
          heightCm: height,
          ageYears: age,
          isMale: true,
          formula: BmrTdeeCalculatorService.formulaMifflin,
        ),
        tdeeResult: BmrTdeeCalculatorService.calculateTdee(
          weightKg: weight,
          heightCm: height,
          ageYears: age,
          isMale: true,
          activityCondition: activity,
          stressCondition: stress,
          bodyTemperatureC: temp,
        ),
      );

      // 2. Kalkulasi Wanita
      _femaleResult = _GenderCalcResult(
        bmiResult: bmiRes,
        bbi: BbiCalculatorService.calculateAdult(
          heightCm: height,
          isMale: false,
        ),
        bmrHarris: BmrTdeeCalculatorService.calculateBmrByFormula(
          weightKg: weight,
          heightCm: height,
          ageYears: age,
          isMale: false,
          formula: BmrTdeeCalculatorService.formulaHarris,
        ),
        bmrMifflin: BmrTdeeCalculatorService.calculateBmrByFormula(
          weightKg: weight,
          heightCm: height,
          ageYears: age,
          isMale: false,
          formula: BmrTdeeCalculatorService.formulaMifflin,
        ),
        tdeeResult: BmrTdeeCalculatorService.calculateTdee(
          weightKg: weight,
          heightCm: height,
          ageYears: age,
          isMale: false,
          activityCondition: activity,
          stressCondition: stress,
          bodyTemperatureC: temp,
        ),
      );
    });

    _scrollToResult();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _ageController.clear();
      _temperatureController.clear();
      _activityFactorController.clear();
      _stressFactorController.clear();
      _maleResult = null;
      _femaleResult = null;
    });
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultSectionKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ── Build UI ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.sizeOf(context).width;
    final double hPad = sw * 0.04;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: _Str.appBarTitle,
        subtitle: _Str.appBarSubtitle,
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: hPad),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _Str.sectionTitle,
                    style: TextStyle(
                      fontSize: _responsiveFont(sw, base: 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: sw * 0.05),

                  // ── Inputs ─────────────────────────────────────────────
                  ResponsiveNumberField(
                    widgetKey: _Keys.weightField,
                    controller: _weightController,
                    label: _Str.weightLabel,
                    prefixIcon: const Icon(Icons.monitor_weight),
                    suffixText: _Str.weightUnit,
                    semanticLabel: 'Input Berat Badan',
                  ),
                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey: _Keys.heightField,
                    controller: _heightController,
                    label: _Str.heightLabel,
                    prefixIcon: const Icon(Icons.height),
                    suffixText: _Str.heightUnit,
                    semanticLabel: 'Input Tinggi Badan',
                  ),
                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey: _Keys.ageField,
                    controller: _ageController,
                    label: _Str.ageLabel,
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixText: _Str.ageUnit,
                    semanticLabel: 'Input Usia',
                    isInteger: true,
                    maxLength: 3,
                  ),
                  SizedBox(height: sw * 0.04),

                  _buildDropdown(
                    widgetKey: _Keys.activityDropdown,
                    controller: _activityFactorController,
                    label: _Str.activityLabel,
                    prefixIcon: const Icon(Icons.directions_run),
                    items: BmrTdeeCalculatorService.activityFactors.keys
                        .toList(),
                    itemAsString: (String key) {
                      final value =
                          BmrTdeeCalculatorService.activityFactors[key];
                      // Menampilkan format: Nama Aktivitas (1.550)
                      return '$key (${value?.toStringAsFixed(3)})';
                    },
                  ),
                  SizedBox(height: sw * 0.04),

                  _buildDropdown(
                    widgetKey: _Keys.stressDropdown,
                    controller: _stressFactorController,
                    label: _Str.stressLabel,
                    prefixIcon: const Icon(Icons.healing),
                    items: BmrTdeeCalculatorService.stressFactors.keys.toList(),
                    itemAsString: (String key) {
                      final value = BmrTdeeCalculatorService.stressFactors[key];
                      // Khusus demam kita beri tanda tambah karena dia multiplier tambahan
                      if (key == BmrTdeeCalculatorService.feverKey) {
                        return '$key (+${value?.toStringAsFixed(2)})';
                      }
                      // Menampilkan format: Nama Stres (1.20)
                      return '$key (${value?.toStringAsFixed(2)})';
                    },
                    onChanged: (String? value) {
                      setState(() {
                        _stressFactorController.text = value ?? '';
                        if (value != BmrTdeeCalculatorService.feverKey) {
                          _temperatureController.clear();
                        }
                      });
                    },
                  ),

                  if (_isFeverSelected) ...[
                    SizedBox(height: sw * 0.04),
                    ResponsiveNumberField(
                      widgetKey: _Keys.tempField,
                      controller: _temperatureController,
                      label: _Str.tempLabel,
                      prefixIcon: const Icon(Icons.thermostat),
                      suffixText: _Str.tempUnit,
                      semanticLabel: 'Input Suhu Tubuh',
                    ),
                  ],

                  SizedBox(height: sw * 0.08),

                  // ── Action Buttons ─────────────────────────────────────
                  FormActionButtons(
                    key: _Keys.btnReset,
                    onReset: _resetForm,
                    onSubmit: _calculateAll,
                    resetButtonColor: Colors.white,
                    resetForegroundColor: _kBrandGreen,
                    submitIcon: const Icon(Icons.calculate, color: Colors.white),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Results Section ────────────────────────────────────
                  if (_maleResult != null && _femaleResult != null) ...[
                    SizedBox(key: _resultSectionKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.04),

                    // Hasil Pria
                    _buildGenderResultCard(
                      context: context,
                      title: 'PRIA',
                      icon: Icons.male,
                      color: _kMaleColor,
                      result: _maleResult!,
                    ),
                    SizedBox(height: sw * 0.04),

                    // Hasil Wanita
                    _buildGenderResultCard(
                      context: context,
                      title: 'WANITA',
                      icon: Icons.female,
                      color: _kFemaleColor,
                      result: _femaleResult!,
                    ),
                    SizedBox(height: sw * 0.08),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Widget _buildDropdown({
    required ValueKey<String> widgetKey,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required List<String> items,
    void Function(String?)? onChanged,
    String Function(String)? itemAsString,
  }) {
    return DropdownSearch<String>(
      key: widgetKey,
      popupProps: const PopupProps.menu(
        showSearchBox: false,
        constraints: BoxConstraints(maxHeight: 200),
      ),
      items: items,
      itemAsString: itemAsString,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged:
          onChanged ?? (val) => setState(() => controller.text = val ?? ''),
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (v) =>
          (v == null || v.isEmpty) ? '$label harus dipilih' : null,
    );
  }

  Widget _buildGenderResultCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Color color,
    required _GenderCalcResult result,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildResultRow(
                  'IMT (BMI)',
                  '${result.bmiResult.bmi.toStringAsFixed(1)} (${result.bmiResult.categoryLabel})',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'Berat Badan Ideal',
                  '${result.bbi.toStringAsFixed(1)} kg',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'BMR (Harris-Benedict)',
                  '${result.bmrHarris.toStringAsFixed(0)} kkal/hari',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'BMR (Mifflin-St Jeor)',
                  '${result.bmrMifflin.toStringAsFixed(0)} kkal/hari',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'TDEE (Total Energi)',
                  '${result.tdeeResult.tdee.toStringAsFixed(0)} kkal/hari',
                  isHighlight: true,
                  color: color,
                ),

                const Divider(height: 16, thickness: 2),

                // --- SECTION MAKRONUTRIEN ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kebutuhan Makronutrien:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildResultRow(
                  'Karbohidrat (60%)',
                  '${result.tdeeResult.carbsGram.toStringAsFixed(0)} g/hari',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Lemak (25%)',
                  '${result.tdeeResult.fatGram.toStringAsFixed(0)} g/hari',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Protein (15%)',
                  '${result.tdeeResult.proteinGram.toStringAsFixed(0)} g/hari',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? (color ?? Colors.black87) : Colors.black54,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: isHighlight ? (color ?? Colors.black87) : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  double _responsiveFont(double sw, {required double base}) {
    if (sw <= 360) return base * 0.90;
    if (sw >= 600) return base * 1.20;
    return base;
  }
}
