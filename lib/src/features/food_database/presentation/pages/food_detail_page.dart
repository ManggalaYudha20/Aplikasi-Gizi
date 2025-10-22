//lib\src\features\food_database\presentation\pages\food_detail_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/add_food_item_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/delete_item_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/role_builder.dart';

class FoodDetailPage extends StatefulWidget {
  final FoodItem foodItem;

  const FoodDetailPage({super.key, required this.foodItem});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  final TextEditingController _portionController = TextEditingController();
  Map<String, num>? _calculatedNutrition;
  bool _showResults = false;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();

  @override
  void dispose() {
    _portionController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _calculateNutrition() {
    final String portionText = _portionController.text;
    if (portionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan takaran makanan terlebih dahulu'),
        ),
      );
      return;
    }

    final num? portionGram = num.tryParse(portionText);
    if (portionGram == null || portionGram <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan angka yang valid')),
      );
      return;
    }

    // Perbaikan: Tambahkan pengecekan untuk portionGram agar tidak nol
    if (widget.foodItem.portionGram == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat menghitung, porsi asli makanan adalah 0 gram.'),
        ),
      );
      return;
    }

    final num ratio = portionGram / widget.foodItem.portionGram;

    setState(() {
      _calculatedNutrition = {
        'air': widget.foodItem.air * ratio,
        'energi': widget.foodItem.calories * ratio,
        'protein': widget.foodItem.protein * ratio,
        'lemak': widget.foodItem.fat * ratio,
        'karbohidrat': widget.foodItem.karbohidrat * ratio,
        'serat': widget.foodItem.fiber * ratio,
        'abu': widget.foodItem.abu * ratio,
        'kalsium': widget.foodItem.kalsium * ratio,
        'fosfor': widget.foodItem.fosfor * ratio,
        'besi': widget.foodItem.besi * ratio,
        'natrium': widget.foodItem.natrium * ratio,
        'kalium': widget.foodItem.kalium * ratio,
        'tembaga': widget.foodItem.tembaga * ratio,
        'seng': widget.foodItem.seng * ratio,
        'retinol': widget.foodItem.retinol * ratio,
        'betaKaroten': widget.foodItem.betaKaroten * ratio,
        'karotenTotal': widget.foodItem.karotenTotal * ratio,
        'thiamin': widget.foodItem.thiamin * ratio,
        'riboflavin': widget.foodItem.riboflavin * ratio,
        'niasin': widget.foodItem.niasin * ratio,
        'vitaminC': widget.foodItem.vitaminC * ratio,
      };
      _showResults = true;
    });
    _scrollToResult();
  }

  void _resetCalculation() {
    setState(() {
      _portionController.clear();
      _calculatedNutrition = null;
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: CustomAppBar(title: widget.foodItem.name, subtitle: '100 gram'),
      body:  SafeArea(
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
          },
        child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Food Name Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  0,
                  148,
                  68,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(
                    255,
                    0,
                    148,
                    68,
                  ).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.foodItem.name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 0, 148, 68),
                          ),
                        ),
                      ),
                      RoleBuilder(
                        requiredRole: 'admin',
                        builder: (context) {
                     return GestureDetector(
                        onTap: () async {
                          // Jadikan async
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddFoodItemPage(foodItem: widget.foodItem),
                            ),
                          );
                          // Cek mounted setelah await
                          if (result == true && mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit,
                              color: Color.fromARGB(255, 0, 148, 68),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: const Color.fromARGB(255, 0, 148, 68),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                     );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kode: ${widget.foodItem.code}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Porsi: ${widget.foodItem.portionGram} gram',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Kelompok Makanan: ${widget.foodItem.kelompokMakanan}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  Text(
                    'Status: ${widget.foodItem.mentahOlahan}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nutrition Information
            const Text(
              'Informasi Gizi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 148, 68),
              ),
            ),
            const SizedBox(height: 16),

            // Nutrition Cards
            _buildNutritionCard(
              'Energi',
              widget.foodItem.calories,
              'kkal',
              Icons.local_fire_department,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildNutritionCard(
              'Protein',
              widget.foodItem.protein,
              'gram',
              Icons.egg,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildNutritionCard(
              'Lemak',
              widget.foodItem.fat,
              'gram',
              Icons.water_drop,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildNutritionCard(
              'Serat',
              widget.foodItem.fiber,
              'gram',
              Icons.grass,
              Colors.green,
            ),
            const SizedBox(height: 24),

            // DIPERBARUI: Menampilkan semua detail nutrisi dalam tabel
            _buildNutritionDetailTable(widget.foodItem),

            const SizedBox(height: 24),

            // Custom Portion Calculator
            Container(
              padding: const EdgeInsets.all(16),
              key: _resultCardKey,
              decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  0,
                  148,
                  68,
                ).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(
                    255,
                    0,
                    148,
                    68,
                  ).withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kalkulator Takaran Gizi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 0, 148, 68),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input field for custom portion
                  TextFormField(
                    controller: _portionController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Takaran makanan (gram)',
                      hintText: 'Masukkan jumlah gram',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.scale),
                      suffixText: 'gram',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Masukkan takaran makanan';
                      }
                      if (double.tryParse(value) == null ||
                          double.parse(value) <= 0) {
                        return 'Masukkan angka yang valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Calculate and Reset buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _resetCalculation,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color.fromARGB(
                              255,
                              0,
                              148,
                              68,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            side: const BorderSide(
                              color: Color.fromARGB(255, 0, 148, 68),
                            ),
                          ),
                          child: const Text('Reset'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: _calculateNutrition,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromARGB(
                              255,
                              0,
                              148,
                              68,
                            ),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Hitung'),
                        ),
                      ),
                    ],
                  ),

                  // Calculated results
                  if (_showResults && _calculatedNutrition != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Hasil Perhitungan Gizi',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 148, 68),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildNutritionRow(
                      'Air',
                      '${_calculatedNutrition!['air']?.toStringAsFixed(2) ?? '0'} g',
                    ),
                    _buildNutritionRow(
                      'Energi',
                      '${_calculatedNutrition!['energi']?.toStringAsFixed(1) ?? '0'} kkal',
                    ),
                    _buildNutritionRow(
                      'Protein',
                      '${_calculatedNutrition!['protein']?.toStringAsFixed(2) ?? '0'} g',
                    ),
                    _buildNutritionRow(
                      'Lemak',
                      '${_calculatedNutrition!['lemak']?.toStringAsFixed(2) ?? '0'} g',
                    ),
                    _buildNutritionRow(
                      'Karbohidrat',
                      '${_calculatedNutrition!['karbohidrat']?.toStringAsFixed(2) ?? '0'} g',
                    ),
                    _buildNutritionRow(
                      'Serat',
                      '${_calculatedNutrition!['serat']?.toStringAsFixed(2) ?? '0'} g',
                    ),
                    _buildNutritionRow(
                      'Abu',
                      '${_calculatedNutrition!['abu']?.toStringAsFixed(2) ?? '0'} g',
                    ),
                    _buildNutritionRow(
                      'Kalsium (Ca)',
                      '${_calculatedNutrition!['kalsium']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Fosfor (P)',
                      '${_calculatedNutrition!['fosfor']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Besi (Fe)',
                      '${_calculatedNutrition!['besi']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Natrium (Na)',
                      '${_calculatedNutrition!['natrium']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Kalium (Ka)',
                      '${_calculatedNutrition!['kalium']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Tembaga (Cu)',
                      '${_calculatedNutrition!['tembaga']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Seng (Zn)',
                      '${_calculatedNutrition!['seng']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Retinol (vit. A)',
                      '${_calculatedNutrition!['retinol']?.toStringAsFixed(2) ?? '0'} mcg',
                    ),
                    _buildNutritionRow(
                      'β-karoten',
                      '${_calculatedNutrition!['betaKaroten']?.toStringAsFixed(2) ?? '0'} mcg',
                    ),
                    _buildNutritionRow(
                      'Karoten total',
                      '${_calculatedNutrition!['karotenTotal']?.toStringAsFixed(2) ?? '0'} mcg',
                    ),
                    _buildNutritionRow(
                      'Thiamin (vit. B1)',
                      '${_calculatedNutrition!['thiamin']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Riboflavin (vit. B2)',
                      '${_calculatedNutrition!['riboflavin']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Niasin',
                      '${_calculatedNutrition!['niasin']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                    _buildNutritionRow(
                      'Vitamin C',
                      '${_calculatedNutrition!['vitaminC']?.toStringAsFixed(2) ?? '0'} mg',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
             RoleBuilder(
                  requiredRole: 'admin',
                  builder: (context) {
                     return Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.white),
                    ),
                    // Memanggil logika hapus dari file terpisah
                    onPressed: () => FoodItemService.deleteFoodItem(
                      context,
                      widget.foodItem,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            );
              },
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }

  Widget _buildNutritionCard(
    String label,
    num value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                Text(
                  '${value.toStringAsFixed(1)} $unit',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionDetailTable(FoodItem item) {
  // Perbaikan: Gunakan getter nutritionPer100g dari model
  final Map<String, num> nutritionPer100g = item.nutritionPer100g;

  return Container(
    // Perbaikan: Mengganti Card dengan Container
    decoration: BoxDecoration(
                color: const Color.fromARGB(
                  255,
                  0,
                  148,
                  68,
                ).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(
                    255,
                    0,
                    148,
                    68,
                  ).withValues(alpha: 0.2),
                ),
              ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNutritionRow('Air', '${nutritionPer100g['air']?.toStringAsFixed(1) ?? '0.0'} g'),
          _buildNutritionRow('Energi', '${nutritionPer100g['energi']?.toStringAsFixed(1) ?? '0.0'} kkal'),
          _buildNutritionRow('Protein', '${nutritionPer100g['protein']?.toStringAsFixed(1) ?? '0.0'} g'),
          _buildNutritionRow('Lemak', '${nutritionPer100g['lemak']?.toStringAsFixed(1) ?? '0.0'} g'),
          _buildNutritionRow('Karbohidrat', '${nutritionPer100g['karbohidrat']?.toStringAsFixed(1) ?? '0.0'} g'),
          _buildNutritionRow('Serat', '${nutritionPer100g['serat']?.toStringAsFixed(1) ?? '0.0'} g'),
          _buildNutritionRow('Abu', '${nutritionPer100g['abu']?.toStringAsFixed(1) ?? '0.0'} g'),
          _buildNutritionRow('Kalsium (Ca)', '${nutritionPer100g['kalsium']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Fosfor (P)', '${nutritionPer100g['fosfor']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Besi (Fe)', '${nutritionPer100g['besi']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Natrium (Na)', '${nutritionPer100g['natrium']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Kalium (Ka)', '${nutritionPer100g['kalium']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Tembaga (Cu)', '${nutritionPer100g['tembaga']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Seng (Zn)', '${nutritionPer100g['seng']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Retinol (vit. A)', '${nutritionPer100g['retinol']?.toStringAsFixed(1) ?? '0.0'} mcg'),
          _buildNutritionRow('β-karoten', '${nutritionPer100g['betaKaroten']?.toStringAsFixed(1) ?? '0.0'} mcg'),
          _buildNutritionRow('Karoten total', '${nutritionPer100g['karotenTotal']?.toStringAsFixed(1) ?? '0.0'} mcg'),
          _buildNutritionRow('Thiamin (vit. B1)', '${nutritionPer100g['thiamin']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Riboflavin (vit. B2)', '${nutritionPer100g['riboflavin']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Niasin', '${nutritionPer100g['niasin']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('Vitamin C', '${nutritionPer100g['vitaminC']?.toStringAsFixed(1) ?? '0.0'} mg'),
          _buildNutritionRow('BDD', '${nutritionPer100g['bdd']?.toStringAsFixed(1) ?? '0.0'} %'),
        ],
      ),
    ),
  );
 }
}
