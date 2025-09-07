import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';

/// Constants for percentile indices to improve readability
class PercentileIndices {
  static const int p3 = 0;    // 3rd percentile
  static const int p10 = 1;   // 10th percentile
  static const int p25 = 2;   // 25th percentile
  static const int p50 = 3;   // 50th percentile (median)
  static const int p75 = 4;   // 75th percentile
  static const int p85 = 5;   // 85th percentile
  static const int p97 = 6;   // 97th percentile
}

/// Helper class for weight-for-height calculations
class WeightForHeightCalculator {
  /// Finds the closest height in the reference data within tolerance
  static double findClosestHeight(
    Map<double, List<double>> referenceData,
    double targetHeight, {
    double tolerance = 1.0,
  }) {
    if (referenceData.isEmpty) {
      throw ArgumentError('Reference data cannot be empty');
    }

    double closestHeight = referenceData.keys.first;
    double minDiff = (closestHeight - targetHeight).abs();

    for (final height in referenceData.keys) {
      final diff = (height - targetHeight).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestHeight = height;
      }
    }

    if (minDiff > tolerance) {
      throw StateError(
        'No height found within tolerance ${tolerance}cm of $targetHeight. '
        'Closest height is ${closestHeight}cm (diff: ${minDiff}cm)',
      );
    }

    return closestHeight;
  }

  /// Calculates Z-score for weight-for-height
  static double calculateZScore({
    required double weight,
    required double median,
    required double standardDeviation,
  }) {
    if (standardDeviation <= 0) {
      throw ArgumentError('Standard deviation must be positive');
    }
    return (weight - median) / standardDeviation;
  }

  /// Extracts statistical parameters from percentile data
  static Map<String, double> extractParameters(List<double> percentiles) {
    if (percentiles.length < 7) {
      throw ArgumentError('Percentiles array must have at least 7 elements');
    }

    final median = percentiles[PercentileIndices.p50];
    final sd = percentiles[PercentileIndices.p75] - median;

    return {
      'median': median,
      'standardDeviation': sd,
      'p3': percentiles[PercentileIndices.p3],
      'p97': percentiles[PercentileIndices.p97],
    };
  }
}

/// Test data class for better organization
class TestCase {
  final String description;
  final Map<double, List<double>> referenceData;
  final double targetHeight;
  final double testWeight;
  final String gender;

  const TestCase({
    required this.description,
    required this.referenceData,
    required this.targetHeight,
    required this.testWeight,
    required this.gender,
  });
}

void main() {
  group('Weight for Height (BB/TB) Calculation Tests', () {
    // Test cases with meaningful descriptions
    final testCases = [
      TestCase(
        description: '75cm boy with 9.5kg weight',
        referenceData: NutritionStatusData.bbPbTbUBoys,
        targetHeight: 75.0,
        testWeight: 9.5,
        gender: 'boy',
      ),
      TestCase(
        description: '80cm girl with 10.5kg weight',
        referenceData: NutritionStatusData.bbPbTbUGirls,
        targetHeight: 80.0,
        testWeight: 10.5,
        gender: 'girl',
      ),
    ];

    for (final testCase in testCases) {
      test('Weight for Height - ${testCase.description}', () {
        // Find closest height with proper error handling
        final closestHeight = WeightForHeightCalculator.findClosestHeight(
          testCase.referenceData,
          testCase.targetHeight,
        );

        // Extract percentiles with validation
        final percentiles = testCase.referenceData[closestHeight];
        expect(percentiles, isNotNull,
            reason:
                'Percentiles data should exist for height ${closestHeight}cm');

        // Calculate statistical parameters
        final parameters =
            WeightForHeightCalculator.extractParameters(percentiles!);

        // Validate parameters
        expect(parameters['median'], greaterThan(0.0),
            reason: 'Median weight should be positive');
        expect(parameters['standardDeviation'], greaterThan(0.0),
            reason: 'Standard deviation should be positive');

        // Calculate Z-score
        final zScore = WeightForHeightCalculator.calculateZScore(
          weight: testCase.testWeight,
          median: parameters['median']!,
          standardDeviation: parameters['standardDeviation']!,
        );

        // Comprehensive assertions
        expect(zScore, isA<double>());
        expect(zScore.isFinite, isTrue,
            reason: 'Z-score should be a finite number');

        // Log results with context
        /*
        
        print(
          '${testCase.targetHeight}cm ${testCase.gender} - '
          'median: ${parameters['median']!.toStringAsFixed(2)}, '
          'sd: ${parameters['standardDeviation']!.toStringAsFixed(2)}, '
          'zScore: ${zScore.toStringAsFixed(2)}',
        );
        
        */

        // Additional validation: Z-score should be within reasonable bounds
        expect(zScore.abs(), lessThanOrEqualTo(5.0),
            reason:
                'Z-score should be within reasonable bounds (±5) for test data');
      });
    }

    group('Weight for Height - Category classification', () {
      /// Enhanced category classification with input validation
      String getWeightForHeightCategory(double zScore) {
        // Input validation
        if (!zScore.isFinite) {
          throw ArgumentError('Z-score must be a finite number');
        }

        // Category classification with proper boundary handling
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

      test('should classify z-scores correctly', () {
        // Test boundary conditions and typical cases
        final testCases = [
          (-3.5, 'Gizi buruk'),
          (-3.0, 'Gizi kurang'), // Boundary test
          (-2.5, 'Gizi kurang'),
          (-2.0, 'Gizi baik'), // Boundary test
          (0.0, 'Gizi baik'),
          (1.0, 'Gizi baik'), // Boundary test
          (1.5, 'Berisiko gizi lebih'),
          (2.0, 'Berisiko gizi lebih'), // Boundary test - corrected
          (2.5, 'Gizi lebih'),
          (3.0, 'Gizi lebih'), // Boundary test - corrected
          (3.5, 'Obesitas'),
        ];

        for (final (zScore, expectedCategory) in testCases) {
          expect(
            getWeightForHeightCategory(zScore),
            equals(expectedCategory),
            reason: 'Z-score $zScore should be classified as $expectedCategory',
          );
        }
      });

      test('should handle edge cases', () {
        // Test error handling for invalid inputs
        expect(
          () => getWeightForHeightCategory(double.infinity),
          throwsArgumentError,
        );
        expect(
          () => getWeightForHeightCategory(double.nan),
          throwsArgumentError,
        );
      });
    });

    group('Weight for Height - Error handling', () {
      test('should handle empty reference data', () {
        expect(
          () => WeightForHeightCalculator.findClosestHeight({}, 75.0),
          throwsArgumentError,
        );
      });

      test('should handle missing height data', () {
        // Create test data with missing target height
        final sparseData = {
          45.0: [1.9, 2.0, 2.2, 2.4, 2.7, 3.0, 3.3],
          50.0: [2.4, 2.6, 2.9, 3.2, 3.5, 3.9, 4.3],
        };

        expect(
          () => WeightForHeightCalculator.findClosestHeight(
            sparseData,
            75.0,
            tolerance: 0.1, // Very strict tolerance
          ),
          throwsStateError,
        );
      });

      test('should handle invalid standard deviation', () {
        expect(
          () => WeightForHeightCalculator.calculateZScore(
            weight: 10.0,
            median: 5.0,
            standardDeviation: 0.0, // Invalid SD
          ),
          throwsArgumentError,
        );

        expect(
          () => WeightForHeightCalculator.calculateZScore(
            weight: 10.0,
            median: 5.0,
            standardDeviation: -1.0, // Invalid SD
          ),
          throwsArgumentError,
        );
      });
    });
  });
}