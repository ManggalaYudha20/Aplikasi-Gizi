// lib/src/features/nutrition_calculation/presentation/pages/bbi_form_page.dart

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
  static const patientPicker  = ValueKey('patientPickerWidget');
  static const heightField    = ValueKey('heightField');
  static const genderDropdown = ValueKey('genderDropdown');
  static const btnReset       = ValueKey('btnReset');
  static const bbiResultCard  = ValueKey('bbiResultCard');
}

// ---------------------------------------------------------------------------
// [OPTIMIZATION] String literal di-hoist agar widget Text dapat memakai
// const constructor — tidak diinstansiasi ulang setiap siklus rebuild.
// ---------------------------------------------------------------------------
class _Str {
  const _Str._();
  static const appBarTitle      = 'BBI';
  static const appBarSubtitle   = 'Berat Badan Ideal';
  static const sectionTitle     = 'Input Data BBI';
  static const heightLabel      = 'Tinggi Badan';
  static const heightUnit       = 'cm';
  static const genderLabel      = 'Jenis Kelamin';
  static const male             = 'Laki-laki';
  static const female           = 'Perempuan';
  static const resultTitle      = 'Hasil Perhitungan BBI';
  static const resultUnit       = 'kg';
  static const resultDesc       =
      'Berat Badan Ideal (BBI) adalah berat badan yang dianggap optimal '
      'untuk tinggi badan dan jenis kelamin.';
  static const List<String> genderOptions = [male, female];
}

// Warna brand sebagai konstanta agar tidak alokasi Color object per-build.
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
  // ── Controllers & Keys ────────────────────────────────────────────────────
  final _formKey          = GlobalKey<FormState>();
  final _heightController = TextEditingController();
  final _genderController = TextEditingController();
  final _scrollController = ScrollController();
  final _resultCardKey    = GlobalKey();
  final _patientPickerKey = GlobalKey<PatientPickerWidgetState>();

  // ── State ─────────────────────────────────────────────────────────────────
  double? _bbiResult;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
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

    // [CLEAN CODE] Pure function diekstrak agar mudah di-unit-test.
    final double bbi = _computeBBI(height, _genderController.text);

    setState(() => _bbiResult = bbi);
    _scrollToResult();
  }

  /// Pure function — tidak bergantung pada widget, bebas side-effect.
  /// Formula BBI Broca yang dimodifikasi:
  ///   Laki-laki   : (TB - 100) × 90%
  ///   Perempuan   : (TB - 100) × 85%
  double _computeBBI(double heightCm, String gender) {
    final double base = heightCm - 100;
    return gender == _Str.male ? base * 0.90 : base * 0.85;
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
      _genderController.text = _normalizeGender(gender);
      // Reset hasil agar user menghitung ulang setelah data pasien diisi
      _bbiResult = null;
    });
  }

  /// Normalisasi string gender dari berbagai variasi penulisan.
  /// [CLEAN CODE] Dipisah agar _fillDataFromPatient tetap ramping.
  String _normalizeGender(String raw) {
    final String lower = raw.toLowerCase();
    if (lower.contains('laki') || lower.contains('pria') || lower == 'l') {
      return _Str.male;
    }
    if (lower.contains('perempuan') || lower.contains('wanita') || lower == 'p') {
      return _Str.female;
    }
    return raw; // Kembalikan asli jika tidak dikenali
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
    // [RESPONSIVE] MediaQuery.sizeOf lebih efisien — hanya subscribe Size,
    // bukan seluruh MediaQueryData seperti MediaQuery.of.
    final double sw   = MediaQuery.sizeOf(context).width;
    final double hPad = sw * 0.04; // ≈ 16 dp pada layar 400 dp

    return Scaffold(
      backgroundColor: Colors.white,
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

                  // ── Patient Picker ─────────────────────────────────────
                  Semantics(
                    key: _Keys.patientPicker,
                    label: 'Pemilih Pasien',
                    hint:  'Pilih pasien untuk mengisi data tinggi badan dan '
                           'jenis kelamin secara otomatis',
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

                  // ── Height Field ───────────────────────────────────────
                  _buildInputField(
                    widgetKey:     _Keys.heightField,
                    controller:    _heightController,
                    label:         _Str.heightLabel,
                    prefixIcon:    const Icon(Icons.height),
                    suffixText:    _Str.heightUnit,
                    semanticLabel: 'Input Tinggi Badan',
                    semanticHint:  'Masukkan tinggi badan dalam sentimeter',
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Gender Dropdown ────────────────────────────────────
                  Semantics(
                    label:    'Dropdown Jenis Kelamin',
                    hint:     'Pilih jenis kelamin: Laki-laki atau Perempuan',
                    child: _buildGenderDropdown(sw),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Action Buttons ─────────────────────────────────────
                  Semantics(
                    label: 'Tombol Aksi Form BBI',
                    hint:  'Tombol Reset menghapus semua input; '
                           'Tombol Hitung menghitung nilai BBI',
                    child: FormActionButtons(
                      key: _Keys.btnReset,
                      onReset: _resetForm,
                      onSubmit: _calculateBBI,
                      resetButtonColor:     Colors.white,
                      resetForegroundColor: _kBrandGreen,
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Result Section ─────────────────────────────────────
                  if (_bbiResult != null) ...[
                    SizedBox(key: _resultCardKey, height: 0), // anchor scroll
                    const Divider(),
                    SizedBox(height: sw * 0.08),
                    _buildResultCard(sw),
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

  /// [CLEAN CODE] Result card diekstrak agar build() tetap ringkas.
  Widget _buildResultCard(double sw) {
    return Semantics(
      label: 'Hasil Perhitungan BBI: '
             '${_bbiResult!.toStringAsFixed(2)} kilogram',
      hint:       'Nilai Berat Badan Ideal berdasarkan tinggi badan dan jenis kelamin',
      liveRegion: true, // Screen-reader otomatis membacakan saat nilai berubah
      child: Container(
        key: _Keys.bbiResultCard,
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: _kBrandGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBrandGreen),
        ),
        child: Column(
          children: [
            Text(
              _Str.resultTitle,
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 18),
                fontWeight: FontWeight.bold,
                color: _kBrandGreen,
              ),
            ),
            SizedBox(height: sw * 0.02),
            Text(
              '${_bbiResult!.toStringAsFixed(2)} ${_Str.resultUnit}',
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

  /// Input field numerik umum dengan Semantics & validasi angka.
  Widget _buildInputField({
    required ValueKey<String> widgetKey,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    required String semanticLabel,
    required String semanticHint,
    int maxLength = 5,
  }) {
    return Semantics(
      label:     semanticLabel,
      hint:      semanticHint,
      textField: true,
      child: TextFormField(
        key: widgetKey,
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          // [RETAINED] Batasi 5 karakter untuk mencegah overflow & error DB
          LengthLimitingTextInputFormatter(maxLength),
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
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

  /// Dropdown jenis kelamin menggunakan package dropdown_search.
  Widget _buildGenderDropdown(double sw) {
    return DropdownSearch<String>(
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
      onChanged: (String? newValue) {
        setState(() => _genderController.text = newValue ?? '');
      },
      selectedItem: _genderController.text.isEmpty
          ? null
          : _genderController.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '${_Str.genderLabel} harus dipilih';
        }
        return null;
      },
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