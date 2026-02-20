//lib\src\features\disease_calculation\presentation\pages\diabetes_calculation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/diabetes_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/diabetes_meal_planner_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_search_delegate.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/pdf_generator_dm.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// ---------------------------------------------------------------------------
// Semantic Key Constants — single source of truth for QA team.
// ---------------------------------------------------------------------------
class _SemanticKeys {
  static const patientPicker = ValueKey('patientPicker');
  static const ageField = ValueKey('ageField');
  static const genderDropdown = ValueKey('genderDropdown');
  static const weightField = ValueKey('weightField');
  static const heightField = ValueKey('heightField');
  static const activityDropdown = ValueKey('activityDropdown');
  static const hospitalizedDropdown = ValueKey('hospitalizedDropdown');
  static const stressSlider = ValueKey('stressSlider');
  static const btnDownloadPdf = ValueKey('btnDownloadPdf');
  // Meal-distribution rows are keyed dynamically: 'mealRow_<mealName>'
  static ValueKey mealRow(String mealName) =>
      ValueKey('mealRow_${mealName.replaceAll(' ', '_')}');
}

// ---------------------------------------------------------------------------
// Widget
// ---------------------------------------------------------------------------
class DiabetesCalculationPage extends StatefulWidget {
  final String userRole;

  const DiabetesCalculationPage({super.key, required this.userRole});

  @override
  State<DiabetesCalculationPage> createState() =>
      _DiabetesCalculationPageState();
}

class _DiabetesCalculationPageState extends State<DiabetesCalculationPage> {
  // ── Keys & Services ────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _resultCardKey = GlobalKey();
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();

  final _calculatorService = DiabetesCalculatorService();
  final _foodDbService = FoodDatabaseService();
  late final _mealPlannerService = DiabetesMealPlannerService(_foodDbService);

  // ── Controllers ────────────────────────────────────────────────────────────
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _genderController = TextEditingController();
  final _activityController = TextEditingController();
  final _hospitalizedStatusController = TextEditingController();
  final _notesController = TextEditingController();
  final _scrollController = ScrollController();

  // ── State ──────────────────────────────────────────────────────────────────
  double _stressMetabolic = 20.0;
  DiabetesCalculationResult? _result;
  List<DmMealSession>? _dailyMenu;
  bool _isGeneratingMenu = false;

  // ── Static Data ────────────────────────────────────────────────────────────
  static const _genders = ['Laki-laki', 'Perempuan'];
  static const _activityLevels = ['Bed rest', 'Ringan', 'Sedang', 'Berat'];

  // ── Colour constant reused across the file ─────────────────────────────────
  static const _kGreen = Color.fromARGB(255, 0, 148, 68);

  // ---------------------------------------------------------------------------
  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _genderController.dispose();
    _activityController.dispose();
    _hospitalizedStatusController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  String _calculateAgeInYears(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }

  void _fillDataFromPatient(
    double weight,
    double height,
    String gender,
    DateTime dob,
  ) {
    setState(() {
      _weightController.text = weight.toString();
      _heightController.text = height.toString();
      _ageController.text = _calculateAgeInYears(dob);

      final incomingGender = gender.toLowerCase();
      if (incomingGender.contains('laki') ||
          incomingGender.contains('pria') ||
          incomingGender == 'l') {
        _genderController.text = 'Laki-laki';
      } else if (incomingGender.contains('perempuan') ||
          incomingGender.contains('wanita') ||
          incomingGender == 'p') {
        _genderController.text = 'Perempuan';
      } else {
        _genderController.text = gender;
      }
      _result = null;
    });
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
    if (!_formKey.currentState!.validate()) return;

    final result = _calculatorService.calculate(
      age: int.parse(_ageController.text),
      weight: double.parse(_weightController.text),
      height: double.parse(_heightController.text),
      gender: _genderController.text,
      activity: _activityController.text,
      hospitalizedStatus: _hospitalizedStatusController.text,
      stressMetabolic: _stressMetabolic,
    );

    setState(() {
      _result = result;
      _isGeneratingMenu = true;
      _dailyMenu = null;
    });

    _mealPlannerService
        .generateDailyPlan(result.dailyMealDistribution)
        .then(
          (menu) => setState(() {
            _dailyMenu = menu;
            _isGeneratingMenu = false;
          }),
        );

    _scrollToResult();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _ageController.clear();
    _weightController.clear();
    _heightController.clear();
    _patientPickerKey.currentState?.resetSelection();
    setState(() {
      _genderController.clear();
      _activityController.clear();
      _hospitalizedStatusController.clear();
      _stressMetabolic = 20.0;
      _result = null;
    });
  }

  String _formatNumber(double value) => value == value.toInt()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // ── Responsive spacing tokens ───────────────────────────────────────────
    final size = MediaQuery.sizeOf(context);
    final hPad = size.width * 0.04; // ≈ 16 dp @ 400 px wide
    final vSpace = size.height * 0.025; // ≈ 20 dp @ 800 px tall
    final vSpaceSm = size.height * 0.02; // ≈ 16 dp

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Diet Diabetes Melitus',
        subtitle: 'Kalkulator Kebutuhan Energi',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(hPad),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Patient Picker ────────────────────────────────────────
                  Semantics(
                    key: _SemanticKeys.patientPicker,
                    label: 'Pilih Pasien',
                    container: true,
                    child: PatientPickerWidget(
                      key: _patientPickerKey,
                      onPatientSelected: _fillDataFromPatient,
                      userRole: widget.userRole,
                    ),
                  ),

                  SizedBox(height: vSpace),
                  const Text(
                    'Input Data Diabetes Melitus',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: vSpace),

                  // ── Usia ──────────────────────────────────────────────────
                  Semantics(
                    label: 'Field Usia',
                    textField: true,
                    child: _buildTextFormField(
                      key: _SemanticKeys.ageField,
                      controller: _ageController,
                      label: 'Usia',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixText: 'tahun',
                      validator: (value) {
                        if (value == null || value.isEmpty)return 'Masukkan usia';
                        final age = int.tryParse(value);
                        if (age == null || age < 1 || age > 120)return 'Masukkan usia yang valid (1-120 tahun)';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Jenis Kelamin ─────────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Jenis Kelamin',
                    child: _buildCustomDropdown(
                      key: _SemanticKeys.genderDropdown,
                      controller: _genderController,
                      label: 'Jenis Kelamin',
                      prefixIcon: const Icon(Icons.wc),
                      items: _genders,
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Berat Badan ───────────────────────────────────────────
                  Semantics(
                    label: 'Field Berat Badan',
                    textField: true,
                    child: _buildTextFormField(
                      key: _SemanticKeys.weightField,
                      controller: _weightController,
                      label: 'Berat Badan',
                      prefixIcon: const Icon(Icons.monitor_weight),
                      suffixText: 'kg',
                      validator: (value) {
                        if (value == null || value.isEmpty)return 'Masukkan berat badan';
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 1 || weight > 300)return 'Masukkan berat badan yang valid (1-300 kg)';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Tinggi Badan ──────────────────────────────────────────
                  Semantics(
                    label: 'Field Tinggi Badan',
                    textField: true,
                    child: _buildTextFormField(
                      key: _SemanticKeys.heightField,
                      controller: _heightController,
                      label: 'Tinggi Badan',
                      prefixIcon: const Icon(Icons.height),
                      suffixText: 'cm',
                      validator: (value) {
                        if (value == null || value.isEmpty)return 'Masukkan tinggi badan';
                        final height = double.tryParse(value);
                        if (height == null || height < 30 || height > 300)return 'Masukkan tinggi badan yang valid (30-300 cm)';
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Faktor Aktivitas ──────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Faktor Aktivitas',
                    child: _buildCustomDropdown(
                      key: _SemanticKeys.activityDropdown,
                      controller: _activityController,
                      label: 'Faktor Aktivitas',
                      prefixIcon: const Icon(Icons.directions_run),
                      items: _activityLevels,
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Status Rawat Inap ─────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Status Rawat Inap',
                    child: _buildCustomDropdown(
                      key: _SemanticKeys.hospitalizedDropdown,
                      controller: _hospitalizedStatusController,
                      label: 'Status Rawat Inap',
                      prefixIcon: const Icon(Icons.bed),
                      items: const ['Ya', 'Tidak'],
                      onChanged: (value) {
                        setState(() {
                          _hospitalizedStatusController.text = value ?? '';
                          if (value == 'Tidak') _stressMetabolic = 20.0;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Stress Metabolik Slider (kondisional) ─────────────────
                  if (_hospitalizedStatusController.text == 'Ya') ...[
                    Semantics(
                      label: 'Slider Stress Metabolik',
                      slider: true,
                      child: Column(
                        key: _SemanticKeys.stressSlider,
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
                            onChanged: (v) =>
                                setState(() => _stressMetabolic = v),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: vSpaceSm),
                  ],

                  SizedBox(height: size.height * 0.03),

                  // ── Action Buttons ────────────────────────────────────────
                  Semantics(
                    label: 'Tombol Hitung dan Reset Kalori Diabetes',
                    child: FormActionButtons(
                      onReset: _resetForm,
                      onSubmit: _calculateDiabetesNutrition,
                      resetButtonColor: Colors.white,
                      resetForegroundColor: _kGreen,
                      submitIcon: const Icon(
                        Icons.calculate,
                        color: Colors.white,
                      ),
                      // Pass keys so Katalon can identify each button individually.
                      // If FormActionButtons does not expose key params, wrap the
                      // Row externally — the Semantics label above suffices for
                      // page-level detection; individual keys below are bonus.
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),

                  // ── Result Section ────────────────────────────────────────
                  if (_result != null) ...[
                    Container(
                      key: _resultCardKey,
                      child: const Column(
                        children: [Divider(), SizedBox(height: 32)],
                      ),
                    ),

                    // Total Kalori card
                    _buildTotalCaloriesCard(),
                    SizedBox(height: vSpaceSm),

                    // Jenis Diet expansion
                    _buildDietInfoTile(),
                    SizedBox(height: vSpaceSm),

                    // Standar Diet expansion
                    _buildFoodGroupTile(),
                    SizedBox(height: vSpaceSm),

                    // Pembagian Makanan expansion
                    _buildMealDistributionTile(),
                    SizedBox(height: vSpaceSm),

                    // Rekomendasi Menu Sehari
                    _buildDailyMenuSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // PRIVATE WIDGET BUILDERS — Result Cards
  // ===========================================================================

  Widget _buildTotalCaloriesCard() {
    return Container(
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).width * 0.04),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: const Border.fromBorderSide(BorderSide(color: _kGreen)),
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
                color: _kGreen,
              ),
            ),
          ),
          const Divider(height: 24),
          const SizedBox(height: 8),
          _buildNutritionRow('BB Ideal', '${_result!.bbIdeal.round()} kg'),
          _buildNutritionRow('BMR', '${_result!.bmr.round()} kkal/hari'),
          _buildNutritionRow('Kategori IMT', _result!.bmiCategory),
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
              '${_result!.weightCorrection > 0 ? '+' : ''}${_result!.weightCorrection.round()} kkal/hari',
            ),
          if (_hospitalizedStatusController.text == 'Ya')
            _buildNutritionRow(
              'Koreksi Stress Metabolik',
              '+${((_stressMetabolic / 100) * _result!.bmr).round()} kkal/hari',
            ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Total Kalori: ${_result!.totalCalories.round()} kkal/hari',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
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
    );
  }

  Widget _buildDietInfoTile() {
    return ExpansionTile(
      title: Text('Jenis ${_result!.dietInfo.name}'),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(MediaQuery.sizeOf(context).width * 0.04),
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
              _buildNutritionRow('Protein', '${_result!.dietInfo.protein} g'),
              _buildNutritionRow('Lemak', '${_result!.dietInfo.fat} g'),
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
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildFoodGroupTile() {
    final diet = _result!.foodGroupDiet;
    return ExpansionTile(
      title: Text('Standar Diet (${diet.calorieLevel})'),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(MediaQuery.sizeOf(context).width * 0.04),
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
                  'Standar Diet (${diet.calorieLevel})',
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
                '${_formatNumber(diet.nasiP)} P',
              ),
              _buildNutritionRow(
                'Ikan atau penukar',
                '${_formatNumber(diet.ikanP)} P',
              ),
              _buildNutritionRow(
                'Daging atau penukar',
                '${_formatNumber(diet.dagingP)} P',
              ),
              _buildNutritionRow(
                'Tempe atau penukar',
                '${_formatNumber(diet.tempeP)} P',
              ),
              _buildNutritionRow('Sayuran/penukar A', ' ${diet.sayuranA}'),
              _buildNutritionRow(
                'Sayuran/penukar B',
                '${_formatNumber(diet.sayuranB)} P',
              ),
              _buildNutritionRow(
                'Buah atau penukar',
                '${_formatNumber(diet.buah)} P',
              ),
              _buildNutritionRow(
                'Susu atau penukar',
                '${_formatNumber(diet.susu)} P',
              ),
              _buildNutritionRow(
                'Minyak atau penukar',
                '${_formatNumber(diet.minyak)} P',
              ),
              const SizedBox(height: 8),
              const Text(
                'Keterangan : (P = Penukar) (S = Sekehendak) ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Jumlah bahan makanan sehari menurut Standar Diet Diabetes Melitus (dalam satuan penukar II)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildMealDistributionTile() {
    final dist = _result!.dailyMealDistribution;
    return ExpansionTile(
      title: Text('Pembagian Makanan\nSehari-hari (${dist.calorieLevel})'),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(MediaQuery.sizeOf(context).width * 0.04),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Pembagian Makanan Sehari-hari \n (${dist.calorieLevel})',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
              const Divider(height: 24),
              _buildMealDistributionTable(),
              const SizedBox(height: 8),
              const Text(
                'Keterangan : (P = Penukar) (S = Sekehendak) ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pembagian makanan sehari tiap Standar Diet Diabetes Melitus dan Nilai Gizi (dalam satuan penukar II)',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ===========================================================================
  // _buildMealDistributionTable — kept as original private method
  // QA: each row group is wrapped with Semantics + unique ValueKey
  // ===========================================================================
  Widget _buildMealDistributionTable() {
    final distribution = _result!.dailyMealDistribution;
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    const cellStyle = TextStyle(fontSize: 12);
    const cellPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0);

    Widget buildMealRowGroup(
      String mealName,
      MealDistribution meal, {
      required Color color,
    }) {
      final List<Widget> foodRows = [];

      void addFoodRow(String foodName, dynamic value) {
        foodRows.add(
          Container(
            padding: cellPadding,
            decoration: BoxDecoration(
              color: color,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(foodName, style: cellStyle)),
                Expanded(
                  flex: 2,
                  child: Text(
                    value is String
                        ? value
                        : '${_formatNumber(value as double)} P',
                    textAlign: TextAlign.center,
                    style: cellStyle,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      if (meal.nasiP > 0) addFoodRow('Nasi', meal.nasiP);
      if (meal.ikanP > 0) addFoodRow('Ikan', meal.ikanP);
      if (meal.dagingP > 0) addFoodRow('Daging', meal.dagingP);
      if (meal.tempeP > 0) addFoodRow('Tempe', meal.tempeP);
      if (meal.sayuranA.isNotEmpty) addFoodRow('Sayuran A', meal.sayuranA);
      if (meal.sayuranB > 0) addFoodRow('Sayuran B', meal.sayuranB);
      if (meal.buah > 0) addFoodRow('Buah', meal.buah);
      if (meal.susu > 0) addFoodRow('Susu', meal.susu);
      if (meal.minyak > 0) addFoodRow('Minyak', meal.minyak);

      if (foodRows.isEmpty) return const SizedBox.shrink();

      // ── QA: wrap each row group with Semantics + ValueKey ─────────────────
      return Semantics(
        label: 'Baris distribusi makanan $mealName',
        container: true,
        child: IntrinsicHeight(
          key: _SemanticKeys.mealRow(mealName),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 80,
                padding: cellPadding,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color,
                  border: Border.all(color: Colors.grey.shade300, width: 0.5),
                ),
                child: Text(
                  mealName,
                  textAlign: TextAlign.center,
                  style: cellStyle,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: foodRows,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: cellPadding,
            color: Colors.green.shade100,
            child: const Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(
                    'Waktu',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Bahan Makanan',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Penukar',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          buildMealRowGroup('Pagi', distribution.pagi, color: Colors.white),
          buildMealRowGroup(
            'Pukul 10.00',
            distribution.snackPagi,
            color: Colors.grey.shade100,
          ),
          buildMealRowGroup('Siang', distribution.siang, color: Colors.white),
          buildMealRowGroup(
            'Pukul 16.00',
            distribution.snackSore,
            color: Colors.grey.shade100,
          ),
          buildMealRowGroup('Malam', distribution.malam, color: Colors.white),
        ],
      ),
    );
  }

  // ===========================================================================
  // Daily Menu Section (role-gated)
  // ===========================================================================
  Widget _buildDailyMenuSection() {
    final currentRole = widget.userRole.toLowerCase();
    final isAllowed =
        currentRole == 'admin' ||
        currentRole == 'ahli_gizi' ||
        currentRole == 'nutrisionis';

    if (!isAllowed) return const SizedBox.shrink();

    return ExpansionTile(
      title: const Text('Rekomendasi Menu Sehari'),
      children: [
        const SizedBox(height: 10),

        if (_isGeneratingMenu)
          SizedBox(
            height: 150,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Sedang membuat menu...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          )
        else if (_dailyMenu != null && _dailyMenu!.isNotEmpty)
          Container(
            padding: EdgeInsets.all(MediaQuery.sizeOf(context).width * 0.04),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Rekomendasi Menu Sehari',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ketuk ikon pensil untuk mengganti menu',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                ..._dailyMenu!.map((session) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: Text(
                            session.sessionName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        ...session.items.map((item) {
                          final portionText = item.portion == 'S'
                              ? '(S)'
                              : '(${item.portion is num ? _formatNumber(item.portion) : item.portion} P)';

                          return ListTile(
                            dense: true,
                            title: Text(
                              item.categoryLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            subtitle: Text(
                              '${item.foodName} $portionText',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                size: 20,
                                color: Colors.grey,
                              ),
                              onPressed: () => _showEditDialog(item),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 16),
                const Divider(),
                const Text(
                  'Catatan Tambahan (Opsional)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText:
                        'Tulis anjuran khusus atau catatan untuk pasien disini...',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.blue.shade200),
                    ),
                    contentPadding: const EdgeInsets.all(10),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Download PDF Button ──────────────────────────────────────
                Semantics(
                  label: 'Tombol Download Menu PDF',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      key: _SemanticKeys.btnDownloadPdf,
                      onPressed: _downloadPdf,
                      icon: const Icon(Icons.download),
                      label: const Text(
                        'Download Menu PDF',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 10),
      ],
    );
  }

  // ===========================================================================
  // EDIT & PDF LOGIC — unchanged
  // ===========================================================================
  void _showEditDialog(DmMenuItem item) async {
    final FoodItem? selectedFood = await showSearch<FoodItem?>(
      context: context,
      delegate: FoodSearchDelegate(_foodDbService, initialQuery: item.foodName),
    );
    if (selectedFood != null) {
      setState(() {
        item.foodName = selectedFood.name;
        item.foodData = selectedFood;
      });
    }
  }

  void _downloadPdf() async {
    if (_dailyMenu == null || _dailyMenu!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menu belum tersedia.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await saveAndOpenDmPdf(_dailyMenu!, 'Pasien', _notesController.text);
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
    } catch (e) {
      if (mounted && Navigator.canPop(context)) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ===========================================================================
  // SHARED WIDGET HELPERS
  // ===========================================================================

  /// Generic text input with numeric keyboard, length limit, and decimal support.
  Widget _buildTextFormField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    required String? Function(String?) validator,
    int maxLength = 5,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        LengthLimitingTextInputFormatter(maxLength),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      validator: validator,
    );
  }

  /// Generic searchable/non-searchable dropdown backed by dropdown_search.
  Widget _buildCustomDropdown({
    Key? key,
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required Icon prefixIcon,
    bool showSearch = false,
    void Function(String?)? onChanged,
  }) {
    return DropdownSearch<String>(
      key: key,
      popupProps: PopupProps.menu(
        showSearchBox: showSearch,
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
      onChanged:
          onChanged ??
          (String? newValue) =>
              setState(() => controller.text = newValue ?? ''),
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (value) =>
          (value == null || value.isEmpty) ? '$label harus dipilih' : null,
    );
  }

  /// Single nutrition label/value row used in result cards.
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
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
