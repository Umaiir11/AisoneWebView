import 'dart:async';

import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_wrapper.dart';
import 'package:untitled/Screen/URL.dart';

import 'Screen/Widget.dart';


void main() {
  runApp(new MaterialApp(
    home: new MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void initState() {
    super.initState();
    new Future.delayed(
        const Duration(seconds: 4),
            () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => URL(),
          ),
        ));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: URL()
    );
  }
}
