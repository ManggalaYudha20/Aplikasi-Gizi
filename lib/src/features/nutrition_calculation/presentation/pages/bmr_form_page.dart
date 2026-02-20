// lib/src/features/nutrition_calculation/presentation/pages/bmr_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// ---------------------------------------------------------------------------
// [OPTIMIZATION] ValueKey literal di-hoist ke class konstanta file-level.
// Tidak realokasi per-build; single source of truth untuk tim QA.
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

// ---------------------------------------------------------------------------
// [OPTIMIZATION] String literal di-hoist agar widget Text dapat memakai
// const constructor — tidak diinstansiasi ulang setiap siklus rebuild.
// ---------------------------------------------------------------------------
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
  static const male           = 'Laki-laki';
  static const female         = 'Perempuan';
  static const formulaMifflin = 'Mifflin-St Jeor';
  static const formulaHarris  = 'Harris-Benedict';
  static const resultUnit     = 'kkal/hari';
  static const resultDesc     =
      'Basal Metabolic Rate (BMR) adalah jumlah kalori yang dibutuhkan '
      'tubuh untuk fungsi dasar saat istirahat.';

  static const List<String> formulaOptions = [formulaMifflin, formulaHarris];
  static const List<String> genderOptions  = [male, female];
}

// Warna brand sebagai konstanta top-level — tidak realokasi object Color per-build.
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
  final _formKey            = GlobalKey<FormState>();
  final _weightController   = TextEditingController();
  final _heightController   = TextEditingController();
  final _ageController      = TextEditingController();
  final _genderController   = TextEditingController();
  final _formulaController  = TextEditingController(text: _Str.formulaMifflin);
  final _scrollController   = ScrollController();
  final _resultCardKey      = GlobalKey();
  final _patientPickerKey   = GlobalKey<PatientPickerWidgetState>();

  // ── State ─────────────────────────────────────────────────────────────────
  double? _bmrResult;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
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

    final double weight = double.parse(_weightController.text);
    final double height = double.parse(_heightController.text);
    final int    age    = int.parse(_ageController.text);
    final String gender  = _genderController.text;
    final String formula = _formulaController.text;

    // [CLEAN CODE] Kalkulasi didelegasikan ke pure function.
    final double bmr = _computeBMR(
      weight:  weight,
      height:  height,
      age:     age,
      gender:  gender,
      formula: formula,
    );

    setState(() => _bmrResult = bmr);
    _scrollToResult();
  }

  /// Pure function — tanpa side-effect, bebas di-unit-test.
  ///
  /// Formula Harris-Benedict (1919):
  ///   Laki-laki  : 66.47 + (13.75×BB) + (5.003×TB) − (6.755×U)
  ///   Perempuan  : 655.1 + (9.563×BB)  + (1.850×TB) − (4.676×U)
  ///
  /// Formula Mifflin-St Jeor (lebih akurat untuk populasi modern):
  ///   Laki-laki  : (9.99×BB) + (6.25×TB) − (4.92×U) + 5
  ///   Perempuan  : (9.99×BB) + (6.25×TB) − (4.92×U) − 161
  double _computeBMR({
    required double weight,
    required double height,
    required int    age,
    required String gender,
    required String formula,
  }) {
    final bool isMale = gender == _Str.male;

    if (formula == _Str.formulaHarris) {
      return isMale
          ? 66.47 + (13.75 * weight) + (5.003 * height) - (6.755 * age)
          : 655.1 + (9.563 * weight) + (1.850 * height) - (4.676 * age);
    }
    // Default: Mifflin-St Jeor
    return isMale
        ? (9.99 * weight) + (6.25 * height) - (4.92 * age) + 5
        : (9.99 * weight) + (6.25 * height) - (4.92 * age) - 161;
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _ageController.clear();
      _genderController.clear();
      _formulaController.text = _Str.formulaMifflin;
      _bmrResult = null;
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
      _ageController.text    = _calculateAgeFromDob(dob).toString();
      _genderController.text = _normalizeGender(gender);
      _bmrResult = null;
    });
  }

  /// Menghitung usia aktual dari tanggal lahir. Pure function.
  int _calculateAgeFromDob(DateTime birthDate) {
    final DateTime now = DateTime.now();
    int age = now.year - birthDate.year;
    final bool birthdayNotYet =
        now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day);
    if (birthdayNotYet) age--;
    return age;
  }

  /// Normalisasi variasi penulisan gender dari data pasien. Pure function.
  String _normalizeGender(String raw) {
    final String lower = raw.toLowerCase();
    if (lower.contains('laki') || lower.contains('pria') || lower == 'l') {
      return _Str.male;
    }
    if (lower.contains('perempuan') || lower.contains('wanita') || lower == 'p') {
      return _Str.female;
    }
    return raw;
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
    // [RESPONSIVE] MediaQuery.sizeOf hanya subscribe perubahan Size,
    // lebih efisien dari MediaQuery.of yang subscribe seluruh MediaQueryData.
    final double sw   = MediaQuery.sizeOf(context).width;
    final double hPad = sw * 0.04; // ≈ 16 dp pada layar 400 dp

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
                    key: _Keys.patientPicker,
                    label: 'Pemilih Pasien',
                    hint:  'Pilih pasien untuk mengisi data berat badan, '
                           'tinggi badan, jenis kelamin, dan umur secara otomatis',
                    child: PatientPickerWidget(
                      key: _patientPickerKey,
                      onPatientSelected: _fillDataFromPatient,
                      userRole: widget.userRole,
                    ),
                  ),

                  SizedBox(height: sw * 0.05),

                  // ── Section Title ──────────────────────────────────────
                  Text(
                    _Str.sectionTitle,
                    style: TextStyle(
                      fontSize: _responsiveFont(sw, base: 20),
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
                      isFormula:  true,
                    ),
                  ),

                  // Keterangan formula yang dipilih
                  _buildFormulaInfo(sw),

                  SizedBox(height: sw * 0.04),

                  // ── Weight Field ───────────────────────────────────────
                  _buildInputField(
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
                  _buildInputField(
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
                      isFormula:  false,
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Age Field ──────────────────────────────────────────
                  _buildInputField(
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
                      key: _Keys.btnReset,
                      onReset: _resetForm,
                      onSubmit: _calculateBMR,
                      resetButtonColor:     Colors.white,
                      resetForegroundColor: _kBrandGreen,
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Result Section ─────────────────────────────────────
                  if (_bmrResult != null) ...[
                    SizedBox(key: _resultCardKey, height: 0), // anchor scroll
                    const Divider(),
                    SizedBox(height: sw * 0.08),
                    _buildBmrResultCard(sw),
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

  /// [CLEAN CODE] Result card diekstrak agar build() tetap ringkas dan mudah dibaca.
  Widget _buildBmrResultCard(double sw) {
    return Semantics(
      label: 'Hasil Perhitungan BMR: '
             '${_bmrResult!.toStringAsFixed(2)} kkal per hari, '
             'menggunakan formula ${_formulaController.text}',
      hint:       'Nilai Basal Metabolic Rate berdasarkan data yang diinput',
      liveRegion: true, // Screen-reader membacakan otomatis saat nilai berubah
      child: Container(
        key: _Keys.bmrResultCard,
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: _kBrandGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBrandGreen),
        ),
        child: Column(
          children: [
            // Judul menyertakan nama formula yang aktif
            Text(
              'Hasil Perhitungan BMR\n(${_formulaController.text})',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 18),
                fontWeight: FontWeight.bold,
                color: _kBrandGreen,
              ),
            ),
            SizedBox(height: sw * 0.02),
            Text(
              '${_bmrResult!.toStringAsFixed(2)} ${_Str.resultUnit}',
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 24),
                fontWeight: FontWeight.bold,
                color: _kBrandGreen,
              ),
            ),
            SizedBox(height: sw * 0.02),
            Text(
              _Str.resultDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 12),
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Keterangan deskriptif formula yang sedang dipilih.
  Widget _buildFormulaInfo(double sw) {
    final String formula = _formulaController.text;
    final String desc    = formula == _Str.formulaHarris
        ? 'Menggunakan rumus Harris-Benedict (1919).'
        : 'Menggunakan rumus Mifflin-St Jeor '
          '(dianggap lebih akurat untuk populasi modern).';

    return Padding(
      padding: EdgeInsets.only(top: sw * 0.02),
      child: Text(
        '$formula dipilih. $desc',
        style: TextStyle(
          fontSize: _responsiveFont(sw, base: 12),
          color: Colors.black54,
        ),
      ),
    );
  }

  /// Dropdown generik — digunakan untuk formula maupun jenis kelamin.
  /// Parameter [isFormula] menentukan apakah perubahan nilai me-reset _bmrResult.
  Widget _buildDropdown({
    required ValueKey<String> widgetKey,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required List<String> items,
    required bool isFormula,
  }) {
    return DropdownSearch<String>(
      key: widgetKey,
      popupProps: const PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
        constraints: BoxConstraints(maxHeight: 240),
      ),
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText:  label,
          border:     const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged: (String? newValue) {
        setState(() {
          controller.text = newValue ?? '';
          // Reset hasil jika formula atau gender berubah — hasil lama tidak valid
          _bmrResult = null;
        });
      },
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (value) {
        if (value == null || value.isEmpty) return '$label harus dipilih';
        return null;
      },
    );
  }

  /// Input field numerik dengan Semantics & validasi, mendukung mode integer.
  Widget _buildInputField({
    required ValueKey<String> widgetKey,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    required String semanticLabel,
    required String semanticHint,
    bool isInteger = false,
    int maxLength  = 5,
  }) {
    return Semantics(
      label:     semanticLabel,
      hint:      semanticHint,
      textField: true,
      child: TextFormField(
        key: widgetKey,
        controller: controller,
        keyboardType: isInteger
            ? TextInputType.number
            : const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          LengthLimitingTextInputFormatter(maxLength),
          isInteger
              ? FilteringTextInputFormatter.digitsOnly
              : FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(
          labelText:  label,
          border:     const OutlineInputBorder(),
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Font responsif: -10% layar kecil (≤360 dp), +20% tablet (≥600 dp).
  double _responsiveFont(double sw, {required double base}) {
    if (sw <= 360) return base * 0.90;
    if (sw >= 600) return base * 1.20;
    return base;
  }
}