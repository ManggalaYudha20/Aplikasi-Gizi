// lib/src/features/nutrition_calculation/presentation/pages/child_quick_calc_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:dropdown_search/dropdown_search.dart';

import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/presentation/widgets/responsive_number_field.dart';

// Service Imports
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/nutrition_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/bbi_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/services/schofield_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/data/models/reference_data.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/reference/widgets/reference_widgets.dart';

class _Keys {
  const _Keys._();
  static const birthDateField = ValueKey('cqc_birthDateField');
  static const measureDateField = ValueKey('cqc_measureDateField');
  static const weightField = ValueKey('cqc_weightField');
  static const heightField = ValueKey('cqc_heightField');
  static const faDropdown = ValueKey('cqc_faDropdown');
  static const fsDropdown = ValueKey('cqc_fsDropdown');
  static const btnReset = ValueKey('cqc_btnReset');
}

class _Str {
  const _Str._();
  static const appBarTitle = 'Anak';
  static const appBarSubtitle = 'Hitung Kebutuhan Gizi (0-18 Tahun)';
  static const sectionTitle = 'Input Data Anak';

  static const weightLabel = 'Berat Badan';
  static const weightUnit = 'kg';
  static const heightLabel = 'Tinggi/Panjang Badan';
  static const heightUnit = 'cm';
  static const birthDateLabel = 'Tanggal Lahir';
  static const measureDateLabel = 'Tanggal Pemeriksaan';
}

const _kBrandGreen = Color(0xFF009444);
const _kMaleColor = Color(0xFF2563EB); // Biru untuk Laki-laki
const _kFemaleColor = Color(0xFFDB2777); // Pink untuk Perempuan

// ============================================================================
// Helper: Resolver warna kategori gizi
// ============================================================================
abstract class _NutritionColorResolver {
  static const Color _green = Color(0xFF009444);

  static Color resolve(String cardTitle, String category) {
    final lowerCat = category.toLowerCase();
    
    if (lowerCat.contains('buruk') || lowerCat.contains('sangat kurang') || lowerCat.contains('severely')) {
      return Colors.red;
    }
    if (lowerCat.contains('kurang') || lowerCat.contains('risiko') || lowerCat.contains('pendek') || lowerCat.contains('stunted')) {
      return Colors.orange;
    }
    if (lowerCat.contains('lebih') || lowerCat.contains('obesitas') || lowerCat.contains('obese')) {
      return Colors.red;
    }
    if (lowerCat.contains('normal') || lowerCat.contains('baik')) {
      return _green;
    }
    return Colors.blue;
  }
}

// ============================================================================
// Model Data Hasil Kalkulasi per Gender
// ============================================================================
class _ChildGenderCalcResult {
  final String ageFormatted;
  final double bbi;
  
  // Jika 0 - 60 Bulan
  final NutritionAllResult? status0to60;
  
  // Jika > 60 Bulan - 18 Tahun
  final ImtuResult? imtu5to18;

  // Energi & Makronutrien
  final double bmrSchofield;
  final double tdee; // Total Daily Energy Expenditure
  final double protein;
  final double lemak;
  final double karbo;
  final double cairan;

  _ChildGenderCalcResult({
    required this.ageFormatted,
    required this.bbi,
    this.status0to60,
    this.imtu5to18,
    required this.bmrSchofield,
    required this.tdee,
    required this.protein,
    required this.lemak,
    required this.karbo,
    required this.cairan,
  });
}

// ============================================================================
// Page Utama
// ============================================================================
class ChildQuickCalcPage extends StatefulWidget {
  const ChildQuickCalcPage({super.key});

  @override
  State<ChildQuickCalcPage> createState() => _ChildQuickCalcPageState();
}

class _ChildQuickCalcPageState extends State<ChildQuickCalcPage> {
  // ── Controllers ───────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _measureDateController = TextEditingController();
  
  final _faController = TextEditingController(text: 'Tanpa Faktor Aktivitas');
  final _fsController = TextEditingController(text: 'Tanpa Faktor Stres');
  
  final _scrollController = ScrollController();
  final _resultSectionKey = GlobalKey();

  // ── State ─────────────────────────────────────────────────────────────────
  DateTime? _birthDate;
  DateTime? _measurementDate;

  _ChildGenderCalcResult? _maleResult;
  _ChildGenderCalcResult? _femaleResult;

  // Pilihan Faktor Aktivitas & Stres (Menggunakan Map untuk DropdownSearch)
  final Map<String, double> _activityFactors = {
    'Tanpa Faktor Aktivitas': 1.0,
    'Aktivitas Sangat Ringan': 1.1,
    'Aktivitas Ringan': 1.2,
    'Aktivitas Sedang': 1.3,
    'Aktivitas Berat': 1.4,
    'Aktivitas Sangat Berat': 1.5,
  };

  final Map<String, double> _stressFactors = {
    'Tanpa Faktor Stres': 1.0,
    'Stres Sangat Ringan': 1.1,
    'Stres Ringan': 1.2,
    'Stres Sedang': 1.3,
    'Stres Berat': 1.4,
    'Stres Sangat Berat': 1.5,
  };

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      if (!mounted) return;
      setState(() {
        _measurementDate = DateTime.now();
        _measureDateController.text =
            DateFormat('dd MMMM yyyy', 'id_ID').format(_measurementDate!);
      });
    });
  }

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    _birthDateController.dispose();
    _measureDateController.dispose();
    _faController.dispose();
    _fsController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Business Logic ────────────────────────────────────────────────────────

  Future<void> _pickDate({required bool isBirthDate}) async {
    final DateTime initial = isBirthDate
        ? (_birthDate ?? DateTime.now())
        : (_measurementDate ?? DateTime.now());

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('id', 'ID'),
    );

    if (picked == null) return;

    setState(() {
      if (isBirthDate) {
        _birthDate = picked;
        _birthDateController.text =
            DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
      } else {
        _measurementDate = picked;
        _measureDateController.text =
            DateFormat('dd MMMM yyyy', 'id_ID').format(picked);
      }
      _maleResult = null;
      _femaleResult = null;
    });
  }

  Map<String, double> _calculateMacrosAndFluid({
    required double weight,
    required double bbi,
    required double ageInYearsFraction,
    required bool isMale,
    required double tdee,
  }) {
    // Gunakan BBI jika valid, jika tidak gunakan aktual
    double weightToUse = (bbi > 0) ? bbi : weight;
    double proteinPerKg = 0;

    // Referensi Protein RDA/AKG Anak (g/kg BB)
    if (ageInYearsFraction < 0.5) {
      proteinPerKg = 2.2;
    } else if (ageInYearsFraction < 1) {
      proteinPerKg = 1.5;
    } else if (ageInYearsFraction <= 3) {
      proteinPerKg = 1.23;
    } else if (ageInYearsFraction <= 6) {
      proteinPerKg = 1.2;
    } else if (ageInYearsFraction <= 10) {
      proteinPerKg = 1.0;
    } else {
      if (ageInYearsFraction <= 14) {
        proteinPerKg = 1.0;
      } else {
        proteinPerKg = 0.8;
      }
    }

    double totalProtein = proteinPerKg * weightToUse;
    double totalLemak = (0.35 * tdee) / 9; // 35% dari TDEE
    double totalKarbo = (tdee - (totalProtein * 4) - (totalLemak * 9)) / 4;
    if (totalKarbo < 0) totalKarbo = 0;

    // Cairan metode Holliday-Segar
    double totalCairan = 0;
    if (weightToUse <= 10) {
      totalCairan =  100 * weightToUse; // 100ml per kg untuk 10kg pertama
    } else if (weightToUse <= 20) {
      totalCairan = 1000 + (50 * (weightToUse - 10)); // 1000ml + 50ml/kg untuk 10kg kedua
    } else {
      totalCairan = 1500 + (20 * (weightToUse - 20)); // 1500ml + 20ml/kg untuk sisa BB
    }

    return {
      'protein': totalProtein,
      'lemak': totalLemak,
      'karbo': totalKarbo,
      'cairan': totalCairan,
    };
  }

  void _calculateAll() {
    if (!_formKey.currentState!.validate()) return;
    if (_birthDate == null || _measurementDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pastikan Tanggal Lahir & Pemeriksaan telah diisi!')),
      );
      return;
    }

    final double weight = double.parse(_weightController.text);
    final double height = double.parse(_heightController.text);
    
    // Ambil nilai FA dan FS dari Map
    final double selectedFA = _activityFactors[_faController.text] ?? 1.0;
    final double selectedFS = _stressFactors[_fsController.text] ?? 1.0;

    // Hitung Usia (Bulan & Tahun Kalender)
    int years = _measurementDate!.year - _birthDate!.year;
    int months = _measurementDate!.month - _birthDate!.month;
    if (_measurementDate!.day < _birthDate!.day) {
      months -= 1;
    }
    if (months < 0) {
      years -= 1;
      months += 12;
    }
    
    final int ageYears = years;
    final int ageMonthsRemainder = months;
    final int totalCalendarMonths = (ageYears * 12) + ageMonthsRemainder;
    
    // Perhitungan umur desimal untuk Formula
    final int days = _measurementDate!.difference(_birthDate!).inDays;
    final double ageInYearsFraction = days / 365.25;

    // Hitung WHO Standard age in months untuk Z-Score 0-60 bulan
    final int whoAgeInMonths = NutritionCalculatorService.calculateAgeInMonths(
      birthDate: _birthDate!,
      checkDate: _measurementDate!,
    );

    if (ageInYearsFraction < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tanggal Lahir tidak boleh melewati Tanggal Pemeriksaan')),
      );
      return;
    }
    
    if (totalCalendarMonths > 216) { // 18 Tahun
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usia pasien melebihi batas 18 tahun untuk kalkulator anak.')),
      );
      return;
    }

    String ageFormatted = ageYears > 0 
        ? '$ageYears tahun $ageMonthsRemainder bulan' 
        : '$ageMonthsRemainder bulan';

    setState(() {
      for (int i = 0; i < 2; i++) {
        bool isMale = i == 0;
        String genderStr = isMale ? NutritionCalculatorService.genderMale : NutritionCalculatorService.genderFemale;
        
        // 1. Hitung BBI
        double bbi = 0;
        if (ageYears <= 12) {
          String bbiCategory = '';
          if (totalCalendarMonths < 12) {
            bbiCategory = BbiCalculatorService.categoryMonths0to11;
          } else if (ageYears >= 1 && ageYears <= 6) {
            bbiCategory = BbiCalculatorService.categoryYears1to6;
          } else if (ageYears >= 7 && ageYears <= 12) {
            bbiCategory = BbiCalculatorService.categoryYears7to12;
          }
          
          double ageValForBbi = (totalCalendarMonths < 12) ? totalCalendarMonths.toDouble() : ageYears.toDouble();
          bbi = BbiCalculatorService.calculateChild(ageValue: ageValForBbi, category: bbiCategory);
        } else {
          bbi = BbiCalculatorService.calculateAdult(heightCm: height, isMale: isMale);
        }

        // 2. Hitung BMR Schofield dan TDEE
        double bmrSchofield = SchofieldCalculatorService.calculateWithWeightAndHeight(
          weightKg: weight,
          heightCm: height,
          ageInYears: ageInYearsFraction,
          isMale: isMale,
        );

        double tdee = bmrSchofield * selectedFA * selectedFS;

        // 3. Hitung Kebutuhan Makro & Cairan menggunakan TDEE
        final macros = _calculateMacrosAndFluid(
          weight: weight,
          bbi: bbi,
          ageInYearsFraction: ageInYearsFraction,
          isMale: isMale,
          tdee: tdee,
        );

        // 4. Status Gizi (0-60 Bulan vs 5-18 Tahun)
        NutritionAllResult? status0to60;
        ImtuResult? imtu5to18;

        if (whoAgeInMonths <= 60) {
          status0to60 = NutritionCalculatorService.calculateAll(
            birthDate: _birthDate!,
            checkDate: _measurementDate!,
            weightKg: weight,
            heightCm: height,
            gender: genderStr,
          );
        } else {
          imtu5to18 = NutritionCalculatorService.calculateIMTUFromRawInputs(
            ageYears: ageYears,
            ageMonthsRemainder: ageMonthsRemainder,
            weightKg: weight,
            heightCm: height,
            gender: genderStr,
          );
        }

        final resultObj = _ChildGenderCalcResult(
          ageFormatted: ageFormatted,
          bbi: bbi,
          status0to60: status0to60,
          imtu5to18: imtu5to18,
          bmrSchofield: bmrSchofield,
          tdee: tdee,
          protein: macros['protein']!,
          lemak: macros['lemak']!,
          karbo: macros['karbo']!,
          cairan: macros['cairan']!,
        );

       if (isMale) {
          _maleResult = resultObj;
        } else {
          _femaleResult = resultObj;
        }
      }
    });

    _scrollToResult();
  }

  void _resetForm() {
    setState(() {
      _formKey.currentState?.reset();
      _weightController.clear();
      _heightController.clear();
      _birthDateController.clear();
      
      _birthDate = null;
      _measurementDate = DateTime.now();
      _measureDateController.text = DateFormat('dd MMMM yyyy', 'id_ID').format(_measurementDate!);
      
      _faController.text = 'Tanpa Faktor Aktivitas';
      _fsController.text = 'Tanpa Faktor Stres';

      _maleResult = null;
      _femaleResult = null;
    });
  }

  void _scrollToResult() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_resultSectionKey.currentContext != null) {
        Scrollable.ensureVisible(
          _resultSectionKey.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  // ── Build UI ──────────────────────────────────────────────────────────────
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
                  Text(
                    _Str.sectionTitle,
                    style: TextStyle(
                      fontSize: _responsiveFont(sw, base: 20),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: sw * 0.05),

                  ResponsiveNumberField(
                    widgetKey: _Keys.birthDateField,
                    controller: _birthDateController,
                    label: _Str.birthDateLabel,
                    prefixIcon: const Icon(Icons.cake),
                    readOnly: true,
                    onTap: () => _pickDate(isBirthDate: true),
                    customValidator: (v) => (v == null || v.isEmpty) ? 'Tanggal lahir wajib diisi' : null,
                  ),
                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey: _Keys.measureDateField,
                    controller: _measureDateController,
                    label: _Str.measureDateLabel,
                    prefixIcon: const Icon(Icons.event),
                    readOnly: true,
                    onTap: () => _pickDate(isBirthDate: false),
                    customValidator: (v) => (v == null || v.isEmpty) ? 'Tanggal pemeriksaan wajib diisi' : null,
                  ),
                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey: _Keys.weightField,
                    controller: _weightController,
                    label: _Str.weightLabel,
                    prefixIcon: const Icon(Icons.monitor_weight),
                    suffixText: _Str.weightUnit,
                    semanticLabel: 'Input Berat Badan',
                  ),
                  SizedBox(height: sw * 0.04),

                  ResponsiveNumberField(
                    widgetKey: _Keys.heightField,
                    controller: _heightController,
                    label: _Str.heightLabel,
                    prefixIcon: const Icon(Icons.height),
                    suffixText: _Str.heightUnit,
                    semanticLabel: 'Input Tinggi Badan',
                  ),
                  SizedBox(height: sw * 0.04),

                  // Dropdown Faktor Aktivitas menggunakan DropdownSearch
                  _buildDropdown(
                    widgetKey: _Keys.faDropdown,
                    controller: _faController,
                    label: 'Faktor Aktivitas (FA)',
                    prefixIcon: const Icon(Icons.directions_run),
                    items: SchofieldCalculatorService.activityFactors.keys.toList(),
                    itemAsString: (String key) => '$key (${SchofieldCalculatorService.activityFactors[key]})',
                  ),
                  SizedBox(height: sw * 0.04),

                  // Dropdown Faktor Stres menggunakan DropdownSearch
                  _buildDropdown(
                    widgetKey: _Keys.fsDropdown,
                    controller: _fsController,
                    label: 'Faktor Stres (FS)',
                    prefixIcon: const Icon(Icons.local_hospital),
                    items: SchofieldCalculatorService.stressFactors.keys.toList(),
                    itemAsString: (String key) => '$key (${SchofieldCalculatorService.stressFactors[key]})',
                  ),

                  SizedBox(height: sw * 0.08),

                  FormActionButtons(
                    key: _Keys.btnReset,
                    onReset: _resetForm,
                    onSubmit: _calculateAll,
                    resetButtonColor: Colors.white,
                    resetForegroundColor: _kBrandGreen,
                    submitIcon: const Icon(Icons.calculate, color: Colors.white),
                  ),

                  SizedBox(height: sw * 0.08),

                  // ── Results Section ────────────────────────────────────
                  if (_maleResult != null && _femaleResult != null) ...[
                    SizedBox(key: _resultSectionKey, height: 0),
                    const Divider(),
                    SizedBox(height: sw * 0.04),

                    _buildGenderResultCard(
                      title: 'ANAK LAKI-LAKI',
                      icon: Icons.boy,
                      color: _kMaleColor,
                      result: _maleResult!,
                    ),
                    SizedBox(height: sw * 0.04),

                    _buildGenderResultCard(
                      title: 'ANAK PEREMPUAN',
                      icon: Icons.girl,
                      color: _kFemaleColor,
                      result: _femaleResult!,
                    ),
                    SizedBox(height: sw * 0.08),
                    const Divider(thickness: 2),
                    SizedBox(height: sw * 0.04),
                    Text(
                      'Referensi Formula',
                      style: TextStyle(
                        fontSize: _responsiveFont(sw, base: 18),
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                    ),
                    SizedBox(height: sw * 0.04),
                    
                    // Menampilkan formula terkait anak (menyaring formula dewasa)
                    ...ReferenceData.formulas
                        .where((formula) => formula.id.contains('_anak'))
                        .map((formula) => FormulaTile(
                              key: ValueKey('cqc_${formula.id}'),
                              semanticId: 'cqc_${formula.id}',
                              title: formula.title,
                              formulaName: formula.formulaName,
                              formulaContent: formula.formulaContent,
                              note: formula.note,
                            )),
                            
                    SizedBox(height: sw * 0.08),
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

  Widget _buildDropdown({
    required ValueKey<String> widgetKey,
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required List<String> items,
    void Function(String?)? onChanged,
    String Function(String)? itemAsString,
    double? menuHeight,
  }) {
    return DropdownSearch<String>(
      key: widgetKey,
      popupProps: PopupProps.menu(
        showSearchBox: false,
        constraints: BoxConstraints(maxHeight: menuHeight ?? 250), 
      ),
      items: items,
      itemAsString: itemAsString,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
          filled: false,
        ),
      ),
      onChanged: onChanged ?? (val) => setState(() => controller.text = val ?? ''),
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (v) => (v == null || v.isEmpty) ? '$label harus dipilih' : null,
    );
  }

  Widget _buildGenderResultCard({
    required String title,
    required IconData icon,
    required Color color,
    required _ChildGenderCalcResult result,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.05),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Usia: ${result.ageFormatted}',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.blueGrey[700]),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Energi & Makronutrien
                const SizedBox(height: 8),
                _buildResultRow('BMR (Schofield)', '${result.bmrSchofield.toStringAsFixed(0)} kkal/hari'),
                const Divider(height: 8),
                _buildResultRow('Total Energi (TDEE)', '${result.tdee.toStringAsFixed(0)} kkal/hari', isHighlight: true, color: color),
                const Divider(height: 8),
                _buildResultRow('Protein', '${result.protein.toStringAsFixed(0)} g/hari'),
                const Divider(height: 8),
                _buildResultRow('Lemak', '${result.lemak.toStringAsFixed(0)} g/hari'),
                const Divider(height: 8),
                _buildResultRow('Karbohidrat', '${result.karbo.toStringAsFixed(0)} g/hari'),
                const Divider(height: 8),
                _buildResultRow('Kebutuhan Cairan', '${result.cairan.toStringAsFixed(0)} ml/hari', isHighlight: true, color: Colors.lightBlue),
                const Divider(height: 16, thickness: 2),

                // Indikator Gizi
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Indikator Status Gizi:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ),
                const SizedBox(height: 8),
                _buildResultRow('Berat Badan Ideal', '${result.bbi.toStringAsFixed(1)} kg'),
                const Divider(height: 8),

                if (result.status0to60 != null) ...[
                  _buildResultRow('IMT/U (Z-Score)', '${result.status0to60!.bmiForAge.zScore?.toStringAsFixed(2) ?? '-'} (${result.status0to60!.bmiForAge.category})',
                      customValueColor: _NutritionColorResolver.resolve('IMT/U', result.status0to60!.bmiForAge.category)),
                  const Divider(height: 8),
                  _buildResultRow('BB/U (Z-Score)', '${result.status0to60!.weightForAge.zScore?.toStringAsFixed(2) ?? '-'} (${result.status0to60!.weightForAge.category})',
                      customValueColor: _NutritionColorResolver.resolve('BB/U', result.status0to60!.weightForAge.category)),
                  const Divider(height: 8),
                  _buildResultRow('TB/U (Z-Score)', '${result.status0to60!.heightForAge.zScore?.toStringAsFixed(2) ?? '-'} (${result.status0to60!.heightForAge.category})',
                      customValueColor: _NutritionColorResolver.resolve('TB/U', result.status0to60!.heightForAge.category)),
                  const Divider(height: 8),
                  _buildResultRow('BB/TB (Z-Score)', '${result.status0to60!.weightForHeight.zScore?.toStringAsFixed(2) ?? '-'} (${result.status0to60!.weightForHeight.category})',
                      customValueColor: _NutritionColorResolver.resolve('BB/TB', result.status0to60!.weightForHeight.category)),
                  const Divider(height: 8),
                ] else if (result.imtu5to18 != null) ...[
                  _buildResultRow('IMT', '${result.imtu5to18!.bmi.toStringAsFixed(2)} kg/m²'),
                  const Divider(height: 8),
                  _buildResultRow('IMT/U 5-18 Thn', '${result.imtu5to18!.zScore?.toStringAsFixed(2) ?? '-'} (${result.imtu5to18!.category})',
                      customValueColor: _NutritionColorResolver.resolve('IMT/U', result.imtu5to18!.category)),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(
    String label,
    String value, {
    bool isHighlight = false,
    Color? color,
    Color? customValueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight ? (color ?? Colors.black87) : Colors.black54,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
              color: customValueColor ?? (isHighlight ? (color ?? Colors.black87) : Colors.black87),
            ),
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