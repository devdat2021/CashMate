import 'package:flutter/material.dart';

class Account {
  final int? id;
  final String name;
  final double balance;
  final int iconCode;

  Account({
    this.id,
    required this.name,
    required this.balance,
    required this.iconCode,
  });

  Icon get iconWidget {
    return Icon(IconData(iconCode, fontFamily: 'MaterialIcons'));
  }

  Map<String, dynamic> toMap() {
    //for insertion and updation
    return {
      'id': id,
      'name': name,
      'current_balance': balance,
      //'icon_code': iconCode, setdefault for now
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as int,
      name: map['name'] as String,
      balance: map['current_balance'] as double,
      iconCode: map['icon_code'] as int,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Account && runtimeType == other.runtimeType && id == other.id; // Compare by ID, not memory address!

  @override
  int get hashCode => id.hashCode;
}
