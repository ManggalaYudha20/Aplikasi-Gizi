import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';

void main() {
  group('Weight for Height (BB/TB) Calculation Tests', () {
    test('Weight for Height - 75cm boy', () {
      final referenceData = NutritionStatusData.bbPbTbUBoys;
      
      // Find closest height (75cm)
      int closestHeight = 0;
      double minDiff = double.infinity;
      
      for (final height in referenceData.keys) {
        final diff = (height - 75).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestHeight = height.toInt();
        }
      }
      
      expect(minDiff, lessThanOrEqualTo(1.0)); // Within 1cm tolerance
      
      final percentiles = referenceData[closestHeight]!;
      final median = percentiles[3];
      final sd = percentiles[4] - median;
      
      // Test with a sample weight
      final weight = 9.5; // kg
      final zScore = (weight - median) / sd;
      
      expect(median, greaterThan(0));
      expect(sd, greaterThan(0));
      expect(zScore, isA<double>());
      print('75cm boy - median: $median, sd: $sd, zScore: $zScore');
    });

    test('Weight for Height - 80cm girl', () {
      final referenceData = NutritionStatusData.bbPbTbUGirls;
      
      // Find closest height (80cm)
      int closestHeight = 0;
      double minDiff = double.infinity;
      
      for (final height in referenceData.keys) {
        final diff = (height - 80).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestHeight = height.toInt();
        }
      }
      
      expect(minDiff, lessThanOrEqualTo(1.0)); // Within 1cm tolerance
      
      final percentiles = referenceData[closestHeight]!;
      final median = percentiles[3];
      final sd = percentiles[4] - median;
      
      // Test with a sample weight
      final weight = 10.5; // kg
      final zScore = (weight - median) / sd;
      
      expect(median, greaterThan(0));
      expect(sd, greaterThan(0));
      expect(zScore, isA<double>());
      print('80cm girl - median: $median, sd: $sd, zScore: $zScore');
    });

    test('Weight for Height - Category classification', () {
      // Test category classification based on z-scores
      String getWeightForHeightCategory(double zScore) {
        if (zScore < -3) {
          return 'Gizi buruk';
        } else if (zScore >= -3 && zScore < -2) {
          return 'Gizi kurang';
        } else if (zScore >= -2 && zScore <= 1) {
          return 'Gizi baik';
        } else if (zScore > 1 && zScore <= 2) {
          return 'Berisiko gizi lebih';
        } else if (zScore > 2 && zScore <= 3) {
          return 'Gizi lebih';
        } else {
          return 'Obesitas';
        }
      }

      expect(getWeightForHeightCategory(-3.5), equals('Gizi buruk'));
      expect(getWeightForHeightCategory(-2.5), equals('Gizi kurang'));
      expect(getWeightForHeightCategory(0), equals('Gizi baik'));
      expect(getWeightForHeightCategory(1.5), equals('Berisiko gizi lebih'));
      expect(getWeightForHeightCategory(2.5), equals('Gizi lebih'));
      expect(getWeightForHeightCategory(3.5), equals('Obesitas'));
    });
  });
}