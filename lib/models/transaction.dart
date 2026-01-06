import 'package:flutter/material.dart';

class Transaction {
  int? id; // optional, for new transactions before DB insert
  double amount;
  String transactionType; // expense/income
  String? note;
  int accountId;
  int? categoryId;
  int? relatedTransactionId;
  DateTime date;
  final String categoryName;
  final int categoryIcon;
  Transaction({
    this.id,
    required this.amount,
    required this.transactionType,
    required this.accountId,
    required this.date,
    this.note,
    this.categoryId,
    this.relatedTransactionId,
    required this.categoryName,
    required this.categoryIcon,
  });

  // Conversions
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] as int?,
      amount: map['amount'] as double,
      transactionType: map['transaction_type'] as String,
      accountId: map['account_id'] as int,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      note: map['note'] as String?,
      categoryId: map['category_id'] as int?,
      relatedTransactionId: map['related_transaction_id'] as int?,
      categoryName: map['category_name'],
      categoryIcon: map['category_icon'],
    );
  }
  Icon get iconWidget {
    return Icon(IconData(categoryIcon, fontFamily: 'MaterialIcons'));
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'transaction_type': transactionType,
      'account_id': accountId,
      'date': date.millisecondsSinceEpoch,
      'note': note,
      'category_id': categoryId,
      'related_transaction_id': relatedTransactionId,
    };
  }
}
