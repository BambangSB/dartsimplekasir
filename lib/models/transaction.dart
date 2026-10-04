import 'dart:convert';
import 'cart_item.dart';

class TransactionModel {
  final int? id;
  final String invoiceNumber;
  final DateTime dateTime;
  final double totalAmount;
  final double cashReceived;
  final double changeAmount;
  final String paymentMethod;
  final List<CartItem> items;

  TransactionModel({
    this.id,
    required this.invoiceNumber,
    required this.dateTime,
    required this.totalAmount,
    required this.cashReceived,
    required this.changeAmount,
    this.paymentMethod = 'Tunai',
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'dateTime': dateTime.toIso8601String(),
      'totalAmount': totalAmount,
      'cashReceived': cashReceived,
      'changeAmount': changeAmount,
      'paymentMethod': paymentMethod,
      'itemsJson': jsonEncode(items.map((i) => i.toMap()).toList()),
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    List<CartItem> itemsList = [];
    if (map['itemsJson'] != null) {
      final List<dynamic> decoded = jsonDecode(map['itemsJson'] as String);
      itemsList = decoded.map((e) => CartItem.fromMap(e as Map<String, dynamic>)).toList();
    }

    return TransactionModel(
      id: map['id'] as int?,
      invoiceNumber: map['invoiceNumber'] as String,
      dateTime: DateTime.parse(map['dateTime'] as String),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      cashReceived: (map['cashReceived'] as num).toDouble(),
      changeAmount: (map['changeAmount'] as num).toDouble(),
      paymentMethod: map['paymentMethod'] as String? ?? 'Tunai',
      items: itemsList,
    );
  }
}
