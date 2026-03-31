// lib/src/features/nutrition_calculation/presentation/pages/imtu_form_page.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// [REFACTOR] Import Service & Widgets baru
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/nutrition_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/calculation_result_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/responsive_number_field.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/data/models/reference_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/widgets/reference_widgets.dart';

// ---------------------------------------------------------------------------
// [QA] ValueKey TIDAK diubah.
// ---------------------------------------------------------------------------
class _Keys {
  const _Keys._();
  static const patientPicker  = ValueKey('patientPickerWidget');
  static const ageYearField   = ValueKey('ageYearField');
  static const ageMonthField  = ValueKey('ageMonthField');
  static const genderDropdown = ValueKey('genderDropdown');
  static const weightField    = ValueKey('weightField');
  static const heightField    = ValueKey('heightField');
  static const btnReset       = ValueKey('btnReset');
  static const imtuResultCard = ValueKey('imtuResultCard');
}

class _Str {
  const _Str._();
  static const appBarTitle        = 'IMT/U';
  static const appBarSubtitle     = 'Usia 5-18 Tahun';
  static const sectionTitle       = 'Input Data IMT/U  5-18 Tahun';
  static const resultSectionTitle = 'Hasil IMT Berdasarkan Usia 5-18 Tahun';
  static const yearLabel          = 'Tahun';
  static const yearUnit           = 'tahun';
  static const monthLabel         = 'Bulan';
  static const monthUnit          = 'bulan';
  static const genderLabel        = 'Jenis Kelamin';
  static const weightLabel        = 'Berat Badan';
  static const weightUnit         = 'kg';
  static const heightLabel        = 'Tinggi Badan';
  static const heightUnit         = 'cm';
  static const snackNoGender      = 'Pilih jenis kelamin terlebih dahulu';
  static const snackAgeRange      = 'Usia harus antara 5-18 tahun';

  static const List<String> genderOptions = [
    NutritionCalculatorService.genderMale,
    NutritionCalculatorService.genderFemale,
  ];
}

const _kBrandGreen = Color(0xFF009444);

// ===========================================================================
// PAGE WIDGET
// ===========================================================================

class IMTUFormPage extends StatefulWidget {
  final String userRole;

  const IMTUFormPage({super.key, required this.userRole});

  @override
  State<IMTUFormPage> createState() => _IMTUFormPageState();
}

class _IMTUFormPageState extends State<IMTUFormPage> {
  final _formKey             = GlobalKey<FormState>();
  final _weightController    = TextEditingController();
  final _heightController    = TextEditingController();
  final _ageYearsController  = TextEditingController();
  final _ageMonthsController = TextEditingController();
  final _genderController    = TextEditingController();
  final _scrollController    = ScrollController();
  final _resultCardKey       = GlobalKey();
  final _patientPickerKey    = GlobalKey<PatientPickerWidgetState>();

  // [REFACTOR] Diganti dari Map<String, dynamic>? ke ImtuResult? yang type-safe.
  ImtuResult? _result;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageYearsController.dispose();
    _ageMonthsController.dispose();
    _genderController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  void _calculateIMTU() {
    if (!_formKey.currentState!.validate()) return;

    if (_genderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_Str.snackNoGender)),
      );
      return;
    }

    final double weight    = double.tryParse(_weightController.text)    ?? 0;
    final double height    = double.tryParse(_heightController.text)    ?? 0;
    final int    ageYears  = int.tryParse(_ageYearsController.text)  ?? 0;
    final int    ageMonths = int.tryParse(_ageMonthsController.text) ?? 0;

    final int totalMonths = (ageYears * 12) + ageMonths;
    if (totalMonths < 60 || totalMonths > 216) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_Str.snackAgeRange)),
      );
      return;
    }

    // [REFACTOR] Semua logika hitung ada di Service.
    setState(() {
      _result = NutritionCalculatorService.calculateIMTUFromRawInputs(
        ageYears:           ageYears,
        ageMonthsRemainder: ageMonths,
        weightKg:           weight,
        heightCm:           height,
        gender:             _genderController.text,
      );
    });

    _scrollToResult();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _ageYearsController.clear();
      _ageMonthsController.clear();
      _genderController.clear();
      _result = null;
    });
    _patientPickerKey.currentState?.resetSelection();
  }

  void _fillDataFromPatient(
    double weight, double height, String gender, DateTime dob,
  ) {
    final DateTime now = DateTime.now();
    int years  = now.year - dob.year;
    int months = now.month - dob.month;
    if (now.day < dob.day) months--;
    if (months < 0) { months += 12; years--; }

    setState(() {
      _weightController.text    = weight.toString();
      _heightController.text    = height.toString();
      _ageYearsController.text  = years.toString();
      _ageMonthsController.text = months.toString();
      _genderController.text    = gender;
      _result = null;
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

  /// Memetakan string kategori ke warna indikator. Logika warna di page (presentasi).
  Color _resolveColor(String category) {
    final String lower = category.toLowerCase();
    if (lower.contains('buruk')  || lower.contains('severely')) return Colors.red;
    if (lower.contains('kurang') || lower.contains('wasted'))   return Colors.orange;
    if (lower.contains('baik')   || lower.contains('normal'))   return _kBrandGreen;
    return Colors.red; // overweight & obesitas
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

                  Semantics(
                    key:   _Keys.patientPicker,
                    label: 'Pemilih Pasien',
                    hint:  'Pilih pasien untuk mengisi data secara otomatis',
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

                  // ── Usia: Tahun + Bulan (baris sejajar) ────────────────
                  Row(
                    children: [
                      Expanded(
                        child: ResponsiveNumberField(
                          widgetKey:     _Keys.ageYearField,
                          controller:    _ageYearsController,
                          label:         _Str.yearLabel,
                          suffixText:    _Str.yearUnit,
                          semanticLabel: 'Input Usia Tahun',
                          semanticHint:  'Masukkan usia dalam tahun (5-18)',
                          isInteger:     true,
                          maxLength:     2,
                          customValidator: (v) {
                            if (v == null || v.isEmpty) return 'Tahun wajib diisi';
                            final n = int.tryParse(v);
                            if (n == null) return 'Angka tidak valid';
                            if (n < 0 || n > 18) return '5-18 tahun';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: sw * 0.04),
                      Expanded(
                        child: ResponsiveNumberField(
                          widgetKey:     _Keys.ageMonthField,
                          controller:    _ageMonthsController,
                          label:         _Str.monthLabel,
                          suffixText:    _Str.monthUnit,
                          semanticLabel: 'Input Usia Bulan',
                          semanticHint:  'Masukkan sisa bulan (0-11)',
                          isInteger:     true,
                          maxLength:     2,
                          customValidator: (v) {
                            if (v == null || v.isEmpty) return 'Bulan wajib diisi';
                            final n = int.tryParse(v);
                            if (n == null) return 'Angka tidak valid';
                            if (n < 0 || n > 11) return '0-11 bulan';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Gender Dropdown ────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Jenis Kelamin IMT/U',
                    hint:  'Pilih jenis kelamin: Laki-laki atau Perempuan',
                    child: DropdownSearch<String>(
                      key: _Keys.genderDropdown,
                      popupProps: const PopupProps.menu(
                        showSearchBox: false,
                        fit:           FlexFit.loose,
                        constraints:   BoxConstraints(maxHeight: 240),
                      ),
                      items: _Str.genderOptions,
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText:  _Str.genderLabel,
                          border:     OutlineInputBorder(),
                          prefixIcon: Icon(Icons.wc),
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _genderController.text = val ?? ''),
                      selectedItem: _genderController.text.isEmpty
                          ? null : _genderController.text,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '${_Str.genderLabel} harus dipilih' : null,
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey:     _Keys.weightField,
                    controller:    _weightController,
                    label:         _Str.weightLabel,
                    prefixIcon:    const Icon(Icons.monitor_weight),
                    suffixText:    _Str.weightUnit,
                    semanticLabel: 'Input Berat Badan IMT/U',
                    semanticHint:  'Masukkan berat badan dalam kilogram',
                  ),

                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey:     _Keys.heightField,
                    controller:    _heightController,
                    label:         _Str.heightLabel,
                    prefixIcon:    const Icon(Icons.height),
                    suffixText:    _Str.heightUnit,
                    semanticLabel: 'Input Tinggi Badan IMT/U',
                    semanticHint:  'Masukkan tinggi badan dalam sentimeter',
                  ),

                  SizedBox(height: sw * 0.08),

                  Semantics(
                    label: 'Tombol Aksi Form IMT/U',
                    hint:  'Tombol Reset menghapus semua input; '
                           'Tombol Hitung menghitung IMT/U',
                    child: FormActionButtons(
                      key:                  _Keys.btnReset,
                      onReset:              _resetForm,
                      onSubmit:             _calculateIMTU,
                      resetButtonColor:     Colors.white,
                      resetForegroundColor: _kBrandGreen,
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Result Section ─────────────────────────────────────
                  if (_result != null) ...[
                    SizedBox(key: _resultCardKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.08),

                    Text(
                      _Str.resultSectionTitle,
                      style: TextStyle(
                        fontSize:   _responsiveFont(sw, base: 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: sw * 0.04),

                    // [REFACTOR] _buildResultCard diganti ZScoreResultCard
                    ZScoreResultCard(
                      containerKey:   _Keys.imtuResultCard,
                      title:          'Indeks Massa Tubuh menurut Umur (IMT/U)',
                      zScore:         _result!.zScore,
                      category:       _result!.category,
                      color:          _resolveColor(_result!.category),
                      additionalInfo: 'IMT: ${_result!.bmi.toStringAsFixed(2)} kg/m\u00B2',
                      semanticsLabel:
                          'Hasil IMT/U: IMT ${_result!.bmi.toStringAsFixed(2)} kg/m², '
                          'Z-Score ${_result!.zScore?.toStringAsFixed(2) ?? "-"}, '
                          'Kategori ${_result!.category}',
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
    final imtFormula = ReferenceData.formulas.firstWhere((f) => f.id == 'formula_imt');
    final zscoreFormula = ReferenceData.formulas.firstWhere((f) => f.id == 'formula_zscore_anak');
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Rumus Perhitungan',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: _responsiveFont(sw, base: 18), fontWeight: FontWeight.bold),
        ),
        SizedBox(height: sw * 0.04),
        FormulaTile(
          semanticId: imtFormula.id,
          title: imtFormula.title,
          formulaName: imtFormula.formulaName,
          formulaContent: imtFormula.formulaContent,
          note: imtFormula.note,
        ),
        FormulaTile(
          semanticId: zscoreFormula.id,
          title: zscoreFormula.title,
          formulaName: zscoreFormula.formulaName,
          formulaContent: zscoreFormula.formulaContent,
          note: zscoreFormula.note,
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