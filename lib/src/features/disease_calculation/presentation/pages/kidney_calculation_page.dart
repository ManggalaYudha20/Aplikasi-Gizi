// lib/src/features/disease_calculation/presentation/pages/kidney_calculation_page.dart

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Alias Imports
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_meal_planner_service.dart'
    as planner;
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart'
    as db;

import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// Service & Models
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_menu_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_dynamic_menu_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_search_delegate.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_dynamic_menu_section.dart';

class KidneyCalculationPage extends StatefulWidget {
  final String userRole;

  const KidneyCalculationPage({super.key, required this.userRole});

  @override
  State<KidneyCalculationPage> createState() => _KidneyCalculationPageState();
}

class _KidneyCalculationPageState extends State<KidneyCalculationPage> {
  final _formKey = GlobalKey<FormState>();
  final _calculatorService = KidneyCalculatorService();
  
  // -- Controllers --
  late final TextEditingController _heightController;
  late final TextEditingController _ageController;
  late final TextEditingController _dialysisController;
  late final TextEditingController _genderController;
  late final TextEditingController _proteinFactorController;
  late final TextEditingController _currentWeightController;
  late final ScrollController _scrollController;
  
  // -- Keys & State --
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();
  final GlobalKey _resultCardKey = GlobalKey(); // Untuk auto-scroll
  
  bool _isHighPotassium = false;
  KidneyDietResult? _result;
  List<planner.FoodItem>? _mealPlan;
  
  // -- Menu Generation State --
  late KidneyDynamicMenuService _menuGenerator;
  List<KidneyMealSession>? _generatedMenu;
  bool _isGeneratingMenu = false;

  @override
  void initState() {
    super.initState();
    _menuGenerator = KidneyDynamicMenuService(FoodDatabaseService());
    
    // Inisialisasi Controller
    _heightController = TextEditingController();
    _ageController = TextEditingController();
    _dialysisController = TextEditingController();
    _genderController = TextEditingController();
    _proteinFactorController = TextEditingController(text: '0.6 (Rendah)');
    _currentWeightController = TextEditingController();
    _scrollController = ScrollController();
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

  // --- Logic Methods ---

  void _calculateAndGenerateMenu() async {
    if (_formKey.currentState!.validate()) {
      FocusManager.instance.primaryFocus?.unfocus();

      final height = double.tryParse(_heightController.text) ?? 0;
      final age = int.tryParse(_ageController.text) ?? 0;
      final isDialysis = _dialysisController.text == 'Ya';
      final gender = _genderController.text;
      final proteinFactorString = _proteinFactorController.text.split(' ')[0];
      final proteinFactor = double.tryParse(proteinFactorString);

      final result = _calculatorService.calculate(
        height: height,
        isDialysis: isDialysis,
        gender: gender,
        proteinFactor: isDialysis ? null : proteinFactor,
        age: age,
      );

      final mealPlan = planner.KidneyMealPlans.getPlan(result.recommendedDiet);

      setState(() {
        _result = result;
        _mealPlan = mealPlan;
        _generatedMenu = null;
        _isGeneratingMenu = true;
      });

      _scrollToResult();

      try {
        int targetProtein = result.recommendedDiet;
        final dynamicMenu = await _menuGenerator.generateDailyMenu(
          targetProtein,
          isHighPotassium: _isHighPotassium,
        );

        if (mounted) {
          setState(() {
            _generatedMenu = dynamicMenu;
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
  }

  Future<void> _editMenuItem(KidneyMenuItem item, int sessionIndex, int itemIndex) async {
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
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }

  void _fillDataFromPatient(double weight, double height, String gender, DateTime dob) {
    setState(() {
      _heightController.text = height.toString();
      _ageController.text = _calculateAgeInYears(dob);
      _currentWeightController.text = weight.toString();
      _isHighPotassium = false;

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

      _result = null;
      _mealPlan = null;
      _generatedMenu = null;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _heightController.clear();
    _ageController.clear();
    _patientPickerKey.currentState?.resetSelection();
    _currentWeightController.clear();
    setState(() {
      _dialysisController.clear();
      _genderController.clear();
      _proteinFactorController.text = '0.6 (Rendah)';
      _result = null;
      _mealPlan = null;
      _generatedMenu = null;
      _isHighPotassium = false;
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

  // --- UI Construction ---

  @override
  Widget build(BuildContext context) {
    // Responsive Measurements
    final Size screenSize = MediaQuery.sizeOf(context);
    final double paddingValue = screenSize.width * 0.04; // ~16px on mobile
    final double gapSmall = screenSize.height * 0.015; // ~10-12px
    final double gapMedium = screenSize.height * 0.025; // ~20px
    final double gapLarge = screenSize.height * 0.04; // ~32px

    final bool canAccessMenu = ['admin', 'ahli gizi', 'nutrisionis']
        .contains(widget.userRole.toLowerCase());

    return Scaffold(
      backgroundColor: Colors.white,
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
                  Semantics(
                    label: "Pilih Pasien dari Database",
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

                  // --- INPUT FIELDS ---
                  _buildCustomDropdown<String>(
                    fieldKey: const ValueKey('input_dialysis'),
                    semanticLabel: 'Status Cuci Darah',
                    controller: _dialysisController,
                    label: 'Apakah Pasien menjalani cuci darah?',
                    prefixIcon: const Icon(Icons.bloodtype_outlined),
                    items: ['Ya', 'Tidak'],
                    itemAsString: (item) => item,
                    onChanged: (value) => setState(() => _dialysisController.text = value ?? ''),
                  ),
                  SizedBox(height: gapSmall),

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
                          () => _proteinFactorController.text = value ?? '0.6 (Rendah)',
                        ),
                      ),
                    ),

                  _buildCustomDropdown<String>(
                    fieldKey: const ValueKey('input_gender'),
                    semanticLabel: 'Jenis Kelamin',
                    controller: _genderController,
                    label: 'Jenis Kelamin',
                    prefixIcon: const Icon(Icons.person),
                    items: ['Laki-laki', 'Perempuan'],
                    itemAsString: (item) => item,
                    onChanged: (value) => setState(() => _genderController.text = value ?? ''),
                  ),
                  SizedBox(height: gapSmall),

                  _buildTextFormField(
                    fieldKey: const ValueKey('input_height'),
                    semanticLabel: 'Input Tinggi Badan',
                    controller: _heightController,
                    label: 'Tinggi Badan',
                    prefixIcon: const Icon(Icons.height),
                    suffixText: 'cm',
                  ),
                  SizedBox(height: gapSmall),

                  _buildTextFormField(
                    fieldKey: const ValueKey('input_weight'),
                    semanticLabel: 'Input Berat Badan Aktual',
                    controller: _currentWeightController,
                    label: 'Berat Badan Aktual',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    suffixText: 'kg',
                  ),
                  SizedBox(height: gapSmall),

                  _buildTextFormField(
                    fieldKey: const ValueKey('input_age'),
                    semanticLabel: 'Input Usia',
                    controller: _ageController,
                    label: 'Usia',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixText: 'tahun',
                  ),
                  SizedBox(height: gapSmall),

                  Semantics(
                    label: "Opsi Kalium Tinggi",
                    toggled: _isHighPotassium,
                    child: SwitchListTile(
                      key: const ValueKey('input_switch_potassium'),
                      title: const Text("Kondisi Kalium Tinggi (Hiperkalemia)?"),
                      subtitle: const Text("Aktifkan untuk menyaring pisang, bayam, alpukat, dll."),
                      value: _isHighPotassium,
                      activeThumbColor: const Color.fromARGB(255, 0, 148, 68),
                      onChanged: (bool value) {
                        setState(() {
                          _isHighPotassium = value;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: gapLarge),

                  Semantics(
                    label: "Tombol Aksi Form",
                    child: FormActionButtons(
                      key: const ValueKey('action_buttons_group'),
                      onReset: _resetForm,
                      onSubmit: _calculateAndGenerateMenu,
                      resetButtonColor: Colors.white,
                      resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: gapLarge),

                  // --- RESULTS SECTION ---
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

  // Extracted Result Section for Clean Code
  Widget _buildResultSection(bool canAccessMenu, double gapMedium, double gapLarge) {
    return Column(
      children: [
        Divider(height: gapLarge),
        SizedBox(height: gapMedium),
        
        Semantics(
          label: "Kartu Hasil Perhitungan",
          child: _buildResultCard(),
        ),
        
        SizedBox(height: gapMedium),

        Semantics(
          label: "Detail Asupan Gizi",
          child: ExpansionTile(
            key: const ValueKey('expansion_nutrition'),
            title: Text(
              'Asupan Gizi per Hari (Diet Protein ${_result!.recommendedDiet}g)',
            ),
            children: [
              if (_result!.nutritionInfo != null)
                _buildNutritionCard(_result!.nutritionInfo!),
              const SizedBox(height: 10),
            ],
          ),
        ),

        if (_mealPlan != null)
          Semantics(
             label: "Tabel Rencana Bahan Makanan",
             child: ExpansionTile(
              key: const ValueKey('expansion_meal_plan'),
              title: const Text('Bahan Makanan Sehari'),
              children: [
                const SizedBox(height: 10),
                _buildMealPlanCard(_mealPlan!),
                const SizedBox(height: 10),
              ],
            ),
          ),

        if (canAccessMenu)
          Semantics(
            label: "Bagian Menu Dinamis",
            child: ExpansionTile(
              key: const ValueKey('expansion_dynamic_menu'),
              title: const Text("Rekomendasi Menu Sehari"),
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

  // --- Helper Widgets with QA Support ---

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
    } catch (e) {
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
        validator: (value) => (value == null && controller.text.isEmpty)
            ? '$label harus dipilih'
            : null,
      ),
    );
  }

  Widget _buildResultCard() {
    final proteinFactorValue = _proteinFactorController.text.split(' ')[0];
    final String recommendationText = _result!.isDialysis
        ? 'Diet Hemodialisis (HD)\nProtein ${_result!.recommendedDiet} gram'
        : 'Diet Protein Rendah ${_result!.recommendedDiet} gram';

    final String factorExplanationText = _result!.isDialysis
        ? '*Pasien hemodialisis membutuhkan asupan protein lebih tinggi (1.2 g/kg BBI).'
        : '*Pasien pre-dialisis membutuhkan asupan protein lebih rendah (${proteinFactorValue}g/kg BBI) untuk memperlambat laju penyakit.';

    final currentWeight = double.tryParse(_currentWeightController.text) ?? 0;
    final heightM = (double.tryParse(_heightController.text) ?? 0) / 100;

    String nutritionalStatus = '-';
    double imt = 0;

    if (currentWeight > 0 && heightM > 0) {
      imt = currentWeight / (heightM * heightM);
      if (imt < 18.5) {
        nutritionalStatus = 'BB Kurang';
      } else if (imt < 25) {
        nutritionalStatus = 'Normal';
      } else if (imt < 30) {
        nutritionalStatus = 'BB Lebih';
      } else {
        nutritionalStatus = 'Obesitas';
      }
    }

    return Container(
      key: _resultCardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 148, 68).withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color.fromARGB(255, 0, 148, 68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hasil Perhitungan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 148, 68),
            ),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Berat Badan Ideal (BBI)',
            '${_result!.idealBodyWeight.toStringAsFixed(1)} kg',
            'result_bbi'
          ),
          _buildInfoRow(
            'Berat Badan Aktual',
            '${currentWeight.toStringAsFixed(1)} kg',
            'result_bb_aktual'
          ),
          _buildInfoRow(
            'Indeks Massa Tubuh (IMT)',
            '${imt.toStringAsFixed(1)} ($nutritionalStatus)',
            'result_imt'
          ),
          if (_result!.bmr > 0)
            _buildInfoRow(
              'BMR',
              '${_result!.bmr.toStringAsFixed(1)} kkal/hari',
              'result_bmr'
            ),
          _buildInfoRow(
            'Kebutuhan Protein Harian',
            '${_result!.proteinNeeds.toStringAsFixed(1)} gram',
            'result_protein_needs'
          ),
          const SizedBox(height: 16),
          const Text(
            'Rekomendasi Diet:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            key: const ValueKey('result_recommendation_box'),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 148, 68),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              recommendationText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            factorExplanationText,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(KidneyDietNutrition nutritionInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Asupan Gizi per Hari (Diet Protein ${_result!.recommendedDiet}g)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const Divider(height: 24),
          _buildInfoRow('Energi', '${nutritionInfo.energi} kkal', 'nut_energi'),
          _buildInfoRow('Protein', '${nutritionInfo.protein} g', 'nut_protein'),
          _buildInfoRow('Lemak', '${nutritionInfo.lemak} g', 'nut_lemak'),
          _buildInfoRow('Karbohidrat', '${nutritionInfo.karbohidrat} g', 'nut_karbo'),
          _buildInfoRow('Kalsium', '${nutritionInfo.kalsium} mg', 'nut_kalsium'),
          _buildInfoRow('Zat Besi', '${nutritionInfo.zatBesi} mg', 'nut_besi'),
          _buildInfoRow('Fosfor', '${nutritionInfo.fosfor} mg', 'nut_fosfor'),
          _buildInfoRow('Vitamin A', '${nutritionInfo.vitaminA} RE', 'nut_vit_a'),
          _buildInfoRow('Tiamin', '${nutritionInfo.tiamin} mg', 'nut_tiamin'),
          _buildInfoRow('Vitamin C', '${nutritionInfo.vitaminC} mg', 'nut_vit_c'),
          _buildInfoRow('Natrium', '${nutritionInfo.natrium} mg', 'nut_natrium'),
          _buildInfoRow('Kalium', '${nutritionInfo.kalium} mg', 'nut_kalium'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, String keySuffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            key: ValueKey('value_$keySuffix'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanCard(List<planner.FoodItem> mealPlan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bahan Makanan Sehari (Diet Protein ${_result!.recommendedDiet}g)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const Divider(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            border: TableBorder.all(color: Colors.purple.shade100, width: 1),
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 196, 86, 216),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Bahan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Berat (g)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'URT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              ...mealPlan.map((planner.FoodItem item) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.name),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item.weight.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.urt),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}