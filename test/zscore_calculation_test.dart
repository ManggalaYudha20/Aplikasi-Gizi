import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';

void main() {
  group('Z-score Calculation Tests', () {
    test('Weight for Age - 12 month boy', () {
      final referenceData = NutritionStatusData.bbUBoys;
      expect(referenceData.containsKey(12), isTrue);
      
      final percentiles = referenceData[12]!;
      final median = percentiles[3];
      final sd = percentiles[4] - median;
      final zScore = (9.5 - median) / sd;
      
      expect(median, greaterThan(0));
      expect(sd, greaterThan(0));
      expect(zScore, isA<double>());
    });

    test('Height for Age - 24 month girl', () {
      final referenceData = NutritionStatusData.pbTbUGirls;
      expect(referenceData.containsKey(24), isTrue);
      
      final percentiles = referenceData[24]!;
      final median = percentiles[3];
      final sd = percentiles[4] - median;
      final zScore = (82.0 - median) / sd;
      
      expect(median, greaterThan(0));
      expect(sd, greaterThan(0));
      expect(zScore, isA<double>());
    });

    test('BMI for Age - 18 month boy', () {
      final referenceData = NutritionStatusData.imtUBoys;
      expect(referenceData.containsKey(18), isTrue);
      
      final percentiles = referenceData[18]!;
      final median = percentiles[3];
      final sd = percentiles[4] - median;
      final zScore = (16.5 - median) / sd;
      
      expect(median, greaterThan(0));
      expect(sd, greaterThan(0));
      expect(zScore, isA<double>());
    });
  });
}