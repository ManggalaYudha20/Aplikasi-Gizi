import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/diabetes_calculator_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/services.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/patient_picker_widget.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/diabetes_meal_planner_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/pdf_generator_dm.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_search_delegate.dart';

class DiabetesCalculationPage extends StatefulWidget {
  final String userRole;

  const DiabetesCalculationPage({super.key, required this.userRole});

  @override
  State<DiabetesCalculationPage> createState() =>
      _DiabetesCalculationPageState();
}

class _DiabetesCalculationPageState extends State<DiabetesCalculationPage> {
  final _formKey = GlobalKey<FormState>();
  final _calculatorService = DiabetesCalculatorService();
  final GlobalKey<PatientPickerWidgetState> _patientPickerKey = GlobalKey();
  final _notesController = TextEditingController();

  // Form controllers
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();
  final _genderController = TextEditingController();
  final _activityController = TextEditingController();
  //final _bloodSugarController = TextEditingController();
  //final _bloodPressureController = TextEditingController();
  final _hospitalizedStatusController = TextEditingController();
  final _foodDbService = FoodDatabaseService();
  late final _mealPlannerService = DiabetesMealPlannerService(_foodDbService);
  List<DmMealSession>? _dailyMenu;
  bool _isGeneratingMenu = false;

  // Form fields
  //List<GeneratedMeal>? _generatedMenu;
  //bool _isGeneratingMenu = false;
  double _stressMetabolic = 20.0;

  // Calculation results
  DiabetesCalculationResult? _result;

  final List<String> _genders = ['Laki-laki', 'Perempuan'];
  final List<String> _activityLevels = [
    'Bed rest',
    'Ringan',
    'Sedang',
    'Berat',
  ];
  //final List<String> _bloodSugarOptions = ['Terkendali', 'Tidak terkendali'];
  //final List<String> _bloodPressureOptions = ['Normal', 'Tinggi'];

  @override
  void dispose() {
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _scrollController.dispose();
    _genderController.dispose();
    _activityController.dispose();
    //_bloodSugarController.dispose();
    //_bloodPressureController.dispose();
    _hospitalizedStatusController.dispose();
    _notesController.dispose();
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

  // TAMBAHAN: Fungsi callback saat pasien dipilih
  void _fillDataFromPatient(
    double weight,
    double height,
    String gender,
    DateTime dob,
  ) {
    setState(() {
      _weightController.text = weight.toString();
      _heightController.text = height.toString();
      _ageController.text = _calculateAgeInYears(dob);

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

      // Reset hasil sebelumnya jika ada data baru masuk
      _result = null;
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

  void _calculateDiabetesNutrition() {
    if (_formKey.currentState!.validate()) {
      final result = _calculatorService.calculate(
        age: int.parse(_ageController.text),
        weight: double.parse(_weightController.text),
        height: double.parse(_heightController.text),
        gender: _genderController.text, // Perbaikan
        activity: _activityController.text, // Perbaikan
        hospitalizedStatus: _hospitalizedStatusController.text, // Perbaikan
        stressMetabolic: _stressMetabolic,
        //bloodSugar: _bloodSugarController.text, // Perbaikan
        //bloodPressure: _bloodPressureController.text,
      );

      setState(() {
        _result = result;
        _isGeneratingMenu = true; // Mulai loading
        _dailyMenu = null;
      });

      // Generate menu baru
      _mealPlannerService.generateDailyPlan(result.dailyMealDistribution).then((
        menu,
      ) {
        setState(() {
          _dailyMenu = menu;
          _isGeneratingMenu = false; // Set loading false
        });
      });

      _scrollToResult();
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _ageController.clear();
    _weightController.clear();
    _heightController.clear();
    _patientPickerKey.currentState?.resetSelection();
    setState(() {
      _genderController.clear();
      _activityController.clear();
      //_bloodSugarController.clear();
      //_bloodPressureController.clear();
      _hospitalizedStatusController.clear();
      _stressMetabolic = 20.0;
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Diet Diabetes Melitus',
        subtitle: 'Kalkulator Kebutuhan Energi',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
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
                    'Input Data Diabetes Melitus',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Input Usia
                  _buildTextFormField(
                    controller: _ageController,
                    label: 'Usia',
                    prefixIcon: const Icon(Icons.calendar_today),
                    suffixText: 'tahun',
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Masukkan usia';
                      final age = int.tryParse(value);
                      if (age == null || age < 1 || age > 120) return 'Masukkan usia yang valid (1-120 tahun)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Jenis Kelamin
                  _buildCustomDropdown(
                    controller: _genderController,
                    label: 'Jenis Kelamin',
                    prefixIcon: const Icon(Icons.wc),
                    items: _genders,
                  ),
                  const SizedBox(height: 16),

                  // Input Berat Badan
                  _buildTextFormField(
                    controller: _weightController,
                    label: 'Berat Badan',
                    prefixIcon: const Icon(Icons.monitor_weight),
                    suffixText: 'kg',
                    validator: (value) {
                      if (value == null || value.isEmpty)return 'Masukkan berat badan';
                      final weight = double.tryParse(value);
                      if (weight == null || weight < 1 || weight > 300)return 'Masukkan berat badan yang valid (1-300 kg)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Input Tinggi Badan
                  _buildTextFormField(
                    controller: _heightController,
                    label: 'Tinggi Badan',
                    prefixIcon: const Icon(Icons.height),
                    suffixText: 'cm',
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Masukkan tinggi badan';
                      final height = double.tryParse(value);
                      if (height == null || height < 30 || height > 300) return 'Masukkan tinggi badan yang valid (30-300 cm)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Faktor Aktivitas
                  _buildCustomDropdown(
                    controller: _activityController,
                    label: 'Faktor Aktivitas',
                    prefixIcon: const Icon(Icons.directions_run),
                    items: _activityLevels,
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Gula Darah
                 /* _buildCustomDropdown(
                    controller: _bloodSugarController,
                    label: 'Gula Darah',
                    prefixIcon: const Icon(Icons.bloodtype),
                    items: _bloodSugarOptions,
                  ),
                  const SizedBox(height: 16),

                  // Dropdown Tekanan Darah
                  _buildCustomDropdown(
                    controller: _bloodPressureController,
                    label: 'Tekanan Darah',
                    prefixIcon: const Icon(Icons.monitor_heart),
                    items: _bloodPressureOptions,
                  ),
                  const SizedBox(height: 16),*/

                  _buildCustomDropdown(
                    controller: _hospitalizedStatusController,
                    label: 'Status Rawat Inap',
                    prefixIcon: const Icon(Icons.bed),
                    items: ['Ya', 'Tidak'],
                    onChanged: (value) {
                      setState(() {
                        _hospitalizedStatusController.text = value ?? '';
                        if (value == 'Tidak') _stressMetabolic = 20.0;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // This conditional logic now reads from the controller
                  if (_hospitalizedStatusController.text == 'Ya') ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stress Metabolik: ${_stressMetabolic.round()}%',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Slider(
                          value: _stressMetabolic,
                          min: 10,
                          max: 40,
                          divisions: 30,
                          label: '${_stressMetabolic.round()}%',
                          onChanged: (value) =>
                              setState(() => _stressMetabolic = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 24),
                  FormActionButtons(
                    onReset: _resetForm,
                    onSubmit: _calculateDiabetesNutrition,
                    resetButtonColor: Colors.white, // Background jadi putih
                    resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
                    submitIcon: const Icon(
                      Icons.calculate,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (_result != null) ...[
                    Container(
                      key: _resultCardKey,
                      child: const Column(
                        children: [Divider(), SizedBox(height: 32)],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          0,
                          148,
                          68,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color.fromARGB(255, 0, 148, 68),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Hasil Total Kebutuhan Energi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 148, 68),
                              ),
                            ),
                          ),
                          const Divider(height: 24),
                          const SizedBox(height: 8),
                          _buildNutritionRow(
                            'BB Ideal',
                            '${_result!.bbIdeal.round()} kg',
                          ),
                          _buildNutritionRow(
                            'BMR',
                            '${_result!.bmr.round()} kkal/hari',
                          ),
                          _buildNutritionRow(
                            'Kategori IMT',
                            _result!.bmiCategory,
                          ),
                          _buildNutritionRow(
                            'Koreksi Aktivitas',
                            '+${_result!.activityCorrection.round()} kkal/hari',
                          ),
                          if (_result!.ageCorrection > 0)
                            _buildNutritionRow(
                              'Koreksi Usia',
                              '-${_result!.ageCorrection.round()} kkal/hari',
                            ),
                          if (_result!.weightCorrection != 0)
                            _buildNutritionRow(
                              'Koreksi Berat Badan',
                              '${_result!.weightCorrection > 0 ? '+' : ''}${_result!.weightCorrection.round()} kkal/hari',
                            ),
                          if (_hospitalizedStatusController.text == 'Ya')
                            _buildNutritionRow(
                              'Koreksi Stress Metabolik',
                              '+${((_stressMetabolic / 100) * _result!.bmr).round()} kkal/hari',
                            ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Total Kalori: ${_result!.totalCalories.round()} kkal/hari',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Total kebutuhan energi digunakan untuk mengetahui jenis diet Diabetes Melitus',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // CONTAINER BARU UNTUK JENIS DIET
                    ExpansionTile(
                      title: Text('Jenis ${_result!.dietInfo.name}'),
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'Jenis ${_result!.dietInfo.name}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              const Divider(height: 24),
                              _buildNutritionRow(
                                'Protein',
                                '${_result!.dietInfo.protein} g',
                              ),
                              _buildNutritionRow(
                                'Lemak',
                                '${_result!.dietInfo.fat} g',
                              ),
                              _buildNutritionRow(
                                'Karbohidrat',
                                '${_result!.dietInfo.carbohydrate} g',
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                'Jenis Diet Diabetes Melitus menurut kandungan energi, protein, lemak, dan karbohidrat',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // CONTAINER BARU UNTUK STANDAR DIET GOLONGAN BAHAN MAKANAN
                    ExpansionTile(
                      title: Text(
                        'Standar Diet (${_result!.foodGroupDiet.calorieLevel})',
                      ),
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.purple.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'Standar Diet (${_result!.foodGroupDiet.calorieLevel})',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple,
                                  ),
                                ),
                              ),
                              const Divider(height: 24),
                              _buildNutritionRow(
                                'Nasi atau penukar',
                                '${_formatNumber(_result!.foodGroupDiet.nasiP)} P',
                              ),
                              _buildNutritionRow(
                                'Ikan atau penukar',
                                '${_formatNumber(_result!.foodGroupDiet.ikanP)} P',
                              ),
                              _buildNutritionRow(
                                'Daging atau penukar',
                                '${_formatNumber(_result!.foodGroupDiet.dagingP)} P',
                              ),
                              _buildNutritionRow(
                                'Tempe atau penukar',
                                '${_formatNumber(_result!.foodGroupDiet.tempeP)} P',
                              ),
                              _buildNutritionRow(
                                'Sayuran/penukar A',
                                ' ${_result!.foodGroupDiet.sayuranA}',
                              ),
                              _buildNutritionRow(
                                'Sayuran/penukar B',
                                '${_formatNumber(_result!.foodGroupDiet.sayuranB)} P',
                              ),
                              _buildNutritionRow(
                                'Buah atau penukar',
                                '${_formatNumber(_result!.foodGroupDiet.buah)} P',
                              ),
                              _buildNutritionRow(
                                'Susu atau penukar',
                                '${_formatNumber(_result!.foodGroupDiet.susu)} P',
                              ),
                              _buildNutritionRow(
                                'Minyak atau penukar',
                                '${_formatNumber(_result!.foodGroupDiet.minyak)} P',
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Keterangan : (P = Penukar) (S = Sekehendak) ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Jumlah bahan makanan sehari menurut Standar Diet Diabetes Melitus (dalam satuan penukar II)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),

                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text(
                        'Pembagian Makanan\nSehari-hari (${_result!.dailyMealDistribution.calorieLevel})',
                      ),
                      children: [
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Text(
                                  'Pembagian Makanan Sehari-hari \n (${_result!.dailyMealDistribution.calorieLevel})',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              const Divider(height: 24),
                              _buildMealDistributionTable(),
                              const SizedBox(height: 8),
                              const Text(
                                'Keterangan : (P = Penukar) (S = Sekehendak) ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Pembagian makanan sehari tiap Standar Diet Diabetes Melitus dan Nilai Gizi (dalam satuan penukar II)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),

                    const SizedBox(height: 16),
                    
                    _buildDailyMenuSection(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

 Widget _buildDailyMenuSection() {

  final String currentRole = widget.userRole.toLowerCase();

    // Daftar role yang diperbolehkan mengakses fitur ini
    // Catatan: Saya sertakan 'nutrisionis' juga jaga-jaga jika di database Anda
    // menggunakan istilah tersebut selain 'ahli gizi'.
    bool isAllowed = currentRole == 'admin' || 
                     currentRole == 'ahli_gizi' || 
                     currentRole == 'nutrisionis';

    // Jika role TIDAK diizinkan (misal: 'tamu'), kembalikan widget kosong (hilang)
    if (!isAllowed) {
      return const SizedBox.shrink();
    }

    // 3. Widget Utama (ExpansionTile -> Container -> Isi Menu Biru)
    return ExpansionTile(
      title: const Text(
        'Rekomendasi Menu Sehari',
      ),
      children: [
        const SizedBox(height: 10),

        if (_isGeneratingMenu)
          Container(
            height: 150, // Beri tinggi agar loading terlihat jelas di tengah
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Sedang membuat menu...", style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        
        // KONDISI 2: DATA ADA (Tampilkan Container Biru)
        else if (_dailyMenu != null && _dailyMenu!.isNotEmpty)
        
        // Container Pembungkus (Style dirapikan, warna disesuaikan dengan tema Biru konten Anda)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1), // Background Biru Transparan
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade300), // Border Biru
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Judul (Warna Tetap Biru)
              const Center(
                child: Text(
                  'Rekomendasi Menu Sehari',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue, // Tetap Biru
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ketuk ikon pensil untuk mengganti menu',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Loop Sesi Makan
              ..._dailyMenu!.map((session) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      // Header Waktu Makan (Warna Tetap Biru Muda)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100, // Tetap Biru Muda
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                        ),
                        child: Text(
                          session.sessionName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900, // Tetap Biru Tua
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      // List Makanan
                      ...session.items.map((item) {
                        // Logika Tampilan Porsi
                        String portionText;
                        if (item.portion == 'S') {
                          portionText = "(S)";
                        } else {
                          String val = item.portion is num
                              ? _formatNumber(item.portion)
                              : item.portion.toString();
                          portionText = "($val P)";
                        }

                        return ListTile(
                          dense: true,
                          title: Text(
                            item.categoryLabel,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          subtitle: Text(
                            "${item.foodName} $portionText",
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 20,
                              color: Colors.grey, // Icon Edit tetap Orange sesuai request
                            ),
                            onPressed: () => _showEditDialog(item),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              const Divider(),
              const Text(
                "Catatan Tambahan (Opsional)",
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3, // Agar bisa input panjang
                decoration: InputDecoration(
                  hintText: "Tulis anjuran khusus atau catatan untuk pasien disini...",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.blue.shade200),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                ),
              ),

              // Tombol Download PDF (Warna Tetap Biru)
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download),
                label: const Text(
                  "Download Menu PDF",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Tetap Biru
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  // --- LOGIKA EDIT MAKANAN ---
  void _showEditDialog(DmMenuItem item) async {
    // Membuka halaman pencarian
    // Tipe generic <FoodItem?> ditambahkan agar sesuai dengan delegate
    final FoodItem? selectedFood = await showSearch<FoodItem?>(
      context: context,
      delegate: FoodSearchDelegate(_foodDbService,initialQuery: item.foodName,),
    );

    if (selectedFood != null) {
      setState(() {
        // Update item menu dengan data baru
        item.foodName = selectedFood.name;
        item.foodData = selectedFood;
      });
    }
  }

  // --- LOGIKA DOWNLOAD PDF ---
  // Di dalam class DiabetesCalculationPage (atau state-nya)

  void _downloadPdf() async {
    // Validasi data kosong
    if (_dailyMenu == null || _dailyMenu!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Menu belum tersedia.')));
      return;
    }

    // Tampilkan Loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // PANGGIL FUNGSI YANG BARU KITA BUAT DI SERVICE
      // Ganti "Pasien" dengan variabel nama pasien yang sesuai di kode Anda (misal: _selectedPatient?.name ?? "Pasien")
      await saveAndOpenDmPdf(_dailyMenu!, "Pasien",_notesController.text,);

      // Tutup loading dialog jika sukses
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Opsional: Tampilkan pesan sukses kecil jika file berhasil terbuka (biasanya tidak perlu karena file langsung terbuka)
      // ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF berhasil dibuka'), backgroundColor: Colors.green));
    } catch (e) {
      // Tutup loading dialog jika error
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Tampilkan pesan error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Widget untuk Input Teks
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required Icon prefixIcon,
    required String suffixText,
    required String? Function(String?) validator,
    int maxLength = 5,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        // Batasi panjang karakter agar tidak overflow/error database
        LengthLimitingTextInputFormatter(maxLength),
        // Opsional: Filter agar hanya angka dan titik (untuk desimal) yang bisa diketik
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: prefixIcon,
        suffixText: suffixText,
        //counterText: "",
      ),
      validator: validator,
    );
  }

  // Widget untuk Dropdown
  Widget _buildCustomDropdown({
    required TextEditingController controller,
    required String label,
    required List<String> items,
    required Icon prefixIcon,
    bool showSearch = false,
    void Function(String?)? onChanged,
  }) {
    return DropdownSearch<String>(
      popupProps: PopupProps.menu(
        showSearchBox: showSearch,
        fit: FlexFit.loose,
        constraints: const BoxConstraints(maxHeight: 240),
      ),
      items: items,
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: prefixIcon,
        ),
      ),
      onChanged:
          onChanged ??
          (String? newValue) {
            setState(() {
              controller.text = newValue ?? '';
            });
          },
      selectedItem: controller.text.isEmpty ? null : controller.text,
      validator: (value) =>
          (value == null || value.isEmpty) ? '$label harus dipilih' : null,
    );
  }

  // Widget helper untuk baris nutrisi di kartu diet
  Widget _buildNutritionRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor ?? const Color.fromARGB(255, 0, 0, 0),
            ),
          ),
        ],
      ),
    );
  }

  // GANTI FUNGSI LAMA DENGAN VERSI BARU INI

  Widget _buildMealDistributionTable() {
    final distribution = _result!.dailyMealDistribution;
    const headerStyle = TextStyle(fontWeight: FontWeight.bold, fontSize: 12);
    const cellStyle = TextStyle(fontSize: 12);
    const cellPadding = EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0);

    // Helper untuk membuat grup baris (misal: semua baris untuk 'Pagi')
    Widget buildMealRowGroup(
      String mealName,
      MealDistribution meal, {
      required Color color,
    }) {
      final List<Widget> foodRows = [];

      // Fungsi kecil untuk membuat baris makanan (Bahan Makanan + Penukar)
      void addFoodRow(String foodName, dynamic value) {
        foodRows.add(
          Container(
            padding: cellPadding,
            decoration: BoxDecoration(
              color: color,
              border: Border(
                top: BorderSide(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(foodName, style: cellStyle),
                ), // Kolom Bahan Makanan
                Expanded(
                  flex: 2,
                  child: Text(
                    // Kolom Penukar
                    value is String
                        ? value
                        : '${_formatNumber(value as double)} P',
                    textAlign: TextAlign.center,
                    style: cellStyle,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      // Tambahkan baris untuk setiap bahan makanan JIKA nilainya ada
      if (meal.nasiP > 0) addFoodRow('Nasi', meal.nasiP);
      if (meal.ikanP > 0) addFoodRow('Ikan', meal.ikanP);
      if (meal.dagingP > 0) addFoodRow('Daging', meal.dagingP);
      if (meal.tempeP > 0) addFoodRow('Tempe', meal.tempeP);
      if (meal.sayuranA.isNotEmpty) addFoodRow('Sayuran A', meal.sayuranA);
      if (meal.sayuranB > 0) addFoodRow('Sayuran B', meal.sayuranB);
      if (meal.buah > 0) addFoodRow('Buah', meal.buah);
      if (meal.susu > 0) addFoodRow('Susu', meal.susu);
      if (meal.minyak > 0) addFoodRow('Minyak', meal.minyak);

      if (foodRows.isEmpty) {
        return const SizedBox.shrink(); // Jangan tampilkan apa-apa jika tidak ada makanan
      }

      // Bungkus dengan IntrinsicHeight agar sel "Waktu" bisa setinggi daftar makanan
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kolom 1: Waktu (Sel yang di-merge)
            Container(
              width: 80, // Atur lebar kolom waktu secara manual
              padding: cellPadding,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color,
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
              child: Text(
                mealName,
                textAlign: TextAlign.center,
                style: cellStyle,
              ),
            ),
            // Kolom 2: Daftar Bahan Makanan & Penukar
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: foodRows,
              ),
            ),
          ],
        ),
      );
    }

    // Bangun Tampilan Akhir
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 1),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: cellPadding,
            color: Colors.green.shade100,
            child: Row(
              children: [
                const SizedBox(
                  width: 80,
                  child: Text(
                    'Waktu',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Bahan Makanan',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Penukar',
                    style: headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          // Isi Tabel
          buildMealRowGroup('Pagi', distribution.pagi, color: Colors.white),
          buildMealRowGroup(
            'Pukul 10.00',
            distribution.snackPagi,
            color: Colors.grey.shade100,
          ),
          buildMealRowGroup('Siang', distribution.siang, color: Colors.white),
          buildMealRowGroup(
            'Pukul 16.00',
            distribution.snackSore,
            color: Colors.grey.shade100,
          ),
          buildMealRowGroup('Malam', distribution.malam, color: Colors.white),
        ],
      ),
    );
  }

  // Helper function to format numbers conditionally
  String _formatNumber(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    } else {
      return value.toStringAsFixed(1);
    }
  }
}
