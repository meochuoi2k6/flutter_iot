// File: lib/main.dart

import 'package:flutter/material.dart';
import 'screens/man_hinh_chinh.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ManHinhChinh(), 
    );
  }
}