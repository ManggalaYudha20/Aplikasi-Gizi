// lib/src/features/nutrition_calculation/presentation/pages/bbi_anak_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// [REFACTOR] Import Service & Widgets baru
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bbi_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/calculation_result_card.dart';

// ---------------------------------------------------------------------------
// [QA] ValueKey TIDAK diubah.
// ---------------------------------------------------------------------------
class _Keys {
  const _Keys._();
  static const patientPicker     = ValueKey('patientPickerWidget');
  static const categoryDropdown  = ValueKey('categoryDropdown');
  static const ageField          = ValueKey('ageField');
  static const btnReset          = ValueKey('btnReset');
  static const bbiAnakResultCard = ValueKey('bbiAnakResultCard');
}

class _Str {
  const _Str._();
  static const appBarTitle    = 'BBI Anak';
  static const appBarSubtitle = 'Berat Badan Ideal Anak';
  static const sectionTitle   = 'Input Data BBI Anak';
  static const categoryLabel  = 'Kategori Usia';
  static const resultTitle    = 'Hasil BBI Anak';
  static const resultUnit     = 'kg';

  // Label & suffix dinamis per kategori
  static const ageLabelMonths  = 'Usia (Bulan)';
  static const ageLabelYears   = 'Usia (Tahun)';
  static const ageSuffixMonths = 'bln';
  static const ageSuffixYears  = 'thn';

  // Pesan snackbar
  static const snackOutOfRange = 'Umur pasien di luar kategori anak (0-12 tahun)';
}

const _kBrandGreen = Color(0xFF009444);

// ===========================================================================
// PAGE WIDGET
// ===========================================================================

class BbiAnakFormPage extends StatefulWidget {
  final String userRole;

  const BbiAnakFormPage({super.key, required this.userRole});

  @override
  State<BbiAnakFormPage> createState() => _BbiAnakFormPageState();
}

class _BbiAnakFormPageState extends State<BbiAnakFormPage> {
  final _formKey            = GlobalKey<FormState>();
  final _ageController      = TextEditingController();
  final _categoryController = TextEditingController();
  final _scrollController   = ScrollController();
  final _resultCardKey      = GlobalKey();
  final _patientPickerKey   = GlobalKey<PatientPickerWidgetState>();

  double? _bbiResult;

  bool get _isMonthCategory => _categoryController.text == BbiCalculatorService.categoryMonths0to11;
  bool get _is1to6Category  => _categoryController.text == BbiCalculatorService.categoryYears1to6;
  bool get _is7to12Category => _categoryController.text == BbiCalculatorService.categoryYears7to12;

  @override
  void dispose() {
    _ageController.dispose();
    _categoryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  void _calculateBBI() {
    if (!_formKey.currentState!.validate()) return;

    final double ageValue = double.parse(_ageController.text);

    // [REFACTOR] Logika formula anak ada di Service.
    setState(() {
      _bbiResult = BbiCalculatorService.calculateChild(
        ageValue: ageValue,
        category: _categoryController.text,
      );
    });
    _scrollToResult();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _ageController.clear();
      _categoryController.clear();
      _bbiResult = null;
    });
    _patientPickerKey.currentState?.resetSelection();
  }

  void _fillDataFromPatient(
    double weight, double height, String gender, DateTime dob,
  ) {
    // [REFACTOR] Logika deteksi kategori usia ada di Service.
    final (int years, int totalMonths) = BbiCalculatorService.calculateAgeComponents(
      birthDate: dob,
      checkDate: DateTime.now(),
    );

    final String? category = BbiCalculatorService.detectAgeCategory(
      ageYears:       years,
      totalAgeMonths: totalMonths,
    );

    setState(() {
      _bbiResult = null;
      if (category == null) {
        _categoryController.clear();
        _ageController.clear();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(_Str.snackOutOfRange)),
          );
        });
        return;
      }
      _categoryController.text = category;
      _ageController.text = category == BbiCalculatorService.categoryMonths0to11
          ? totalMonths.toString()
          : years.toString();
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

  // Getters dinamis tetap di page (presentasi)
  String get _ageLabel  => _isMonthCategory ? _Str.ageLabelMonths  : _Str.ageLabelYears;
  String get _ageSuffix => _isMonthCategory ? _Str.ageSuffixMonths : _Str.ageSuffixYears;

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
                    hint:  'Pilih pasien untuk mengisi kategori usia dan '
                           'nilai usia secara otomatis',
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

                  // ── Category Dropdown ──────────────────────────────────
                  Semantics(
                    label: 'Dropdown Kategori Usia BBI Anak',
                    hint:  'Pilih kategori usia: 0-11 Bulan, 1-6 Tahun, atau 7-12 Tahun',
                    child: DropdownSearch<String>(
                      key: _Keys.categoryDropdown,
                      popupProps: const PopupProps.menu(
                        showSearchBox: false,
                        fit:           FlexFit.loose,
                      ),
                      // [REFACTOR] Konstanta dari Service
                      items: BbiCalculatorService.ageCategories,
                      dropdownDecoratorProps: const DropDownDecoratorProps(
                        dropdownSearchDecoration: InputDecoration(
                          labelText:  _Str.categoryLabel,
                          border:     OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                      ),
                      onChanged: (val) => setState(() {
                        _categoryController.text = val ?? '';
                        _ageController.clear();
                        _bbiResult = null;
                      }),
                      selectedItem: _categoryController.text.isEmpty
                          ? null : _categoryController.text,
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '${_Str.categoryLabel} harus dipilih' : null,
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Age Field (label & suffix dinamis) ─────────────────
                  Semantics(
                    label:     'Input Nilai Usia BBI Anak',
                    hint:      _isMonthCategory
                        ? 'Masukkan usia dalam satuan bulan (0 hingga 11)'
                        : 'Masukkan usia dalam satuan tahun',
                    textField: true,
                    child: TextFormField(
                      key:          _Keys.ageField,
                      controller:   _ageController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(3),
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: InputDecoration(
                        labelText:  _ageLabel,
                        suffixText: _ageSuffix,
                        border:     const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.cake),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Usia tidak boleh kosong';
                        }
                        final age = double.tryParse(value);
                        if (age == null) return 'Masukkan angka valid';
                        if (_categoryController.text.isEmpty) {
                          return 'Pilih kategori usia terlebih dahulu';
                        }
                        if (_isMonthCategory && (age < 0 || age > 11)) {
                          return 'Usia untuk kategori ini harus 0 - 11 bulan';
                        }
                        if (_is1to6Category && (age < 1 || age > 6)) {
                          return 'Usia untuk kategori ini harus 1 - 6 tahun';
                        }
                        if (_is7to12Category && (age < 7 || age > 12)) {
                          return 'Usia untuk kategori ini harus 7 - 12 tahun';
                        }
                        return null;
                      },
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  Semantics(
                    label: 'Tombol Aksi Form BBI Anak',
                    hint:  'Tombol Reset menghapus semua input; '
                           'Tombol Hitung menghitung nilai BBI Anak',
                    child: FormActionButtons(
                      key:                  _Keys.btnReset,
                      onReset:              _resetForm,
                      onSubmit:             _calculateBBI,
                      resetButtonColor:     Colors.white,
                      resetForegroundColor: _kBrandGreen,
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  if (_bbiResult != null) ...[
                    SizedBox(key: _resultCardKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.08),
                    CalculationResultCard(
                      containerKey:   _Keys.bbiAnakResultCard,
                      title:          _Str.resultTitle,
                      value:          '${_bbiResult!.toStringAsFixed(2)} ${_Str.resultUnit}',
                      color:          _kBrandGreen,
                      // [REFACTOR] Deskripsi formula dari Service — tidak ada string formula di page
                      subtitle: BbiCalculatorService.getChildFormulaDescription(
                        _categoryController.text,
                      ),
                      semanticsLabel:
                          'Hasil BBI Anak: '
                          '${_bbiResult!.toStringAsFixed(2)} kilogram, '
                          'kategori ${_categoryController.text}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _responsiveFont(double sw, {required double base}) {
    if (sw <= 360) return base * 0.90;
    if (sw >= 600) return base * 1.20;
    return base;
  }
}