import 'package:flutter/material.dart';

class CropItem {
  final String nameKey;
  final String imagePath; // Changed from 'IconData icon' to 'String imagePath'
  final Color color;      // Background color for the card
  bool isSelected;

  CropItem({
    required this.nameKey,
    required this.imagePath,
    required this.color,
    this.isSelected = false,
  });
}