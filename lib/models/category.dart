// class Category {
//   final int? id;
//   final int iconCode;
//   final String name;
//   final double? budget;

//   Category({this.id, required this.iconCode, required this.name, this.budget});
// }
import 'package:flutter/material.dart';

class Category {
  final int? id;
  final int iconCode;
  final String name;
  final String type; //Expense/income
  final double budget;

  Category({
    this.id,
    required this.iconCode,
    required this.name,
    required this.type,
    this.budget = 0.0, // Set default for budget
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'budget_limit': budget,
      'icon_code': iconCode,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as int,
      name: map['name'] as String,
      type: map['type'] as String,
      iconCode: map['icon_code'] as int,
      budget: map['budget_limit'] as double,
    );
  }

  Icon get iconWidget {
    return Icon(IconData(iconCode, fontFamily: 'MaterialIcons'));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category && runtimeType == other.runtimeType && id == other.id; // Compare by ID, not memory address!

  @override
  int get hashCode => id.hashCode;
}
