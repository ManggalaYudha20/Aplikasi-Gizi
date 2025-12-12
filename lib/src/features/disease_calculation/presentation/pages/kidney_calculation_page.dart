// lib/src/features/disease_calculation/presentation/pages/kidney_calculation_page.dart

import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:flutter/material.dart';

// Import file planner dengan alias 'planner'
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_meal_planner_service.dart'
    as planner;

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';

// Import Service & Model Baru
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_menu_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_dynamic_menu_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_search_delegate.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/kidney_dynamic_menu_section.dart';

// Import file database dengan alias 'db'
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart'
    as db;

class KidneyCalculationPage extends StatefulWidget {
  final String userRole;

  const KidneyCalculationPage({super.key, required this.userRole});

  @override
  State<KidneyCalculationPage> createState() => _KidneyCalculationPageState();
}

class _KidneyCalculationPageState extends State<KidneyCalculationPage> {
  final _formKey = GlobalKey<FormState>();
  final _calculatorService = KidneyCalculatorService();

  // Menggunakan 'planner.FoodItem' untuk data rencana statis
  List<planner.FoodItem>? _mealPlan;

  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();

  // Controllers
  final _heightController = TextEditingController();
  final _ageController = TextEditingController();
  final _scrollController = ScrollController();
  final _resultCardKey = GlobalKey();
  final _dialysisController = TextEditingController();
  final _genderController = TextEditingController();
  final _proteinFactorController = TextEditingController(text: '0.6 (Rendah)');
  final _currentWeightController = TextEditingController();
  bool _isHighPotassium = false;

  KidneyDietResult? _result;
  late KidneyDynamicMenuService _menuGenerator;

  // State untuk Menu Dinamis Baru
  List<KidneyMealSession>? _generatedMenu;
  bool _isGeneratingMenu =
      false; // Loading KHUSUS untuk menu, tidak memblokir UI utama

  @override
  void initState() {
    super.initState();
    _menuGenerator = KidneyDynamicMenuService(FoodDatabaseService());
  }

  void _calculateAndGenerateMenu() async {
    if (_formKey.currentState!.validate()) {
      // 1. Ambil data (Synchronous)
      final height = double.tryParse(_heightController.text) ?? 0;
      final age = int.tryParse(_ageController.text) ?? 0;
      final isDialysis = _dialysisController.text == 'Ya';
      final gender = _genderController.text;
      final proteinFactorString = _proteinFactorController.text.split(' ')[0];
      final proteinFactor = double.tryParse(proteinFactorString);

      // 2. Hitung Hasil Utama (Synchronous - Sangat Cepat)
      final result = _calculatorService.calculate(
        height: height,
        isDialysis: isDialysis,
        gender: gender,
        proteinFactor: isDialysis ? null : proteinFactor,
        age: age,
      );

      // 3. Ambil Rencana Bahan Mentah (Synchronous - Cepat)
      final mealPlan = planner.KidneyMealPlans.getPlan(result.recommendedDiet);

      // 4. UPDATE STATE PERTAMA: Tampilkan Hasil Hitungan SEGERA
      // Ini membuat UI langsung muncul tanpa delay
      setState(() {
        _result = result;
        _mealPlan = mealPlan;
        _generatedMenu = null; // Reset menu lama
        _isGeneratingMenu =
            true; // Tandai menu sedang diproses (loading di dalam expansion tile)
      });

      _scrollToResult();

      // 5. Generate Menu (Asynchronous - Lambat/Butuh Waktu)
      // Proses ini berjalan di background sementara user sudah melihat hasil hitungan
      try {
        int targetProtein = result.recommendedDiet;

        // UPDATE DISINI: Tambahkan parameter isHighPotassium
        final dynamicMenu = await _menuGenerator.generateDailyMenu(
          targetProtein,
          isHighPotassium: _isHighPotassium, // Ambil dari state checkbox
        );

        if (mounted) {
          setState(() {
            _generatedMenu = dynamicMenu;
            _isGeneratingMenu = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isGeneratingMenu = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal membuat menu otomatis: $e')),
          );
        }
      }
    }
  }

  // Fungsi Edit Menu
  Future<void> _editMenuItem(
    KidneyMenuItem item,
    int sessionIndex,
    int itemIndex,
  ) async {
    final db.FoodItem? selectedFood = await showSearch<db.FoodItem?>(
      context: context,
      delegate: FoodSearchDelegate(
        FoodDatabaseService(),
        initialQuery: item.foodName,
      ),
    );

    if (selectedFood != null && _generatedMenu != null) {
      setState(() {
        final oldItem = _generatedMenu![sessionIndex].items[itemIndex];

        _generatedMenu![sessionIndex].items[itemIndex] = KidneyMenuItem(
          categoryLabel: oldItem.categoryLabel,
          foodName: selectedFood.name,
          weight: oldItem.weight,
          urt: oldItem.urt,
          foodData: selectedFood,
        );
      });
    }
  }

  @override
  void dispose() {
    _heightController.dispose();
    _ageController.dispose();
    _scrollController.dispose();
    _dialysisController.dispose();
    _genderController.dispose();
    _proteinFactorController.dispose();
    _currentWeightController.dispose();
    super.dispose();
  }

  String _calculateAgeInYears(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age.toString();
  }

  void _fillDataFromPatient(
    double weight,
    double height,
    String gender,
    DateTime dob,
  ) {
    setState(() {
      _heightController.text = height.toString();
      _ageController.text = _calculateAgeInYears(dob);
      _currentWeightController.text = weight.toString();
      _isHighPotassium = false;

      String incomingGender = gender.toLowerCase();
      String normalizedGender = '';

      if (incomingGender.contains('laki') ||
          incomingGender.contains('pria') ||
          incomingGender == 'l') {
        normalizedGender = 'Laki-laki';
      } else if (incomingGender.contains('perempuan') ||
          incomingGender.contains('wanita') ||
          incomingGender == 'p') {
        normalizedGender = 'Perempuan';
      } else {
        normalizedGender = gender;
      }
      _genderController.text = normalizedGender;

      _result = null;
      _mealPlan = null;
      _generatedMenu = null;
    });
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _heightController.clear();
    _ageController.clear();
    _patientPickerKey.currentState?.resetSelection();
    _currentWeightController.clear();
    setState(() {
      _dialysisController.clear();
      _genderController.clear();
      _proteinFactorController.text = '0.6 (Rendah)';
      _result = null;
      _mealPlan = null;
      _generatedMenu = null;
      _isHighPotassium = false;
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Diet Ginjal Kronis',
        subtitle: 'Kalkulator Kebutuhan Protein',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PatientPickerWidget(
                    key: _patientPickerKey,
                    onPatientSelected: _fillDataFromPatient,
                    userRole: widget.userRole,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Input Data Pasien Ginjal',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // --- INPUT FIELDS ---
                  _buildCustomDropdown<String>(
                    controller: _dialysisController,
                    label: 'Apakah Pasien menjalani cuci darah?',
                    prefixIcon: const Icon(Icons.bloodtype_outlined),
                    items: ['Ya', 'Tidak'],
                    itemAsString: (item) => item,
                    onChanged: (value) =>
                        setState(() => _dialysisController.text = value ?? ''),
                  ),
                  const SizedBox(height: 16),

                  if (_dialysisController.text == 'Tidak')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildCustomDropdown<String>(
                        controller: _proteinFactorController,
                        label: 'Faktor Kebutuhan Protein',
                        prefixIcon: const Icon(Icons.rule),
                        items: ['0.6 (Rendah)', '0.7 (Sedang)', '0.8 (Tinggi)'],
                        itemAsString: (item) => item,
                        onChanged: (value) => setState(
                          () => _proteinFactorController.text =
                              value ?? '0.6 (Rendah)',
                        ),
                      ),
                    ),

                  _buildCustomDropdown<String>(
                    controller: _genderController,
                    label: 'Jenis Kelamin',
                    prefixIcon: const Icon(Icons.person),
                    items: ['Laki-laki', 'Perempuan'],
                    itemAsString: (item) => item,
                    onChanged: (value) =>
                        setState(() => _genderController.text = value ?? ''),
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _heightController,
                    label: 'Tinggi Badan',
                    prefixIcon: const Icon(Icons.height),
                    suffixText: 'cm',
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _currentWeightController,
                    label: 'Berat Badan Aktual',
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    suffixText: 'kg',
                  ),
                  const SizedBox(height: 16),

                  _buildTextFormField(
                    controller: _ageController,
                    label: 'Usia',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixText: 'tahun',
                  ),

                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text("Kondisi Kalium Tinggi (Hiperkalemia)?"),
                    subtitle: const Text(
                      "Aktifkan untuk menyaring pisang, bayam, alpukat, dll.",
                    ),
                    value: _isHighPotassium,
                    activeThumbColor: const Color.fromARGB(255, 0, 148, 68),
                    onChanged: (bool value) {
                      setState(() {
                        _isHighPotassium = value;
                      });
                    },
                  ),
                  const SizedBox(height: 32),

                  FormActionButtons(
                    onReset: _resetForm,
                    onSubmit: _calculateAndGenerateMenu,
                    resetButtonColor: Colors.white,
                    resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                    submitIcon: const Icon(
                      Icons.calculate,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- TAMPILAN HASIL ---
                  // Hapus Global Loading Indicator di sini agar tidak memblokir UI
                  if (_result != null) ...[
                    const Divider(height: 32),
                    const SizedBox(height: 25),
                    _buildResultCard(),
                    const SizedBox(height: 25),

                    ExpansionTile(
                      title: Text(
                        'Asupan Gizi per Hari (Diet Protein ${_result!.recommendedDiet}g)',
                      ),
                      children: [
                        if (_result!.nutritionInfo != null)
                          _buildNutritionCard(_result!.nutritionInfo!),
                        const SizedBox(height: 10),
                      ],
                    ),

                    if (_mealPlan != null)
                      ExpansionTile(
                        title: Text('Bahan Makanan Sehari'),
                        children: [
                          const SizedBox(height: 10),
                          _buildMealPlanCard(_mealPlan!),
                          const SizedBox(height: 10),
                        ],
                      ),

                    // WIDGET EXPANSION TILE UNTUK MENU MATANG
                    // Loading hanya terjadi di dalam sini
                    ExpansionTile(
                      title: const Text("Rekomendasi Menu Sehari"),
                      // Opsional: Jika ingin otomatis terbuka saat selesai loading, bisa pakai key atau state variable
                      children: [
                        KidneyDynamicMenuSection(
                          isLoading: _isGeneratingMenu,
                          generatedMenu: _generatedMenu,
                          onEditItem: _editMenuItem,
                        ),
                        const SizedBox(height: 10),
                      ],
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

  // Helper Widgets

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    int maxLength = 5,
  }) {
    return TextFormField(
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

  Widget _buildCustomDropdown<T>({
    required TextEditingController controller,
    required String label,
    required List<T> items,
    required Icon prefixIcon,
    required String Function(T) itemAsString,
    void Function(T?)? onChanged,
  }) {
    T? selectedItem;
    try {
      selectedItem = items.firstWhere(
        (item) => itemAsString(item) == controller.text,
      );
    } catch (e) {
      selectedItem = null;
    }

    return DropdownSearch<T>(
      popupProps: const PopupProps.menu(
        showSearchBox: false,
        fit: FlexFit.loose,
      ),
      items: items,
      itemAsString: itemAsString,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged: onChanged,
      selectedItem: selectedItem,
      validator: (value) => (value == null && controller.text.isEmpty)
          ? '$label harus dipilih'
          : null,
    );
  }

  Widget _buildResultCard() {
    final proteinFactorValue = _proteinFactorController.text.split(' ')[0];
    final String recommendationText = _result!.isDialysis
        ? 'Diet Hemodialisis (HD)\nProtein ${_result!.recommendedDiet} gram'
        : 'Diet Protein Rendah ${_result!.recommendedDiet} gram';

    final String factorExplanationText = _result!.isDialysis
        ? '*Pasien hemodialisis membutuhkan asupan protein lebih tinggi (1.2 g/kg BBI).'
        : '*Pasien pre-dialisis membutuhkan asupan protein lebih rendah (${proteinFactorValue}g/kg BBI) untuk memperlambat laju penyakit.';

    final currentWeight = double.tryParse(_currentWeightController.text) ?? 0;
    final heightM =
        (double.tryParse(_heightController.text) ?? 0) / 100; // ubah ke meter

    // Hitung IMT
    String nutritionalStatus = '-';
    double imt = 0;

    if (currentWeight > 0 && heightM > 0) {
      imt = currentWeight / (heightM * heightM);

      if (imt < 18.5) {
        nutritionalStatus = 'BB Kurang';
      } else if (imt < 25) {
        nutritionalStatus = 'Normal';
      } else if (imt < 30) {
        nutritionalStatus = 'BB Lebih';
      } else {
        nutritionalStatus = 'Obesitas';
      }
    }

    return Container(
      key: _resultCardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 148, 68).withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color.fromARGB(255, 0, 148, 68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Hasil Perhitungan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 0, 148, 68),
            ),
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Berat Badan Ideal (BBI)',
            '${_result!.idealBodyWeight.toStringAsFixed(1)} kg',
          ),
          _buildInfoRow(
            'Berat Badan Aktual',
            '${currentWeight.toStringAsFixed(1)} kg',
          ),
          _buildInfoRow(
            'Indeks Massa Tubuh (IMT)',
            '${imt.toStringAsFixed(1)} ($nutritionalStatus)', // Menampilkan status gizi
          ),
          if (_result!.bmr > 0)
            _buildInfoRow(
              'BMR',
              '${_result!.bmr.toStringAsFixed(1)} kkal/hari',
            ),
          _buildInfoRow(
            'Kebutuhan Protein Harian',
            '${_result!.proteinNeeds.toStringAsFixed(1)} gram',
          ),
          const SizedBox(height: 16),
          const Text(
            'Rekomendasi Diet:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 148, 68),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              recommendationText,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            factorExplanationText,
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(KidneyDietNutrition nutritionInfo) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              'Asupan Gizi per Hari (Diet Protein ${_result!.recommendedDiet}g)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const Divider(height: 24),
          _buildInfoRow('Energi', '${nutritionInfo.energi} kkal'),
          _buildInfoRow('Protein', '${nutritionInfo.protein} g'),
          _buildInfoRow('Lemak', '${nutritionInfo.lemak} g'),
          _buildInfoRow('Karbohidrat', '${nutritionInfo.karbohidrat} g'),
          _buildInfoRow('Kalsium', '${nutritionInfo.kalsium} mg'),
          _buildInfoRow('Zat Besi', '${nutritionInfo.zatBesi} mg'),
          _buildInfoRow('Fosfor', '${nutritionInfo.fosfor} mg'),
          _buildInfoRow('Vitamin A', '${nutritionInfo.vitaminA} RE'),
          _buildInfoRow('Tiamin', '${nutritionInfo.tiamin} mg'),
          _buildInfoRow('Vitamin C', '${nutritionInfo.vitaminC} mg'),
          _buildInfoRow('Natrium', '${nutritionInfo.natrium} mg'),
          _buildInfoRow('Kalium', '${nutritionInfo.kalium} mg'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPlanCard(List<planner.FoodItem> mealPlan) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.purple.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Bahan Makanan Sehari (Diet Protein ${_result!.recommendedDiet}g)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.purple,
            ),
          ),
          const Divider(height: 24),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(2),
              2: FlexColumnWidth(3),
            },
            border: TableBorder.all(color: Colors.purple.shade100, width: 1),
            children: [
              const TableRow(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 196, 86, 216),
                ),
                children: [
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Bahan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Berat (g)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'URT',
                      style: TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              ...mealPlan.map((planner.FoodItem item) {
                return TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.name),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        item.weight.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(item.urt),
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
