// lib/src/features/nutrition_calculation/presentation/pages/bmi_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// ---------------------------------------------------------------------------
// [OPTIMIZATION] ValueKey literal di-hoist ke class konstanta file-level.
// Tujuan: (1) tidak realokasi memori per-build; (2) single source of truth
// untuk tim QA — ubah di satu tempat, berlaku di seluruh file.
// ---------------------------------------------------------------------------
class _Keys {
  const _Keys._();
  static const patientPicker = ValueKey('patientPickerWidget');
  static const weightField   = ValueKey('weightField');
  static const heightField   = ValueKey('heightField');
  static const btnReset      = ValueKey('btnReset');
  static const bmiResultCard = ValueKey('bmiResultCard');
}

// ---------------------------------------------------------------------------
// [OPTIMIZATION] String literal di-hoist agar widget Text dapat memakai
// const constructor — tidak diinstansiasi ulang setiap siklus rebuild.
// ---------------------------------------------------------------------------
class _Str {
  const _Str._();
  static const sectionTitle = 'Input Data IMT';
  static const weightLabel  = 'Berat Badan';
  static const heightLabel  = 'Tinggi Badan';
  static const weightUnit   = 'kg';
  static const heightUnit   = 'cm';
  static const resultTitle  = 'Hasil Perhitungan IMT';
  static const resultDesc   =
      'Indeks Massa Tubuh (IMT) adalah ukuran untuk mengevaluasi berat badan '
      'ideal berdasarkan tinggi badan.';
  static const whoTitle   = 'Kategori Indeks Massa Tubuh\nMenurut WHO';
  static const whoSource  = 'sumber menurut WHO';
  static const whoContent =
      'Berat Badan Kurang (Underweight): < 18,5\n'
      'Kurus Parah (Severe thinness): < 16,0\n'
      'Kurus Sedang (Moderate thinness): 16,0 - 16,9\n'
      'Kurus Ringan (Mild thinness): 17,0 - 18,4\n\n'
      'Berat Badan Normal (Normal range): 18,5 - 24,9\n\n'
      'Berat Badan Berlebih (Overweight): \u2265 25,0\n\n'
      'Pre-obesitas (Pre-obese): 25,0 - 29,9\n'
      'Obesitas (Obese): \u2265 30,0\n'
      'Obesitas Kelas I: 30,0 - 34,9\n'
      'Obesitas Kelas II: 35,0 - 39,9\n'
      'Obesitas Kelas III (Ekstrem): \u2265 40,0';
}

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
  final _formKey          = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _scrollController = ScrollController();
  final _resultCardKey    = GlobalKey();
  final _patientPickerKey = GlobalKey<PatientPickerWidgetState>();

  // ── State ─────────────────────────────────────────────────────────────────
  double? _bmiResult;
  String? _bmiCategory;
  Color?  _resultColor;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  void _calculateBMI() {
    if (!_formKey.currentState!.validate()) return;

    final double weight  = double.parse(_weightController.text);
    final double heightM = double.parse(_heightController.text) / 100;
    final double bmi     = weight / (heightM * heightM);
    final (String cat, Color col) = _classifyBMI(bmi);

    setState(() {
      _bmiResult   = bmi;
      _bmiCategory = cat;
      _resultColor = col;
    });
    _scrollToResult();
  }

  /// Pure function — tidak bergantung pada widget, mudah di-unit-test.
  (String, Color) _classifyBMI(double bmi) {
    if (bmi < 18.5) return ('Kurus', Colors.red);
    if (bmi < 25.0) return ('Normal', const Color(0xFF009444));
    if (bmi < 30.0) return ('Gemuk', Colors.orange);
    return ('Obesitas', Colors.red);
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _bmiResult   = null;
      _bmiCategory = null;
      _resultColor = null;
    });
    _patientPickerKey.currentState?.resetSelection();
  }

  void _fillDataFromPatient(
    double weight, double height, String gender, DateTime dob,
  ) {
    setState(() {
      _weightController.text = weight.toString();
      _heightController.text = height.toString();
      // Reset hasil agar user menghitung ulang setelah data pasien diisi
      _bmiResult   = null;
      _bmiCategory = null;
      _resultColor = null;
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
    // [RESPONSIVE] MediaQuery.sizeOf lebih efisien daripada MediaQuery.of
    // karena hanya subscribe perubahan Size, bukan seluruh MediaQueryData.
    final double sw   = MediaQuery.sizeOf(context).width;
    final double hPad = sw * 0.04; // ≈ 16 dp pada layar 400 dp

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
                    hint:  'Pilih pasien untuk mengisi data berat dan tinggi badan secara otomatis',
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

                  // ── Weight Field ───────────────────────────────────────
                  _buildInputField(
                    widgetKey:     _Keys.weightField,
                    controller:    _weightController,
                    label:         _Str.weightLabel,
                    prefixIcon:    const Icon(Icons.monitor_weight),
                    suffixText:    _Str.weightUnit,
                    semanticLabel: 'Input Berat Badan',
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
                    semanticLabel: 'Input Tinggi Badan',
                    semanticHint:  'Masukkan tinggi badan dalam sentimeter',
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Action Buttons ─────────────────────────────────────
                  Semantics(
                    label: 'Tombol Aksi Form IMT',
                    hint:  'Tombol Reset menghapus semua input; Tombol Hitung menghitung nilai IMT',
                    child: FormActionButtons(
                      key: _Keys.btnReset,   // key diletakkan di wrapper FormActionButtons
                      onReset: _resetForm,
                      onSubmit: _calculateBMI,
                      resetButtonColor:     Colors.white,
                      resetForegroundColor: const Color(0xFF009444),
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Result Section ─────────────────────────────────────
                  if (_bmiResult != null) ...[
                    SizedBox(key: _resultCardKey, height: 0), // anchor scroll
                    const Divider(),
                    SizedBox(height: sw * 0.08),
                    _buildResultCard(sw),
                    SizedBox(height: sw * 0.08),
                    _buildWhoTable(sw),
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

  /// [CLEAN CODE] Diekstrak dari build() agar metode utama tetap ringkas.
  Widget _buildResultCard(double sw) {
    final Color color = _resultColor!;
    return Semantics(
      label: 'Hasil Perhitungan IMT: '
             '${_bmiResult!.toStringAsFixed(2)} kilogram per meter kuadrat, '
             'Kategori $_bmiCategory',
      hint:       'Nilai IMT beserta kategori dan interpretasi berat badan',
      liveRegion: true, // Screen-reader otomatis membacakan saat nilai berubah
      child: Container(
        key: _Keys.bmiResultCard,
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color),
        ),
        child: Column(
          children: [
            Text(
              _Str.resultTitle,
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 18),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: sw * 0.02),
            // \u00B2 = karakter superscript ² (menggantikan 'Â²' yang corrupted)
            Text(
              '${_bmiResult!.toStringAsFixed(2)} kg/m\u00B2',
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 24),
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: sw * 0.02),
            Text(
              'Kategori: $_bmiCategory',
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 16),
                fontWeight: FontWeight.bold,
                color: color,
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

  Widget _buildWhoTable(double sw) {
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFAEAEAE).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        children: [
          Text(
            _Str.whoTitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _responsiveFont(sw, base: 18),
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(height: 16),
          SizedBox(height: sw * 0.03),
          Text(
            _Str.whoContent,
            textAlign: TextAlign.left,
            style: TextStyle(fontSize: _responsiveFont(sw, base: 14)),
          ),
          SizedBox(height: sw * 0.02),
          Text(
            _Str.whoSource,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _responsiveFont(sw, base: 12),
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  /// Input field umum dengan Semantics untuk Katalon Object Spy.
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
          // [RETAINED] Dibatasi 5 karakter untuk mencegah overflow & error DB
          LengthLimitingTextInputFormatter(maxLength),
          // Hanya izinkan digit 0-9 dan titik desimal
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Font responsif linear: -10% layar kecil (≤360 dp), +20% tablet (≥600 dp).
  double _responsiveFont(double sw, {required double base}) {
    if (sw <= 360) return base * 0.90;
    if (sw >= 600) return base * 1.20;
    return base;
  }
}