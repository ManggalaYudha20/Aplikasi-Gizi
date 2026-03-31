// lib/src/features/food_database/presentation/pages/food_list_page.dart

import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_item_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/services/food_database_service.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_detail_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/add_food_item_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/role_builder.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/data/models/food_filter_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/widgets/food_filter_sheet.dart';

class FoodListPage extends StatefulWidget {
  const FoodListPage({super.key});

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  final TextEditingController _searchController = TextEditingController();
  final FoodDatabaseService _dbService = FoodDatabaseService();

  String _searchQuery = '';
  FoodFilterModel _activeFilters = FoodFilterModel();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Fungsi Penentu Jumlah Kolom ---
  int _getCrossAxisCount(double screenWidth) {
    if (screenWidth >= 1200) return 3; // Layar Desktop/Web lebar
    if (screenWidth >= 800) return 2;  // Layar Tablet
    return 1;                          // Layar Mobile
  }

  void _applyFilters(FoodFilterModel newFilters) {
    setState(() {
      _activeFilters = newFilters;
    });
  }

  void _showFilterModal(BuildContext context) async {
    final newFilters = await showModalBottomSheet<FoodFilterModel?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FoodFilterSheet(
          currentFilters: _activeFilters,
          onResetPressed: () {
            _applyFilters(FoodFilterModel());
          },
        );
      },
    );

    if (newFilters != null) {
      setState(() {
        _activeFilters = newFilters;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: const CustomAppBar(
        title: 'Daftar Makanan',
        subtitle: 'Temukan informasi gizi makanan',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // ── Search bar + filter button (Dibatasi lebarnya) ────────────
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Semantics(
                            label: 'Input pencarian makanan',
                            child: _buildSearchBar(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          label: 'Tombol filter makanan',
                          button: true,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withValues(alpha: 0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              key: const Key('btn_filter'),
                              icon: Icon(
                                Icons.filter_list,
                                color: !_activeFilters.isDefault
                                    ? const Color.fromARGB(255, 0, 148, 68)
                                    : Colors.grey,
                              ),
                              onPressed: () => _showFilterModal(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── List (Menggunakan GridView) ──────────────────────────────
              Expanded(
                child: StreamBuilder<List<FoodItem>>(
                  stream: _dbService.getFoodItemsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final allItems = snapshot.data ?? [];

                    if (allItems.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada data makanan'),
                      );
                    }

                    final filteredItems = allItems.where((foodItem) {
                      final bool matchesSearch =
                          foodItem.name.toLowerCase().contains(_searchQuery) ||
                          foodItem.code.toLowerCase().contains(_searchQuery);
                      final bool matchesFilter =
                          _activeFilters.matches(foodItem);
                      return matchesSearch && matchesFilter;
                    }).toList();

                    if (filteredItems.isEmpty && _searchQuery.isNotEmpty) {
                      return Center(
                        child: Text('Tidak ada hasil untuk "$_searchQuery"'),
                      );
                    }

                    if (filteredItems.isEmpty) {
                      return const Center(
                        child: Text('Tidak ada data yang sesuai filter'),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.only(
                        bottom: 80, // Ruang untuk FAB
                        left: 16,
                        right: 16,
                        top: 8,
                      ),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _getCrossAxisCount(screenWidth),
                        crossAxisSpacing: 12.0,
                        mainAxisSpacing: 12.0,
                        mainAxisExtent: 150.0, // Tinggi konstan Card disesuaikan agar isi tidak terpotong
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final foodItem = filteredItems[index];
                        final String itemKey =
                            'card_item_${foodItem.id.isNotEmpty ? foodItem.id : index}';

                        return Semantics(
                          label: 'Kartu makanan ${foodItem.name}',
                          button: true,
                          child: Card(
                            key: Key(itemKey),
                            margin: EdgeInsets.zero, // Margin diatur oleh GridView spacing
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FoodDetailPage(foodItem: foodItem),
                                  ),
                                );
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // ── Header row ─────────────────────
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color.fromARGB(
                                              255, 0, 148, 68,
                                            ).withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.restaurant,
                                            color: Color.fromARGB(
                                              255, 0, 148, 68,
                                            ),
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                foodItem.name,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.black87,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Kode: ${foodItem.code}',
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
                                    const Spacer(), // Mendorong konten gizi ke bawah

                                    // ── Nutrition summary row ───────────
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        _buildNutritionInfo(
                                          'Energi',
                                          '${foodItem.calories.toStringAsFixed(0)} kkal',
                                          Icons.local_fire_department,
                                          Colors.orange,
                                        ),
                                        _buildNutritionInfo(
                                          'Protein',
                                          '${foodItem.protein.toStringAsFixed(1)} g',
                                          Icons.egg,
                                          Colors.blue,
                                        ),
                                        _buildNutritionInfo(
                                          'Lemak',
                                          '${foodItem.fat.toStringAsFixed(1)} g',
                                          Icons.water_drop,
                                          Colors.red,
                                        ),
                                        _buildNutritionInfo(
                                          'Serat',
                                          '${foodItem.fiber.toStringAsFixed(1)} g',
                                          Icons.grass,
                                          Colors.green,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // ── Meta row ───────────────────────
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Porsi: ${foodItem.portionGram}g',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Flexible(
                                          child: Text(
                                            foodItem.kelompokMakanan,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Text(
                                          foodItem.mentahOlahan,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),

      // ── FAB (admin only) ───────────────────────────────────────────────
      floatingActionButton: RoleBuilder(
        requiredRole: 'admin',
        builder: (context) {
          return FloatingActionButton(
            key: const Key('btn_add_food'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddFoodItemPage(),
                ),
              );
            },
            backgroundColor: const Color.fromARGB(255, 0, 148, 68),
            child: const Icon(Icons.add, color: Colors.white),
          );
        },
      ),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────

 Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Memberikan background putih
        borderRadius: BorderRadius.circular(12), // Membuat sudut membulat
        boxShadow: [
          // Menambahkan bayangan halus agar sama dengan tombol filter
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        key: const Key('field_search'),
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari makanan...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  key: const Key('btn_clear_search'),
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          border: InputBorder.none, // Menghilangkan garis bawah bawaan TextField
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14, // Padding tetap agar tidak terlalu gemuk
          ),
        ),
        style: const TextStyle(fontSize: 16),
      ),
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
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}