import 'package:flutter/material.dart';

class WorkoutSession {
  final String id;
  final String title;
  final String description;
  final String duration;
  final int minutes;
  final String level;
  final String category;
  final int calories;
  final IconData icon;

  const WorkoutSession({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.minutes,
    required this.level,
    required this.category,
    required this.calories,
    required this.icon,
  });
}
