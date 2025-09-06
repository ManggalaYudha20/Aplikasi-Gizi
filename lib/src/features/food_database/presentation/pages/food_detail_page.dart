import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/add_food_item_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/delete_item_service.dart';

class FoodDetailPage extends StatefulWidget {
  final FoodItem foodItem;

  const FoodDetailPage({
    super.key,
    required this.foodItem,
  });

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  final TextEditingController _portionController = TextEditingController();
  Map<String, double>? _calculatedNutrition;
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
        const SnackBar(content: Text('Masukkan takaran makanan terlebih dahulu')),
      );
      return;
    }

    final double? portionGram = double.tryParse(portionText);
    if (portionGram == null || portionGram <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan angka yang valid')),
      );
      return;
    }

    final double ratio = portionGram / 100.0;
    
    setState(() {
      _calculatedNutrition = {
        'kalori': (widget.foodItem.nutritionPer100g['kalori'] ?? 0.0) * ratio,
        'protein': (widget.foodItem.nutritionPer100g['protein'] ?? 0.0) * ratio,
        'lemak': (widget.foodItem.nutritionPer100g['lemak'] ?? 0.0) * ratio,
        'serat': (widget.foodItem.nutritionPer100g['serat'] ?? 0.0) * ratio,
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
      body: SingleChildScrollView(
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
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddFoodItemPage(foodItem: widget.foodItem),
                            ),
                          ).then((result) {
                            if (result == true && mounted) {
                              // Refresh the page by popping with true to signal refresh
                              Navigator.of(context).pop(true);
                            }
                          });
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.edit, color: Color.fromARGB(255, 0, 148, 68)),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kode: ${widget.foodItem.code}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Porsi: ${widget.foodItem.portionGram} gram',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
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
              'Kalori',
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
            
            // Custom Portion Calculator
            Container(
              padding: const EdgeInsets.all(16),
              key: _resultCardKey, 
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
                      if (double.tryParse(value) == null || double.parse(value) <= 0) {
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
                            foregroundColor: const Color.fromARGB(255, 0, 148, 68),
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
                            backgroundColor: const Color.fromARGB(255, 0, 148, 68),
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
                      'Kalori',
                      '${_calculatedNutrition!['kalori']?.toStringAsFixed(1) ?? '0'} kkal',
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
                      'Serat',
                      '${_calculatedNutrition!['serat']?.toStringAsFixed(2) ?? '0'} g',
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete_forever, color: Colors.white),
                    label: const Text('Hapus', style: TextStyle(color: Colors.white)),
                    // Memanggil logika hapus dari file terpisah
                    onPressed: () => FoodItemService.deleteFoodItem(context, widget.foodItem),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
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
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
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
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
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
}