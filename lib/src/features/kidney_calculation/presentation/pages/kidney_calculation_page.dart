// lib/src/features/kidney_calculation/presentation/pages/kidney_calculation_page.dart

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ── Shared widgets ─────────────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// ── Data models ────────────────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_diet_nutrition_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_menu_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_standard_food_model.dart';

// ── Services ───────────────────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/services/kidney_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/services/kidney_dynamic_menu_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/services/kidney_meal_planner_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/food_search_delegate.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart' as db;
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/expert_system_engine.dart';

// ── Widgets modul ginjal ───────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/presentation/widgets/kidney_result_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/presentation/widgets/kidney_nutrition_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/presentation/widgets/kidney_meal_plan_table.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/presentation/widgets/kidney_dynamic_menu_section.dart';

class KidneyCalculationPage extends StatefulWidget {
  final String userRole;

  const KidneyCalculationPage({super.key, required this.userRole});

  @override
  State<KidneyCalculationPage> createState() => _KidneyCalculationPageState();
}

class _KidneyCalculationPageState extends State<KidneyCalculationPage> {
  // ── Keys & Services ────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();
  final GlobalKey _resultCardKey = GlobalKey();

  final _calculatorService = KidneyCalculatorService();
  late final KidneyDynamicMenuService _menuGenerator;

  // ── Controllers ────────────────────────────────────────────────────────────
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  late final TextEditingController _dialysisController;
  late final TextEditingController _genderController;
  late final TextEditingController _proteinFactorController;
  late final TextEditingController _currentWeightController;
  late final ScrollController _scrollController;

  // ── State ──────────────────────────────────────────────────────────────────
  bool _isHighPotassium = false;
  KidneyDietResult? _result;
  List<KidneyStandardFoodItem>? _mealPlan;
  List<KidneyMealSession>? _generatedMenu;
  bool _isGeneratingMenu = false;

  // ---------------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _menuGenerator = KidneyDynamicMenuService(FoodDatabaseService(), ExpertSystemEngine());
    _heightController        = TextEditingController();
    _ageController           = TextEditingController();
    _dialysisController      = TextEditingController();
    _genderController        = TextEditingController();
    _proteinFactorController = TextEditingController(text: '0.6 (Rendah)');
    _currentWeightController = TextEditingController();
    _scrollController        = ScrollController();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _ageController.dispose();
    _dialysisController.dispose();
    _genderController.dispose();
    _proteinFactorController.dispose();
    _currentWeightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Logic ──────────────────────────────────────────────────────────────────

  void _calculateAndGenerateMenu() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();

    final height             = double.tryParse(_heightController.text) ?? 0;
    final age                = int.tryParse(_ageController.text) ?? 0;
    final isDialysis         = _dialysisController.text == 'Ya';
    final proteinFactorValue = _proteinFactorController.text.split(' ')[0];
    final proteinFactor      = double.tryParse(proteinFactorValue);

    final result = _calculatorService.calculate(
      height: height,
      isDialysis: isDialysis,
      gender: _genderController.text,
      proteinFactor: isDialysis ? null : proteinFactor,
      age: age,
    );

    final mealPlan = KidneyMealPlans.getPlan(result.recommendedDiet);

    setState(() {
      _result           = result;
      _mealPlan         = mealPlan;
      _generatedMenu    = null;
      _isGeneratingMenu = true;
    });

    _scrollToResult();

    try {
      final dynamicMenu = await _menuGenerator.generateDailyMenu(
        result.recommendedDiet,
        isHighPotassium: _isHighPotassium,
        totalCalories: result.bmr,
      );
      if (mounted) {
        setState(() {
          _generatedMenu    = dynamicMenu;
          _isGeneratingMenu = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingMenu = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat menu otomatis: $e')),
        );
      }
    }
  }

  Future<void> _editMenuItem(
    KidneyMenuItem item,
    int sessionIndex,
    int itemIndex,
  ) async {
    final db.FoodItem? selectedFood = await showSearch<db.FoodItem?>(
      context: context,
      delegate: FoodSearchDelegate(
        FoodDatabaseService(),
        initialQuery: item.foodName,
      ),
    );

    if (selectedFood != null && _generatedMenu != null) {
      setState(() {
        final oldItem = _generatedMenu![sessionIndex].items[itemIndex];
        _generatedMenu![sessionIndex].items[itemIndex] = KidneyMenuItem(
          categoryLabel: oldItem.categoryLabel,
          foodName: selectedFood.name,
          weight: oldItem.weight,
          urt: oldItem.urt,
          foodData: selectedFood,
        );
      });
    }
  }

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
      _heightController.text       = height.toString();
      _ageController.text          = _calculateAgeInYears(dob);
      _currentWeightController.text = weight.toString();
      _isHighPotassium             = false;

      final g = gender.toLowerCase();
      if (g.contains('laki') || g.contains('pria') || g == 'l') {
        _genderController.text = 'Laki-laki';
      } else if (g.contains('perempuan') || g.contains('wanita') || g == 'p') {
        _genderController.text = 'Perempuan';
      } else {
        _genderController.text = gender;
      }

      _result        = null;
      _mealPlan      = null;
      _generatedMenu = null;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _heightController.clear();
    _ageController.clear();
    _currentWeightController.clear();
    _patientPickerKey.currentState?.resetSelection();
    setState(() {
      _dialysisController.clear();
      _genderController.clear();
      _proteinFactorController.text = '0.6 (Rendah)';
      _result           = null;
      _mealPlan         = null;
      _generatedMenu    = null;
      _isHighPotassium  = false;
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

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size         = MediaQuery.sizeOf(context);
    final paddingValue = size.width * 0.04;
    final gapSmall     = size.height * 0.015;
    final gapMedium    = size.height * 0.025;
    final gapLarge     = size.height * 0.04;

    final canAccessMenu = ['admin', 'ahli gizi', 'nutrisionis']
        .contains(widget.userRole.toLowerCase());

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Diet Ginjal Kronis',
        subtitle: 'Kalkulator Kebutuhan Protein',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.all(paddingValue),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Patient Picker ─────────────────────────────────────────
                  Semantics(
                    label: 'Pilih Pasien dari Database',
                    child: PatientPickerWidget(
                      key: _patientPickerKey,
                      onPatientSelected: _fillDataFromPatient,
                      userRole: widget.userRole,
                    ),
                  ),
                  SizedBox(height: gapMedium),

                  const Text(
                    'Input Data Pasien Ginjal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: gapMedium),

                  // ── Status Cuci Darah ──────────────────────────────────────
                  _buildCustomDropdown<String>(
                    fieldKey: const ValueKey('input_dialysis'),
                    semanticLabel: 'Status Cuci Darah',
                    controller: _dialysisController,
                    label: 'Apakah Pasien menjalani cuci darah?',
                    prefixIcon: const Icon(Icons.bloodtype_outlined),
                    items: ['Ya', 'Tidak'],
                    itemAsString: (item) => item,
                    onChanged: (value) =>
                        setState(() => _dialysisController.text = value ?? ''),
                  ),
                  SizedBox(height: gapSmall),

                  // ── Faktor Protein (kondisional) ───────────────────────────
                  if (_dialysisController.text == 'Tidak')
                    Padding(
                      padding: EdgeInsets.only(bottom: gapSmall),
                      child: _buildCustomDropdown<String>(
                        fieldKey: const ValueKey('input_protein_factor'),
                        semanticLabel: 'Faktor Protein',
                        controller: _proteinFactorController,
                        label: 'Faktor Kebutuhan Protein',
                        prefixIcon: const Icon(Icons.rule),
                        items: ['0.6 (Rendah)', '0.7 (Sedang)', '0.8 (Tinggi)'],
                        itemAsString: (item) => item,
                        onChanged: (value) => setState(
                          () => _proteinFactorController.text =
                              value ?? '0.6 (Rendah)',
                        ),
                      ),
                    ),

                  // ── Jenis Kelamin ──────────────────────────────────────────
                  _buildCustomDropdown<String>(
                    fieldKey: const ValueKey('input_gender'),
                    semanticLabel: 'Jenis Kelamin',
                    controller: _genderController,
                    label: 'Jenis Kelamin',
                    prefixIcon: const Icon(Icons.person),
                    items: ['Laki-laki', 'Perempuan'],
                    itemAsString: (item) => item,
                    onChanged: (value) =>
                        setState(() => _genderController.text = value ?? ''),
                  ),
                  SizedBox(height: gapSmall),

                  // ── Tinggi Badan ───────────────────────────────────────────
                  _buildTextFormField(
                    fieldKey: const ValueKey('input_height'),
                    semanticLabel: 'Input Tinggi Badan',
                    controller: _heightController,
                    label: 'Tinggi Badan',
                    prefixIcon: const Icon(Icons.height),
                    suffixText: 'cm',
                  ),
                  SizedBox(height: gapSmall),

                  // ── Berat Badan Aktual ─────────────────────────────────────
                  _buildTextFormField(
                    fieldKey: const ValueKey('input_weight'),
                    semanticLabel: 'Input Berat Badan Aktual',
                    controller: _currentWeightController,
                    label: 'Berat Badan Aktual',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    suffixText: 'kg',
                  ),
                  SizedBox(height: gapSmall),

                  // ── Usia ───────────────────────────────────────────────────
                  _buildTextFormField(
                    fieldKey: const ValueKey('input_age'),
                    semanticLabel: 'Input Usia',
                    controller: _ageController,
                    label: 'Usia',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixText: 'tahun',
                  ),
                  SizedBox(height: gapSmall),

                  // ── Toggle Hiperkalemia ────────────────────────────────────
                  Semantics(
                    label: 'Opsi Kalium Tinggi',
                    toggled: _isHighPotassium,
                    child: SwitchListTile(
                      key: const ValueKey('input_switch_potassium'),
                      title: const Text('Kondisi Kalium Tinggi (Hiperkalemia)?'),
                      subtitle: const Text(
                        'Aktifkan untuk menyaring pisang, bayam, alpukat, dll.',
                      ),
                      value: _isHighPotassium,
                      activeThumbColor: kKidneyGreen,
                      onChanged: (value) =>
                          setState(() => _isHighPotassium = value),
                    ),
                  ),
                  SizedBox(height: gapLarge),

                  // ── Action Buttons ─────────────────────────────────────────
                  Semantics(
                    label: 'Tombol Aksi Form',
                    child: FormActionButtons(
                      key: const ValueKey('action_buttons_group'),
                      onReset: _resetForm,
                      onSubmit: _calculateAndGenerateMenu,
                      resetButtonColor: Colors.white,
                      resetForegroundColor: kKidneyGreen,
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: gapLarge),

                  // ── Result Section ─────────────────────────────────────────
                  if (_result != null)
                    _buildResultSection(canAccessMenu, gapMedium, gapLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Result Section
  // ---------------------------------------------------------------------------
  Widget _buildResultSection(
    bool canAccessMenu,
    double gapMedium,
    double gapLarge,
  ) {
    return Column(
      children: [
        Divider(height: gapLarge),
        SizedBox(height: gapMedium),

        // 1. Hasil Perhitungan
        Semantics(
          label: 'Kartu Hasil Perhitungan',
          child: KidneyResultCard(
            result: _result!,
            currentWeight:
                double.tryParse(_currentWeightController.text) ?? 0,
            heightCm: double.tryParse(_heightController.text) ?? 0,
            proteinFactorLabel: _proteinFactorController.text,
            cardKey: _resultCardKey,
          ),
        ),
        SizedBox(height: gapMedium),

        // 2. Detail Asupan Gizi
        Semantics(
          label: 'Detail Asupan Gizi',
          child: ExpansionTile(
            key: const ValueKey('expansion_nutrition'),
            title: Text(
              'Asupan Gizi per Hari (Diet Protein ${_result!.recommendedDiet}g)',
            ),
            children: [
              if (_result!.nutritionInfo != null)
                KidneyNutritionCard(
                  nutritionInfo: _result!.nutritionInfo!,
                  dietProteinGram: _result!.recommendedDiet,
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),

        // 3. Tabel Bahan Makanan Standar
        if (_mealPlan != null)
          Semantics(
            label: 'Tabel Rencana Bahan Makanan',
            child: ExpansionTile(
              key: const ValueKey('expansion_meal_plan'),
              title: const Text('Bahan Makanan Sehari'),
              children: [
                const SizedBox(height: 10),
                KidneyMealPlanTable(
                  mealPlan: _mealPlan!,
                  dietProteinGram: _result!.recommendedDiet,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),

        // 4. Rekomendasi Menu Dinamis (role-gated)
        if (canAccessMenu)
          Semantics(
            label: 'Bagian Menu Dinamis',
            child: ExpansionTile(
              key: const ValueKey('expansion_dynamic_menu'),
              title: const Text('Rekomendasi Menu Sehari'),
              children: [
                KidneyDynamicMenuSection(
                  key: const ValueKey('widget_dynamic_menu_section'),
                  isLoading: _isGeneratingMenu,
                  generatedMenu: _generatedMenu,
                  onEditItem: _editMenuItem,
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared form widget helpers
  // ---------------------------------------------------------------------------

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    required Key fieldKey,
    required String semanticLabel,
    int maxLength = 5,
  }) {
    return Semantics(
      label: semanticLabel,
      child: TextFormField(
        key: fieldKey,
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
        validator: (value) {
          if (value == null || value.isEmpty) return '$label tidak boleh kosong';
          if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
          return null;
        },
      ),
    );
  }

  Widget _buildCustomDropdown<T>({
    required TextEditingController controller,
    required String label,
    required List<T> items,
    required Icon prefixIcon,
    required String Function(T) itemAsString,
    required Key fieldKey,
    required String semanticLabel,
    void Function(T?)? onChanged,
  }) {
    T? selectedItem;
    try {
      selectedItem = items.firstWhere(
        (item) => itemAsString(item) == controller.text,
      );
    } catch (_) {
      selectedItem = null;
    }

    return Semantics(
      label: semanticLabel,
      child: DropdownSearch<T>(
        key: fieldKey,
        popupProps: const PopupProps.menu(
          showSearchBox: false,
          fit: FlexFit.loose,
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
        onChanged: onChanged,
        selectedItem: selectedItem,
        validator: (value) =>
            (value == null && controller.text.isEmpty)
                ? '$label harus dipilih'
                : null,
      ),
    );
  }
}