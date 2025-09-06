import 'package:flutter/material.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/add_leaflet_page.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/pdf_leaflets/presentation/pages/leaflet_list_model.dart';

class EditLeafletService {
  static Future<bool?> showEditPage(BuildContext context, Leaflet leaflet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLeafletPage(leaflet: leaflet),
      ),
    );
    
    // Return true if the edit was successful (user saved changes)
    return result == true;
  }
}