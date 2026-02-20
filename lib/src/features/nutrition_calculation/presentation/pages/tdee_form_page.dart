// lib/src/features/nutrition_calculation/presentation/pages/tdee_form_page.dart

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
  static const patientPicker    = ValueKey('patientPickerWidget');
  static const weightField      = ValueKey('weightField');
  static const heightField      = ValueKey('heightField');
  static const genderDropdown   = ValueKey('genderDropdown');
  static const ageField         = ValueKey('ageField');
  static const activityDropdown = ValueKey('activityDropdown');
  static const stressDropdown   = ValueKey('stressDropdown');
  static const tempField        = ValueKey('tempField');
  static const btnReset         = ValueKey('btnReset');
  static const tdeeResultCard   = ValueKey('tdeeResultCard');
}

// ---------------------------------------------------------------------------
// [OPTIMIZATION] String literal di-hoist agar widget Text dapat memakai
// const constructor — tidak diinstansiasi ulang setiap siklus rebuild.
// ---------------------------------------------------------------------------
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
  static const male           = 'Laki-laki';
  static const female         = 'Perempuan';
  static const feverKey       = 'Demam (per 1°C)';
  static const resultUnit     = 'kkal/hari';
  static const resultTitle    = 'Hasil Perhitungan TDEE';
  static const resultDesc     =
      'TDEE adalah perkiraan jumlah total kalori yang dibakar oleh tubuh '
      'dalam satu hari (24 jam).';

  static const List<String> genderOptions = [male, female];
}

// ---------------------------------------------------------------------------
// [OPTIMIZATION] Map faktor dijadikan static const di level file.
// Sebelumnya berupa instance variable — diinisialisasi ulang setiap kali
// widget dibuat. Kini hanya ada SATU instance di memori selama app berjalan.
// ---------------------------------------------------------------------------
const Map<String, double> _kActivityFactors = {
  'Sangat Jarang'      : 1.200,
  'Aktivitas Ringan'   : 1.375,
  'Aktivitas Sedang'   : 1.550,
  'Aktivitas Berat'    : 1.725,
  'Sangat Aktif'       : 1.900,
};

const Map<String, double> _kStressFactors = {
  'Normal'                         : 1.00,
  _Str.feverKey                    : 0.13, // dipakai sebagai multiplier delta suhu
  'Peritonitis'                    : 1.35,
  'Cedera Jaringan Lunak Ringan'   : 1.14,
  'Cedera Jaringan Lunak Berat'    : 1.37,
  'Patah Tulang Multiple Ringan'   : 1.20,
  'Patah Tulang Multiple Berat'    : 1.35,
  'Sepsis Ringan'                  : 1.40,
  'Sepsis Berat'                   : 1.80,
  'Luka Bakar 0-20%'               : 1.25,
  'Luka Bakar 20-40%'              : 1.675,
  'Luka Bakar 40-100%'             : 1.95,
  'Puasa'                          : 0.70,
  'Payah Gagal Jantung Ringan'     : 1.30,
  'Payah Gagal Jantung Berat'      : 1.50,
  'Kanker'                         : 1.30,
};

// Warna brand sebagai konstanta top-level — tidak realokasi Color object per-build.
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
  double? _calculatedBmr;
  double? _calculatedTdee;

  // Shorthand untuk membaca teks stress factor saat ini.
  bool get _isFeverSelected =>
      _stressFactorController.text == _Str.feverKey;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
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

    final double bmr            = _computeBMR();
    final double activityFactor = _kActivityFactors[_activityFactorController.text] ?? 1.0;
    final double stressFactor   = _computeStressFactor();
    final double tdee           = bmr * activityFactor * stressFactor;

    setState(() {
      _calculatedBmr  = bmr;
      _calculatedTdee = tdee;
    });
    _scrollToResult();
  }

  /// Menghitung BMR menggunakan persamaan Harris-Benedict.
  ///
  /// Laki-laki  : 88.362 + (13.397×BB) + (4.799×TB) − (5.677×U)
  /// Perempuan  : 447.593 + (9.247×BB)  + (3.098×TB) − (4.330×U)
  ///
  /// [CLEAN CODE] Diekstrak dari calculateTDEE agar dapat diuji secara mandiri.
  double _computeBMR() {
    final double weight = double.tryParse(_weightController.text) ?? 0;
    final double height = double.tryParse(_heightController.text) ?? 0;
    final int    age    = int.tryParse(_ageController.text) ?? 0;

    if (_genderController.text.isEmpty || weight <= 0 || height <= 0 || age <= 0) {
      return 0;
    }

    return _genderController.text == _Str.male
        ? 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age)
        : 447.593 + (9.247 * weight)  + (3.098 * height) - (4.330 * age);
  }

  /// Menghitung stress factor.
  /// Untuk "Demam" dihitung dari delta suhu terhadap 37°C.
  ///
  /// [CLEAN CODE] Logika khusus demam dipisah agar _calculateTDEE tetap ramping.
  double _computeStressFactor() {
    if (_isFeverSelected) {
      final double temperature = double.tryParse(_temperatureController.text) ?? 0;
      return temperature > 37 ? 1.0 + (0.13 * (temperature - 37)) : 1.0;
    }
    return _kStressFactors[_stressFactorController.text] ?? 1.0;
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
      _calculatedBmr  = null;
      _calculatedTdee = null;
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
      _calculatedBmr  = null;
      _calculatedTdee = null;
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
                  Semantics(
                    key: _Keys.patientPicker, 
                    label: 'Pemilih Pasien',
                    hint:  'Pilih pasien untuk mengisi data berat badan, '
                           'tinggi badan, jenis kelamin, dan usia secara otomatis',
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
                    semanticLabel: 'Input Berat Badan TDEE',
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

                  // ── Age Field ──────────────────────────────────────────
                  _buildInputField(
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

                  // ── Activity Factor Dropdown ───────────────────────────
                  Semantics(
                    label: 'Dropdown Faktor Aktivitas TDEE',
                    hint:  'Pilih tingkat aktivitas fisik harian untuk '
                           'kalkulasi kebutuhan energi',
                    child: _buildDropdown(
                      widgetKey:  _Keys.activityDropdown,
                      controller: _activityFactorController,
                      label:      _Str.activityLabel,
                      prefixIcon: const Icon(Icons.directions_run),
                      items:      _kActivityFactors.keys.toList(),
                    ),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Stress Factor Dropdown ─────────────────────────────
                  Semantics(
                    label: 'Dropdown Faktor Stress TDEE',
                    hint:  'Pilih kondisi klinis atau faktor stress metabolik '
                           'yang sesuai dengan kondisi pasien',
                    child: _buildDropdown(
                      widgetKey:  _Keys.stressDropdown,
                      controller: _stressFactorController,
                      label:      _Str.stressLabel,
                      prefixIcon: const Icon(Icons.healing),
                      items:      _kStressFactors.keys.toList(),
                      // Custom onChanged: tampilkan/sembunyikan field suhu
                      onChanged: (String? value) {
                        final FocusScopeNode scope = FocusScope.of(context);
                        setState(() {
                          _stressFactorController.text = value ?? '';
                          if (value != _Str.feverKey) {
                            _temperatureController.clear();
                          }
                        });
                        // Tutup keyboard setelah dropdown dipilih
                        Future.delayed(
                          const Duration(milliseconds: 10),
                          () { if (mounted) scope.unfocus(); },
                        );
                      },
                    ),
                  ),

                  // ── Temperature Field (kondisional) ────────────────────
                  if (_isFeverSelected) ...[
                    SizedBox(height: sw * 0.04),
                    _buildInputField(
                      widgetKey:     _Keys.tempField,
                      controller:    _temperatureController,
                      label:         _Str.tempLabel,
                      prefixIcon:    const Icon(Icons.thermostat),
                      suffixText:    _Str.tempUnit,
                      semanticLabel: 'Input Suhu Tubuh TDEE',
                      semanticHint:  'Masukkan suhu tubuh dalam derajat Celsius '
                                     'untuk menghitung faktor demam',
                      // Validator khusus suhu — berbeda dari field lainnya
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
                      key: _Keys.btnReset,
                      onReset: _resetForm,
                      onSubmit: _calculateTDEE,
                      resetButtonColor:     Colors.white,
                      resetForegroundColor: _kBrandGreen,
                      submitIcon: const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Result Section ─────────────────────────────────────
                  if (_calculatedTdee != null) ...[
                    SizedBox(key: _resultCardKey, height: 0), // anchor scroll
                    const Divider(),
                    SizedBox(height: sw * 0.08),
                    _buildTdeeResultCard(sw),
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
  /// Menampilkan BMR sebagai nilai antara dan TDEE sebagai hasil akhir.
  Widget _buildTdeeResultCard(double sw) {
    return Semantics(
      label: 'Hasil Perhitungan TDEE: '
             'BMR ${_calculatedBmr?.toStringAsFixed(2) ?? "0"} kkal per hari, '
             'TDEE ${_calculatedTdee?.toStringAsFixed(2) ?? "0"} kkal per hari',
      hint:       'Nilai Basal Metabolic Rate dan Total Daily Energy Expenditure',
      liveRegion: true, // Screen-reader membacakan otomatis saat nilai berubah
      child: Container(
        key: _Keys.tdeeResultCard,
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
            // Baris BMR (nilai antara)
            Text(
              'BMR: ${_calculatedBmr?.toStringAsFixed(2) ?? "0"} ${_Str.resultUnit}',
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 17),
                fontWeight: FontWeight.bold,
                color: _kBrandGreen,
              ),
            ),
            SizedBox(height: sw * 0.02),
            // Baris TDEE (hasil akhir)
            Text(
              'TDEE: ${_calculatedTdee?.toStringAsFixed(2) ?? "0"} ${_Str.resultUnit}',
              style: TextStyle(
                fontSize: _responsiveFont(sw, base: 17),
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

  /// Input field numerik dengan Semantics, validasi, dan dukungan mode integer.
  Widget _buildInputField({
    required ValueKey<String> widgetKey,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    required String semanticLabel,
    required String semanticHint,
    bool isInteger                       = false,
    int maxLength                        = 5,
    String? Function(String?)? customValidator,
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
        // customValidator dipakai untuk field Suhu; lainnya pakai validator default
        validator: customValidator ??
            (value) {
              if (value == null || value.isEmpty) return '$label tidak boleh kosong';
              if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
              return null;
            },
      ),
    );
  }

  /// Dropdown generik dengan scrollbar dan penutup keyboard otomatis.
  Widget _buildDropdown({
    required ValueKey<String> widgetKey,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required List<String> items,
    double? menuHeight,
    void Function(String?)? onChanged,
  }) {
    return DropdownSearch<String>(
      key: widgetKey,
      onBeforePopupOpening: (_) {
        FocusScope.of(context).unfocus();
        return Future.value(true);
      },
      popupProps: PopupProps.menu(
        showSearchBox: false,
        constraints: BoxConstraints(maxHeight: menuHeight ?? 180),
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
          (String? newValue) {
            setState(() => controller.text = newValue ?? '');
            Future.delayed(
              const Duration(milliseconds: 10),
              () { if (mounted) FocusScope.of(context).unfocus(); },
            );
          },
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (value) {
        if (value == null || value.isEmpty) return '$label harus dipilih';
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