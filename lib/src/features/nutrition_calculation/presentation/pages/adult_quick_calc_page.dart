// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\nutrition_calculation\presentation\pages\adult_quick_calc_page.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/responsive_number_field.dart';

// Service Imports
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bmi_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bmr_tdee_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bbi_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/services/diabetes_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/services/kidney_calculator_service.dart'; // Import Service Ginjal
import 'package:aplikasi_diagnosa_gizi/src/features/reference/data/models/reference_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/widgets/reference_widgets.dart';

class _Keys {
  const _Keys._();
  static const weightField = ValueKey('qc_weightField');
  static const heightField = ValueKey('qc_heightField');
  static const ageField = ValueKey('qc_ageField');
  static const activityDropdown = ValueKey('qc_activityDropdown');
  static const stressDropdown = ValueKey('qc_stressDropdown');
  static const tempField = ValueKey('qc_tempField');
  static const btnReset = ValueKey('qc_btnReset');

  // Tambahan Key untuk DM
  static const dmActivityDropdown = ValueKey('qc_dmActivityDropdown');
  static const hospitalizedDropdown = ValueKey('qc_hospitalizedDropdown');
  static const stressSlider = ValueKey('qc_stressSlider');

  // Tambahan Key untuk Ginjal Kronis
  static const ckdDialysisDropdown = ValueKey('qc_ckdDialysisDropdown');
  static const ckdProteinFactorDropdown = ValueKey(
    'qc_ckdProteinFactorDropdown',
  );
}

class _Str {
  const _Str._();
  static const appBarTitle = 'Dewasa';
  static const appBarSubtitle = 'Hitung kebutuhan gizi (18+ Tahun)';
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

  // Tambahan Label untuk DM
  static const dmSectionTitle = 'Input Tambahan: Diabetes Melitus';
  static const dmActivityLabel = 'Faktor Aktivitas (Khusus DM)';
  static const hospitalizedLabel = 'Status Rawat Inap (DM)';

  // Tambahan Label untuk Ginjal
  static const ckdSectionTitle = 'Input Tambahan: Ginjal Kronis';
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
  final dynamic dmResult;
  final dynamic ckdResult; // Menampung hasil Ginjal Kronis

  _GenderCalcResult({
    required this.bmiResult,
    required this.bbi,
    required this.bmrHarris,
    required this.bmrMifflin,
    required this.tdeeResult,
    required this.dmResult,
    required this.ckdResult,
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

  final _activityFactorController = TextEditingController(
    text: 'Sangat Jarang',
  );
  final _stressFactorController = TextEditingController(text: 'Normal');

  // Controllers Tambahan DM
  final _dmActivityController = TextEditingController(text: 'Ringan');
  final _hospitalizedStatusController = TextEditingController(text: 'Tidak');

  // Controllers Tambahan Ginjal
  final _ckdDialysisController = TextEditingController(text: 'Tidak');
  final _ckdProteinFactorController = TextEditingController(
    text: '0.6 (Rendah)',
  );

  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();

  // Services
  final _dmCalculatorService = DiabetesCalculatorService();
  final _ckdCalculatorService = KidneyCalculatorService();

  // ── State ─────────────────────────────────────────────────────────────────
  _GenderCalcResult? _maleResult;
  _GenderCalcResult? _femaleResult;
  double _stressMetabolic = 20.0;

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
    _dmActivityController.dispose();
    _hospitalizedStatusController.dispose();
    _ckdDialysisController.dispose();
    _ckdProteinFactorController.dispose();
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

    // Variabel kalkulasi Ginjal
    final bool isDialysis = _ckdDialysisController.text == 'Ya';
    final double? proteinFactor = isDialysis
        ? null
        : double.tryParse(_ckdProteinFactorController.text.split(' ')[0]);

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
        dmResult: _dmCalculatorService.calculate(
          age: age,
          weight: weight,
          height: height,
          gender: 'Laki-laki',
          activity: _dmActivityController.text,
          hospitalizedStatus: _hospitalizedStatusController.text,
          stressMetabolic: _stressMetabolic,
        ),
        ckdResult: _ckdCalculatorService.calculate(
          height: height,
          isDialysis: isDialysis,
          gender: 'Laki-laki',
          age: age,
          proteinFactor: proteinFactor,
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
        dmResult: _dmCalculatorService.calculate(
          age: age,
          weight: weight,
          height: height,
          gender: 'Perempuan',
          activity: _dmActivityController.text,
          hospitalizedStatus: _hospitalizedStatusController.text,
          stressMetabolic: _stressMetabolic,
        ),
        ckdResult: _ckdCalculatorService.calculate(
          height: height,
          isDialysis: isDialysis,
          gender: 'Perempuan',
          age: age,
          proteinFactor: proteinFactor,
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

      _activityFactorController.text = 'Sangat Jarang';
      _stressFactorController.text = 'Normal';
      _dmActivityController.text = 'Ringan';
      _hospitalizedStatusController.text = 'Tidak';
      _ckdDialysisController.text = 'Tidak';
      _ckdProteinFactorController.text = '0.6 (Rendah)';

      _stressMetabolic = 20.0;
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

                  // ── Inputs Umum ────────────────────────────────────────
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
                      if (key == BmrTdeeCalculatorService.feverKey) {
                        return '$key (+${value?.toStringAsFixed(2)})';
                      }
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

                  // ── Inputs Diabetes Melitus ────────────────────────────
                  SizedBox(height: sw * 0.08),

                  // Gunakan Theme untuk menghilangkan garis border bawaan ExpansionTile
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: Column(
                      children: [
                        // ── TILE DIABETES MELITUS ──────────────────────────────
                        Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              _Str.dmSectionTitle,
                              style: TextStyle(
                                fontSize: _responsiveFont(sw, base: 16),
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                            leading: Icon(
                              Icons.bloodtype,
                              color: Colors.red[400],
                            ),
                            childrenPadding: EdgeInsets.fromLTRB(
                              sw * 0.04,
                              0,
                              sw * 0.04,
                              sw * 0.04,
                            ),
                            children: [
                              SizedBox(height: 10),
                              _buildDropdown(
                                widgetKey: _Keys.dmActivityDropdown,
                                controller: _dmActivityController,
                                label: _Str.dmActivityLabel,
                                prefixIcon: const Icon(Icons.directions_walk),
                                items: const [
                                  'Bed rest',
                                  'Ringan',
                                  'Sedang',
                                  'Berat',
                                ],
                                itemAsString: (String key) {
                                  double val = 0.0;
                                  switch (key) {
                                    case 'Bed rest':
                                      val = 0.1;
                                      break;
                                    case 'Ringan':
                                      val = 0.2;
                                      break;
                                    case 'Sedang':
                                      val = 0.3;
                                      break;
                                    case 'Berat':
                                      val = 0.4;
                                      break;
                                  }
                                  return '$key (+${(val * 100).toStringAsFixed(0)}%)';
                                },
                              ),
                              SizedBox(height: sw * 0.04),

                              _buildDropdown(
                                widgetKey: _Keys.hospitalizedDropdown,
                                controller: _hospitalizedStatusController,
                                label: _Str.hospitalizedLabel,
                                prefixIcon: const Icon(Icons.local_hospital),
                                items: const ['Ya', 'Tidak'],
                                menuHeight: 120,
                                onChanged: (String? value) {
                                  setState(() {
                                    _hospitalizedStatusController.text =
                                        value ?? 'Tidak';
                                    if (value == 'Tidak') {
                                      _stressMetabolic = 20.0;
                                    }
                                  });
                                },
                              ),

                              if (_hospitalizedStatusController.text ==
                                  'Ya') ...[
                                SizedBox(height: sw * 0.04),
                                Column(
                                  key: _Keys.stressSlider,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Stress Metabolik: ${_stressMetabolic.round()}%',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Slider(
                                      value: _stressMetabolic,
                                      min: 10,
                                      max: 40,
                                      divisions: 30,
                                      label: '${_stressMetabolic.round()}%',
                                      onChanged: (v) =>
                                          setState(() => _stressMetabolic = v),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),

                        SizedBox(height: sw * 0.04),

                        // ── TILE GINJAL KRONIS ─────────────────────────────────
                        Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          child: ExpansionTile(
                            title: Text(
                              _Str.ckdSectionTitle,
                              style: TextStyle(
                                fontSize: _responsiveFont(sw, base: 16),
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey[800],
                              ),
                            ),
                            leading: Icon(
                              Icons.water_drop,
                              color: Colors.blue[400],
                            ),
                            childrenPadding: EdgeInsets.fromLTRB(
                              sw * 0.04,
                              0,
                              sw * 0.04,
                              sw * 0.04,
                            ),
                            children: [
                              SizedBox(height: 10),
                              _buildDropdown(
                                widgetKey: _Keys.ckdDialysisDropdown,
                                controller: _ckdDialysisController,
                                label: 'Status Cuci Darah',
                                prefixIcon: const Icon(
                                  Icons.bloodtype_outlined,
                                ),
                                items: const ['Ya', 'Tidak'],
                                menuHeight: 120,
                                onChanged: (String? value) {
                                  setState(() {
                                    _ckdDialysisController.text =
                                        value ?? 'Tidak';
                                  });
                                },
                              ),

                              if (_ckdDialysisController.text == 'Tidak') ...[
                                SizedBox(height: sw * 0.04),
                                _buildDropdown(
                                  widgetKey: _Keys.ckdProteinFactorDropdown,
                                  controller: _ckdProteinFactorController,
                                  label: 'Faktor Kebutuhan Protein',
                                  prefixIcon: const Icon(Icons.rule),
                                  items: const [
                                    '0.6 (Rendah)',
                                    '0.7 (Sedang)',
                                    '0.8 (Tinggi)',
                                  ],
                                  menuHeight: 170,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Action Buttons ─────────────────────────────────────
                  FormActionButtons(
                    key: _Keys.btnReset,
                    onReset: _resetForm,
                    onSubmit: _calculateAll,
                    resetButtonColor: Colors.white,
                    resetForegroundColor: _kBrandGreen,
                    submitIcon: const Icon(
                      Icons.calculate,
                      color: Colors.white,
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Results Section ────────────────────────────────────
                  if (_maleResult != null && _femaleResult != null) ...[
                    SizedBox(key: _resultSectionKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.04),

                    _buildGenderResultCard(
                      context: context,
                      title: 'PRIA',
                      icon: Icons.male,
                      color: _kMaleColor,
                      result: _maleResult!,
                    ),
                    SizedBox(height: sw * 0.04),

                    _buildGenderResultCard(
                      context: context,
                      title: 'WANITA',
                      icon: Icons.female,
                      color: _kFemaleColor,
                      result: _femaleResult!,
                    ),
                    SizedBox(height: sw * 0.08),
                    const Divider(thickness: 2),
                    SizedBox(height: sw * 0.04),
                    Text(
                      'Referensi Formula',
                      style: TextStyle(
                        fontSize: _responsiveFont(sw, base: 18),
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    SizedBox(height: sw * 0.04),

                    // Menampilkan formula terkait orang dewasa (menyaring formula anak)
                    ...ReferenceData.formulas
                        .where((formula) => !formula.id.contains('_anak'))
                        .map(
                          (formula) => FormulaTile(
                            key: ValueKey('qc_${formula.id}'),
                            semanticId: 'qc_${formula.id}',
                            title: formula.title,
                            formulaName: formula.formulaName,
                            formulaContent: formula.formulaContent,
                            note: formula.note,
                          ),
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
    double? menuHeight,
  }) {
    return DropdownSearch<String>(
      key: widgetKey,
      popupProps: PopupProps.menu(
        showSearchBox: false,
        constraints: BoxConstraints(maxHeight: menuHeight ?? 200),
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
    final double bmrDm = result.dmResult.bmr;
    final double stressMetabolicCorrection =
        result.dmResult.totalCalories -
        bmrDm -
        result.dmResult.activityCorrection -
        result.dmResult.weightCorrection +
        result.dmResult.ageCorrection;

    // --- Perhitungan Makronutrien Ginjal Kronis (CKD) ---
    // Energi menggunakan nilai BMR CKD (di service sudah dihitung 30-35 kkal/kg BBI)
    final double ckdEnergi = result.ckdResult.bmr;

    // Protein menggunakan proteinNeeds (Faktor 0.6/0.7/0.8/1.2 x BBI) dari hasil service
    final double ckdProtein = result.ckdResult.proteinNeeds;

    // Lemak = 25% dari Total Energi dibagi 9 (kkal/g)
    final double ckdLemak = (0.25 * ckdEnergi) / 9;

    // Karbohidrat = (Total Energi - Energi Protein - Energi Lemak) dibagi 4 (kkal/g)
    final double ckdKarbo = (ckdEnergi - (ckdProtein * 4) - (ckdLemak * 9)) / 4;

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
                // --- SECTION MAKRONUTRIEN (UMUM) ---
                _buildResultRow(
                  'IMT (BMI)',
                  '${result.bmiResult.bmi.toStringAsFixed(2)} (${result.bmiResult.categoryLabel})',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'Berat Badan Ideal',
                  '${result.bbi.toStringAsFixed(1)} kg',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'TDEE (Total Energi)',
                  '${result.tdeeResult.tdee.toStringAsFixed(1)} kkal/hari',
                  isHighlight: true,
                  color: color,
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'Protein (15%)',
                  '${result.tdeeResult.proteinGram.toStringAsFixed(1)} g/hari',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'Lemak (25%)',
                  '${result.tdeeResult.fatGram.toStringAsFixed(1)} g/hari',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'Karbohidrat (60%)',
                  '${result.tdeeResult.carbsGram.toStringAsFixed(1)} g/hari',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'BMR (Harris-Benedict)',
                  '${result.bmrHarris.toStringAsFixed(2)} kkal/hari',
                ),
                const Divider(height: 16),
                _buildResultRow(
                  'BMR (Mifflin-St Jeor)',
                  '${result.bmrMifflin.toStringAsFixed(2)} kkal/hari',
                ),

                const Divider(height: 16, thickness: 2),

                // --- SECTION DIABETES MELITUS ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kebutuhan Diabetes Melitus (DM):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _buildResultRow(
                  title == 'PRIA' ? 'BMR DM (BBI x 30)' : 'BMR DM (BBI x 25)',
                  '${bmrDm.toStringAsFixed(0)} kkal/hari',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Protein DM',
                  '${result.dmResult.dietInfo.protein.toStringAsFixed(0)} g/hari',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Lemak DM',
                  '${result.dmResult.dietInfo.fat.toStringAsFixed(0)} g/hari',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Karbohidrat DM',
                  '${result.dmResult.dietInfo.carbohydrate.toStringAsFixed(0)} g/hari',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Koreksi Aktivitas',
                  '${result.dmResult.activityCorrection >= 0 ? '+' : ''}${result.dmResult.activityCorrection.toStringAsFixed(0)} kkal',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Koreksi Berat Badan',
                  '${result.dmResult.weightCorrection > 0 ? '+' : ''}${result.dmResult.weightCorrection.toStringAsFixed(0)} kkal',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Koreksi Usia',
                  '${result.dmResult.ageCorrection > 0 ? '-' : ''}${result.dmResult.ageCorrection.toStringAsFixed(0)} kkal',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Koreksi Stress Metabolik',
                  '${stressMetabolicCorrection > 0 ? '+' : ''}${stressMetabolicCorrection.toStringAsFixed(0)} kkal',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Total Kalori DM',
                  '${result.dmResult.totalCalories.toStringAsFixed(0)} kkal/hari',
                  isHighlight: true,
                  color: color,
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Rekomendasi Diet',
                  '${result.dmResult.dietInfo.name}',
                ),

                const Divider(height: 16, thickness: 2),

                // --- SECTION GINJAL KRONIS ---
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Kebutuhan Ginjal Kronis (CKD):',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Makronutrien spesifik CKD (Bila objeknya tidak null)
                if (result.ckdResult.nutritionInfo != null) ...[
                  _buildResultRow(
                    'BMR (Ginjal)',
                    '${ckdEnergi.toStringAsFixed(0)} kkal/hari',
                  ),
                  const Divider(height: 8),
                ],
                _buildResultRow(
                  'Protein CKD',
                  '${ckdProtein.toStringAsFixed(1)} g/hari',
                  isHighlight: true,
                  color: color,
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Lemak CKD',
                  '${ckdLemak.toStringAsFixed(0)} g/hari',
                ),
                const Divider(height: 8),
                _buildResultRow(
                  'Karbohidrat CKD',
                  '${ckdKarbo.toStringAsFixed(0)} g/hari',
                ),
                const Divider(height: 8),

                _buildResultRow(
                  'Rekomendasi Diet',
                  'Diet Protein ${result.ckdResult.recommendedDiet}g',
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
          flex: 3,
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
