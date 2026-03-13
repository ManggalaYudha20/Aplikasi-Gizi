// lib/src/features/kidney_calculation/presentation/widgets/kidney_nutrition_card.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/kidney_calculation/data/models/kidney_diet_nutrition_model.dart';

/// Kartu yang menampilkan asupan gizi harian berdasarkan level diet ginjal.
///
/// Biasanya dibungkus [ExpansionTile] di halaman induk:
/// ```dart
/// ExpansionTile(
///   title: Text('Asupan Gizi per Hari (Diet Protein ${result.recommendedDiet}g)'),
///   children: [
///     KidneyNutritionCard(
///       nutritionInfo: result.nutritionInfo!,
///       dietProteinGram: result.recommendedDiet,
///     ),
///   ],
/// )
/// ```
class KidneyNutritionCard extends StatelessWidget {
  final KidneyDietNutrition nutritionInfo;
  final int dietProteinGram;

  const KidneyNutritionCard({
    super.key,
    required this.nutritionInfo,
    required this.dietProteinGram,
  });

  @override
  Widget build(BuildContext context) {
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
              'Asupan Gizi per Hari (Diet Protein ${dietProteinGram}g)',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
          ),
          const Divider(height: 24),
          _row('Energi',      '${nutritionInfo.energi} kkal',   'nut_energi'),
          _row('Protein',     '${nutritionInfo.protein} g',      'nut_protein'),
          _row('Lemak',       '${nutritionInfo.lemak} g',        'nut_lemak'),
          _row('Karbohidrat', '${nutritionInfo.karbohidrat} g',  'nut_karbo'),
          _row('Kalsium',     '${nutritionInfo.kalsium} mg',     'nut_kalsium'),
          _row('Zat Besi',    '${nutritionInfo.zatBesi} mg',     'nut_besi'),
          _row('Fosfor',      '${nutritionInfo.fosfor} mg',      'nut_fosfor'),
          _row('Vitamin A',   '${nutritionInfo.vitaminA} RE',    'nut_vit_a'),
          _row('Tiamin',      '${nutritionInfo.tiamin} mg',      'nut_tiamin'),
          _row('Vitamin C',   '${nutritionInfo.vitaminC} mg',    'nut_vit_c'),
          _row('Natrium',     '${nutritionInfo.natrium} mg',     'nut_natrium'),
          _row('Kalium',      '${nutritionInfo.kalium} mg',      'nut_kalium'),
        ],
      ),
    );
  }

  Widget _row(String label, String value, String keySuffix) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            key: ValueKey('value_$keySuffix'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}