import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

import 'package:universal_html/html.dart' hide Text;

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 72, 144),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.all(32.0),
              child: const Text('ENS492 Project - 26258'),
            ),
            Image.asset(
              'assets/sabanci_logo.jpg',
              fit: BoxFit.contain,
              height: 40,
            ),
          ],
        ),
      ),
      body: Container(
        width: size.width,
        height: size.height,
        padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: size.height * 0.2,
            bottom: size.height * 0.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Welcome",
                style: TextStyle(
                  fontSize: 30,
                  color: Color.fromARGB(255, 0, 72, 144),
                ),
                textAlign: TextAlign.center),
            const Text(
              "Sign in with Google",
              style: TextStyle(
                fontSize: 25,
                color: Color.fromARGB(255, 0, 72, 144),
              ),
            ),
            GestureDetector(
              onTap: () {
                AuthService().signInWithGoogle();
              },
              child: const Image(
                width: 60,
                image: AssetImage('assets/google.png'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
