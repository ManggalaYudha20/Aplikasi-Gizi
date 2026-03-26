// lib/src/features/nutrition_calculation/presentation/pages/nutrition_status_form_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// [REFACTOR] Import Service & Widgets baru
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/nutrition_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/calculation_result_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/responsive_number_field.dart';

// ============================================================================
// Helper: Resolver warna kategori gizi
// Dipreservasi utuh — logika warna adalah tanggung jawab presentasi.
// ============================================================================
abstract class _NutritionColorResolver {
  static const Color _green = Color(0xFF009444);

  static Color forWeightForAge(String category) {
    if (category.contains('sangat kurang') ||
        category.contains('severely underweight')) {
      return Colors.red;
    }
    if (category.contains('kurang') || category.contains('underweight')) {
      return Colors.orange;
    }
    if (category.contains('Normal')) return _green;
    return Colors.orange;
  }

  static Color forHeightForAge(String category) {
    if (category.contains('Sangat pendek') ||
        category.contains('severely stunted')) {
      return Colors.red;
    }
    if (category.contains('Pendek') || category.contains('stunted')) {
      return Colors.orange;
    }
    if (category.contains('Normal')) return _green;
    return Colors.blue;
  }

  static Color forWeightForHeight(String category) {
    if (category.contains('Gizi buruk') ||
        category.contains('severely wasted')) {
      return Colors.red;
    }
    if (category.contains('Gizi kurang') ||
        category.contains('wasted') ||
        category.contains('Berisiko gizi lebih')) {
      return Colors.orange;
    }
    if (category.contains('Gizi baik') || category.contains('normal')) {
      return _green;
    }
    return Colors.red;
  }

  static Color forBMIForAge(String category) => forWeightForHeight(category);

  static Color resolve(String cardTitle, String category) {
    if (cardTitle.contains('BB/U'))  return forWeightForAge(category);
    if (cardTitle.contains('TB/U'))  return forHeightForAge(category);
    if (cardTitle.contains('BB/TB')) return forWeightForHeight(category);
    if (cardTitle.contains('IMT/U')) return forBMIForAge(category);
    return _green;
  }
}

// ============================================================================
// StatefulWidget
// ============================================================================

class NutritionStatusFormPage extends StatefulWidget {
  final String userRole;

  const NutritionStatusFormPage({super.key, required this.userRole});

  @override
  State<NutritionStatusFormPage> createState() =>
      _NutritionStatusFormPageState();
}

class _NutritionStatusFormPageState extends State<NutritionStatusFormPage> {
  // ── Controllers & Keys ────────────────────────────────────────────────────
  final _formKey                  = GlobalKey<FormState>();
  final _weightController         = TextEditingController();
  final _heightController         = TextEditingController();
  final _birthDateController      = TextEditingController();
  final _measurementDateController = TextEditingController();
  final _genderController         = TextEditingController();
  final _scrollController         = ScrollController();
  final _resultSectionKey         = GlobalKey();
  final _patientPickerKey         = GlobalKey<PatientPickerWidgetState>();

  // ── State ─────────────────────────────────────────────────────────────────
  DateTime?         _birthDate;
  DateTime?         _measurementDate;
  int?              _ageInMonths;
  // [REFACTOR] Diganti dari Map<String, dynamic>? ke NutritionAllResult? yang type-safe.
  NutritionAllResult? _result;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (!mounted) return;
      setState(() {
        _measurementDate = DateTime.now();
        _measurementDateController.text =
            DateFormat('dd MMMM yyyy', 'id_ID').format(_measurementDate!);
      });
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _birthDateController.dispose();
    _measurementDateController.dispose();
    _genderController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  void _recalculateAge() {
    if (_birthDate == null || _measurementDate == null) return;
    _ageInMonths = NutritionCalculatorService.calculateAgeInMonths(
      birthDate: _birthDate!,
      checkDate: _measurementDate!,
    );
    if (_ageInMonths! < 0 || _ageInMonths! > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Usia anak harus antara 0-60 bulan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calculateNutritionStatus() {
    if (!_formKey.currentState!.validate()) return;

    if (_ageInMonths == null || _ageInMonths! < 0 || _ageInMonths! > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:         Text('Pastikan usia anak antara 0-60 bulan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // [REFACTOR] Delegasi penuh ke Service.
    setState(() {
      _result = NutritionCalculatorService.calculateAll(
        birthDate: _birthDate!,
        checkDate: _measurementDate!,
        weightKg:  double.parse(_weightController.text),
        heightCm:  double.parse(_heightController.text),
        gender:    _genderController.text,
      );
    });

    _scrollToResult();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _birthDateController.clear();
      _genderController.clear();
      _birthDate   = null;
      _ageInMonths = null;
      _result      = null;
      _measurementDate = DateTime.now();
      _measurementDateController.text =
          DateFormat('dd MMMM yyyy', 'id_ID').format(_measurementDate!);
    });
    _patientPickerKey.currentState?.resetSelection();
  }

  void _fillDataFromPatient(
    double weight, double height, String gender, DateTime dob,
  ) {
    setState(() {
      _weightController.text = weight.toString();
      _heightController.text = height.toString();
      _genderController.text = gender;
      _birthDate             = dob;
      _birthDateController.text =
          DateFormat('dd MMMM yyyy', 'id_ID').format(dob);
      _result = null;
      _recalculateAge();
    });
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 600),
          curve:    Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _pickDate({required bool isBirthDate}) async {
    final DateTime initial = isBirthDate
        ? (_birthDate ?? DateTime.now())
        : (_measurementDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context:     context,
      initialDate: initial,
      firstDate:   DateTime(2000),
      lastDate:    DateTime.now(),
      locale:      const Locale('id', 'ID'),
    );

    if (picked == null) return;

    setState(() {
      if (isBirthDate) {
        _birthDate = picked;
        _birthDateController.text =
            DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
      } else {
        _measurementDate = picked;
        _measurementDateController.text =
            DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
      }
      _recalculateAge();
      _result = null;
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double sw          = MediaQuery.sizeOf(context).width;
    final double hPad        = sw * 0.04;
    final double scaleFactor = sw >= 600 ? 1.2 : (sw <= 360 ? 0.9 : 1.0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title:    'Status Gizi',
        subtitle: 'Usia 0-60 Bulan',
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

                  // ── Patient Picker ─────────────────────────────────────
                  PatientPickerWidget(
                    key:               _patientPickerKey,
                    onPatientSelected: _fillDataFromPatient,
                    userRole:          widget.userRole,
                  ),

                  SizedBox(height: sw * 0.05),

                  Text(
                    'Input Data Status Gizi',
                    style: TextStyle(
                      fontSize:   16 * scaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Tanggal Lahir ──────────────────────────────────────
                  ResponsiveNumberField(
                    widgetKey:  const ValueKey('birthDateField'),
                    controller: _birthDateController,
                    label:      'Tanggal Lahir',
                    prefixIcon: const Icon(Icons.calendar_today),
                    readOnly:   true,
                    onTap:      () => _pickDate(isBirthDate: true),
                    customValidator: (v) =>
                        (v == null || v.isEmpty) ? 'Tanggal lahir tidak boleh kosong' : null,
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Tanggal Pemeriksaan ────────────────────────────────
                  ResponsiveNumberField(
                    widgetKey:  const ValueKey('measurementDateField'),
                    controller: _measurementDateController,
                    label:      'Tanggal Pemeriksaan',
                    prefixIcon: const Icon(Icons.event),
                    readOnly:   true,
                    onTap:      () => _pickDate(isBirthDate: false),
                    customValidator: (v) =>
                        (v == null || v.isEmpty) ? 'Tanggal pemeriksaan tidak boleh kosong' : null,
                  ),

                  if (_ageInMonths != null) ...[
                    SizedBox(height: sw * 0.02),
                    Text(
                      'Usia: $_ageInMonths bulan',
                      style: TextStyle(
                        fontSize: 14 * scaleFactor,
                        color:    Colors.grey.shade600,
                      ),
                    ),
                  ],

                  SizedBox(height: sw * 0.04),

                  // ── Gender Dropdown ────────────────────────────────────
                  DropdownSearch<String>(
                    key: const ValueKey('genderDropdown'),
                    popupProps: const PopupProps.menu(
                      showSearchBox: false,
                      fit:           FlexFit.loose,
                      constraints:   BoxConstraints(maxHeight: 240),
                    ),
                    items: const [
                      NutritionCalculatorService.genderMale,
                      NutritionCalculatorService.genderFemale,
                    ],
                    dropdownDecoratorProps: DropDownDecoratorProps(
                      dropdownSearchDecoration: InputDecoration(
                        labelText:  'Jenis Kelamin',
                        border:     const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.wc),
                      ),
                    ),
                    onChanged: (val) =>
                        setState(() => _genderController.text = val ?? ''),
                    selectedItem: _genderController.text.isEmpty
                        ? null : _genderController.text,
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Jenis kelamin harus dipilih' : null,
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Berat & Tinggi ─────────────────────────────────────
                  ResponsiveNumberField(
                    widgetKey:  const ValueKey('weightField'),
                    controller: _weightController,
                    label:      'Berat Badan',
                    prefixIcon: const Icon(Icons.monitor_weight),
                    suffixText: 'kg',
                  ),

                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey:  const ValueKey('heightField'),
                    controller: _heightController,
                    label:      'Tinggi/Panjang Badan',
                    prefixIcon: const Icon(Icons.height),
                    suffixText: 'cm',
                  ),

                  SizedBox(height: sw * 0.08),

                  FormActionButtons(
                    onReset:              _resetForm,
                    onSubmit:             _calculateNutritionStatus,
                    resetButtonColor:     Colors.white,
                    resetForegroundColor: const Color(0xFF009444),
                    submitIcon: const Icon(Icons.calculate, color: Colors.white),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Result Section ─────────────────────────────────────
                  if (_result != null) ...[
                    SizedBox(key: _resultSectionKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.04),
                    _buildResultSection(sw, scaleFactor),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Private Widget Builders ───────────────────────────────────────────────

  Widget _buildResultSection(double sw, double scaleFactor) {
    final r = _result!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Hasil Perhitungan Status Gizi',
          style: TextStyle(
            fontSize:   16.0 * scaleFactor,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16.0 * scaleFactor),

        // BB/U
        ZScoreResultCard(
          containerKey:   const ValueKey('resultCard_bbPerU'),
          semanticsLabel: 'Hasil Z-Score BB per Umur',
          title:          'Berat Badan menurut Umur (BB/U)',
          zScore:         r.weightForAge.zScore,
          category:       r.weightForAge.category,
          color: _NutritionColorResolver.resolve(
            'BB/U', r.weightForAge.category,
          ),
        ),
        SizedBox(height: 12.0 * scaleFactor),

        // TB/U
        ZScoreResultCard(
          containerKey:   const ValueKey('resultCard_tbPerU'),
          semanticsLabel: 'Hasil Z-Score TB per Umur',
          title:          'Tinggi Badan menurut Umur (TB/U)',
          zScore:         r.heightForAge.zScore,
          category:       r.heightForAge.category,
          color: _NutritionColorResolver.resolve(
            'TB/U', r.heightForAge.category,
          ),
        ),
        SizedBox(height: 12.0 * scaleFactor),

        // BB/TB
        ZScoreResultCard(
          containerKey:   const ValueKey('resultCard_bbPerTb'),
          semanticsLabel: 'Hasil Z-Score BB per Tinggi Badan',
          title:          'Berat Badan menurut Tinggi Badan (BB/TB)',
          zScore:         r.weightForHeight.zScore,
          category:       r.weightForHeight.category,
          color: _NutritionColorResolver.resolve(
            'BB/TB', r.weightForHeight.category,
          ),
        ),
        SizedBox(height: 12.0 * scaleFactor),

        // IMT/U
        ZScoreResultCard(
          containerKey:   const ValueKey('resultCard_imtPerU'),
          semanticsLabel: 'Hasil Z-Score IMT per Umur',
          title:          'Indeks Massa Tubuh menurut Umur (IMT/U)',
          zScore:         r.bmiForAge.zScore,
          category:       r.bmiForAge.category,
          color: _NutritionColorResolver.resolve(
            'IMT/U', r.bmiForAge.category,
          ),
          additionalInfo:
              'IMT: ${r.bmi.toStringAsFixed(2)} kg/m²',
        ),
      ],
    );
  }
}