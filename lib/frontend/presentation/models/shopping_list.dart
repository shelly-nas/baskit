import 'package:flutter/material.dart';

class ShoppingList {
  final String name;
  final IconData icon;
  final int itemCount;
  final int completedItems;
  final bool isShared;
  final int? memberCount;

  ShoppingList({
    required this.name,
    required this.icon,
    required this.itemCount,
    this.completedItems = 0,
    this.isShared = false,
    this.memberCount,
  });

  double get completionPercentage {
    if (itemCount == 0) return 0.0;
    return completedItems / itemCount;
  }
}
