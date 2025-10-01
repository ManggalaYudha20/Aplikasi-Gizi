import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/form_action_buttons.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

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

  @override
  void initState() {
    super.initState();
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
    super.dispose();
  }

  Future<void> _submitFoodItem() async {
    if (_formKey.currentState!.validate()) {
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
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(
        title: _isEditMode ? 'Edit Makanan' : 'Tambah Makanan Baru',
        subtitle: 'Isi data dengan lengkap',
      ),
      body: SingleChildScrollView(
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
              ),
              _buildTextFormField(
                controller: _kodeController,
                label: 'Kode Makanan',
                icon: Icons.qr_code,
              ),
              _buildTextFormField(
                controller: _mentahOlahanController,
                label: 'Mentah / Olahan',
                icon: Icons.category,
              ),
              _buildTextFormField(
                controller: _kelompokMakananController,
                label: 'Kelompok Makanan',
                icon: Icons.group,
              ),
              _buildTextFormField(
                controller: _porsiGramController,
                label: 'Porsi (gram)',
                icon: Icons.scale,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _airController,
                label: 'Air (g)',
                icon: Icons.water_drop,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _kaloriController,
                label: 'Energi (Kal)',
                icon: Icons.local_fire_department,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _proteinController,
                label: 'Protein (g)',
                icon: Icons.egg,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _lemakController,
                label: 'Lemak (g)',
                icon: Icons.water,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _karbohidratController,
                label: 'Karbohidrat (g)',
                icon: Icons.rice_bowl,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _seratController,
                label: 'Serat (g)',
                icon: Icons.grass,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _abuController,
                label: 'Abu (g)',
                icon: Icons.grain,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _kalsiumController,
                label: 'Kalsium (Ca) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _fosforController,
                label: 'Fosfor (P) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _besiController,
                label: 'Besi (Fe) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _natriumController,
                label: 'Natrium (Na) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _kaliumController,
                label: 'Kalium (Ka) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _tembagaController,
                label: 'Tembaga (Cu) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _sengController,
                label: 'Seng (Zn) (mg)',
                icon: Icons.monitor_heart,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _retinolController,
                label: 'Retinol (vit. A) (mcg)',
                icon: Icons.visibility,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _betaKarotenController,
                label: 'β-karoten (mcg)',
                icon: Icons.visibility,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _karotenTotalController,
                label: 'Karoten total (mcg)',
                icon: Icons.visibility,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _thiaminController,
                label: 'Thiamin (vit. B1) (mg)',
                icon: Icons.local_dining,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _riboflavinController,
                label: 'Riboflavin (vit. B2) (mg)',
                icon: Icons.local_dining,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _niasinController,
                label: 'Niasin (mg)',
                icon: Icons.local_dining,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _vitaminCController,
                label: 'Vitamin C (mg)',
                icon: Icons.medical_services,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _bddController,
                label: 'BDD (%)',
                icon: Icons.percent,
                isNumber: true,
              ),
              const SizedBox(height: 32),
              FormActionButtons(
                onReset: _resetForm,
                onSubmit: _submitFoodItem,
                submitText: _isEditMode ? 'Simpan' : 'Tambah Data',
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
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