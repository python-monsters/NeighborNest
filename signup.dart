import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final auth = FirebaseAuth.instance;
  String errorMessage = "";

  Future<void> signup() async {
    try {
      await auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => errorMessage = "Signup failed: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase Signup')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          TextField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Password'),
          ),
          SizedBox(height: 16),
          ElevatedButton(onPressed: signup, child: Text("Sign Up")),
          if (errorMessage.isNotEmpty)
            Text(errorMessage, style: TextStyle(color: Colors.red)),
        ]),
      ),
    );
  }
}

