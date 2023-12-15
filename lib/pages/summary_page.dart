import 'dart:convert';

import 'package:expense/model/expense.dart';
import 'package:expense/pages/login_page.dart';
import 'package:expense/widgets/expenses.dart';
import 'package:expense/widgets/expenses_list/expenses_list.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final List<Expense> _regIncome = [];

  var _totalIncome = 0.0;
  var _totalExpense = 0.0;
  var _currentMonthIncome = 0.0;
  var _currentMonthExpense = 0.0;
  var _currentMonth = DateTime.now().month;

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

  void loadSummary() {
    SharedPreferences.getInstance().then((prefs) async {
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
        final response = await getSummary(id);
        if (response.statusCode == 200) {
          final summary = jsonDecode(response.body);
          // add the jsonArray to _regExpenses
          setState(() {
            _totalIncome = double.parse(summary['income']);
            _totalExpense = double.parse(summary['expense']);
            _currentMonthIncome = double.parse(summary['currentMonthIncome']);
            _currentMonthExpense = double.parse(summary['currentMonthExpense']);
          });
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
    });
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
            _regIncome.add(expenseObj);
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

  void _removeIncome(Expense expense) async {
    final expensIndex = _regIncome.indexOf(expense);
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
                _regIncome.insert(expensIndex, expenseObj);
              });
              // Load summary again
              loadSummary();
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
        _regIncome.remove(expense);
      });
      // Load summary again
      loadSummary();
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

  void loadSummaryByMonth(int month) async {
    // Show loading indicator
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    // print(id);
    final response = await getSummaryByMonth(id, month);
    if (response.statusCode == 200) {
      final summary = jsonDecode(response.body);
      // add the jsonArray to _regExpenses
      setState(() {
        _currentMonthIncome = double.parse(summary['income']);
        _currentMonthExpense = double.parse(summary['expense']);
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
  void initState() {
    super.initState();
    loadData();
    loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    // Find the total width of the screen
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    Widget mainContent = const Center(
      child: Text('No Expenses added yet!'),
    );

    if (_regIncome.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _regIncome,
        onRemoveExpense: _removeIncome,
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Summary of Expenses'),
        actions: [
          IconButton(
            onPressed: () {
              // Clear the shared preferences
              SharedPreferences.getInstance().then((prefs) {
                prefs.remove('_id');
              });
              Get.to(() => LoginPage(), transition: Transition.leftToRight);
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      // Summary of Income and Expense in a month
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => const Expenses(), transition: Transition.rightToLeft);
        },
        child: const Icon(
          Icons.attach_money,
          color: Color.fromARGB(255, 4, 76, 109),
        ),
      ),

      body: SafeArea(
        child: width < height
            ? Column(
                children: [
                  // Month Dropdown
                  DropdownMenu(
                    initialSelection: _currentMonth,
                    onSelected: (value) {
                      setState(() {
                        _currentMonth = value ?? _currentMonth;
                      });
                      loadSummaryByMonth(_currentMonth);
                    },
                    dropdownMenuEntries: const [
                      DropdownMenuEntry(value: 1, label: 'January'),
                      DropdownMenuEntry(value: 2, label: 'February'),
                      DropdownMenuEntry(value: 3, label: 'March'),
                      DropdownMenuEntry(value: 4, label: 'April'),
                      DropdownMenuEntry(value: 5, label: 'May'),
                      DropdownMenuEntry(value: 6, label: 'June'),
                      DropdownMenuEntry(value: 7, label: 'July'),
                      DropdownMenuEntry(value: 8, label: 'August'),
                      DropdownMenuEntry(value: 9, label: 'September'),
                      DropdownMenuEntry(value: 10, label: 'October'),
                      DropdownMenuEntry(value: 11, label: 'November'),
                      DropdownMenuEntry(value: 12, label: 'December'),
                    ],
                  ),
                  _buildSummaryCard(
                    totalIncome: _totalIncome,
                    totalExpense: _totalExpense,
                    currentMonthIncome: _currentMonthIncome,
                    currentMonthExpense: _currentMonthExpense,
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  const Text(
                    'Income List',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
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
                    child: Column(
                      children: [
                        // Month Dropdown
                        DropdownMenu(
                          initialSelection: _currentMonth,
                          onSelected: (value) {
                            setState(() {
                              _currentMonth = value ?? _currentMonth;
                            });
                            loadSummaryByMonth(_currentMonth);
                          },
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: 1, label: 'January'),
                            DropdownMenuEntry(value: 2, label: 'February'),
                            DropdownMenuEntry(value: 3, label: 'March'),
                            DropdownMenuEntry(value: 4, label: 'April'),
                            DropdownMenuEntry(value: 5, label: 'May'),
                            DropdownMenuEntry(value: 6, label: 'June'),
                            DropdownMenuEntry(value: 7, label: 'July'),
                            DropdownMenuEntry(value: 8, label: 'August'),
                            DropdownMenuEntry(value: 9, label: 'September'),
                            DropdownMenuEntry(value: 10, label: 'October'),
                            DropdownMenuEntry(value: 11, label: 'November'),
                            DropdownMenuEntry(value: 12, label: 'December'),
                          ],
                        ),
                        Expanded(
                          child: _buildSummaryCard(
                            totalIncome: _totalIncome,
                            totalExpense: _totalExpense,
                            currentMonthIncome: _currentMonthIncome,
                            currentMonthExpense: _currentMonthExpense,
                          ),
                        ),
                      ],
                    ),
                  ),
                  mainContent,
                ],
              ),
      ),
    );
  }
}

Widget _buildSummaryCard(
        {required double totalIncome,
        required double totalExpense,
        required double currentMonthIncome,
        required double currentMonthExpense}) =>
    Card(
      elevation: 5,
      child: Container(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Income',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "৳ $totalIncome",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Expense',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "৳ $totalExpense",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Month Income',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "৳ $currentMonthIncome",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Current Month Expense',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "৳ $currentMonthExpense",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // Add a divider
            const Divider(
              thickness: 1,
            ),
            // Available Balance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Available Balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "৳ ${totalIncome - totalExpense}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

// ignore: constant_identifier_names
const BASE_URL = 'https://expense-api-coma.onrender.com/api/v1';

getBalanceList(String id) async {
  const slag = '/balance/get-income-list';

  final uri = Uri.parse(BASE_URL + slag);

  final response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{"_uid": id}));

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

getSummary(String id) async {
  const slag = '/balance/get-summary';

  final uri = Uri.parse(BASE_URL + slag);

  final response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{"_uid": id}));

  return response;
}

getSummaryByMonth(String id, int month) async {
  const slag = '/balance/get-summary-by-month';

  final uri = Uri.parse(BASE_URL + slag);

  final response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{
        "_uid": id,
        "month": month.toString(),
      }));

  return response;
}
