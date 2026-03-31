// lib/src/features/nutrition_calculation/presentation/pages/schofield_form_page.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/schofield_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bmr_tdee_calculator_service.dart'; // Untuk helper umur & normalisasi gender
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/calculation_result_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/responsive_number_field.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/data/models/reference_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/widgets/reference_widgets.dart';

class _Keys {
  const _Keys._();
  static const patientPicker = ValueKey('patientPickerWidget');
  static const modeDropdown = ValueKey('modeDropdown');
  static const genderDropdown = ValueKey('genderDropdown');
  static const ageField = ValueKey('ageField');
  static const weightField = ValueKey('weightField');
  static const heightField = ValueKey('heightField');
  static const activityDropdown = ValueKey('activityDropdown');
  static const stressDropdown = ValueKey('stressDropdown');
  static const btnReset = ValueKey('btnReset');
  static const resultCard = ValueKey('schofieldResultCard');
}

class _Str {
  const _Str._();
  static const appBarTitle = 'Schofield';
  static const appBarSubtitle = 'BMR Anak & Remaja (0-18 Tahun)';
  static const sectionTitle = 'Input Data Schofield';

  static const modeLabel = 'Metode Perhitungan';
  static const modeWeightOnly = 'Hanya Berat Badan';
  static const modeWeightHeight = 'Berat & Tinggi Badan';

  static const List<String> genderOptions = ['Laki-laki', 'Perempuan'];
  static const List<String> modeOptions = [modeWeightOnly, modeWeightHeight];
}

const _kBrandGreen = Color(0xFF009444);

class SchofieldFormPage extends StatefulWidget {
  final String userRole;
  const SchofieldFormPage({super.key, required this.userRole});

  @override
  State<SchofieldFormPage> createState() => _SchofieldFormPageState();
}

class _SchofieldFormPageState extends State<SchofieldFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _modeController = TextEditingController(text: _Str.modeWeightOnly);
  final _genderController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _activityController = TextEditingController(
    text: 'Tanpa Faktor Aktivitas',
  );
  final _stressController = TextEditingController(text: 'Tanpa Faktor Stres');

  final _scrollController = ScrollController();
  final _resultCardKey = GlobalKey();
  final _patientPickerKey = GlobalKey<PatientPickerWidgetState>();

  double? _bmrResult;
  double? _totalEnergyResult;

  bool get _requiresHeight => _modeController.text == _Str.modeWeightHeight;

  @override
  void dispose() {
    _modeController.dispose();
    _genderController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _activityController.dispose();
    _stressController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _calculateSchofield() {
    if (!_formKey.currentState!.validate()) return;

    final double age = double.parse(_ageController.text);
    final double weight = double.parse(_weightController.text);
    final bool isMale = _genderController.text == 'Laki-laki';

    double bmr = 0;

    try {
      if (_requiresHeight) {
        final double height = double.parse(_heightController.text);
        bmr = SchofieldCalculatorService.calculateWithWeightAndHeight(
          weightKg: weight,
          heightCm: height,
          ageInYears: age,
          isMale: isMale,
        );
      } else {
        bmr = SchofieldCalculatorService.calculateWithWeightOnly(
          weightKg: weight,
          ageInYears: age,
          isMale: isMale,
        );
      }

      final double activity =
          SchofieldCalculatorService.activityFactors[_activityController
              .text] ??
          1.0;
      final double stress =
          SchofieldCalculatorService.stressFactors[_stressController.text] ??
          1.0;

      setState(() {
        _bmrResult = bmr;
        _totalEnergyResult = bmr * activity * stress;
      });

      _scrollToResult();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _modeController.text = _Str.modeWeightOnly;
      _genderController.clear();
      _ageController.clear();
      _weightController.clear();
      _heightController.clear();
      _activityController.text = 'Tanpa Faktor Aktivitas';
      _stressController.text = 'Tanpa Faktor Stres';
      _bmrResult = null;
      _totalEnergyResult = null;
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
      _genderController.text = BmrTdeeCalculatorService.normalizeGender(gender);
      _ageController.text = BmrTdeeCalculatorService.calculateAgeInYears(
        birthDate: dob,
        checkDate: DateTime.now(),
      ).toString();
      _bmrResult = null;
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
                  PatientPickerWidget(
                    key: _Keys.patientPicker,
                    onPatientSelected: _fillDataFromPatient,
                    userRole: widget.userRole,
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

                  _buildDropdown(
                    widgetKey: _Keys.modeDropdown,
                    controller: _modeController,
                    label: _Str.modeLabel,
                    prefixIcon: const Icon(Icons.tune),
                    items: _Str.modeOptions,
                    onChanged: (val) => setState(() {
                      _modeController.text = val ?? '';
                      _bmrResult = null;
                    }),
                    menuHeight: 120,
                  ),
                  SizedBox(height: sw * 0.04),

                  _buildDropdown(
                    widgetKey: _Keys.genderDropdown,
                    controller: _genderController,
                    label: 'Jenis Kelamin',
                    prefixIcon: const Icon(Icons.wc),
                    items: _Str.genderOptions,
                    menuHeight: 120,
                  ),
                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey: _Keys.ageField,
                    controller: _ageController,
                    label: 'Usia',
                    prefixIcon: const Icon(Icons.cake),
                    suffixText: 'tahun',
                    customValidator: (v) {
                      if (v == null || v.isEmpty) return 'Usia wajib diisi';
                      final age = double.tryParse(v);
                      if (age == null) return 'Angka tidak valid';
                      if (age < 0 || age > 18) return 'Usia harus 0-18 tahun';
                      return null;
                    },
                  ),
                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey: _Keys.weightField,
                    controller: _weightController,
                    label: 'Berat Badan',
                    prefixIcon: const Icon(Icons.monitor_weight),
                    suffixText: 'kg',
                  ),

                  if (_requiresHeight) ...[
                    SizedBox(height: sw * 0.04),
                    ResponsiveNumberField(
                      widgetKey: _Keys.heightField,
                      controller: _heightController,
                      label: 'Tinggi Badan',
                      prefixIcon: const Icon(Icons.height),
                      suffixText: 'cm',
                    ),
                  ],

                  SizedBox(height: sw * 0.04),
                  _buildDropdown(
                    widgetKey: _Keys.activityDropdown,
                    controller: _activityController,
                    label: 'Faktor Aktivitas',
                    prefixIcon: const Icon(Icons.directions_run),
                    items: SchofieldCalculatorService.activityFactors.keys
                        .toList(),
                    menuHeight: 250,
                  ),
                  SizedBox(height: sw * 0.04),

                  _buildDropdown(
                    widgetKey: _Keys.stressDropdown,
                    controller: _stressController,
                    label: 'Faktor Stres',
                    prefixIcon: const Icon(Icons.healing),
                    items: SchofieldCalculatorService.stressFactors.keys
                        .toList(),
                    menuHeight: 250,
                  ),

                  SizedBox(height: sw * 0.08),
                  FormActionButtons(
                    key: _Keys.btnReset,
                    onReset: _resetForm,
                    onSubmit: _calculateSchofield,
                    resetButtonColor: Colors.white,
                    resetForegroundColor: _kBrandGreen,
                    submitIcon: const Icon(
                      Icons.calculate,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: sw * 0.08),

                  if (_bmrResult != null) ...[
                    SizedBox(key: _resultCardKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.08),

                    CalculationResultCard(
                      containerKey: _Keys.resultCard,
                      title: 'Kebutuhan Kalori Anak (Schofield)',
                      value:
                          'Total: ${_totalEnergyResult!.toStringAsFixed(2)} kkal/hari',
                      color: _kBrandGreen,
                      subtitle:
                          'Estimasi total energi harian berdasarkan BMR, aktivitas, dan stres.',
                      extra: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'BMR Basal: ${_bmrResult!.toStringAsFixed(2)} kkal/hari',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ),
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
      (f) => f.id == 'formula_schofield_anak',
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

  Widget _buildDropdown({
    required ValueKey<String> widgetKey,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required List<String> items,
    void Function(String?)? onChanged,
    double? menuHeight,
  }) {
    return DropdownSearch<String>(
      key: widgetKey,
      popupProps: PopupProps.menu(
        showSearchBox: false,
        constraints: BoxConstraints(maxHeight: menuHeight ?? 180),
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
          onChanged ?? (val) => setState(() => controller.text = val ?? ''),
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (v) =>
          (v == null || v.isEmpty) ? '$label harus dipilih' : null,
    );
  }

  double _responsiveFont(double sw, {required double base}) {
    if (sw <= 360) return base * 0.90;
    if (sw >= 600) return base * 1.20;
    return base;
  }
}
