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
  final _porsiGramController = TextEditingController();
  final _kaloriController = TextEditingController();
  final _proteinController = TextEditingController();
  final _lemakController = TextEditingController();
  final _seratController = TextEditingController();
  bool _isLoading = false;
  bool get _isEditMode => widget.foodItem != null;

  @override
  void initState() {
    super.initState();
    // BARU: Jika ini mode edit, isi semua field dengan data yang ada
    if (_isEditMode) {
      final item = widget.foodItem!;
      _namaController.text = item.name;
      _kodeController.text = item.code;
      _porsiGramController.text = item.portionGram.toString();
      _proteinController.text = item.protein.toString();
      _lemakController.text = item.fat.toString();
      _kaloriController.text = item.calories.toString();
      _seratController.text = item.fiber.toString();
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _kodeController.dispose();
    _porsiGramController.dispose();
    _kaloriController.dispose();
    _proteinController.dispose();
    _lemakController.dispose();
    _seratController.dispose();
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
        'porsi_gram': num.tryParse(_porsiGramController.text) ?? 0,
        'kalori': num.tryParse(_kaloriController.text) ?? 0,
        'protein': num.tryParse(_proteinController.text) ?? 0,
        'lemak': num.tryParse(_lemakController.text) ?? 0,
        'serat': num.tryParse(_seratController.text) ?? 0,
      };

      try {
        // DIUBAH: Logika untuk menyimpan atau memperbarui data
        if (_isEditMode) {
          // Mode Edit: perbarui dokumen yang ada
          await FirebaseFirestore.instance
              .collection('food_items')
              .doc(widget.foodItem!.id)
              .update(foodData);
        } else {
          // Mode Tambah: buat dokumen baru
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
          // Kembali ke halaman sebelumnya
          if (_isEditMode) {
            Navigator.pop(context, true); // Kirim 'true' untuk refresh
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
    _porsiGramController.clear();
    _kaloriController.clear();
    _proteinController.clear();
    _lemakController.clear();
    _seratController.clear();
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
                controller: _porsiGramController,
                label: 'Porsi (gram)',
                icon: Icons.scale,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _kaloriController,
                label: 'Kalori (kkal)',
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
                icon: Icons.water_drop,
                isNumber: true,
              ),
              _buildTextFormField(
                controller: _seratController,
                label: 'Serat (g)',
                icon: Icons.grass,
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
            ? TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return '$label tidak boleh kosong';
          }
          if (isNumber && double.tryParse(value) == null) {
            return 'Masukkan angka yang valid';
          }
          return null;
        },
      ),
    );
  }
}
