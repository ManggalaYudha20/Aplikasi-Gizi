// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\food_database\presentation\widgets\food_nutrition_card.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';

// =============================================================================
// FoodNutritionCard
// =============================================================================

/// Menampilkan satu baris kartu informasi gizi dengan ikon, label, dan nilai.
///
/// Digunakan untuk menyorot gizi utama (energi, protein, lemak, serat) pada
/// halaman detail makanan.
class FoodNutritionCard extends StatelessWidget {
  final String label;
  final num value;
  final String unit;
  final IconData icon;
  final Color color;

  const FoodNutritionCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label: ${value.toStringAsFixed(1)} $unit',
      child: Container(
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
      ),
    );
  }
}

// =============================================================================
// FoodNutritionRow
// =============================================================================

/// Menampilkan satu baris pasangan label–nilai gizi dalam tabel nutrisi.
class FoodNutritionRow extends StatelessWidget {
  final String label;
  final String value;

  const FoodNutritionRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
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
}

// =============================================================================
// FoodNutritionDetailTable
// =============================================================================

/// Menampilkan tabel lengkap semua nilai gizi per 100 gram untuk [item].
///
/// Nilai gizi dikalkulasi menggunakan getter [FoodItem.nutritionPer100g].
class FoodNutritionDetailTable extends StatelessWidget {
  final FoodItem item;

  const FoodNutritionDetailTable({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final Map<String, num> n = item.nutritionPer100g;

    return Container(
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 0, 148, 68).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color.fromARGB(255, 0, 148, 68).withValues(alpha: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FoodNutritionRow(
              label: 'Air',
              value: '${n['air']?.toStringAsFixed(1) ?? '0.0'} g',
            ),
            FoodNutritionRow(
              label: 'Energi',
              value: '${n['energi']?.toStringAsFixed(1) ?? '0.0'} kkal',
            ),
            FoodNutritionRow(
              label: 'Protein',
              value: '${n['protein']?.toStringAsFixed(1) ?? '0.0'} g',
            ),
            FoodNutritionRow(
              label: 'Lemak',
              value: '${n['lemak']?.toStringAsFixed(1) ?? '0.0'} g',
            ),
            FoodNutritionRow(
              label: 'Karbohidrat',
              value: '${n['karbohidrat']?.toStringAsFixed(1) ?? '0.0'} g',
            ),
            FoodNutritionRow(
              label: 'Serat',
              value: '${n['serat']?.toStringAsFixed(1) ?? '0.0'} g',
            ),
            FoodNutritionRow(
              label: 'Abu',
              value: '${n['abu']?.toStringAsFixed(1) ?? '0.0'} g',
            ),
            FoodNutritionRow(
              label: 'Kalsium (Ca)',
              value: '${n['kalsium']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Fosfor (P)',
              value: '${n['fosfor']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Besi (Fe)',
              value: '${n['besi']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Natrium (Na)',
              value: '${n['natrium']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Kalium (Ka)',
              value: '${n['kalium']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Tembaga (Cu)',
              value: '${n['tembaga']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Seng (Zn)',
              value: '${n['seng']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Retinol (vit. A)',
              value: '${n['retinol']?.toStringAsFixed(1) ?? '0.0'} mcg',
            ),
            FoodNutritionRow(
              label: 'β-karoten',
              value: '${n['betaKaroten']?.toStringAsFixed(1) ?? '0.0'} mcg',
            ),
            FoodNutritionRow(
              label: 'Karoten total',
              value: '${n['karotenTotal']?.toStringAsFixed(1) ?? '0.0'} mcg',
            ),
            FoodNutritionRow(
              label: 'Thiamin (vit. B1)',
              value: '${n['thiamin']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Riboflavin (vit. B2)',
              value: '${n['riboflavin']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Niasin',
              value: '${n['niasin']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'Vitamin C',
              value: '${n['vitaminC']?.toStringAsFixed(1) ?? '0.0'} mg',
            ),
            FoodNutritionRow(
              label: 'BDD',
              value: '${n['bdd']?.toStringAsFixed(1) ?? '0.0'} %',
            ),
          ],
        ),
      ),
    );
  }
}
