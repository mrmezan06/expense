import 'dart:convert';

import 'package:expense/model/user.dart';
import 'package:expense/widgets/expenses.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:expense/components/my_button.dart';
import 'package:expense/components/my_textfield.dart';
import 'package:expense/pages/login_page.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatelessWidget {
  RegisterPage({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  void _registerUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Get.snackbar('Error', 'Please fill all the fields',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);

      return;
    }

    if (password != confirmPassword) {
      Get.snackbar('Error', 'Password and Confirm Password does not match',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white);

      return;
    }

    // show loading indicator
    Get.dialog(const Center(child: CircularProgressIndicator()),
        barrierDismissible: false);

    final response = await registerUser(email, password);

    if (response.statusCode == 201) {
      final user = User.fromJson(jsonDecode(response.body));
      prefs.setString('_id', user.id);
      // hide loading indicator

      Get.to(() => const Expenses(), transition: Transition.rightToLeft);
    } else {
      var message = jsonDecode(response.body)['message'];
      Get.snackbar(
        'Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }

    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                const Icon(Icons.lock, size: 100),
                const SizedBox(height: 50),
                Text(
                  'Welcome to Expense Tracker',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: emailController,
                  hintText: 'Email Address',
                  obscureText: false,
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: passwordController,
                  hintText: 'Password',
                  obscureText: true,
                ),
                const SizedBox(height: 25),
                MyTextField(
                  controller: confirmPasswordController,
                  hintText: 'Confirm Password',
                  obscureText: true,
                ),
                const SizedBox(height: 25),
                MyButton(
                  'Sign Up',
                  onTap: _registerUser,
                ),
                const SizedBox(height: 50),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Get.to(() => LoginPage(),
                            transition: Transition.leftToRight);
                      },
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ignore: constant_identifier_names
const BASE_URL = 'https://expense-api-coma.onrender.com/api/v1';

registerUser(String email, String password) async {
  const slag = '/user/register';

  final uri = Uri.parse(BASE_URL + slag);

  final response = await http.post(uri,
      headers: <String, String>{
        'Content-Type': 'application/json',
      },
      body: jsonEncode(<String, String>{'email': email, 'password': password}));

  return response;
}
