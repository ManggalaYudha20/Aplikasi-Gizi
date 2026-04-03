// lib/src/features/diabetes_calculation/presentation/pages/diabetes_calculation_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';

// ── Data models ─────────────────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/dm_meal_session_model.dart';

// ── Services ─────────────────────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/services/diabetes_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/services/diabetes_meal_planner_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/services/pdf_generator_dm.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/food_search_delegate.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/expert_system/services/expert_system_engine.dart';

// ── Shared widgets ───────────────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';

// ── Widgets modul diabetes ────────────────────────────────────────────────────
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/presentation/widgets/dm_result_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/presentation/widgets/dm_diet_expansion_cards.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/presentation/widgets/dm_meal_plan_table.dart';

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
  // ── Keys & services ─────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _resultCardKey = GlobalKey();
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();

  final _calculatorService = DiabetesCalculatorService();
  final _foodDbService = FoodDatabaseService();
  final _expertEngine = ExpertSystemEngine(); 
  late final _mealPlannerService = DiabetesMealPlannerService(_foodDbService, _expertEngine);

  // ── Controllers ─────────────────────────────────────────────────────────────
  final _ageController                = TextEditingController();
  final _weightController             = TextEditingController();
  final _heightController             = TextEditingController();
  final _genderController             = TextEditingController();
  final _activityController           = TextEditingController();
  final _hospitalizedStatusController = TextEditingController(text: 'Tidak');
  final _notesController              = TextEditingController();
  final _scrollController             = ScrollController();

  // ── State ────────────────────────────────────────────────────────────────────
  double _stressMetabolic = 20.0;
  DiabetesCalculationResult? _result;
  List<DmMealSession>? _dailyMenu;
  bool _isGeneratingMenu = false;

  // ── Static data ──────────────────────────────────────────────────────────────
  static const _genders        = ['Laki-laki', 'Perempuan'];
  static const _activityLevels = [
  'Bed rest (0.1)', 
  'Ringan (0.2)', 
  'Sedang (0.3)', 
  'Berat (0.4)'
];

  // ── Colour constant (dipakai di action buttons) ───────────────────────────
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

  // ── Helpers ──────────────────────────────────────────────────────────────────
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
      _ageController.text    = _calculateAgeInYears(dob);

      final g = gender.toLowerCase();
      if (g.contains('laki') || g.contains('pria') || g == 'l') {
        _genderController.text = 'Laki-laki';
      } else if (g.contains('perempuan') || g.contains('wanita') || g == 'p') {
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
      activity: _activityController.text.split(' (')[0],
      hospitalizedStatus: _hospitalizedStatusController.text,
      stressMetabolic: _stressMetabolic,
    );

    setState(() {
      _result = result;
      _isGeneratingMenu = true;
      _dailyMenu = null;
    });

    _mealPlannerService
        .generateDailyPlan(result.totalCalories) 
        .then((menu) {
          if (mounted) {
            setState(() {
              _dailyMenu = menu;
              _isGeneratingMenu = false;
            });
          }
        })
        .catchError((error) {
          if (mounted) {
            setState(() {
              _isGeneratingMenu = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal membuat menu: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        });

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
      _hospitalizedStatusController.text = 'Tidak';
      _stressMetabolic = 20.0;
      _result = null;
    });
  }

  /// Format angka: hilangkan desimal jika bulat (1.0 → '1', 1.5 → '1.5').
  String _formatNumber(double value) =>
      value == value.toInt() ? value.toInt().toString() : value.toStringAsFixed(1);

  // ---------------------------------------------------------------------------
  // BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final size    = MediaQuery.sizeOf(context);
    final hPad    = size.width * 0.04;
    final vSpace  = size.height * 0.025;
    final vSpaceSm = size.height * 0.02;

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
                  // ── Patient Picker ──────────────────────────────────────────
                  Semantics(
                    key: DmSemanticKeys.patientPicker,
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

                  // ── Usia ────────────────────────────────────────────────────
                  Semantics(
                    label: 'Field Usia',
                    textField: true,
                    child: _buildTextFormField(
                      key: DmSemanticKeys.ageField,
                      controller: _ageController,
                      label: 'Usia',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixText: 'tahun',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Masukkan usia';
                        final age = int.tryParse(value);
                        if (age == null || age < 1 || age > 120) {
                          return 'Masukkan usia yang valid (1-120 tahun)';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Jenis Kelamin ────────────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Jenis Kelamin',
                    child: _buildCustomDropdown(
                      key: DmSemanticKeys.genderDropdown,
                      controller: _genderController,
                      label: 'Jenis Kelamin',
                      prefixIcon: const Icon(Icons.wc),
                      items: _genders,
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Berat Badan ──────────────────────────────────────────────
                  Semantics(
                    label: 'Field Berat Badan',
                    textField: true,
                    child: _buildTextFormField(
                      key: DmSemanticKeys.weightField,
                      controller: _weightController,
                      label: 'Berat Badan',
                      prefixIcon: const Icon(Icons.monitor_weight),
                      suffixText: 'kg',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Masukkan berat badan';
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 1 || weight > 300) {
                          return 'Masukkan berat badan yang valid (1-300 kg)';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Tinggi Badan ─────────────────────────────────────────────
                  Semantics(
                    label: 'Field Tinggi Badan',
                    textField: true,
                    child: _buildTextFormField(
                      key: DmSemanticKeys.heightField,
                      controller: _heightController,
                      label: 'Tinggi Badan',
                      prefixIcon: const Icon(Icons.height),
                      suffixText: 'cm',
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Masukkan tinggi badan';
                        final height = double.tryParse(value);
                        if (height == null || height < 30 || height > 300) {
                          return 'Masukkan tinggi badan yang valid (30-300 cm)';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Faktor Aktivitas ─────────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Faktor Aktivitas',
                    child: _buildCustomDropdown(
                      key: DmSemanticKeys.activityDropdown,
                      controller: _activityController,
                      label: 'Faktor Aktivitas',
                      prefixIcon: const Icon(Icons.directions_run),
                      items: _activityLevels,
                    ),
                  ),
                  SizedBox(height: vSpaceSm),

                  // ── Status Rawat Inap ────────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Status Rawat Inap',
                    child: _buildCustomDropdown(
                      key: DmSemanticKeys.hospitalizedDropdown,
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

                  // ── Stress Metabolik Slider (kondisional) ──────────────────
                  if (_hospitalizedStatusController.text == 'Ya') ...[
                    Semantics(
                      label: 'Slider Stress Metabolik',
                      slider: true,
                      child: Column(
                        key: DmSemanticKeys.stressSlider,
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
                            onChanged: (v) => setState(() => _stressMetabolic = v),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: vSpaceSm),
                  ],

                  SizedBox(height: size.height * 0.03),

                  // ── Action Buttons ───────────────────────────────────────────
                  Semantics(
                    label: 'Tombol Hitung dan Reset Kalori Diabetes',
                    child: FormActionButtons(
                      onReset: _resetForm,
                      onSubmit: _calculateDiabetesNutrition,
                      resetButtonColor: Colors.white,
                      resetForegroundColor: _kGreen,
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),
                  SizedBox(height: size.height * 0.04),

                  // ── Result Section ───────────────────────────────────────────
                  if (_result != null) ...[
                    Container(
                      key: _resultCardKey,
                      child: const Column(
                        children: [Divider(), SizedBox(height: 32)],
                      ),
                    ),

                    // 1. Kartu total kalori
                    DmResultCard(
                      result: _result!,
                      isHospitalized: _hospitalizedStatusController.text == 'Ya',
                      stressMetabolic: _stressMetabolic,
                    ),
                    SizedBox(height: vSpaceSm),

                    // 2. Jenis diet
                    DmDietInfoTile(result: _result!),
                    SizedBox(height: vSpaceSm),

                    // 3. Standar diet (golongan bahan makanan)
                    DmFoodGroupTile(result: _result!),
                    SizedBox(height: vSpaceSm),

                    // 4. Pembagian makanan sehari-hari
                    DmMealDistributionTile(result: _result!),
                    SizedBox(height: vSpaceSm),

                    // 5. Rekomendasi menu sehari (role-gated)
                    _buildDailyMenuSection(),
                  ],

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Daily Menu Section (role-gated, tetap di halaman karena butuh setState)
  // ---------------------------------------------------------------------------
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
          const SizedBox(
            height: 150,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sedang membuat menu...', style: TextStyle(color: Colors.grey)),
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
                        // Header sesi waktu makan
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

                        // Daftar item makanan
                        ...session.items.map((item) {
                          final portionText = item.portion == 'S'
                              ? '(S)'
                              : '(${item.portion is num ? _formatNumber(item.portion as double) : item.portion} P)';

                          return ListTile(
                            dense: true,
                            title: Text(
                              item.categoryLabel,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                              icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
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
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const SizedBox(height: 8),

                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Tulis anjuran khusus atau catatan untuk pasien disini...',
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
                      key: DmSemanticKeys.btnDownloadPdf,
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Edit & PDF logic
  // ---------------------------------------------------------------------------
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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Menu belum tersedia.')));
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

  // ---------------------------------------------------------------------------
  // Shared form widget helpers (tetap di halaman, dipakai oleh form input)
  // ---------------------------------------------------------------------------

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
          (String? newValue) => setState(() => controller.text = newValue ?? ''),
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (value) =>
          (value == null || value.isEmpty) ? '$label harus dipilih' : null,
    );
  }
}