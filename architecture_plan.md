# Nutrition Diagnosis Application Architecture Plan

## Application Overview
This is a nutrition diagnosis application designed specifically for nutritionists to calculate and assess patient nutritional needs. The app will include features for calculating nutrition requirements for specific diseases, a food exchange list database, and informational PDF leaflets.

## Key Features
1. **Disease-Specific Nutrition Calculation**
   - Support for at least one specific disease initially with potential for expansion
   - Common nutrition formulas: BMI, Benedict Harris, TDEE, BMR, etc.

2. **Food Exchange List Database**
   - Database of food items with nutritional values
   - Information includes food name, food code, carbohydrates, protein, etc.

3. **PDF Leaflets**
   - Static PDF documents provided by the developer
   - Informational content for nutritionists and patients

4. **Navigation**
   - Bottom navigation bar with three main sections:
     - Home (Beranda)
     - Nutrition Information (Info Gizi)
     - About Us (Tentang Kami)

## Folder Structure Architecture

```
lib/
├── main.dart
├── src/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart
│   │   │   ├── app_strings.dart
│   │   │   └── app_styles.dart
│   │   ├── utils/
│   │   │   ├── calculator_utils.dart
│   │   │   └── file_utils.dart
│   │   └── services/
│   │       ├── database_service.dart
│   │       └── pdf_service.dart
│   ├── features/
│   │   ├── home/
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   └── home_page.dart
│   │   │   │   └── widgets/
│   │   │   │       └── home_widgets.dart
│   │   │   └── domain/
│   │   │       └── entities/
│   │   │           └── home_entity.dart
│   │   ├── nutrition_calculation/
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   ├── disease_calculation_page.dart
│   │   │   │   │   └── formula_calculation_page.dart
│   │   │   │   └── widgets/
│   │   │   │       └── calculation_widgets.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   ├── disease_entity.dart
│   │   │   │   │   └── nutrition_formula_entity.dart
│   │   │   │   └── usecases/
│   │   │   │       └── calculate_nutrition_usecase.dart
│   │   │   └── data/
│   │   │       ├── models/
│   │   │       │   ├── disease_model.dart
│   │   │       │   └── nutrition_formula_model.dart
│   │   │       └── repositories/
│   │   │           └── nutrition_repository_impl.dart
│   │   ├── food_database/
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   └── food_list_page.dart
│   │   │   │   └── widgets/
│   │   │   │       └── food_item_widget.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── food_entity.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── food_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       └── get_food_list_usecase.dart
│   │   │   └── data/
│   │   │       ├── models/
│   │   │       │   └── food_model.dart
│   │   │       └── repositories/
│   │   │           └── food_repository_impl.dart
│   │   ├── pdf_leaflets/
│   │   │   ├── presentation/
│   │   │   │   ├── pages/
│   │   │   │   │   └── leaflet_viewer_page.dart
│   │   │   │   └── widgets/
│   │   │   │       └── pdf_widgets.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── leaflet_entity.dart
│   │   │   │   └── usecases/
│   │   │   │       └── get_leaflet_usecase.dart
│   │   │   └── data/
│   │   │       └── repositories/
│   │   │           └── leaflet_repository_impl.dart
│   │   └── about/
│   │       └── presentation/
│   │           └── pages/
│   │               └── about_page.dart
│   └── shared/
│       ├── widgets/
│       │   ├── custom_app_bar.dart
│       │   ├── custom_bottom_navbar.dart
│       │   └── custom_button.dart
│       └── theme/
│           └── app_theme.dart
└── routes/
    ├── app_routes.dart
    └── route_generator.dart
```

## Architecture Pattern
The application will follow a Clean Architecture pattern with separation of concerns:

1. **Presentation Layer**: Contains UI components, pages, and widgets
2. **Domain Layer**: Contains business logic, use cases, and entities
3. **Data Layer**: Contains data models, repositories, and data sources

## Technology Stack
- Flutter SDK for cross-platform development
- Dart programming language
- SQLite for local food database storage
- PDF viewer plugin for displaying leaflets
- State management using Provider or Riverpod

## UI/UX Design Approach
- Minimalist and clean design inspired by healthcare applications
- Focus on functionality for measuring and displaying nutrition diagnosis
- Intuitive navigation with bottom navigation bar
- Clear data visualization for nutrition calculations

## Implementation Roadmap
1. Setup project structure and basic navigation
2. Implement the food database feature
3. Develop nutrition calculation functionality
4. Integrate PDF leaflet viewer
5. Create About Us page
6. Testing and refinement
7. Final deployment preparation

## Future Enhancements
- Expand disease-specific calculation features
- Add patient data management
- Implement cloud synchronization
- Add more advanced reporting features