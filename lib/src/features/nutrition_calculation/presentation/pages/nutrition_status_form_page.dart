// lib/src/features/nutrition_calculation/presentation/pages/nutrition_status_form_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_calculation_helper.dart';

// ============================================================================
// Helper: Resolver warna kategori gizi
// Dideklarasikan di atas agar tidak di-rebuild bersama widget tree.
// ============================================================================
abstract class _NutritionColorResolver {
  static const Color _green = Color(0xFF009444);

  // BB/U — string dari helper: 'Berat badan sangat kurang (severely underweight)'
  //                             'Berat badan kurang (underweight)'
  //                             'Berat badan normal'
  //                             'Risiko Berat badan lebih'
  static Color forWeightForAge(String category) {
    // Periksa 'sangat kurang' SEBELUM 'kurang' agar tidak salah cocok substring.
    if (category.contains('sangat kurang') ||
        category.contains('severely underweight')) {
      return Colors.red;
    }
    if (category.contains('kurang') || category.contains('underweight')) {
      return Colors.orange;
    }
    if (category.contains('Normal')) {
      return _green;
    }
    return Colors.orange; // 'Risiko Berat badan lebih' — peringatan, bukan merah
  }

  // TB/U — string dari helper: 'Sangat pendek (severely stunted)'
  //                             'Pendek (stunted)'
  //                             'Normal'
  //                             'Tinggi'
  static Color forHeightForAge(String category) {
    // Periksa 'Sangat pendek' SEBELUM 'Pendek' agar tidak salah cocok substring.
    if (category.contains('Sangat pendek') ||
        category.contains('severely stunted')) {
      return Colors.red;
    }
    if (category.contains('Pendek') || category.contains('stunted')) {
      return Colors.orange;
    }
    if (category.contains('Normal')) {
      return _green;
    }
    return Colors.blue; // 'Tinggi'
  }

  // BB/TB & IMT/U — string dari helper: 'Gizi buruk (severely wasted)'
  //                                      'Gizi kurang (wasted)'
  //                                      'Gizi baik (normal)'
  //                                      'Berisiko gizi lebih'
  //                                      'Gizi lebih (overweight)'
  //                                      'Obesitas (obese)'
  static Color forWeightForHeight(String category) {
    if (category.contains('Gizi buruk') ||
        category.contains('severely wasted')) {
      return Colors.red;
    }
    // 'Gizi kurang' dicek SEBELUM 'wasted' agar tidak konflik dengan 'severely wasted'.
    if (category.contains('Gizi kurang') ||
        category.contains('wasted') ||
        category.contains('Berisiko gizi lebih')) {
      return Colors.orange;
    }
    if (category.contains('Gizi baik') || category.contains('normal')) {
      return _green;
    }
    return Colors.red; // 'Gizi lebih' / 'Obesitas'
  }

  static Color forBMIForAge(String category) => forWeightForHeight(category);

  /// Dispatch ke resolver yang tepat berdasarkan judul kartu.
  static Color resolve(String cardTitle, String category) {
    if (cardTitle.contains('BB/U')) {
      return forWeightForAge(category);
    }
    if (cardTitle.contains('TB/U')) {
      return forHeightForAge(category);
    }
    if (cardTitle.contains('BB/TB')) {
      return forWeightForHeight(category);
    }
    if (cardTitle.contains('IMT/U')) {
      return forBMIForAge(category);
    }
    return _green;
  }
}

// ============================================================================
// StatefulWidget
// ============================================================================
class NutritionStatusFormPage extends StatefulWidget {
  final String userRole;

  const NutritionStatusFormPage({
    super.key,
    required this.userRole,
  });

  @override
  State<NutritionStatusFormPage> createState() =>
      _NutritionStatusFormPageState();
}

class _NutritionStatusFormPageState extends State<NutritionStatusFormPage> {
  // --------------------------------------------------------------------------
  // Keys & Controllers
  // --------------------------------------------------------------------------
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _measurementDateController = TextEditingController();
  final _genderController = TextEditingController();
  final _scrollController = ScrollController();

  /// Dipakai untuk scroll ke seksi hasil setelah hitung.
  final GlobalKey _resultSectionKey = GlobalKey();

  /// Dipakai untuk reset PatientPickerWidget dari luar.
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();

  // --------------------------------------------------------------------------
  // State
  // --------------------------------------------------------------------------
  DateTime? _birthDate;
  DateTime? _measurementDate;
  int? _ageInMonths;
  Map<String, dynamic>? _calculationResults;

  // --------------------------------------------------------------------------
  // Lifecycle
  // --------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (!mounted) return;
      setState(() {
        _measurementDate = DateTime.now();
        _measurementDateController.text =
            DateFormat('dd MMMM yyyy', 'id_ID').format(_measurementDate!);
      });
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _birthDateController.dispose();
    _measurementDateController.dispose();
    _genderController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------------------------
  // Logika bisnis
  // --------------------------------------------------------------------------

  void _calculateAgeInMonths() {
    if (_birthDate == null || _measurementDate == null) return;
    final days = _measurementDate!.difference(_birthDate!).inDays;
    _ageInMonths = (days / 30.44).round();

    if (_ageInMonths! < 0 || _ageInMonths! > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usia anak harus antara 0-60 bulan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _calculateNutritionStatus() {
    if (!_formKey.currentState!.validate()) return;

    if (_ageInMonths == null || _ageInMonths! < 0 || _ageInMonths! > 60) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pastikan usia anak antara 0-60 bulan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // [CLEAN] Delegasi penuh ke NutritionCalculationHelper — tidak ada duplikasi
    final results = NutritionCalculationHelper.calculateAll(
      birthDate: _birthDate!,
      checkDate: _measurementDate!,
      weight: double.parse(_weightController.text),
      height: double.parse(_heightController.text),
      gender: _genderController.text,
    );

    setState(() => _calculationResults = results);
    _scrollToResult();
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _resultSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _birthDate = null;
      _measurementDate = DateTime.now();
      _birthDateController.clear();
      _measurementDateController.text =
          DateFormat('dd MMMM yyyy', 'id_ID').format(_measurementDate!);
      _weightController.clear();
      _heightController.clear();
      _genderController.clear();
      _ageInMonths = null;
      _calculationResults = null;
      _patientPickerKey.currentState?.resetSelection();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isBirthDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      locale: const Locale('id', 'ID'),
      initialDate: isBirthDate
          ? (_birthDate ?? DateTime.now())
          : (_measurementDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked == null) return;

    setState(() {
      final formatted = DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
      if (isBirthDate) {
        _birthDate = picked;
        _birthDateController.text = formatted;
      } else {
        _measurementDate = picked;
        _measurementDateController.text = formatted;
      }
      if (_birthDate != null && _measurementDate != null) {
        _calculateAgeInMonths();
      }
    });
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

      _birthDate = dob;
      _birthDateController.text =
          DateFormat('dd MMMM yyyy', 'id_ID').format(dob);

      _measurementDate = DateTime.now();
      _measurementDateController.text =
          DateFormat('dd MMMM yyyy', 'id_ID').format(_measurementDate!);

      _calculateAgeInMonths();

      final incomingGender = gender.toLowerCase();
      if (incomingGender.contains('laki') ||
          incomingGender.contains('pria') ||
          incomingGender == 'l') {
        _genderController.text = 'Laki-laki';
      } else if (incomingGender.contains('perempuan') ||
          incomingGender.contains('wanita') ||
          incomingGender == 'p') {
        _genderController.text = 'Perempuan';
      } else {
        _genderController.text = gender;
      }

      _calculationResults = null;
    });
  }

  // --------------------------------------------------------------------------
  // Build utama
  // [RESPONSIVE] Semua nilai jarak & font dihitung dari MediaQuery
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // scaleFactor: 1.0 pada HP 360dp lebar, maksimal 2.0 untuk tablet lebar ~720dp+
    final double sw = MediaQuery.of(context).size.width;
    final double scaleFactor = (sw / 360.0).clamp(1.0, 2.0);

    final double hPad = 16.0 * scaleFactor;
    final double vPad = 16.0 * scaleFactor;
    final double sectionSpacing = 20.0 * scaleFactor;
    final double itemSpacing = 16.0 * scaleFactor;
    final double titleFontSize = 20.0 * scaleFactor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Status Gizi Anak',
        subtitle: 'Usia 0-60 Bulan',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(
              horizontal: hPad,
              vertical: vPad,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Patient Picker ──────────────────────────────────────
                  // [QA] ValueKey untuk Katalon Object Spy
                  PatientPickerWidget(
                    key: _patientPickerKey,
                    onPatientSelected: _fillDataFromPatient,
                    userRole: widget.userRole,
                  ),

                  SizedBox(height: sectionSpacing),

                  Text(
                    'Input Data Status Gizi',
                    style: TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: sectionSpacing),

                  // ── Tanggal Lahir ───────────────────────────────────────
                  Semantics(
                    label: 'Field Tanggal Lahir Pasien',
                    child: _buildDatePickerField(
                      key: const ValueKey('birthDateField'), // [QA]
                      controller: _birthDateController,
                      label: 'Tanggal Lahir',
                      onTap: () => _selectDate(context, true),
                    ),
                  ),

                  SizedBox(height: itemSpacing),

                  // ── Tanggal Pengukuran ──────────────────────────────────
                  Semantics(
                    label: 'Field Tanggal Pengukuran',
                    child: _buildDatePickerField(
                      key: const ValueKey('checkDateField'), // [QA]
                      controller: _measurementDateController,
                      label: 'Tanggal Pengukuran',
                      onTap: () => _selectDate(context, false),
                    ),
                  ),

                  // ── Usia (tampil setelah kedua tanggal terisi) ──────────
                  if (_ageInMonths != null) ...[
                    SizedBox(height: itemSpacing),
                    Semantics(
                      label: 'Usia Pasien dalam Bulan',
                      value: '$_ageInMonths bulan',
                      child: Container(
                        key: const ValueKey('ageDisplay'), // [QA]
                        padding: EdgeInsets.all(12.0 * scaleFactor),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue),
                        ),
                        child: Text(
                          'Usia: $_ageInMonths bulan',
                          style: TextStyle(
                            fontSize: 16.0 * scaleFactor,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: itemSpacing),

                  // ── Jenis Kelamin ───────────────────────────────────────
                  Semantics(
                    label: 'Dropdown Jenis Kelamin',
                    child: _buildCustomDropdown(
                      key: const ValueKey('genderDropdown'), // [QA]
                      controller: _genderController,
                      label: 'Jenis Kelamin',
                      prefixIcon: const Icon(Icons.wc),
                      items: const ['Laki-laki', 'Perempuan'],
                    ),
                  ),

                  SizedBox(height: itemSpacing),

                  // ── Berat Badan ─────────────────────────────────────────
                  Semantics(
                    label: 'Field Berat Badan dalam Kilogram',
                    child: _buildTextFormField(
                      key: const ValueKey('weightField'), // [QA]
                      controller: _weightController,
                      label: 'Berat Badan',
                      prefixIcon: const Icon(Icons.monitor_weight),
                      suffixText: 'kg',
                    ),
                  ),

                  SizedBox(height: itemSpacing),

                  // ── Tinggi Badan ────────────────────────────────────────
                  Semantics(
                    label: 'Field Tinggi Badan dalam Sentimeter',
                    child: _buildTextFormField(
                      key: const ValueKey('heightField'), // [QA]
                      controller: _heightController,
                      label: 'Tinggi Badan',
                      prefixIcon: const Icon(Icons.height),
                      suffixText: 'cm',
                    ),
                  ),

                  SizedBox(height: 32.0 * scaleFactor),

                  // ── Tombol Aksi ─────────────────────────────────────────
                  // [QA] key diletakkan pada wrapper agar Katalon dapat
                  //      mendeteksi area tombol "Hitung" & "Reset" sekaligus.
                  Semantics(
                    label: 'Tombol Hitung dan Reset Status Gizi',
                    child: FormActionButtons(
                      key: const ValueKey('btnHitung'), // [QA]
                      onReset: _resetForm,
                      onSubmit: _calculateNutritionStatus,
                      resetButtonColor: Colors.white,
                      resetForegroundColor: const Color(0xFF009444),
                      submitIcon:
                          const Icon(Icons.calculate, color: Colors.white),
                    ),
                  ),

                  SizedBox(height: 32.0 * scaleFactor),

                  // ── Seksi Hasil (diekstrak ke _buildResultList) ─────────
                  if (_calculationResults != null)
                    _buildResultList(
                      scaleFactor: scaleFactor,
                      itemSpacing: itemSpacing,
                      titleFontSize: titleFontSize,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // [CLEAN] Daftar hasil diagnosa — diekstrak dari build() agar tetap ramping
  // --------------------------------------------------------------------------
  Widget _buildResultList({
    required double scaleFactor,
    required double itemSpacing,
    required double titleFontSize,
  }) {
    return Column(
      key: _resultSectionKey, // Anchor untuk ensureVisible
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        SizedBox(height: 32.0 * scaleFactor),

        Text(
          'Hasil Status Gizi',
          style: TextStyle(
            fontSize: titleFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: 16.0 * scaleFactor),

        // BB/U
        _buildResultCard(
          valueKey: const ValueKey('resultCard_bbPerU'), // [QA]
          semanticsLabel: 'Hasil Z-Score BB per Umur',
          title: 'Berat Badan menurut Umur (BB/U)',
          data: _calculationResults!['bbPerU'] as Map<String, dynamic>,
          scaleFactor: scaleFactor,
        ),

        SizedBox(height: 12.0 * scaleFactor),

        // TB/U
        _buildResultCard(
          valueKey: const ValueKey('resultCard_tbPerU'), // [QA]
          semanticsLabel: 'Hasil Z-Score TB per Umur',
          title: 'Tinggi Badan menurut Umur (TB/U)',
          data: _calculationResults!['tbPerU'] as Map<String, dynamic>,
          scaleFactor: scaleFactor,
        ),

        SizedBox(height: 12.0 * scaleFactor),

        // BB/TB
        _buildResultCard(
          valueKey: const ValueKey('resultCard_bbPerTb'), // [QA]
          semanticsLabel: 'Hasil Z-Score BB per Tinggi Badan',
          title: 'Berat Badan menurut Tinggi Badan (BB/TB)',
          data: _calculationResults!['bbPerTB'] as Map<String, dynamic>,
          scaleFactor: scaleFactor,
        ),

        SizedBox(height: 12.0 * scaleFactor),

        // IMT/U
        _buildResultCard(
          valueKey: const ValueKey('resultCard_imtPerU'), // [QA]
          semanticsLabel: 'Hasil Z-Score IMT per Umur',
          title: 'Indeks Massa Tubuh menurut Umur (IMT/U)',
          data: _calculationResults!['imtPerU'] as Map<String, dynamic>,
          scaleFactor: scaleFactor,
          additionalInfo:
              'IMT: ${(_calculationResults!['bmi'] as double?)?.toStringAsFixed(2) ?? '-'} kg/m²',
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Helper Widget: Result Card
  // --------------------------------------------------------------------------
  Widget _buildResultCard({
    required ValueKey<String> valueKey,
    required String semanticsLabel,
    required String title,
    required Map<String, dynamic> data,
    required double scaleFactor,
    String? additionalInfo,
  }) {
    final String category = (data['category'] as String?) ?? '-';
    final double? zScore = data['zScore'] as double?;
    final Color resultColor = _NutritionColorResolver.resolve(title, category);

    return Semantics(
      label: semanticsLabel,
      value: 'Z-Score: ${zScore?.toStringAsFixed(2) ?? '-'}, Kategori: $category',
      child: Container(
        key: valueKey,
        padding: EdgeInsets.all(16.0 * scaleFactor),
        decoration: BoxDecoration(
          color: resultColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: resultColor, width: 2.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14.0 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 8.0 * scaleFactor),
            Text(
              'Z-Score: ${zScore?.toStringAsFixed(2) ?? '-'}',
              style: TextStyle(
                fontSize: 14.0 * scaleFactor,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 4.0 * scaleFactor),
            Text(
              'Kategori: $category',
              style: TextStyle(
                fontSize: 14.0 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: resultColor,
              ),
            ),
            if (additionalInfo != null) ...[
              SizedBox(height: 4.0 * scaleFactor),
              Text(
                additionalInfo,
                style: TextStyle(
                  fontSize: 14.0 * scaleFactor,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Helper Widget: Text Form Field (BB & TB)
  // [PERF] const pada border & inputFormatters yang tidak berubah
  // --------------------------------------------------------------------------
  Widget _buildTextFormField({
    required ValueKey<String> key,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    int maxLength = 5,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        LengthLimitingTextInputFormatter(maxLength),
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label tidak boleh kosong';
        if (double.tryParse(value) == null) return 'Masukkan angka yang valid';
        return null;
      },
    );
  }

  // --------------------------------------------------------------------------
  // Helper Widget: Custom Dropdown (Jenis Kelamin)
  // [PERF] PopupProps diubah ke const
  // --------------------------------------------------------------------------
  Widget _buildCustomDropdown({
    required ValueKey<String> key,
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required Icon prefixIcon,
  }) {
    return DropdownSearch<String>(
      key: key,
      popupProps: const PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
        constraints: BoxConstraints(maxHeight: 240),
      ),
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged: (String? newValue) =>
          setState(() => controller.text = newValue ?? ''),
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (value) =>
          (value == null || value.isEmpty) ? '$label harus dipilih' : null,
    );
  }

  // --------------------------------------------------------------------------
  // Helper Widget: Date Picker Field
  // [PERF] const pada OutlineInputBorder dan Icon
  // --------------------------------------------------------------------------
  Widget _buildDatePickerField({
    required ValueKey<String> key,
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today),
      ),
      onTap: onTap,
      validator: (value) {
        if (value == null || value.isEmpty) return '$label tidak boleh kosong';
        return null;
      },
    );
  }
}