// lib/src/features/nutrition_calculation/presentation/pages/bbi_anak_form_page.dart

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
  static const categoryDropdown = ValueKey('categoryDropdown');
  static const ageField         = ValueKey('ageField');
  static const btnReset         = ValueKey('btnReset');
  static const bbiAnakResultCard = ValueKey('bbiAnakResultCard');
}

// ---------------------------------------------------------------------------
// [OPTIMIZATION] String literal di-hoist agar widget Text dapat memakai
// const constructor — tidak diinstansiasi ulang setiap siklus rebuild.
// ---------------------------------------------------------------------------
class _Str {
  const _Str._();
  static const appBarTitle      = 'BBI Anak';
  static const appBarSubtitle   = 'Berat Badan Ideal Anak';
  static const sectionTitle     = 'Input Data BBI Anak';
  static const categoryLabel    = 'Kategori Usia';
  static const resultTitle      = 'Hasil BBI Anak';
  static const resultUnit       = 'kg';

  // Kategori usia
  static const cat0to11  = '0 - 11 Bulan';
  static const cat1to6   = '1 - 6 Tahun';
  static const cat7to12  = '7 - 12 Tahun';
  static const List<String> ageCategories = [cat0to11, cat1to6, cat7to12];

  // Label & suffix dinamis per kategori
  static const ageLabelMonths = 'Usia (Bulan)';
  static const ageLabelYears  = 'Usia (Tahun)';
  static const ageSuffixMonths = 'bln';
  static const ageSuffixYears  = 'thn';

  // Deskripsi formula per kategori
  static const formulaMonths = 'Rumus: (Usia bulan + 9) / 2';
  static const formula1to6   = 'Rumus: (2 × Usia tahun) + 8';
  static const formula7to12  = 'Rumus: ((7 × Usia tahun) − 5) / 2';
  static const formulaDefault = 'Berat Badan Ideal Anak';

  // Pesan snackbar
  static const snackOutOfRange =
      'Umur pasien di luar kategori anak (0-12 tahun)';
}

// Warna brand sebagai konstanta top-level — tidak realokasi Color object per-build.
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
  // ── Controllers & Keys ────────────────────────────────────────────────────
  final _formKey            = GlobalKey<FormState>();
  final _ageController      = TextEditingController();
  final _categoryController = TextEditingController();
  final _scrollController   = ScrollController();
  final _resultCardKey      = GlobalKey();
  final _patientPickerKey   = GlobalKey<PatientPickerWidgetState>(); // GlobalKey untuk akses .currentState

  // ── State ─────────────────────────────────────────────────────────────────
  double? _bbiResult;

  // Shorthand agar kondisi kategori terbaca jelas di seluruh kode.
  bool get _isMonthCategory  => _categoryController.text == _Str.cat0to11;
  bool get _is1to6Category   => _categoryController.text == _Str.cat1to6;
  bool get _is7to12Category  => _categoryController.text == _Str.cat7to12;

  // ── Lifecycle ─────────────────────────────────────────────────────────────
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
    final double bbi      = _computeBBI(ageValue, _categoryController.text);

    setState(() => _bbiResult = bbi);
    _scrollToResult();
  }

  /// Pure function — tanpa side-effect, bebas di-unit-test.
  ///
  /// Formula BBI Anak:
  ///   0-11 Bulan : (Usia bulan + 9) / 2
  ///   1-6 Tahun  : (2 × Usia tahun) + 8
  ///   7-12 Tahun : ((7 × Usia tahun) − 5) / 2
  double _computeBBI(double age, String category) {
    if (category == _Str.cat0to11)  return (age + 9) / 2;
    if (category == _Str.cat1to6)   return (2 * age) + 8;
    if (category == _Str.cat7to12)  return ((7 * age) - 5) / 2;
    return 0;
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
    double weight,
    double height,
    String gender,
    DateTime dob,
  ) {
    final (int years, int months) = _calculateAgeComponents(dob);

    setState(() {
      _bbiResult = null;

      if (months < 12) {
        _categoryController.text = _Str.cat0to11;
        _ageController.text      = months.toString();
      } else if (years >= 1 && years <= 6) {
        _categoryController.text = _Str.cat1to6;
        _ageController.text      = years.toString();
      } else if (years >= 7 && years <= 12) {
        _categoryController.text = _Str.cat7to12;
        _ageController.text      = years.toString();
      } else {
        _categoryController.clear();
        _ageController.clear();
        // Tampilkan notifikasi setelah setState selesai
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text(_Str.snackOutOfRange)),
          );
        });
      }
    });
  }

  /// Menghitung komponen usia (tahun & bulan total) dari tanggal lahir.
  /// Mengembalikan record (years, totalMonths). Pure function.
  (int years, int months) _calculateAgeComponents(DateTime dob) {
    final DateTime now = DateTime.now();

    int years  = now.year - dob.year;
    int months = (now.year - dob.year) * 12 + (now.month - dob.month);

    if (now.day < dob.day) {
      months--;
      if (now.month <= dob.month) years--;
    }

    return (years < 0 ? 0 : years, months < 0 ? 0 : months);
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

  // ── Helpers Dinamis ───────────────────────────────────────────────────────

  /// Label field usia berubah tergantung kategori yang dipilih.
  String get _ageLabel => _isMonthCategory ? _Str.ageLabelMonths : _Str.ageLabelYears;

  /// Suffix field usia berubah tergantung kategori yang dipilih.
  String get _ageSuffix => _isMonthCategory ? _Str.ageSuffixMonths : _Str.ageSuffixYears;

  /// Deskripsi formula yang digunakan pada result card.
  String get _formulaDescription {
    if (_isMonthCategory)  return _Str.formulaMonths;
    if (_is1to6Category)   return _Str.formula1to6;
    if (_is7to12Category)  return _Str.formula7to12;
    return _Str.formulaDefault;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // [RESPONSIVE] MediaQuery.sizeOf hanya subscribe perubahan Size —
    // lebih efisien dari MediaQuery.of yang subscribe seluruh MediaQueryData.
    final double sw   = MediaQuery.sizeOf(context).width;
    final double hPad = sw * 0.04; // ≈ 16 dp pada layar 400 dp

    return Scaffold(
      backgroundColor: Colors.white,
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
                    key:   _Keys.patientPicker, // ← ValueKey untuk Katalon
                    label: 'Pemilih Pasien BBI Anak',
                    hint:  'Pilih pasien anak untuk mengisi kategori usia '
                           'dan nilai usia secara otomatis',
                    child: PatientPickerWidget(
                      key: _patientPickerKey,   // ← GlobalKey untuk .currentState
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

                  // ── Category Dropdown ──────────────────────────────────
                  Semantics(
                    label: 'Dropdown Kategori Usia BBI Anak',
                    hint:  'Pilih kategori usia: 0-11 Bulan, 1-6 Tahun, '
                           'atau 7-12 Tahun',
                    child: _buildCategoryDropdown(),
                  ),

                  SizedBox(height: sw * 0.04),

                  // ── Age Field (label & suffix dinamis) ─────────────────
                  _buildAgeField(sw),

                  SizedBox(height: sw * 0.08),

                  // ── Action Buttons ─────────────────────────────────────
                  Semantics(
                    label: 'Tombol Aksi Form BBI Anak',
                    hint:  'Tombol Reset menghapus semua input; '
                           'Tombol Hitung menghitung nilai BBI Anak',
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
      label: 'Hasil BBI Anak: '
             '${_bbiResult!.toStringAsFixed(2)} kilogram, '
             'kategori ${_categoryController.text}',
      hint:       'Nilai Berat Badan Ideal anak berdasarkan kategori dan nilai usia',
      liveRegion: true, // Screen-reader membacakan otomatis saat nilai berubah
      child: Container(
        key: _Keys.bbiAnakResultCard,
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
              _formulaDescription,
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

  /// Dropdown kategori usia dengan key QA & reset age saat ganti kategori.
  Widget _buildCategoryDropdown() {
    return DropdownSearch<String>(
      key: _Keys.categoryDropdown,
      popupProps: const PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: _Str.ageCategories,
      dropdownDecoratorProps: const DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText:  _Str.categoryLabel,
          border:     OutlineInputBorder(),
          prefixIcon: Icon(Icons.category),
        ),
      ),
      onChanged: (String? newValue) {
        setState(() {
          _categoryController.text = newValue ?? '';
          // Reset nilai usia saat ganti kategori agar tidak rancu
          _ageController.clear();
          _bbiResult = null;
        });
      },
      selectedItem: _categoryController.text.isEmpty
          ? null
          : _categoryController.text,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '${_Str.categoryLabel} harus dipilih';
        }
        return null;
      },
    );
  }

  /// Field usia dengan label & suffix yang berubah dinamis sesuai kategori.
  Widget _buildAgeField(double sw) {
    return Semantics(
      label: 'Input Nilai Usia BBI Anak',
      hint:  _isMonthCategory
          ? 'Masukkan usia dalam satuan bulan (0 hingga 11)'
          : 'Masukkan usia dalam satuan tahun',
      textField: true,
      child: TextFormField(
        key: _Keys.ageField,
        controller: _ageController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          // Maks 3 karakter — usia anak tidak lebih dari 3 digit
          LengthLimitingTextInputFormatter(3),
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
        ],
        decoration: InputDecoration(
          // Label & suffix berubah dinamis berdasarkan getter
          labelText:  _ageLabel,
          suffixText: _ageSuffix,
          border:     const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.cake),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Usia tidak boleh kosong';
          if (double.tryParse(value) == null) return 'Masukkan angka valid';
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