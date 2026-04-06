// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\nutrition_calculation\presentation\pages\bmi_form_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/data/models/reference_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/widgets/reference_widgets.dart';

// [REFACTOR] Import Service & Widgets baru
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bmi_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/calculation_result_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/responsive_number_field.dart';

// ---------------------------------------------------------------------------
// [OPTIMIZATION] ValueKey & String literal di-hoist — tidak realokasi per-build.
// [QA] Nilai key TIDAK diubah agar Katalon Object Spy tetap valid.
// ---------------------------------------------------------------------------
class _Keys {
  const _Keys._();
  static const patientPicker = ValueKey('patientPickerWidget');
  static const weightField = ValueKey('weightField');
  static const heightField = ValueKey('heightField');
  static const btnReset = ValueKey('btnReset');
  static const bmiResultCard = ValueKey('bmiResultCard');
}

class _Str {
  const _Str._();
  static const sectionTitle = 'Input Data IMT';
  static const weightLabel = 'Berat Badan';
  static const heightLabel = 'Tinggi Badan';
  static const weightUnit = 'kg';
  static const heightUnit = 'cm';
  static const resultTitle = 'Hasil Perhitungan IMT';
  static const resultDesc =
      'Indeks Massa Tubuh (IMT) adalah ukuran untuk mengevaluasi berat badan '
      'ideal berdasarkan tinggi badan.';
}

const _kBrandGreen = Color(0xFF009444);

// ===========================================================================
// PAGE WIDGET
// ===========================================================================

class BmiFormPage extends StatefulWidget {
  final String userRole;

  const BmiFormPage({super.key, required this.userRole});

  @override
  State<BmiFormPage> createState() => _BmiFormPageState();
}

class _BmiFormPageState extends State<BmiFormPage> {
  // ── Controllers & Keys ────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _scrollController = ScrollController();
  final _resultCardKey = GlobalKey();
  final _patientPickerKey = GlobalKey<PatientPickerWidgetState>();

  // ── State ─────────────────────────────────────────────────────────────────
  // [REFACTOR] Diganti dari (double?, String?, Color?) ke BmiResult? yang type-safe.
  BmiResult? _result;

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic (didelegasikan ke BmiCalculatorService) ────────────────

  void _calculateBMI() {
    if (!_formKey.currentState!.validate()) return;

    final double weight = double.parse(_weightController.text);
    final double height = double.parse(_heightController.text);

    // [REFACTOR] Semua logika hitung + klasifikasi ada di Service.
    // Page hanya meneruskan input dan menyimpan hasil.
    setState(() {
      _result = BmiCalculatorService.calculateAndClassify(
        weightKg: weight,
        heightCm: height,
      );
    });

    _scrollToResult();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _result = null;
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
      _weightController.text = weight.toString();
      _heightController.text = height.toString();
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.sizeOf(context).width;
    final double hPad = sw * 0.04;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(title: 'IMT', subtitle: 'Indeks Massa Tubuh'),
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
                    key: _Keys.patientPicker,
                    label: 'Pemilih Pasien',
                    hint:
                        'Pilih pasien untuk mengisi data berat dan tinggi badan secara otomatis',
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

                  // ── Weight Field ───────────────────────────────────────
                  // [REFACTOR] _buildInputField diganti ResponsiveNumberField
                  ResponsiveNumberField(
                    widgetKey: _Keys.weightField,
                    controller: _weightController,
                    label: _Str.weightLabel,
                    prefixIcon: const Icon(Icons.monitor_weight),
                    suffixText: _Str.weightUnit,
                    semanticLabel: 'Input Berat Badan',
                    semanticHint: 'Masukkan berat badan dalam kilogram',
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Height Field ───────────────────────────────────────
                  ResponsiveNumberField(
                    widgetKey: _Keys.heightField,
                    controller: _heightController,
                    label: _Str.heightLabel,
                    prefixIcon: const Icon(Icons.height),
                    suffixText: _Str.heightUnit,
                    semanticLabel: 'Input Tinggi Badan',
                    semanticHint: 'Masukkan tinggi badan dalam sentimeter',
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Action Buttons ─────────────────────────────────────
                  Semantics(
                    label: 'Tombol Aksi Form IMT',
                    hint:
                        'Tombol Reset menghapus semua input; Tombol Hitung menghitung nilai IMT',
                    child: FormActionButtons(
                      key: _Keys.btnReset,
                      onReset: _resetForm,
                      onSubmit: _calculateBMI,
                      resetButtonColor: Colors.white,
                      resetForegroundColor: _kBrandGreen,
                      submitIcon: const Icon(
                        Icons.calculate,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Result Section ─────────────────────────────────────
                  if (_result != null) ...[
                    SizedBox(key: _resultCardKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.08),

                    // [REFACTOR] _buildResultCard diganti CalculationResultCard
                    CalculationResultCard(
                      containerKey: _Keys.bmiResultCard,
                      title: _Str.resultTitle,
                      value: '${_result!.bmi.toStringAsFixed(2)} kg/m\u00B2',
                      category: _result!.categoryLabel,
                      color: _resolveColor(_result!.classification),
                      subtitle: _Str.resultDesc,
                      semanticsLabel:
                          'Hasil Perhitungan IMT: '
                          '${_result!.bmi.toStringAsFixed(2)} kilogram per meter kuadrat, '
                          'Kategori ${_result!.categoryLabel}',
                    ),

                    SizedBox(height: sw * 0.08),
                    _buildReferenceFormula(sw),

                    SizedBox(height: sw * 0.08),
                    _buildReferenceTables(sw),
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

  /// Memetakan [BmiClassification] ke warna indikator.
  /// Logika warna tetap di page (presentasi), bukan di service.
  Color _resolveColor(BmiClassification cls) {
    switch (cls) {
      case BmiClassification.normal:
        return _kBrandGreen;
      case BmiClassification.gemuk:
      case BmiClassification.kurus:
        return Colors.orange;
      case BmiClassification.kurusSekali:
      case BmiClassification.obesitas:
        return Colors.red;
    }
  }

  Widget _buildReferenceFormula(double sw) {
    // Ambil data formula IMT dari ReferenceData
    final imtFormula = ReferenceData.formulas.firstWhere(
      (f) => f.id == 'formula_imt',
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
          semanticId: imtFormula.id,
          title: imtFormula.title,
          formulaName: imtFormula.formulaName,
          formulaContent: imtFormula.formulaContent,
          note: imtFormula.note,
        ),
      ],
    );
  }

  Widget _buildReferenceTables(double sw) {
    final imtTables = ReferenceData.referenceTables
        .where(
          (t) => [
            'table_imt_indo',
            'table_imt_asia',
            'table_imt_eropa',
          ].contains(t.id),
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tabel Referensi IMT',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: _responsiveFont(sw, base: 18),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: sw * 0.04),
        ...imtTables.map(
          (table) => ReferenceTableWidget(
            key: ValueKey(table.id),
            semanticId: table.id,
            title: table.title,
            subtitle: table.subtitle,
            headers: table.headers,
            data: table.data,
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
