import 'package:flutter/material.dart';

class MeditationSession {
  final String title;
  final String description;
  final String duration;
  final int minutes;
  final IconData icon;

  const MeditationSession({
    required this.title,
    required this.description,
    required this.duration,
    required this.minutes,
    required this.icon,
  });
}
