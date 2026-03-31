// lib/src/features/nutrition_calculation/presentation/pages/bbi_form_page.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// [REFACTOR] Import Service & Widgets baru
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bbi_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/calculation_result_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/responsive_number_field.dart';

import 'package:aplikasi_diagnosa_gizi/src/features/reference/data/models/reference_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/widgets/reference_widgets.dart';

// ---------------------------------------------------------------------------
// [QA] ValueKey TIDAK diubah.
// ---------------------------------------------------------------------------
class _Keys {
  const _Keys._();
  static const patientPicker = ValueKey('patientPickerWidget');
  static const heightField = ValueKey('heightField');
  static const genderDropdown = ValueKey('genderDropdown');
  static const btnReset = ValueKey('btnReset');
  static const bbiResultCard = ValueKey('bbiResultCard');
}

class _Str {
  const _Str._();
  static const appBarTitle = 'BBI';
  static const appBarSubtitle = 'Berat Badan Ideal';
  static const sectionTitle = 'Input Data BBI';
  static const heightLabel = 'Tinggi Badan';
  static const heightUnit = 'cm';
  static const genderLabel = 'Jenis Kelamin';
  static const resultTitle = 'Hasil Perhitungan BBI';
  static const resultUnit = 'kg';
  static const resultDesc =
      'Berat Badan Ideal (BBI) adalah berat badan yang dianggap optimal '
      'untuk tinggi badan dan jenis kelamin.';
  static const List<String> genderOptions = [
    BbiCalculatorService.genderMale,
    BbiCalculatorService.genderFemale,
  ];
}

const _kBrandGreen = Color(0xFF009444);

// ===========================================================================
// PAGE WIDGET
// ===========================================================================

class BbiFormPage extends StatefulWidget {
  final String userRole;

  const BbiFormPage({super.key, required this.userRole});

  @override
  State<BbiFormPage> createState() => _BbiFormPageState();
}

class _BbiFormPageState extends State<BbiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _genderController = TextEditingController();
  final _scrollController = ScrollController();
  final _resultCardKey = GlobalKey();
  final _patientPickerKey = GlobalKey<PatientPickerWidgetState>();

  double? _bbiResult;

  @override
  void dispose() {
    _heightController.dispose();
    _genderController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  void _calculateBBI() {
    if (!_formKey.currentState!.validate()) return;

    final double height = double.parse(_heightController.text);
    final bool isMale = BbiCalculatorService.isMaleFromString(
      _genderController.text,
    );

    // [REFACTOR] Logika Broca ada di Service.
    setState(() {
      _bbiResult = BbiCalculatorService.calculateAdult(
        heightCm: height,
        isMale: isMale,
      );
    });
    _scrollToResult();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _heightController.clear();
      _genderController.clear();
      _bbiResult = null;
    });
    _patientPickerKey.currentState?.resetSelection();
  }

  void _fillDataFromPatient(
    double weight,
    double height,
    String gender,
    DateTime dob,
  ) {
    setState(() {
      _heightController.text = height.toString();
      _genderController.text = BbiCalculatorService.normalizeGender(gender);
      _bbiResult = null;
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

  // ── Build ─────────────────────────────────────────────────────────────────

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
                  Semantics(
                    key: _Keys.patientPicker,
                    label: 'Pemilih Pasien',
                    hint:
                        'Pilih pasien untuk mengisi data tinggi badan dan '
                        'jenis kelamin secara otomatis',
                    child: PatientPickerWidget(
                      key: _patientPickerKey,
                      onPatientSelected: _fillDataFromPatient,
                      userRole: widget.userRole,
                    ),
                  ),

                  SizedBox(height: sw * 0.05),

                  Text(
                    _Str.sectionTitle,
                    style: TextStyle(
                      fontSize: _responsiveFont(sw, base: 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: sw * 0.05),

                  ResponsiveNumberField(
                    widgetKey: _Keys.heightField,
                    controller: _heightController,
                    label: _Str.heightLabel,
                    prefixIcon: const Icon(Icons.height),
                    suffixText: _Str.heightUnit,
                    semanticLabel: 'Input Tinggi Badan',
                    semanticHint: 'Masukkan tinggi badan dalam sentimeter',
                  ),

                  SizedBox(height: sw * 0.04),

                  Semantics(
                    label: 'Dropdown Jenis Kelamin',
                    hint: 'Pilih jenis kelamin: Laki-laki atau Perempuan',
                    child: DropdownSearch<String>(
                      key: _Keys.genderDropdown,
                      popupProps: const PopupProps.menu(
                        showSearchBox: false,
                        fit: FlexFit.loose,
                      ),
                      items: _Str.genderOptions,
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText: _Str.genderLabel,
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.wc),
                        ),
                      ),
                      onChanged: (val) =>
                          setState(() => _genderController.text = val ?? ''),
                      selectedItem: _genderController.text.isEmpty
                          ? null
                          : _genderController.text,
                      validator: (v) => (v == null || v.isEmpty)
                          ? '${_Str.genderLabel} harus dipilih'
                          : null,
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  Semantics(
                    label: 'Tombol Aksi Form BBI',
                    hint:
                        'Tombol Reset menghapus semua input; '
                        'Tombol Hitung menghitung nilai BBI',
                    child: FormActionButtons(
                      key: _Keys.btnReset,
                      onReset: _resetForm,
                      onSubmit: _calculateBBI,
                      resetButtonColor: Colors.white,
                      resetForegroundColor: _kBrandGreen,
                      submitIcon: const Icon(
                        Icons.calculate,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  if (_bbiResult != null) ...[
                    SizedBox(key: _resultCardKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.08),
                    CalculationResultCard(
                      containerKey: _Keys.bbiResultCard,
                      title: _Str.resultTitle,
                      value:
                          '${_bbiResult!.toStringAsFixed(2)} ${_Str.resultUnit}',
                      color: _kBrandGreen,
                      subtitle: _Str.resultDesc,
                      semanticsLabel:
                          'Hasil Perhitungan BBI: '
                          '${_bbiResult!.toStringAsFixed(2)} kilogram',
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
    final formula = ReferenceData.formulas.firstWhere(
      (f) => f.id == 'formula_broca',
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
          semanticId: formula.id,
          title: formula.title,
          formulaName: formula.formulaName,
          formulaContent: formula.formulaContent,
          note: formula.note,
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
