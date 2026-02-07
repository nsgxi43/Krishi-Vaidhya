import 'package:flutter/material.dart';

class CalendarEvent {
  final String titleKey; // For translation (e.g., 'activity_water')
  final String descriptionKey; // Description key
  final int daysAfterSowing; // When does this happen? (e.g., Day 10)
  final IconData icon;
  final Color color;

  CalendarEvent({
    required this.titleKey,
    required this.descriptionKey,
    required this.daysAfterSowing,
    required this.icon,
    required this.color,
  });
}