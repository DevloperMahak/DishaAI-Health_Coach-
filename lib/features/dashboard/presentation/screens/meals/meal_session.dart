import 'package:flutter/material.dart';

class MealSession {
  final String id;
  final String name;
  final String description;
  final String mealType;

  final String calories;
  final String protein;
  final String carbs;
  final String fat;

  final String servingSize;
  final String preparationTime;
  final String difficulty;

  final String imageUrl;
  final IconData icon;

  final List<String> ingredients;
  final List<String> benefits;

  final bool isRecommended;

  const MealSession({
    required this.id,
    required this.name,
    required this.description,
    required this.mealType,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
    required this.preparationTime,
    required this.difficulty,
    required this.imageUrl,
    required this.icon,
    required this.ingredients,
    required this.benefits,
    this.isRecommended = false,
  });
}
