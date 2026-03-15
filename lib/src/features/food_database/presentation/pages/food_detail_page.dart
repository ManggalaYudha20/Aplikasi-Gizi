// lib/src/features/food_database/presentation/pages/food_detail_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/services/food_delete_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/add_food_item_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/widgets/food_nutrition_card.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/role_builder.dart';

class FoodDetailPage extends StatefulWidget {
  final FoodItem foodItem;

  const FoodDetailPage({super.key, required this.foodItem});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  final TextEditingController _portionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _resultCardKey = GlobalKey();

  Map<String, num>? _calculatedNutrition;
  bool _showResults = false;

  @override
  void dispose() {
    _portionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ── Calculation logic ─────────────────────────────────────────────────────

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

    if (widget.foodItem.portionGram == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tidak dapat menghitung, porsi asli makanan adalah 0 gram.',
          ),
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: CustomAppBar(
        title: widget.foodItem.name,
        subtitle: '100 gram',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Food header card ──────────────────────────────────────
                _buildFoodHeaderCard(),
                const SizedBox(height: 24),

                // ── Nutrition section title ───────────────────────────────
                const Text(
                  'Informasi Gizi',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 148, 68),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Highlight cards ───────────────────────────────────────
                FoodNutritionCard(
                  label: 'Energi',
                  value: widget.foodItem.calories,
                  unit: 'kkal',
                  icon: Icons.local_fire_department,
                  color: Colors.orange,
                ),
                const SizedBox(height: 12),
                FoodNutritionCard(
                  label: 'Protein',
                  value: widget.foodItem.protein,
                  unit: 'gram',
                  icon: Icons.egg,
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                FoodNutritionCard(
                  label: 'Lemak',
                  value: widget.foodItem.fat,
                  unit: 'gram',
                  icon: Icons.water_drop,
                  color: Colors.red,
                ),
                const SizedBox(height: 12),
                FoodNutritionCard(
                  label: 'Serat',
                  value: widget.foodItem.fiber,
                  unit: 'gram',
                  icon: Icons.grass,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),

                // ── Full detail table ─────────────────────────────────────
                FoodNutritionDetailTable(item: widget.foodItem),
                const SizedBox(height: 24),

                // ── Portion calculator ────────────────────────────────────
                _buildPortionCalculator(),
                const SizedBox(height: 24),

                // ── Delete button (admin only) ────────────────────────────
                RoleBuilder(
                  requiredRole: 'admin',
                  builder: (context) {
                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(
                              Icons.delete_forever,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Hapus',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () => FoodDeleteService.deleteFoodItem(
                              context,
                              widget.foodItem,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
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

  // ── Private builder helpers ───────────────────────────────────────────────

  Widget _buildFoodHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 148, 68).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 0, 148, 68).withValues(alpha: 0.3),
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
              // Edit button (admin only)
              RoleBuilder(
                requiredRole: 'admin',
                builder: (context) {
                  return GestureDetector(
                    key: const Key('btn_edit_food'),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AddFoodItemPage(foodItem: widget.foodItem),
                        ),
                      );
                      if (result == true && context.mounted) {
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
    );
  }

  Widget _buildPortionCalculator() {
    return Container(
      key: _resultCardKey,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 148, 68).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 0, 148, 68).withValues(alpha: 0.2),
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

          // Input field
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

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetCalculation,
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        const Color.fromARGB(255, 0, 148, 68),
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
                    backgroundColor:
                        const Color.fromARGB(255, 0, 148, 68),
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
            FoodNutritionRow(
              label: 'Air',
              value:
                  '${_calculatedNutrition!['air']?.toStringAsFixed(2) ?? '0'} g',
            ),
            FoodNutritionRow(
              label: 'Energi',
              value:
                  '${_calculatedNutrition!['energi']?.toStringAsFixed(1) ?? '0'} kkal',
            ),
            FoodNutritionRow(
              label: 'Protein',
              value:
                  '${_calculatedNutrition!['protein']?.toStringAsFixed(2) ?? '0'} g',
            ),
            FoodNutritionRow(
              label: 'Lemak',
              value:
                  '${_calculatedNutrition!['lemak']?.toStringAsFixed(2) ?? '0'} g',
            ),
            FoodNutritionRow(
              label: 'Karbohidrat',
              value:
                  '${_calculatedNutrition!['karbohidrat']?.toStringAsFixed(2) ?? '0'} g',
            ),
            FoodNutritionRow(
              label: 'Serat',
              value:
                  '${_calculatedNutrition!['serat']?.toStringAsFixed(2) ?? '0'} g',
            ),
            FoodNutritionRow(
              label: 'Abu',
              value:
                  '${_calculatedNutrition!['abu']?.toStringAsFixed(2) ?? '0'} g',
            ),
            FoodNutritionRow(
              label: 'Kalsium (Ca)',
              value:
                  '${_calculatedNutrition!['kalsium']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Fosfor (P)',
              value:
                  '${_calculatedNutrition!['fosfor']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Besi (Fe)',
              value:
                  '${_calculatedNutrition!['besi']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Natrium (Na)',
              value:
                  '${_calculatedNutrition!['natrium']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Kalium (Ka)',
              value:
                  '${_calculatedNutrition!['kalium']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Tembaga (Cu)',
              value:
                  '${_calculatedNutrition!['tembaga']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Seng (Zn)',
              value:
                  '${_calculatedNutrition!['seng']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Retinol (vit. A)',
              value:
                  '${_calculatedNutrition!['retinol']?.toStringAsFixed(2) ?? '0'} mcg',
            ),
            FoodNutritionRow(
              label: 'β-karoten',
              value:
                  '${_calculatedNutrition!['betaKaroten']?.toStringAsFixed(2) ?? '0'} mcg',
            ),
            FoodNutritionRow(
              label: 'Karoten total',
              value:
                  '${_calculatedNutrition!['karotenTotal']?.toStringAsFixed(2) ?? '0'} mcg',
            ),
            FoodNutritionRow(
              label: 'Thiamin (vit. B1)',
              value:
                  '${_calculatedNutrition!['thiamin']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Riboflavin (vit. B2)',
              value:
                  '${_calculatedNutrition!['riboflavin']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Niasin',
              value:
                  '${_calculatedNutrition!['niasin']?.toStringAsFixed(2) ?? '0'} mg',
            ),
            FoodNutritionRow(
              label: 'Vitamin C',
              value:
                  '${_calculatedNutrition!['vitaminC']?.toStringAsFixed(2) ?? '0'} mg',
            ),
          ],
        ],
      ),
    );
  }
}