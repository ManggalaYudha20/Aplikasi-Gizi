// lib/src/features/nutrition_calculation/presentation/pages/tdee_form_page.dart

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
  static const patientPicker     = ValueKey('patientPickerWidget');
  static const weightField       = ValueKey('weightField');
  static const heightField       = ValueKey('heightField');
  static const genderDropdown    = ValueKey('genderDropdown');
  static const ageField          = ValueKey('ageField');
  static const activityDropdown  = ValueKey('activityDropdown');
  static const stressDropdown    = ValueKey('stressDropdown');
  static const tempField         = ValueKey('tempField');
  static const btnReset          = ValueKey('btnReset');
  static const tdeeResultCard    = ValueKey('tdeeResultCard');
}

class _Str {
  const _Str._();
  static const appBarTitle    = 'TDEE';
  static const appBarSubtitle = 'Total Daily Energy Expenditure';
  static const sectionTitle   = 'Input Data TDEE';
  static const weightLabel    = 'Berat Badan';
  static const weightUnit     = 'kg';
  static const heightLabel    = 'Tinggi Badan';
  static const heightUnit     = 'cm';
  static const genderLabel    = 'Jenis Kelamin';
  static const ageLabel       = 'Usia';
  static const ageUnit        = 'tahun';
  static const activityLabel  = 'Faktor Aktivitas';
  static const stressLabel    = 'Faktor Stress';
  static const tempLabel      = 'Suhu Tubuh';
  static const tempUnit       = '°C';
  static const resultUnit     = 'kkal/hari';
  static const resultTitle    = 'Hasil Perhitungan TDEE';
  static const resultDesc     =
      'TDEE adalah perkiraan jumlah total kalori yang dibakar oleh tubuh '
      'dalam satu hari (24 jam).';
  static const macroUnit  = 'gram/hari';
  static const macroTitle = 'Kebutuhan Makronutrien';
  static const macroDesc  =
      'Kebutuhan zat gizi dihitung berdasarkan pedoman gizi seimbang: '
      '60% energi dari Karbohidrat, 25% dari Lemak, dan 15% dari Protein.';

  static const List<String> genderOptions = [
    BmrTdeeCalculatorService.genderMale,
    BmrTdeeCalculatorService.genderFemale,
  ];
}

const _kBrandGreen = Color(0xFF009444);

// ===========================================================================
// PAGE WIDGET
// ===========================================================================

class TdeeFormPage extends StatefulWidget {
  final String userRole;

  const TdeeFormPage({super.key, required this.userRole});

  @override
  State<TdeeFormPage> createState() => _TdeeFormPageState();
}

class _TdeeFormPageState extends State<TdeeFormPage> {
  // ── Controllers & Keys ────────────────────────────────────────────────────
  final _formKey                  = GlobalKey<FormState>();
  final _weightController         = TextEditingController();
  final _heightController         = TextEditingController();
  final _ageController            = TextEditingController();
  final _temperatureController    = TextEditingController();
  final _genderController         = TextEditingController();
  final _activityFactorController = TextEditingController();
  final _stressFactorController   = TextEditingController();
  final _scrollController         = ScrollController();
  final _resultCardKey            = GlobalKey();
  final _patientPickerKey         = GlobalKey<PatientPickerWidgetState>();

  // ── State ─────────────────────────────────────────────────────────────────
  // [REFACTOR] Diganti dari 5 variabel double? menjadi TdeeResult? yang type-safe.
  TdeeResult? _result;

  bool get _isFeverSelected =>
      _stressFactorController.text == BmrTdeeCalculatorService.feverKey;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _ageController.dispose();
    _temperatureController.dispose();
    _genderController.dispose();
    _activityFactorController.dispose();
    _stressFactorController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  void _calculateTDEE() {
    if (!_formKey.currentState!.validate()) return;

    final double weight = double.parse(_weightController.text);
    final double height = double.parse(_heightController.text);
    final int    age    = int.parse(_ageController.text);
    final bool   isMale =
        BmrTdeeCalculatorService.isMaleFromString(_genderController.text);
    final double temp = double.tryParse(_temperatureController.text) ??
        BmrTdeeCalculatorService.normalBodyTemperature;

    // [REFACTOR] Semua logika (BMR, stres, aktivitas, makro) ada di Service.
    setState(() {
      _result = BmrTdeeCalculatorService.calculateTdee(
        weightKg:          weight,
        heightCm:          height,
        ageYears:          age,
        isMale:            isMale,
        activityCondition: _activityFactorController.text,
        stressCondition:   _stressFactorController.text,
        bodyTemperatureC:  temp,
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
      _genderController.clear();
      _activityFactorController.clear();
      _stressFactorController.clear();
      _result = null;
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
                           'tinggi badan, jenis kelamin, dan usia secara otomatis',
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

                  ResponsiveNumberField(
                    widgetKey:     _Keys.weightField,
                    controller:    _weightController,
                    label:         _Str.weightLabel,
                    prefixIcon:    const Icon(Icons.monitor_weight),
                    suffixText:    _Str.weightUnit,
                    semanticLabel: 'Input Berat Badan TDEE',
                    semanticHint:  'Masukkan berat badan dalam kilogram',
                  ),

                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey:     _Keys.heightField,
                    controller:    _heightController,
                    label:         _Str.heightLabel,
                    prefixIcon:    const Icon(Icons.height),
                    suffixText:    _Str.heightUnit,
                    semanticLabel: 'Input Tinggi Badan TDEE',
                    semanticHint:  'Masukkan tinggi badan dalam sentimeter',
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Gender Dropdown ────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Jenis Kelamin TDEE',
                    hint:  'Pilih jenis kelamin: Laki-laki atau Perempuan',
                    child: _buildDropdown(
                      widgetKey:  _Keys.genderDropdown,
                      controller: _genderController,
                      label:      _Str.genderLabel,
                      prefixIcon: const Icon(Icons.wc),
                      items:      _Str.genderOptions,
                      menuHeight: 120,
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey:     _Keys.ageField,
                    controller:    _ageController,
                    label:         _Str.ageLabel,
                    prefixIcon:    const Icon(Icons.calendar_today),
                    suffixText:    _Str.ageUnit,
                    semanticLabel: 'Input Usia TDEE',
                    semanticHint:  'Masukkan usia dalam tahun',
                    isInteger:     true,
                    maxLength:     3,
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Activity Dropdown ──────────────────────────────────
                  Semantics(
                    label: 'Dropdown Faktor Aktivitas TDEE',
                    hint:  'Pilih tingkat aktivitas fisik harian untuk '
                           'kalkulasi kebutuhan energi',
                    child: _buildDropdown(
                      widgetKey:  _Keys.activityDropdown,
                      controller: _activityFactorController,
                      label:      _Str.activityLabel,
                      prefixIcon: const Icon(Icons.directions_run),
                      // [REFACTOR] Ambil key dari Service, bukan Map lokal
                      items: BmrTdeeCalculatorService.activityFactors.keys.toList(),
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Stress Dropdown ────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Faktor Stress TDEE',
                    hint:  'Pilih kondisi klinis atau faktor stress metabolik '
                           'yang sesuai dengan kondisi pasien',
                    child: _buildDropdown(
                      widgetKey:  _Keys.stressDropdown,
                      controller: _stressFactorController,
                      label:      _Str.stressLabel,
                      prefixIcon: const Icon(Icons.healing),
                      items: BmrTdeeCalculatorService.stressFactors.keys.toList(),
                      onChanged: (String? value) {
                        final scope = FocusScope.of(context);
                        setState(() {
                          _stressFactorController.text = value ?? '';
                          if (value != BmrTdeeCalculatorService.feverKey) {
                            _temperatureController.clear();
                          }
                        });
                        Future.delayed(
                          const Duration(milliseconds: 10),
                          () { if (mounted) scope.unfocus(); },
                        );
                      },
                      menuHeight: 240,
                    ),
                  ),

                  // ── Temperature Field (kondisional, hanya saat Demam) ──
                  if (_isFeverSelected) ...[
                    SizedBox(height: sw * 0.04),
                    ResponsiveNumberField(
                      widgetKey:     _Keys.tempField,
                      controller:    _temperatureController,
                      label:         _Str.tempLabel,
                      prefixIcon:    const Icon(Icons.thermostat),
                      suffixText:    _Str.tempUnit,
                      semanticLabel: 'Input Suhu Tubuh TDEE',
                      semanticHint:  'Masukkan suhu tubuh dalam derajat Celsius '
                                     'untuk menghitung faktor demam',
                      customValidator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Suhu tidak boleh kosong';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Masukkan angka yang valid';
                        }
                        return null;
                      },
                    ),
                  ],

                  SizedBox(height: sw * 0.08),

                  // ── Action Buttons ─────────────────────────────────────
                  Semantics(
                    label: 'Tombol Aksi Form TDEE',
                    hint:  'Tombol Reset menghapus semua input; '
                           'Tombol Hitung menghitung nilai TDEE',
                    child: FormActionButtons(
                      key:                  _Keys.btnReset,
                      onReset:              _resetForm,
                      onSubmit:             _calculateTDEE,
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

                    // [REFACTOR] _buildTdeeResultCard diganti CalculationResultCard + extra
                    CalculationResultCard(
                      containerKey: _Keys.tdeeResultCard,
                      title:        _Str.resultTitle,
                      value:        'TDEE: ${_result!.tdee.toStringAsFixed(2)} ${_Str.resultUnit}',
                      color:        _kBrandGreen,
                      subtitle:     _Str.resultDesc,
                      semanticsLabel:
                          'Hasil Perhitungan TDEE: '
                          'BMR ${_result!.bmr.toStringAsFixed(2)} kkal per hari, '
                          'TDEE ${_result!.tdee.toStringAsFixed(2)} kkal per hari',
                      extra: _buildMacroSection(sw),
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
    // Ambil data formula TDEE dan Makro dari ReferenceData
    final tdeeFormula = ReferenceData.formulas.firstWhere(
      (f) => f.id == 'formula_tdee',
    );
    final macroFormula = ReferenceData.formulas.firstWhere(
      (f) => f.id == 'formula_makronutrien',
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
        
        // Memakai widget FormulaTile bawaan Anda yang sudah berupa ExpansionTile
        FormulaTile(
          semanticId: tdeeFormula.id,
          title: tdeeFormula.title,
          formulaName: tdeeFormula.formulaName,
          formulaContent: tdeeFormula.formulaContent,
          note: tdeeFormula.note,
        ),
        
        FormulaTile(
          semanticId: macroFormula.id,
          title: macroFormula.title,
          formulaName: macroFormula.formulaName,
          formulaContent: macroFormula.formulaContent,
          note: macroFormula.note,
        ),
      ],
    );
  }

  // ── Private Helpers ───────────────────────────────────────────────────────

  /// Baris detail BMR + distribusi makronutrien untuk slot [extra] di result card.
  Widget _buildMacroSection(double sw) {
    final double fontBase14 = _responsiveFont(sw, base: 14);
    final double fontBase16 = _responsiveFont(sw, base: 16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // BMR (nilai antara)
        Text(
          'BMR: ${_result!.bmr.toStringAsFixed(2)} ${_Str.resultUnit}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize:   fontBase16,
            fontWeight: FontWeight.bold,
            color:      _kBrandGreen,
          ),
        ),
        SizedBox(height: sw * 0.02),

        Text(
          _Str.macroTitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize:   fontBase14,
            fontWeight: FontWeight.w600,
            color:      Colors.black87,
          ),
        ),
        SizedBox(height: sw * 0.02),

        Text(
          'Karbohidrat (60%): ${_result!.carbsGram.toStringAsFixed(2)} ${_Str.macroUnit}',
          style: TextStyle(
            fontSize:   fontBase16,
            fontWeight: FontWeight.bold,
            color:      Colors.blue[700],
          ),
        ),
        SizedBox(height: sw * 0.01),

        Text(
          'Lemak (25%): ${_result!.fatGram.toStringAsFixed(2)} ${_Str.macroUnit}',
          style: TextStyle(
            fontSize:   fontBase16,
            fontWeight: FontWeight.bold,
            color:      Colors.orange[700],
          ),
        ),
        SizedBox(height: sw * 0.01),

        Text(
          'Protein (15%): ${_result!.proteinGram.toStringAsFixed(2)} ${_Str.macroUnit}',
          style: TextStyle(
            fontSize:   fontBase16,
            fontWeight: FontWeight.bold,
            color:      Colors.red[700],
          ),
        ),
        SizedBox(height: sw * 0.02),

        Text(
          _Str.macroDesc,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: fontBase14,
            color:    Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required ValueKey<String>        widgetKey,
    required TextEditingController   controller,
    required String                  label,
    required Icon                    prefixIcon,
    required List<String>            items,
    void Function(String?)?          onChanged,
    double?                          menuHeight,
  }) {
    return DropdownSearch<String>(
      key:        widgetKey,
      onBeforePopupOpening: (_) {
        FocusScope.of(context).unfocus();
        return Future.value(true);
      },
      popupProps: PopupProps.menu(
        showSearchBox: false,
        constraints:   BoxConstraints(maxHeight: menuHeight ?? 180),
        scrollbarProps: const ScrollbarProps(
          thumbVisibility: true,
          thickness:       6,
          radius:          Radius.circular(10),
        ),
      ),
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText:  label,
          border:     const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged: onChanged ??
          (String? val) {
            setState(() => controller.text = val ?? '');
            Future.delayed(
              const Duration(milliseconds: 10),
              () { if (mounted) FocusScope.of(context).unfocus(); },
            );
          },
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