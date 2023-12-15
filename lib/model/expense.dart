import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

final formatter = DateFormat.yMd();

const uuid = Uuid();

enum Category {
  income,
  food,
  bazar,
  breakfast,
  shopping,
  health,
  entertainment,
  cigarette,
  rent,
  utility,
  wifi,
  travel,
  fuel,
  other
}

const categoryIcons = {
  Category.income: Icons.attach_money,
  Category.food: Icons.food_bank,
  Category.bazar: Icons.shopping_bag,
  Category.breakfast: Icons.breakfast_dining,
  Category.shopping: Icons.shopping_cart,
  Category.health: Icons.medical_services,
  Category.entertainment: Icons.movie,
  Category.cigarette: Icons.smoking_rooms,
  Category.rent: Icons.house,
  Category.utility: Icons.water,
  Category.wifi: Icons.wifi,
  Category.travel: Icons.flight,
  Category.fuel: Icons.local_gas_station,
  Category.other: Icons.money,
};

class Expense {
  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
  });

  final String id;
  final String title;
  final String amount;
  final DateTime date;
  final Category category;

  String get formattedDate {
    return formatter.format(date);
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['_id'],
      title: json['title'],
      amount: json['amount'].toString(),
      date: DateTime.parse(json['date']),
      category: Category.values[json['category']],
    );
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['_id'],
      title: map['title'],
      // int to double conversion
      amount: map['amount'].toString(),
      date: DateTime.parse(map['date']),
      category: Category.values[map['category']],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'amount': amount.toString(),
      'date': date.toIso8601String(),
      'category': category.index,
    };
  }
}

class ExpenseBucket {
  ExpenseBucket({
    required this.category,
    required this.expenses,
  });

  ExpenseBucket.forCategory(List<Expense> allExpense, this.category)
      : expenses = allExpense
            .where((expense) => expense.category == category)
            .toList();

  final Category category;
  final List<Expense> expenses;

  double get totalExpense {
    // Similar to the reduce() method in JavaScript
    return expenses.fold(
        0, (sum, expense) => sum + double.parse(expense.amount));
  }
}
