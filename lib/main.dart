import 'package:flutter/material.dart';
import 'package:test_ml/home.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ML Demo',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        accentColor: Colors.blue,
        floatingActionButtonTheme: FloatingActionButtonThemeData(backgroundColor: Colors.blue)
      ),
      home: MyHomePage(title: 'Flutter ML Demo'),
    );
  }
}