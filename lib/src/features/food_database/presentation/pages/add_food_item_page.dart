//lib\src\features\food_database\presentation\pages\add_food_item_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/scaffold_with_animated_fab.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_validator_utils.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AddFoodItemPage extends StatefulWidget {
  final FoodItem? foodItem;
  const AddFoodItemPage({super.key, this.foodItem});

  @override
  State<AddFoodItemPage> createState() => _AddFoodItemPageState();
}

class _AddFoodItemPageState extends State<AddFoodItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _kodeController = TextEditingController();
  final _mentahOlahanController = TextEditingController();
  final _kelompokMakananController = TextEditingController();
  final _porsiGramController = TextEditingController();
  final _airController = TextEditingController();
  final _kaloriController = TextEditingController();
  final _proteinController = TextEditingController();
  final _lemakController = TextEditingController();
  final _karbohidratController = TextEditingController();
  final _seratController = TextEditingController();
  final _abuController = TextEditingController();
  final _kalsiumController = TextEditingController();
  final _fosforController = TextEditingController();
  final _besiController = TextEditingController();
  final _natriumController = TextEditingController();
  final _kaliumController = TextEditingController();
  final _tembagaController = TextEditingController();
  final _sengController = TextEditingController();
  final _retinolController = TextEditingController();
  final _betaKarotenController = TextEditingController();
  final _karotenTotalController = TextEditingController();
  final _thiaminController = TextEditingController();
  final _riboflavinController = TextEditingController();
  final _niasinController = TextEditingController();
  final _vitaminCController = TextEditingController();
  final _bddController = TextEditingController();
  bool _isLoading = false;
  bool get _isEditMode => widget.foodItem != null;
  final List<FocusNode> _focusNodes = [];

  @override
  void initState() {
    super.initState();

    final controllers = [
    _namaController, _kodeController, _mentahOlahanController, 
    _kelompokMakananController, _porsiGramController, _airController, 
    _kaloriController, _proteinController, _lemakController, 
    _karbohidratController, _seratController, _abuController, 
    _kalsiumController, _fosforController, _besiController, 
    _natriumController, _kaliumController, _tembagaController, 
    _sengController, _retinolController, _betaKarotenController, 
    _karotenTotalController, _thiaminController, _riboflavinController, 
    _niasinController, _vitaminCController, _bddController,
  ];

  // Buat FocusNode untuk setiap controller
  for (int i = 0; i < controllers.length; i++) {
    _focusNodes.add(FocusNode());
  }
    // Jika ini mode edit, isi semua field dengan data yang ada
    if (_isEditMode) {
      final item = widget.foodItem!;
      _namaController.text = item.name;
      _kodeController.text = item.code;
      _mentahOlahanController.text = item.mentahOlahan;
      _kelompokMakananController.text = item.kelompokMakanan;
      _porsiGramController.text = item.portionGram.toString();
      _airController.text = item.air.toString();
      _kaloriController.text = item.calories.toString();
      _proteinController.text = item.protein.toString();
      _lemakController.text = item.fat.toString();
      _karbohidratController.text = item.karbohidrat.toString();
      _seratController.text = item.fiber.toString();
      _abuController.text = item.abu.toString();
      _kalsiumController.text = item.kalsium.toString();
      _fosforController.text = item.fosfor.toString();
      _besiController.text = item.besi.toString();
      _natriumController.text = item.natrium.toString();
      _kaliumController.text = item.kalium.toString();
      _tembagaController.text = item.tembaga.toString();
      _sengController.text = item.seng.toString();
      _retinolController.text = item.retinol.toString();
      _betaKarotenController.text = item.betaKaroten.toString();
      _karotenTotalController.text = item.karotenTotal.toString();
      _thiaminController.text = item.thiamin.toString();
      _riboflavinController.text = item.riboflavin.toString();
      _niasinController.text = item.niasin.toString();
      _vitaminCController.text = item.vitaminC.toString();
      _bddController.text = item.bdd.toString();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose();
    _mentahOlahanController.dispose();
    _kelompokMakananController.dispose();
    _porsiGramController.dispose();
    _airController.dispose();
    _kaloriController.dispose();
    _proteinController.dispose();
    _lemakController.dispose();
    _karbohidratController.dispose();
    _seratController.dispose();
    _abuController.dispose();
    _kalsiumController.dispose();
    _fosforController.dispose();
    _besiController.dispose();
    _natriumController.dispose();
    _kaliumController.dispose();
    _tembagaController.dispose();
    _sengController.dispose();
    _retinolController.dispose();
    _betaKarotenController.dispose();
    _karotenTotalController.dispose();
    _thiaminController.dispose();
    _riboflavinController.dispose();
    _niasinController.dispose();
    _vitaminCController.dispose();
    _bddController.dispose();

    for (final node in _focusNodes) {
    node.dispose();
  }
    super.dispose();
  }

  Future<void> _submitFoodItem() async {
    if (FormValidatorUtils.validateAndScroll(
    context: context,
    formKey: _formKey,
    focusNodes: _focusNodes,
  )) {
    setState(() {
      _isLoading = true;
    });

      final foodData = {
        'nama': _namaController.text,
        'kode': _kodeController.text,
        'mentah_olahan': _mentahOlahanController.text,
        'kelompok_makanan': _kelompokMakananController.text,
        'porsi_gram': num.tryParse(_porsiGramController.text) ?? 0,
        'air': num.tryParse(_airController.text) ?? 0,
        'energi': num.tryParse(_kaloriController.text) ?? 0,
        'protein': num.tryParse(_proteinController.text) ?? 0,
        'lemak': num.tryParse(_lemakController.text) ?? 0,
        'karbohidrat': num.tryParse(_karbohidratController.text) ?? 0,
        'serat': num.tryParse(_seratController.text) ?? 0,
        'abu': num.tryParse(_abuController.text) ?? 0,
        'kalsium': num.tryParse(_kalsiumController.text) ?? 0,
        'fosfor': num.tryParse(_fosforController.text) ?? 0,
        'besi': num.tryParse(_besiController.text) ?? 0,
        'natrium': num.tryParse(_natriumController.text) ?? 0,
        'kalium': num.tryParse(_kaliumController.text) ?? 0,
        'tembaga': num.tryParse(_tembagaController.text) ?? 0,
        'seng': num.tryParse(_sengController.text) ?? 0,
        'retinol': num.tryParse(_retinolController.text) ?? 0,
        'beta_karoten': num.tryParse(_betaKarotenController.text) ?? 0,
        'karoten_total': num.tryParse(_karotenTotalController.text) ?? 0,
        'thiamin': num.tryParse(_thiaminController.text) ?? 0,
        'riboflavin': num.tryParse(_riboflavinController.text) ?? 0,
        'niasin': num.tryParse(_niasinController.text) ?? 0,
        'vitamin_c': num.tryParse(_vitaminCController.text) ?? 0,
        'bdd': num.tryParse(_bddController.text) ?? 0,
      };

      try {
        if (_isEditMode) {
          await FirebaseFirestore.instance
              .collection('food_items')
              .doc(widget.foodItem!.id)
              .update(foodData);
        } else {
          await FirebaseFirestore.instance
              .collection('food_items')
              .add(foodData);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Data makanan berhasil ${_isEditMode ? 'diperbarui' : 'disimpan'}!',
              ),
              backgroundColor: Colors.green,
            ),
          );
          if (_isEditMode) {
            Navigator.pop(context, true);
          } else {
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menyimpan data: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _namaController.clear();
    _kodeController.clear();
    _mentahOlahanController.clear();
    _kelompokMakananController.clear();
    _porsiGramController.clear();
    _airController.clear();
    _kaloriController.clear();
    _proteinController.clear();
    _lemakController.clear();
    _karbohidratController.clear();
    _seratController.clear();
    _abuController.clear();
    _kalsiumController.clear();
    _fosforController.clear();
    _besiController.clear();
    _natriumController.clear();
    _kaliumController.clear();
    _tembagaController.clear();
    _sengController.clear();
    _retinolController.clear();
    _betaKarotenController.clear();
    _karotenTotalController.clear();
    _thiaminController.clear();
    _riboflavinController.clear();
    _niasinController.clear();
    _vitaminCController.clear();
    _bddController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithAnimatedFab(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: _isEditMode ? 'Edit Makanan' : 'Tambah Makanan',
        subtitle: 'Isi data dengan lengkap',
      ),
      floatingActionButton: FormActionButtons(
        onReset: _resetForm,
        onSubmit: _submitFoodItem,
        resetButtonColor: Colors.white, // Background jadi putih
        resetForegroundColor: const Color.fromARGB(255, 0, 148, 68),
        submitText: _isEditMode ? 'Simpan' : 'Tambah',
        submitIcon: _isEditMode ? const Icon(Icons.save, color: Colors.white) : const Icon(Icons.add, color: Colors.white),
        isLoading: _isLoading,
      ),
      body:  SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },

        child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Input Data Makanan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildTextFormField(
                controller: _namaController,
                label: 'Nama Makanan',
                icon: Icons.restaurant,
                focusNode: _focusNodes[0],
              ),
              _buildTextFormField(
                controller: _kodeController,
                label: 'Kode Makanan',
                icon: Icons.qr_code,
                focusNode: _focusNodes[1],
              ),
              _buildSearchableDropdown(
                controller: _mentahOlahanController,
                label: 'Tunggal (Mentah) / Olahan',
                icon: Icons.category,
                items: ['Tunggal', 'Olahan'],
                focusNode: _focusNodes[2],
              ),
              _buildSearchableDropdown(
                controller: _kelompokMakananController,
                label: 'Kelompok Makanan',
                icon: Icons.group,
                items: ['Serealia', 'Umbi', 'Kacang', 'Sayur', 'Buah', 'Daging', 'Ikan dsb', 'Telur', 'Susu', 'Lemak', 'Gula', 'Bumbu'],
                focusNode: _focusNodes[3],
                //showSearch: true,
              ),
              _buildTextFormField(
                controller: _porsiGramController,
                label: 'Porsi (gram)',
                icon: Icons.scale,
                isNumber: true,
                focusNode: _focusNodes[4],
              ),
              _buildTextFormField(
                controller: _airController,
                label: 'Air (g)',
                icon: Icons.water_drop,
                isNumber: true,
                focusNode: _focusNodes[5],
              ),
              _buildTextFormField(
                controller: _kaloriController,
                label: 'Energi (Kal)',
                icon: Icons.local_fire_department,
                isNumber: true,
                focusNode: _focusNodes[6],
              ),
              _buildTextFormField(
                controller: _proteinController,
                label: 'Protein (g)',
                icon: Icons.egg,
                isNumber: true,
                focusNode: _focusNodes[7],
              ),
              _buildTextFormField(
                controller: _lemakController,
                label: 'Lemak (g)',
                icon: Icons.water,
                isNumber: true,
                focusNode: _focusNodes[8],
              ),
              _buildTextFormField(
                controller: _karbohidratController,
                label: 'Karbohidrat (g)',
                icon: Icons.rice_bowl,
                isNumber: true,
                focusNode: _focusNodes[9],
              ),
              _buildTextFormField(
                controller: _seratController,
                label: 'Serat (g)',
                icon: Icons.grass,
                isNumber: true,
                focusNode: _focusNodes[10],
              ),
              _buildTextFormField(
                controller: _abuController,
                label: 'Abu (g)',
                icon: Icons.grain,
                isNumber: true,
                focusNode: _focusNodes[11],
              ),
              _buildTextFormField(
                controller: _kalsiumController,
                label: 'Kalsium (Ca) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
                focusNode: _focusNodes[12],
              ),
              _buildTextFormField(
                controller: _fosforController,
                label: 'Fosfor (P) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
                focusNode: _focusNodes[13],
              ),
              _buildTextFormField(
                controller: _besiController,
                label: 'Besi (Fe) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
                focusNode: _focusNodes[14],
              ),
              _buildTextFormField(
                controller: _natriumController,
                label: 'Natrium (Na) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
                focusNode: _focusNodes[15],
              ),
              _buildTextFormField(
                controller: _kaliumController,
                label: 'Kalium (Ka) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
                focusNode: _focusNodes[16],
              ),
              _buildTextFormField(
                controller: _tembagaController,
                label: 'Tembaga (Cu) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
                focusNode: _focusNodes[17],
              ),
              _buildTextFormField(
                controller: _sengController,
                label: 'Seng (Zn) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
                focusNode: _focusNodes[18],
              ),
              _buildTextFormField(
                controller: _retinolController,
                label: 'Retinol (vit. A) (mcg)',
                icon: Icons.visibility,
                isNumber: true,
                focusNode: _focusNodes[19],
              ),
              _buildTextFormField(
                controller: _betaKarotenController,
                label: 'β-karoten (mcg)',
                icon: Icons.visibility,
                isNumber: true,
                focusNode: _focusNodes[20],
              ),
              _buildTextFormField(
                controller: _karotenTotalController,
                label: 'Karoten total (mcg)',
                icon: Icons.visibility,
                isNumber: true,
                focusNode: _focusNodes[21],
              ),
              _buildTextFormField(
                controller: _thiaminController,
                label: 'Thiamin (vit. B1) (mg)',
                icon: Icons.local_dining,
                isNumber: true,
                focusNode: _focusNodes[22],
              ),
              _buildTextFormField(
                controller: _riboflavinController,
                label: 'Riboflavin (vit. B2) (mg)',
                icon: Icons.local_dining,
                isNumber: true,
                focusNode: _focusNodes[23],
              ),
              _buildTextFormField(
                controller: _niasinController,
                label: 'Niasin (mg)',
                icon: Icons.local_dining,
                isNumber: true,
                focusNode: _focusNodes[24],
              ),
              _buildTextFormField(
                controller: _vitaminCController,
                label: 'Vitamin C (mg)',
                icon: Icons.medical_services,
                isNumber: true,
                focusNode: _focusNodes[25],
              ),
              _buildTextFormField(
                controller: _bddController,
                label: 'BDD (%)',
                icon: Icons.percent,
                isNumber: true,
                focusNode: _focusNodes[26],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Letakkan ini di bawah _buildDropdownFormField
Widget _buildSearchableDropdown({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  required List<String> items,
  required FocusNode focusNode,
  bool showSearch = false,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: DropdownSearch<String>(
      // Properti untuk menampilkan menu popup
      popupProps: PopupProps.menu(
        showSearchBox: showSearch, // AKTIFKAN KOTAK PENCARIAN
        // Atur ketinggian maksimal, kira-kira untuk 3 item
        constraints: const BoxConstraints(
          maxHeight: 180, // Ketinggian maksimal untuk sekitar 3 item
        ),
        // Kustomisasi tampilan kotak pencarian
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Cari...",
          ),
        ),
        // Pastikan dropdown muncul di bawah field
        fit: FlexFit.loose,
      ),
      // Data item yang akan ditampilkan
      items: items,
      // Kustomisasi tampilan field utama
      dropdownDecoratorProps: DropDownDecoratorProps(
        // Kita gunakan FocusNode di sini
        baseStyle: TextStyle(fontSize: 16), // Sesuaikan agar tidak overflow
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
      ),
      // Saat item dipilih, perbarui controller
      onChanged: (String? newValue) {
        setState(() {
          controller.text = newValue ?? '';
        });
      },
      // Item yang sedang terpilih (dari controller)
      selectedItem: controller.text.isEmpty ? null : controller.text,
      // Validasi
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '$label tidak boleh kosong';
        }
        return null;
      },
    ),
  );
}


  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
    required FocusNode focusNode,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          prefixIcon: Icon(icon),
        ),
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label tidak boleh kosong';
          }
          if (isNumber && num.tryParse(value) == null) {
            return 'Masukkan angka yang valid';
          }
          return null;
        },
      ),
    );
  }
}
