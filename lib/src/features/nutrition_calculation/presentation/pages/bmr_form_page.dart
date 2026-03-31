// lib/src/features/nutrition_calculation/presentation/pages/bmr_form_page.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// [REFACTOR] Import Service & Widgets baru
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bmr_tdee_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/calculation_result_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/responsive_number_field.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/data/models/reference_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/widgets/reference_widgets.dart';
// ---------------------------------------------------------------------------
// [QA] ValueKey TIDAK diubah.
// ---------------------------------------------------------------------------
class _Keys {
  const _Keys._();
  static const patientPicker   = ValueKey('patientPickerWidget');
  static const formulaDropdown = ValueKey('formulaDropdown');
  static const weightField     = ValueKey('weightField');
  static const heightField     = ValueKey('heightField');
  static const genderDropdown  = ValueKey('genderDropdown');
  static const ageField        = ValueKey('ageField');
  static const btnReset        = ValueKey('btnReset');
  static const bmrResultCard   = ValueKey('bmrResultCard');
}

class _Str {
  const _Str._();
  static const appBarTitle    = 'BMR';
  static const appBarSubtitle = 'Basal Metabolic Rate';
  static const sectionTitle   = 'Input Data BMR';
  static const formulaLabel   = 'Pilih Formula BMR';
  static const weightLabel    = 'Berat Badan';
  static const weightUnit     = 'kg';
  static const heightLabel    = 'Tinggi Badan';
  static const heightUnit     = 'cm';
  static const genderLabel    = 'Jenis Kelamin';
  static const ageLabel       = 'Umur';
  static const ageUnit        = 'tahun';
  static const resultUnit     = 'kkal/hari';
  static const resultDesc     =
      'Basal Metabolic Rate (BMR) adalah jumlah kalori yang dibutuhkan '
      'tubuh untuk fungsi dasar saat istirahat.';

  // [REFACTOR] Referensi ke konstanta Service agar Single Source of Truth
  static const List<String> formulaOptions = [
    BmrTdeeCalculatorService.formulaMifflin,
    BmrTdeeCalculatorService.formulaHarris,
  ];
  static const List<String> genderOptions = [
    BmrTdeeCalculatorService.genderMale,
    BmrTdeeCalculatorService.genderFemale,
  ];
}

const _kBrandGreen = Color(0xFF009444);

// ===========================================================================
// PAGE WIDGET
// ===========================================================================

class BmrFormPage extends StatefulWidget {
  final String userRole;

  const BmrFormPage({super.key, required this.userRole});

  @override
  State<BmrFormPage> createState() => _BmrFormPageState();
}

class _BmrFormPageState extends State<BmrFormPage> {
  // ── Controllers & Keys ────────────────────────────────────────────────────
  final _formKey           = GlobalKey<FormState>();
  final _weightController  = TextEditingController();
  final _heightController  = TextEditingController();
  final _ageController     = TextEditingController();
  final _genderController  = TextEditingController();
  final _formulaController = TextEditingController(
    text: BmrTdeeCalculatorService.formulaMifflin,
  );
  final _scrollController = ScrollController();
  final _resultCardKey    = GlobalKey();
  final _patientPickerKey = GlobalKey<PatientPickerWidgetState>();

  // ── State ─────────────────────────────────────────────────────────────────
  double? _bmrResult;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _genderController.dispose();
    _formulaController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  void _calculateBMR() {
    if (!_formKey.currentState!.validate()) return;

    final double weight  = double.parse(_weightController.text);
    final double height  = double.parse(_heightController.text);
    final int    age     = int.parse(_ageController.text);
    final bool   isMale  =
        BmrTdeeCalculatorService.isMaleFromString(_genderController.text);
    final String formula = _formulaController.text;

    // [REFACTOR] Logika hitung didelegasikan penuh ke Service.
    setState(() {
      _bmrResult = BmrTdeeCalculatorService.calculateBmrByFormula(
        weightKg: weight,
        heightCm: height,
        ageYears: age,
        isMale:   isMale,
        formula:  formula,
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
      _genderController.clear();
      _formulaController.text = BmrTdeeCalculatorService.formulaMifflin;
      _bmrResult = null;
    });
    _patientPickerKey.currentState?.resetSelection();
  }

  void _fillDataFromPatient(
    double weight, double height, String gender, DateTime dob,
  ) {
    setState(() {
      _weightController.text = weight.toString();
      _heightController.text = height.toString();
      _ageController.text    = BmrTdeeCalculatorService.calculateAgeInYears(
        birthDate: dob,
        checkDate: DateTime.now(),
      ).toString();
      _genderController.text = BmrTdeeCalculatorService.normalizeGender(gender);
      _bmrResult = null;
    });
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultCardKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultCardKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve:    Curves.easeInOut,
        );
      }
    });
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double sw   = MediaQuery.sizeOf(context).width;
    final double hPad = sw * 0.04;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title:    _Str.appBarTitle,
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

                  // ── Patient Picker ─────────────────────────────────────
                  Semantics(
                    key:   _Keys.patientPicker,
                    label: 'Pemilih Pasien',
                    hint:  'Pilih pasien untuk mengisi data berat badan, '
                           'tinggi badan, jenis kelamin, dan umur secara otomatis',
                    child: PatientPickerWidget(
                      key:               _patientPickerKey,
                      onPatientSelected: _fillDataFromPatient,
                      userRole:          widget.userRole,
                    ),
                  ),

                  SizedBox(height: sw * 0.05),

                  Text(
                    _Str.sectionTitle,
                    style: TextStyle(
                      fontSize:   _responsiveFont(sw, base: 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: sw * 0.05),

                  // ── Formula Dropdown ───────────────────────────────────
                  Semantics(
                    label: 'Dropdown Formula BMR',
                    hint:  'Pilih formula kalkulasi: Mifflin-St Jeor atau Harris-Benedict',
                    child: _buildDropdown(
                      widgetKey:  _Keys.formulaDropdown,
                      controller: _formulaController,
                      label:      _Str.formulaLabel,
                      prefixIcon: const Icon(Icons.calculate),
                      items:      _Str.formulaOptions,
                      onChanged:  (val) => setState(() {
                        _formulaController.text = val ?? '';
                        _bmrResult = null;
                      }),
                    ),
                  ),

                  _buildFormulaInfo(sw),
                  SizedBox(height: sw * 0.04),

                  // ── Weight Field ───────────────────────────────────────
                  ResponsiveNumberField(
                    widgetKey:     _Keys.weightField,
                    controller:    _weightController,
                    label:         _Str.weightLabel,
                    prefixIcon:    const Icon(Icons.monitor_weight),
                    suffixText:    _Str.weightUnit,
                    semanticLabel: 'Input Berat Badan BMR',
                    semanticHint:  'Masukkan berat badan dalam kilogram',
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Height Field ───────────────────────────────────────
                  ResponsiveNumberField(
                    widgetKey:     _Keys.heightField,
                    controller:    _heightController,
                    label:         _Str.heightLabel,
                    prefixIcon:    const Icon(Icons.height),
                    suffixText:    _Str.heightUnit,
                    semanticLabel: 'Input Tinggi Badan BMR',
                    semanticHint:  'Masukkan tinggi badan dalam sentimeter',
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Gender Dropdown ────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Jenis Kelamin BMR',
                    hint:  'Pilih jenis kelamin: Laki-laki atau Perempuan',
                    child: _buildDropdown(
                      widgetKey:  _Keys.genderDropdown,
                      controller: _genderController,
                      label:      _Str.genderLabel,
                      prefixIcon: const Icon(Icons.wc),
                      items:      _Str.genderOptions,
                      onChanged:  (val) => setState(() {
                        _genderController.text = val ?? '';
                        _bmrResult = null;
                      }),
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Age Field ──────────────────────────────────────────
                  ResponsiveNumberField(
                    widgetKey:     _Keys.ageField,
                    controller:    _ageController,
                    label:         _Str.ageLabel,
                    prefixIcon:    const Icon(Icons.calendar_today),
                    suffixText:    _Str.ageUnit,
                    semanticLabel: 'Input Umur BMR',
                    semanticHint:  'Masukkan umur dalam tahun',
                    isInteger:     true,
                    maxLength:     3,
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Action Buttons ─────────────────────────────────────
                  Semantics(
                    label: 'Tombol Aksi Form BMR',
                    hint:  'Tombol Reset menghapus semua input; '
                           'Tombol Hitung menghitung nilai BMR',
                    child: FormActionButtons(
                      key:                  _Keys.btnReset,
                      onReset:              _resetForm,
                      onSubmit:             _calculateBMR,
                      resetButtonColor:     Colors.white,
                      resetForegroundColor: _kBrandGreen,
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Result Section ─────────────────────────────────────
                  if (_bmrResult != null) ...[
                    SizedBox(key: _resultCardKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.08),

                    // [REFACTOR] _buildBmrResultCard diganti CalculationResultCard
                    CalculationResultCard(
                      containerKey: _Keys.bmrResultCard,
                      title:        'Hasil Perhitungan BMR\n(${_formulaController.text})',
                      value:        '${_bmrResult!.toStringAsFixed(2)} ${_Str.resultUnit}',
                      color:        _kBrandGreen,
                      subtitle:     _Str.resultDesc,
                      semanticsLabel:
                          'Hasil Perhitungan BMR: '
                          '${_bmrResult!.toStringAsFixed(2)} kkal per hari, '
                          'menggunakan formula ${_formulaController.text}',
                    ),
                    SizedBox(height: sw * 0.08),
                    _buildReferenceFormula(sw),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
Widget _buildReferenceFormula(double sw) {
    final bmrFormula = ReferenceData.formulas.firstWhere(
      (f) => f.id == 'formula_bmr',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Rumus Perhitungan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _responsiveFont(sw, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sw * 0.04),
        
        FormulaTile(
          semanticId: bmrFormula.id,
          title: bmrFormula.title,
          formulaName: bmrFormula.formulaName,
          formulaContent: bmrFormula.formulaContent,
          note: bmrFormula.note,
        ),
      ],
    );
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  Widget _buildFormulaInfo(double sw) {
    final String formula = _formulaController.text;
    final String desc    = formula == BmrTdeeCalculatorService.formulaHarris
        ? 'Menggunakan rumus Harris-Benedict (1919).'
        : 'Menggunakan rumus Mifflin-St Jeor '
          '(dianggap lebih akurat untuk populasi modern).';
    return Padding(
      padding: EdgeInsets.only(top: sw * 0.02),
      child: Text(
        '$formula dipilih. $desc',
        style: TextStyle(
          fontSize: _responsiveFont(sw, base: 12),
          color:    Colors.black54,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required ValueKey<String>        widgetKey,
    required TextEditingController   controller,
    required String                  label,
    required Icon                    prefixIcon,
    required List<String>            items,
    void Function(String?)?          onChanged,
  }) {
    return DropdownSearch<String>(
      key:       widgetKey,
      popupProps: const PopupProps.menu(
        showSearchBox: false,
        fit:           FlexFit.loose,
        constraints:   BoxConstraints(maxHeight: 240),
      ),
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText:  label,
          border:     const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged:    onChanged ?? (val) => setState(() => controller.text = val ?? ''),
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator:    (v) => (v == null || v.isEmpty) ? '$label harus dipilih' : null,
    );
  }

  double _responsiveFont(double sw, {required double base}) {
    if (sw <= 360) return base * 0.90;
    if (sw >= 600) return base * 1.20;
    return base;
  }
}