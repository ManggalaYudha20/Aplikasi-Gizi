// D:\flutter sdk\aplikasi_diagnosa_gizi\lib\src\features\diabetes_calculation\presentation\widgets\dm_diet_expansion_cards.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/diabetes_calculation/data/models/dm_meal_session_model.dart';

// ---------------------------------------------------------------------------
// DmDietInfoTile
// ---------------------------------------------------------------------------

/// ExpansionTile yang menampilkan jenis diet DM beserta kandungan makronutrien.
class DmDietInfoTile extends StatelessWidget {
  final DiabetesCalculationResult result;

  const DmDietInfoTile({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final diet = result.dietInfo;
    final hPad = MediaQuery.sizeOf(context).width * 0.04;

    return ExpansionTile(
      title: Text('Jenis ${diet.name}'),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(hPad),
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
                  'Jenis ${diet.name}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const Divider(height: 24),
              _row('Protein', '${diet.protein} g'),
              _row('Lemak', '${diet.fat} g'),
              _row('Karbohidrat', '${diet.carbohydrate} g'),
              const SizedBox(height: 8),
              const Text(
                'Jenis Diet Diabetes Melitus menurut kandungan energi, protein, lemak, dan karbohidrat',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _row(String label, String value) {
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
}

// ---------------------------------------------------------------------------
// DmFoodGroupTile
// ---------------------------------------------------------------------------

/// ExpansionTile yang menampilkan standar diet (golongan bahan makanan per penukar).
class DmFoodGroupTile extends StatelessWidget {
  final DiabetesCalculationResult result;

  const DmFoodGroupTile({super.key, required this.result});

  String _fmt(double v) =>
      v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final diet = result.foodGroupDiet;
    final hPad = MediaQuery.sizeOf(context).width * 0.04;

    return ExpansionTile(
      title: Text('Standar Diet (${diet.calorieLevel})'),
      children: [
        const SizedBox(height: 10),
        Container(
          padding: EdgeInsets.all(hPad),
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
                  'Standar Diet (${diet.calorieLevel})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
              ),
              const Divider(height: 24),
              _row('Nasi atau penukar', '${_fmt(diet.nasiP)} P'),
              _row('Ikan atau penukar', '${_fmt(diet.ikanP)} P'),
              _row('Daging atau penukar', '${_fmt(diet.dagingP)} P'),
              _row('Tempe atau penukar', '${_fmt(diet.tempeP)} P'),
              _row('Sayuran/penukar A', ' ${diet.sayuranA}'),
              _row('Sayuran/penukar B', '${_fmt(diet.sayuranB)} P'),
              _row('Buah atau penukar', '${_fmt(diet.buah)} P'),
              _row('Susu atau penukar', '${_fmt(diet.susu)} P'),
              _row('Minyak atau penukar', '${_fmt(diet.minyak)} P'),
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
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _row(String label, String value) {
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
}
