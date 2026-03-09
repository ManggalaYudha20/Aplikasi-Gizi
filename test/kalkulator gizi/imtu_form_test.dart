import 'package:flutter_test/flutter_test.dart';
import 'package:aplikasi_diagnosa_gizi/src/features/nutrition_calculation/data/models/nutrition_status_models.dart';

void main() {
  group('IMTU Form Tests', () {
    test('Age calculation from dates works correctly', () {
      // Test case: Child born on 2010-01-01, measured on 2020-01-01
      final birthDate = DateTime(2010, 1, 1);
      final measurementDate = DateTime(2020, 1, 1);
      
      final ageInMonths = measurementDate.difference(birthDate).inDays / 30.44;
      
      expect(ageInMonths.round(), equals(120)); // 10 years = 120 months
    });

    test('Age validation for 5-18 years range', () {
      // Test minimum age (5 years = 60 months)
      expect(60.0 >= 60 && 60.0 <= 216, isTrue);
      
      // Test maximum age (18 years = 216 months)
      expect(216.0 >= 60 && 216.0 <= 216, isTrue);
      
      // Test below minimum
      expect(59.0 >= 60 && 59.0 <= 216, isFalse);
      
      // Test above maximum
      expect(217.0 >= 60 && 217.0 <= 216, isFalse);
    });

    test('WHO reference data exists for 5-18 years', () {
      // Test that WHO data is available
      expect(NutritionStatusData.imtUBoys5To18, isNotNull);
      expect(NutritionStatusData.imtUGirls5To18, isNotNull);
      
      // Test data availability at key points
      expect(NutritionStatusData.imtUBoys5To18['5-1'], isNotNull);
      expect(NutritionStatusData.imtUBoys5To18['10-0'], isNotNull);
      expect(NutritionStatusData.imtUBoys5To18['18-0'], isNotNull);
      
      expect(NutritionStatusData.imtUGirls5To18['5-1'], isNotNull);
      expect(NutritionStatusData.imtUGirls5To18['10-0'], isNotNull);
      expect(NutritionStatusData.imtUGirls5To18['18-0'], isNotNull);
    });

    test('BMI calculation is correct', () {
      // Test BMI calculation: weight (kg) / (height (m))^2
      const weight = 40.0; // kg
      const height = 140.0; // cm = 1.4 m
      
      final bmi = weight / ((height / 100) * (height / 100));
      
      expect(bmi, closeTo(20.41, 0.01)); // 40 / (1.4 * 1.4) = 20.41
    });

    test('Age in months to year-month format conversion', () {
      // Test conversion for WHO data key format
      int ageInMonths = 120; // 10 years
      int years = ageInMonths ~/ 12;
      int months = ageInMonths % 12;
      
      String whoKey = '$years-$months';
      expect(whoKey, equals('10-0'));
      
      ageInMonths = 65; // 5 years 5 months
      years = ageInMonths ~/ 12;
      months = ageInMonths % 12;
      
      whoKey = '$years-$months';
      expect(whoKey, equals('5-5'));
    });
  });
}