// lib/src/features/nutrition_calculation/presentation/pages/imtu_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';

// ---------------------------------------------------------------------------
// [OPTIMIZATION] ValueKey literal di-hoist ke class konstanta file-level.
// Tidak realokasi per-build; single source of truth untuk tim QA.
//
// [BUG FIX] Pola yang diterapkan konsisten dengan halaman lain:
//   ValueKey → di Semantics wrapper (untuk Katalon Object Spy)
//   GlobalKey → di PatientPickerWidget langsung (untuk .currentState)
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

// ---------------------------------------------------------------------------
// [OPTIMIZATION] String literal di-hoist agar widget Text dapat memakai
// const constructor — tidak diinstansiasi ulang setiap siklus rebuild.
// ---------------------------------------------------------------------------
class _Str {
  const _Str._();
  static const appBarTitle     = 'IMT/U';
  static const appBarSubtitle  = 'Usia 5-18 Tahun';
  static const sectionTitle    = 'Input Data IMT/U  5-18 Tahun';
  static const resultSectionTitle = 'Hasil IMT Berdasarkan Usia 5-18 Tahun';
  static const resultCardTitle = 'Indeks Massa Tubuh menurut Umur (IMT/U)';
  static const yearLabel       = 'Tahun';
  static const yearUnit        = 'tahun';
  static const monthLabel      = 'Bulan';
  static const monthUnit       = 'bulan';
  static const genderLabel     = 'Jenis Kelamin';
  static const weightLabel     = 'Berat Badan';
  static const weightUnit      = 'kg';
  static const heightLabel     = 'Tinggi Badan';
  static const heightUnit      = 'cm';
  static const male            = 'Laki-laki';
  static const female          = 'Perempuan';

  // Pesan validasi & snackbar
  static const validYear       = '5-18 tahun';
  static const validMonth      = '0-11 bulan';
  static const snackNoGender   = 'Pilih jenis kelamin terlebih dahulu';
  static const snackAgeRange   = 'Usia harus antara 5-18 tahun';

  static const List<String> genderOptions = [male, female];
}

// Warna brand sebagai konstanta top-level — tidak realokasi Color object per-build.
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
  // ── Controllers & Keys ────────────────────────────────────────────────────
  final _formKey              = GlobalKey<FormState>();
  final _weightController     = TextEditingController();
  final _heightController     = TextEditingController();
  final _ageYearsController   = TextEditingController();
  final _ageMonthsController  = TextEditingController();
  final _genderController     = TextEditingController();
  final _scrollController     = ScrollController();
  final _resultCardKey        = GlobalKey();
  final _patientPickerKey     = GlobalKey<PatientPickerWidgetState>();

  // ── State ─────────────────────────────────────────────────────────────────
  Map<String, dynamic>? _calculationResult;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
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

    // Validasi gender — dropdown tidak akan lolos form validator jika kosong,
    // namun guard ini tetap dipertahankan sesuai logika asli.
    if (_genderController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_Str.snackNoGender)),
      );
      return;
    }

    final double weight    = double.tryParse(_weightController.text) ?? 0;
    final double height    = double.tryParse(_heightController.text) ?? 0;
    final int    ageYears  = int.tryParse(_ageYearsController.text) ?? 0;
    final int    ageMonths = int.tryParse(_ageMonthsController.text) ?? 0;

    // Validasi rentang usia (5-18 tahun dalam total bulan)
    final int totalMonths = (ageYears * 12) + ageMonths;
    if (totalMonths < 60 || totalMonths > 216) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(_Str.snackAgeRange)),
      );
      return;
    }

    // Hitung BMI lalu z-score IMT/U
    final double bmi = weight / ((height / 100) * (height / 100));
    final Map<String, dynamic> result = _computeIMTUZScore(
      ageYears:  ageYears,
      ageMonths: ageMonths,
      bmi:       bmi,
      gender:    _genderController.text,
    );

    setState(() => _calculationResult = result);
    _scrollToResult();
  }

  /// Menghitung z-score IMT/U menggunakan tabel referensi NutritionStatusData.
  /// [CLEAN CODE] Diekstrak dari _calculateIMTU untuk testability & keterbacaan.
  Map<String, dynamic> _computeIMTUZScore({
    required int    ageYears,
    required int    ageMonths,
    required double bmi,
    required String gender,
  }) {
    try {
      final String ageKey = '$ageYears-$ageMonths';
      final percentiles = gender == _Str.male
          ? NutritionStatusData.imtUBoys5To18[ageKey]
          : NutritionStatusData.imtUGirls5To18[ageKey];

      if (percentiles == null) {
        return {
          'zScore'  : null,
          'category': 'Data referensi tidak tersedia untuk usia ini',
          'bmi'     : bmi,
          'ageKey'  : ageKey,
        };
      }

      final double median = percentiles[3];
      final double sd     = percentiles[4] - median;
      final double zScore = (bmi - median) / sd;

      return {
        'zScore'  : zScore,
        'category': _getIMTUCategory(zScore),
        'bmi'     : bmi,
        'ageKey'  : ageKey,
      };
    } catch (e) {
      return {
        'zScore'  : null,
        'category': 'Error dalam perhitungan',
        'bmi'     : bmi,
        'ageKey'  : '$ageYears-$ageMonths',
      };
    }
  }

  /// Klasifikasi status gizi berdasarkan nilai z-score IMT/U. Pure function.
  String _getIMTUCategory(double zScore) {
    if (zScore < -3) return 'Gizi buruk (severely wasted)';
    if (zScore < -2) return 'Gizi kurang (wasted)';
    if (zScore <= 1) return 'Gizi baik (normal)';
    if (zScore <= 2) return 'Gizi lebih (overweight)';
    return 'Obesitas (obese)';
  }

  /// Warna indikator berdasarkan string kategori. Pure function.
  Color _getIMTUColor(String category) {
    final String lower = category.toLowerCase();
    if (lower.contains('buruk') || lower.contains('severely')) return Colors.red;
    if (lower.contains('kurang') || lower.contains('wasted'))  return Colors.orange;
    if (lower.contains('baik')   || lower.contains('normal'))  return _kBrandGreen;
    return Colors.red; // overweight & obesitas
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _ageYearsController.clear();
      _ageMonthsController.clear();
      _genderController.clear();
      _calculationResult = null;
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
      _computeAgeDetail(dob);
      _genderController.text = _normalizeGender(gender);
      _calculationResult = null;
    });
  }

  /// Mengisi _ageYearsController dan _ageMonthsController dari tanggal lahir.
  void _computeAgeDetail(DateTime birthDate) {
    final DateTime now = DateTime.now();
    int years  = now.year - birthDate.year;
    int months = now.month - birthDate.month;

    if (now.day < birthDate.day) months--;
    if (months < 0) {
      years--;
      months += 12;
    }

    _ageYearsController.text  = years.toString();
    _ageMonthsController.text = months.toString();
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
    // [RESPONSIVE] MediaQuery.sizeOf hanya subscribe perubahan Size —
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
                  // [BUG FIX] ValueKey di Semantics, GlobalKey di widget.
                  Semantics(
                    key:   _Keys.patientPicker,   // ← ValueKey untuk Katalon
                    label: 'Pemilih Pasien IMT/U',
                    hint:  'Pilih pasien untuk mengisi berat badan, tinggi badan, '
                           'usia, dan jenis kelamin secara otomatis',
                    child: PatientPickerWidget(
                      key: _patientPickerKey,     // ← GlobalKey untuk .currentState
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

                  // ── Age Input Row (Tahun | Bulan) ──────────────────────
                  SizedBox(height: sw * 0.02),
                  Row(
                    children: [
                      // Tahun
                      Expanded(
                        child: _buildInputField(
                          widgetKey:     _Keys.ageYearField,
                          controller:    _ageYearsController,
                          label:         _Str.yearLabel,
                          prefixIcon:    const Icon(Icons.calendar_today),
                          suffixText:    _Str.yearUnit,
                          semanticLabel: 'Input Tahun Usia IMTU',
                          semanticHint:  'Masukkan komponen tahun usia, antara 5 hingga 18',
                          isInteger:     true,
                          maxLength:     2,
                          customValidator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Masukkan tahun';
                            }
                            final int? years = int.tryParse(value);
                            if (years == null || years < 5 || years > 18) {
                              return _Str.validYear;
                            }
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: sw * 0.04),
                      // Bulan
                      Expanded(
                        child: _buildInputField(
                          widgetKey:     _Keys.ageMonthField,
                          controller:    _ageMonthsController,
                          label:         _Str.monthLabel,
                          suffixText:    _Str.monthUnit,
                          semanticLabel: 'Input Bulan Usia IMTU',
                          semanticHint:  'Masukkan komponen bulan usia, antara 0 hingga 11',
                          isInteger:     true,
                          maxLength:     2,
                          customValidator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Masukkan bulan';
                            }
                            final int? months = int.tryParse(value);
                            if (months == null || months < 0 || months > 11) {
                              return _Str.validMonth;
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Gender Dropdown ────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Jenis Kelamin IMTU',
                    hint:  'Pilih jenis kelamin: Laki-laki atau Perempuan. '
                           'Digunakan untuk memilih tabel referensi z-score yang tepat',
                    child: _buildGenderDropdown(),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Weight Field ───────────────────────────────────────
                  _buildInputField(
                    widgetKey:     _Keys.weightField,
                    controller:    _weightController,
                    label:         _Str.weightLabel,
                    prefixIcon:    const Icon(Icons.monitor_weight),
                    suffixText:    _Str.weightUnit,
                    semanticLabel: 'Input Berat Badan IMTU',
                    semanticHint:  'Masukkan berat badan dalam kilogram',
                    customValidator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan berat badan';
                      }
                      final double? w = double.tryParse(value);
                      if (w == null || w <= 0) return 'Masukkan berat yang valid';
                      return null;
                    },
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Height Field ───────────────────────────────────────
                  _buildInputField(
                    widgetKey:     _Keys.heightField,
                    controller:    _heightController,
                    label:         _Str.heightLabel,
                    prefixIcon:    const Icon(Icons.height),
                    suffixText:    _Str.heightUnit,
                    semanticLabel: 'Input Tinggi Badan IMTU',
                    semanticHint:  'Masukkan tinggi badan dalam sentimeter',
                    customValidator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan tinggi badan';
                      }
                      final double? h = double.tryParse(value);
                      if (h == null || h <= 0) return 'Masukkan tinggi yang valid';
                      return null;
                    },
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Action Buttons ─────────────────────────────────────
                  Semantics(
                    label: 'Tombol Aksi Form IMTU',
                    hint:  'Tombol Reset menghapus semua input; '
                           'Tombol Hitung menghitung status gizi IMT/U',
                    child: FormActionButtons(
                      key: _Keys.btnReset,
                      onReset: _resetForm,
                      onSubmit: _calculateIMTU,
                      resetButtonColor:     Colors.white,
                      resetForegroundColor: _kBrandGreen,
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Result Section ─────────────────────────────────────
                  if (_calculationResult != null) ...[
                    SizedBox(key: _resultCardKey, height: 0), // anchor scroll
                    const Divider(),
                    SizedBox(height: sw * 0.08),
                    Text(
                      _Str.resultSectionTitle,
                      style: TextStyle(
                        fontSize: _responsiveFont(sw, base: 20),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: sw * 0.04),
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
  /// Menampilkan nilai IMT, z-score, dan kategori status gizi dengan warna.
  Widget _buildResultCard(double sw) {
    final Map<String, dynamic> data = _calculationResult!;
    final Color color = _getIMTUColor(data['category'] ?? '');
    final String bmiText =
        'IMT: ${data['bmi']?.toStringAsFixed(2) ?? '-'} kg/m\u00B2';

    return Semantics(
      label: 'Hasil IMT/U: $bmiText, '
             'Z-Score ${data['zScore']?.toStringAsFixed(2) ?? '-'}, '
             'Kategori ${data['category'] ?? '-'}',
      hint:       'Status gizi berdasarkan Indeks Massa Tubuh menurut Umur',
      liveRegion: true,
      child: Container(
        key: _Keys.imtuResultCard,
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 2.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Judul card
            Text(
              _Str.resultCardTitle,
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 16),
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: sw * 0.03),

            // Nilai IMT
            Text(
              bmiText,
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 14),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: sw * 0.02),

            // Baris Z-Score
            Row(
              children: [
                Text(
                  'Z-Score: ',
                  style: TextStyle(
                    fontSize: _responsiveFont(sw, base: 14),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
                Text(
                  data['zScore']?.toStringAsFixed(2) ?? '-',
                  style: TextStyle(
                    fontSize: _responsiveFont(sw, base: 14),
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9E9E9E),
                  ),
                ),
              ],
            ),
            SizedBox(height: sw * 0.01),

            // Baris Kategori
            Row(
              children: [
                Text(
                  'Kategori: ',
                  style: TextStyle(
                    fontSize: _responsiveFont(sw, base: 14),
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Expanded(
                  child: Text(
                    data['category'] ?? '-',
                    style: TextStyle(
                      fontSize: _responsiveFont(sw, base: 14),
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Input field numerik umum dengan Semantics, validasi kustom per field.
  Widget _buildInputField({
    required ValueKey<String>          widgetKey,
    required TextEditingController     controller,
    required String                    label,
    required String                    suffixText,
    required String                    semanticLabel,
    required String                    semanticHint,
    Icon?                              prefixIcon,
    bool                               isInteger      = false,
    int                                maxLength      = 5,
    required String? Function(String?) customValidator,
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
        validator: customValidator,
      ),
    );
  }

  /// Dropdown jenis kelamin dengan key QA dan const props.
  Widget _buildGenderDropdown() {
    return DropdownSearch<String>(
      key: _Keys.genderDropdown,
      popupProps: const PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
        constraints: BoxConstraints(maxHeight: 240),
      ),
      items: _Str.genderOptions,
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText:  _Str.genderLabel,
          border:     OutlineInputBorder(),
          prefixIcon: Icon(Icons.wc),
        ),
      ),
      onChanged: (String? newValue) {
        setState(() => _genderController.text = newValue ?? '');
      },
      selectedItem: _genderController.text.isEmpty
          ? null
          : _genderController.text,
      validator: (value) =>
          (value == null || value.isEmpty) ? '${_Str.genderLabel} harus dipilih' : null,
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