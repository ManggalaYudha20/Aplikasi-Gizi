import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/food_database/presentation/pages/food_list_models.dart';
import 'dart:convert';
import 'package:flutter/widgets.dart';

class FoodImportService {
  static Future<int> importFoodData() async {
    final ByteData csvData = await rootBundle.load('assets/TKPI 2019.csv');
    final String csvString = latin1.decode(csvData.buffer.asUint8List());

    final List<List<dynamic>> rowsAsListOfLists =
        const CsvToListConverter(fieldDelimiter: ';').convert(csvString);

    final CollectionReference foodCollection =
        FirebaseFirestore.instance.collection('food_items');

    num parseNum(dynamic value) {
      if (value == null || value.toString().trim().isEmpty || value.toString().contains('-')) {
        return 0;
      }
      String cleanedValue = value.toString().replaceAll('.', '');
      cleanedValue = cleanedValue.replaceAll(',', '.');
      return num.tryParse(cleanedValue) ?? 0;
    }

    final List<Map<String, dynamic>> foodItemsToUpload = [];

    for (var i = 4; i < rowsAsListOfLists.length; i++) {
      final row = rowsAsListOfLists[i];
      
      if (row.length < 28) continue;
      
      final nama = row[2]?.toString().trim();
      if (nama == null || nama.isEmpty) continue;

      try {
        final foodItem = FoodItem(
          code: row[1].toString().trim(),
          name: nama,
          mentahOlahan: row[25].toString().trim(),
          kelompokMakanan: row[26].toString().trim(),
          portionGram: parseNum(row[27]),
          air: parseNum(row[3]),
          calories: parseNum(row[4]),
          protein: parseNum(row[5]),
          fat: parseNum(row[6]),
          karbohidrat: parseNum(row[7]),
          fiber: parseNum(row[8]),
          abu: parseNum(row[9]),
          kalsium: parseNum(row[10]),
          fosfor: parseNum(row[11]),
          besi: parseNum(row[12]),
          natrium: parseNum(row[13]),
          kalium: parseNum(row[14]),
          tembaga: parseNum(row[15]),
          seng: parseNum(row[16]),
          retinol: parseNum(row[17]),
          betaKaroten: parseNum(row[18]),
          karotenTotal: parseNum(row[19]),
          thiamin: parseNum(row[20]),
          riboflavin: parseNum(row[21]),
          niasin: parseNum(row[22]),
          vitaminC: parseNum(row[23]),
          bdd: parseNum(row[24]),
        );
        foodItemsToUpload.add(foodItem.toFirestore());
      } catch (e) {
        debugPrint('Gagal memproses baris $i (${row[2]}): $e');
      }
    }

    int uploadedCount = 0;
    for (var i = 0; i < foodItemsToUpload.length; i += 500) {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      final endIndex = (i + 500 > foodItemsToUpload.length)
          ? foodItemsToUpload.length
          : i + 500;
      final batchItems = foodItemsToUpload.sublist(i, endIndex);

      for (var item in batchItems) {
        final docRef = foodCollection.doc();
        batch.set(docRef, item);
      }

      await batch.commit();
      uploadedCount += batchItems.length;
    }

    return uploadedCount;
  }
}