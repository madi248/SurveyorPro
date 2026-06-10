import 'package:flutter/material.dart';

class CalculationItem {
  final String id;
  final String name;
  final String desc;
  final String? targetRoute; // GoRouter path
  final String? badge;

  const CalculationItem({
    required this.id,
    required this.name,
    required this.desc,
    this.targetRoute,
    this.badge,
  });
}

class CategoryData {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  final List<CalculationItem> items;

  const CategoryData({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.items,
  });
}

class CalcInputDef {
  final String key;
  final String label;
  final String type; // 'number', 'text', 'textarea', 'select'
  final List<Map<String, String>>? options;
  final String? placeholder;
  final String? defaultValue;

  const CalcInputDef({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.placeholder,
    this.defaultValue,
  });
}

class CalcDefinition {
  final String title;
  final List<CalcInputDef> inputs;
  final Map<String, dynamic> Function(Map<String, String>) calculate;
  final List<String> outputOrder;

  const CalcDefinition({
    required this.title,
    required this.inputs,
    required this.calculate,
    required this.outputOrder,
  });
}
