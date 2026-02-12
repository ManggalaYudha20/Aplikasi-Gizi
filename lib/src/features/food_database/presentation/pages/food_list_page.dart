//lib\src\features\food_database\presentation\pages\food_list_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/app_bar.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_detail_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/add_food_item_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/role_builder.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/food_filter_model.dart';
import 'package:aplikasi_diagnosa_gizi/src/shared/widgets/food_filter_sheet.dart';

class FoodListPage extends StatefulWidget {
  const FoodListPage({super.key});

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  final TextEditingController _searchController = TextEditingController();
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
        return FoodFilterSheet(currentFilters: _activeFilters,
        onResetPressed: () {
            // Panggil fungsi yang me-reset state halaman home
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
    final bool isTablet = screenWidth > 600;
    final double horizontalPadding = isTablet ? 24.0 : 16.0;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: const CustomAppBar(
        title: 'Daftar Makanan',
        subtitle: 'Temukan informasi gizi makanan',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () =>
            FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 5),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                        label: 'Input pencarian makanan',
                        child: _buildSearchBar(),
                      ),
                  ),
                  const SizedBox(width: 8),
                  // Tombol Filter
                  Semantics(
                      label: 'Tombol filter makanan',
                      button: true,
                      child:
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha:0.1),
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
                      onPressed: () {
                        _showFilterModal(context);
                      },
                    ),
                  ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('food_items')
                    .orderBy('nama')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Tidak ada data makanan'));
                  }

                  final filteredDocs = snapshot.data!.docs.where((doc) {
                    final foodItem = FoodItem.fromFirestore(
                      doc as DocumentSnapshot<Map<String, dynamic>>,
                    );
                    
                    // 1. Logika Search
                    final searchQueryLower = _searchQuery.toLowerCase();
                    final bool matchesSearch = foodItem.name.toLowerCase().contains(searchQueryLower) ||
                           foodItem.code.toLowerCase().contains(searchQueryLower);
                    
                    // 2. Logika Filter
                    final bool matchesFilter = _activeFilters.matches(foodItem);

                    return matchesSearch && matchesFilter;
                  }).toList();

                  if (filteredDocs.isEmpty && _searchQuery.isNotEmpty) {
                    return Center(
                      child: Text('Tidak ada hasil untuk "$_searchQuery"'),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.all(horizontalPadding),
                    itemCount: filteredDocs.length,
                    itemBuilder: (context, index) {
                      final doc = filteredDocs[index];
                      final foodItem = FoodItem.fromFirestore(
                        doc as DocumentSnapshot<Map<String, dynamic>>,
                      );
                      final String itemKey = 'card_item_${foodItem.id.isNotEmpty ? foodItem.id : index}';

                      return Semantics(
                          label: 'Kartu makanan ${foodItem.name}',
                          button: true,
                          child:
                          Card(
                          key: Key(itemKey),
                        margin: const EdgeInsets.only(bottom: 12),
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ... (kode tampilan item list tetap sama) ...
                                Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(
                                          255,
                                          0,
                                          148,
                                          68,
                                        ).withValues(alpha: 0.1),
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            foodItem.name,
                                            style: TextStyle(
                                              fontSize: isTablet ? 18 : 16,
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
                                const SizedBox(height: 12),
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
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    Text(
                                      'Porsi: ${foodItem.portionGram} gram',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Kategori: ${foodItem.kelompokMakanan}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Status: ${foodItem.mentahOlahan}',
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
      // --- TAMBAHKAN TOMBOL INI UNTUK CREATE DATA ---
      floatingActionButton: RoleBuilder(
        requiredRole: 'admin', // Ganti 'isAhliGizi' menjadi cek role 'admin'
        builder: (context) {
          // Widget ini hanya akan dibuat jika role-nya adalah 'admin'
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
            ); // Jika bukan ahli gizi, tombol tidak akan tampil
        },
      ),
    );
  }

  // ... (kode _buildSearchBar dan _buildNutritionInfo tetap sama) ...
  Widget _buildSearchBar() {
    return Container(
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
                  onPressed: () {
                    _searchController.clear();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
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
