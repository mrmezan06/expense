import 'dart:convert';

import 'package:expense/pages/login_page.dart';
import 'package:expense/pages/summary_page.dart';
import 'package:expense/widgets/chart/chart.dart';
import 'package:expense/widgets/expenses_list/expenses_list.dart';
import 'package:expense/widgets/new_expense.dart';
import 'package:flutter/material.dart';
import 'package:expense/model/expense.dart';
import 'package:get/get.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() => _ExpensesState();
}

class _ExpensesState extends State<Expenses> {
  final List<Expense> _regExpenses = [
    // Expense(
    //   title: 'Eggs',
    //   amount: 40,
    //   date: DateTime.now(),
    //   category: Category.bazar,
    // ),
    // Expense(
    //   title: 'Chilly',
    //   amount: 15,
    //   date: DateTime.now(),
    //   category: Category.bazar,
    // ),
  ];

  var id;

  Category _categoryFinder(String category) {
    switch (category) {
      case 'income':
        return Category.income;
      case 'food':
        return Category.food;
      case 'bazar':
        return Category.bazar;
      case 'breakfast':
        return Category.breakfast;
      case 'shopping':
        return Category.shopping;
      case 'health':
        return Category.health;
      case 'entertainment':
        return Category.entertainment;
      case 'cigarette':
        return Category.cigarette;
      case 'rent':
        return Category.rent;
      case 'utility':
        return Category.utility;
      case 'wifi':
        return Category.wifi;
      case 'travel':
        return Category.travel;
      case 'fuel':
        return Category.fuel;
      case 'other':
        return Category.other;
      default:
        return Category.other;
    }
  }

  void loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    id = prefs.getString('_id');
    if (id == null) {
      Get.to(() => LoginPage(), transition: Transition.leftToRight);
    } else {
      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // print(id);
      final response = await getBalanceList(id);
      if (response.statusCode == 200) {
        final expenses = jsonDecode(response.body);
        // add the jsonArray to _regExpenses
        for (var expense in expenses) {
          // create a new expense object
          Expense expenseObj = Expense(
            id: expense['_id'],
            title: expense['title'],
            amount: expense['amount'].toString(),
            date: DateTime.parse(expense['date']),
            category: _categoryFinder(expense['category']),
          );
          // add the expense object to _regExpenses
          setState(() {
            _regExpenses.add(expenseObj);
          });
        }
      } else {
        var message = jsonDecode(response.body)['message'];
        Get.snackbar('Error', message,
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    }
    // Hide loading indicator
    Get.back();
  }

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void _addExpense(Expense expense) async {
    // _regExpenses.add(expense);

    // First of all server call to add expense
    // Then if successfull then add to _regExpenses to the list of the response

    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    // _regExpenses encode to json then store in shared preferences
    final response = await addBalance(
      id,
      expense.title,
      expense.amount,
      expense.date,
      expense.category.name,
    );

    if (response.statusCode == 201) {
      final expense = jsonDecode(response.body);
      // add the jsonArray to _regExpenses
      // create a new expense object
      Expense expenseObj = Expense(
        id: expense['_id'],
        title: expense['title'],
        amount: expense['amount'].toString(),
        date: DateTime.parse(expense['date']),
        category: _categoryFinder(expense['category']),
      );
      // add the expense object to _regExpenses
      setState(() {
        _regExpenses.add(expenseObj);
      });
    } else {
      var message = jsonDecode(response.body)['message'];
      Get.snackbar('Error', message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }

    // Hide loading indicator
    Get.back();
  }

  void _openAddExpenseOverlay() {
    showModalBottomSheet(
        useSafeArea: true,
        context: context,
        isScrollControlled: true,
        builder: (context) => NewExpense(
              onAddExpense: _addExpense,
            ));
  }

  void _removeExpense(Expense expense) async {
    final expensIndex = _regExpenses.indexOf(expense);
    // setState(() {
    //   _regExpenses.remove(expense);
    // });

    // Clear previous snackbar if any
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        content: const Text('Expense removed successfully!'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // setState(() {
            //   _regExpenses.insert(expensIndex, expense);
            // });
            // Show loading indicator
            Get.dialog(
              const Center(
                child: CircularProgressIndicator(),
              ),
              barrierDismissible: false,
            );

            final response = await addBalance(
              id,
              expense.title,
              expense.amount,
              expense.date,
              expense.category.name,
            );

            if (response.statusCode == 201) {
              final expense = jsonDecode(response.body);
              // add the jsonArray to _regExpenses
              // create a new expense object
              Expense expenseObj = Expense(
                id: expense['_id'],
                title: expense['title'],
                amount: expense['amount'].toString(),
                date: DateTime.parse(expense['date']),
                category: _categoryFinder(expense['category']),
              );
              // add the expense object to _regExpenses
              setState(() {
                _regExpenses.insert(expensIndex, expenseObj);
              });
            } else {
              var message = jsonDecode(response.body)['message'];
              Get.snackbar('Error', message,
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white);
            }

            // Hide loading indicator
            Get.back();
          },
        ),
      ),
    );

    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    final response = await deleteBalance(expense.id);

    if (response.statusCode == 200) {
      setState(() {
        _regExpenses.remove(expense);
      });
    } else {
      var message = jsonDecode(response.body)['message'];
      Get.snackbar('Error', message,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);
    }

    // Hide loading indicator
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    // Find the total width of the screen
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    Widget mainContent = const Center(
      child: Text('No Expenses added yet!'),
    );

    if (_regExpenses.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _regExpenses,
        onRemoveExpense: _removeExpense,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Expense Tracker'),
        actions: [
          IconButton(
            onPressed: _openAddExpenseOverlay,
            icon: const Icon(Icons.add),
          )
        ],
      ),
      // Summary of Income and Expense in a month
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const SummaryPage(), transition: Transition.leftToRight);
        },
        child: const Icon(
          Icons.summarize,
          color: Color.fromARGB(255, 4, 76, 109),
        ),
      ),

      body: SafeArea(
        child: width < height
            ? Column(
                children: [
                  Chart(expenses: _regExpenses),
                  const SizedBox(
                    height: 10,
                  ),
                  mainContent
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 25,
                  ),
                  Expanded(
                    child: Chart(expenses: _regExpenses),
                  ),
                  mainContent,
                ],
              ),
      ),
    );
  }
}

// ignore: constant_identifier_names
const BASE_URL = 'https://expense-api-coma.onrender.com/api/v1';

getBalanceList(String id) async {
  const slag = '/balance/get-expense-list';

  final uri = Uri.parse(BASE_URL + slag);

  final response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{"_uid": id}));

  return response;
}

addBalance(String id, String title, String amount, DateTime date,
    String category) async {
  const slag1 = '/balance/add-expense';
  const slag2 = '/balance/add-income';

  final slag = category == 'income' ? slag2 : slag1;

  final uri = Uri.parse(BASE_URL + slag);

  final response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        "title": title,
        "amount": amount,
        "date": date.toIso8601String(),
        "category": category,
        "_uid": id,
      }));

  return response;
}

deleteBalance(String id) async {
  const slag = "/balance/delete-balance";

  final uri = Uri.parse(BASE_URL + slag);

  final response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        "_id": id,
      }));

  return response;
}
