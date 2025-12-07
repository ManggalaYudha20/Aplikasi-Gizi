// lib/src/features/disease_calculation/presentation/widgets/food_search_delegate.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/disease_calculation/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';

class FoodSearchDelegate extends SearchDelegate<FoodItem?> {
  final FoodDatabaseService _dbService;

  // Constructor menerima initialQuery opsional
  FoodSearchDelegate(this._dbService, {String? initialQuery}) {
    if (initialQuery != null) {
      query = initialQuery;
    }
  }

  @override
  String get searchFieldLabel => 'Cari nama makanan...';

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            showSuggestions(context); // Refresh agar kembali menampilkan semua list
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // LANGSUNG panggil _buildList() agar saat kosong pun dia me-load data
    return _buildList();
  }

  Widget _buildList() {
    // Logika pemilihan method:
    // Jika kosong -> panggil getAllFoodItems()
    // Jika ada teks -> panggil searchFoodByName()
    Future<List<FoodItem>> fetchFuture;
    
    if (query.isEmpty) {
      fetchFuture = _dbService.getAllFoodItems();
    } else {
      fetchFuture = _dbService.searchFoodByName(query);
    }

    return FutureBuilder<List<FoodItem>>(
      future: fetchFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        // Tampilan jika data benar-benar kosong di database
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          if (query.isNotEmpty) {
            return Center(child: Text('Tidak ada hasil untuk "$query"'));
          }
          return const Center(child: Text("Belum ada data makanan di database"));
        }

        final results = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final food = results[index];

            // --- TAMPILAN CARD (Sama dengan FoodListPage) ---
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  close(context, food);
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 0, 148, 68)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              color: Color.fromARGB(255, 0, 148, 68),
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Kode: ${food.code}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutritionInfo(
                            'Energi',
                            '${food.calories.toStringAsFixed(0)} kkal',
                            Icons.local_fire_department,
                            Colors.orange,
                          ),
                          _buildNutritionInfo(
                            'Protein',
                            '${food.protein.toStringAsFixed(1)} g',
                            Icons.egg,
                            Colors.blue,
                          ),
                          _buildNutritionInfo(
                            'Lemak',
                            '${food.fat.toStringAsFixed(1)} g',
                            Icons.water_drop,
                            Colors.red,
                          ),
                          _buildNutritionInfo(
                            'Serat',
                            '${food.fiber.toStringAsFixed(1)} g',
                            Icons.grass,
                            Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            'Porsi: ${food.portionGram} gram',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Kat: ${food.kelompokMakanan}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Status: ${food.mentahOlahan}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildNutritionInfo(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}