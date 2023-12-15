import 'dart:convert';

import 'package:expense/model/expense.dart';
import 'package:expense/pages/login_page.dart';
import 'package:expense/pages/summary_page.dart';
import 'package:expense/widgets/expenses.dart';
import 'package:expense/widgets/expenses_list/expenses_list.dart';
import 'package:expense/widgets/new_expense.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

final yMFormat = DateFormat.yM();

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final List<Expense> _regIncome = [];
  var _currentDate = DateTime.now();

  void _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(1960, now.month, now.day);
    final lastDate = DateTime(2060, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (pickedDate == null) {
      return;
    }
    setState(() {
      _currentDate = pickedDate;
    });
    loadIncome(_currentDate);
  }

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

  void loadIncome(DateTime date) {
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
        final response = await getIncomeList(id, date);
        if (response.statusCode == 200) {
          final incomeArray = jsonDecode(response.body);

          // Clear _regIncome
          setState(() {
            _regIncome.clear();
          });
          for (var expense in incomeArray) {
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

          // Clear loading indicator
          Get.back();
        } else if (response.statusCode == 404) {
          // Clear _regIncome
          setState(() {
            _regIncome.clear();
          });
          // Clear loading indicator
          Get.back();
        } else {
          // Hide loading indicator
          Get.back();
          var message = jsonDecode(response.body)['message'];
          Get.snackbar('Error', message,
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: Colors.red,
              colorText: Colors.white);
        }
      }
    });
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
              loadIncome(_currentDate);
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
      loadIncome(_currentDate);
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
      // Get the title of the expense
      final nExpense = jsonDecode(response.body);
// if its category is income then got to income page
      if (expense.category.name != 'income') {
        Get.back();
        Get.to(() => const Expenses(), transition: Transition.rightToLeft);
        return;
      }

      // create a new expense object
      Expense expenseObj = Expense(
        id: nExpense['_id'],
        title: nExpense['title'],
        amount: nExpense['amount'].toString(),
        date: DateTime.parse(nExpense['date']),
        category: _categoryFinder(nExpense['category']),
      );
      // add the expense object to _regExpenses
      setState(() {
        _regIncome.add(expenseObj);
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

  @override
  void initState() {
    super.initState();
    loadIncome(_currentDate);
  }

  @override
  Widget build(BuildContext context) {
    // Find the total width of the screen
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    Widget mainContent = const Center(
      child: Text('No Incomes added yet!'),
    );

    if (_regIncome.isNotEmpty) {
      mainContent = ExpensesList(
        expenses: _regIncome,
        onRemoveExpense: _removeIncome,
      );
    }
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Expense',
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.attach_money,
              color: Colors.white,
            ),
            label: 'Income',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.summarize),
            label: 'Summary',
          ),
        ],
        currentIndex: 1,
        selectedItemColor: Colors.amber[800],
        onTap: (index) {
          switch (index) {
            case 0:
              Get.to(() => const Expenses(),
                  transition: Transition.rightToLeft);
              break;
            case 1:
              break;
            case 2:
              Get.to(() => const SummaryPage(),
                  transition: Transition.leftToRight);
              break;
          }
        },
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Income Tracker'),
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
        onPressed: _openAddExpenseOverlay,
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 4, 76, 109),
        ),
      ),

      body: SafeArea(
        child: width < height
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(yMFormat.format(_currentDate)),
                      IconButton(
                        onPressed: _presentDatePicker,
                        icon: const Icon(
                          Icons.calendar_month,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(
                        width: 25,
                      ),
                      const Text(
                        'Incomes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(yMFormat.format(_currentDate)),
                            IconButton(
                              onPressed: _presentDatePicker,
                              icon: const Icon(
                                Icons.calendar_month,
                                color: Colors.blue,
                              ),
                            ),
                          ],
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

getIncomeList(String id, DateTime date) async {
  const slag = '/balance/get-income-list';

  final uri = Uri.parse(BASE_URL + slag);

  final response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(
          <String, String>{"_uid": id, "date": date.toIso8601String()}));

  return response;
}
