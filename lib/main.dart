// File: lib/main.dart

import 'package:flutter/material.dart';
import 'screens/man_hinh_chinh.dart'; // Import màn hình chính

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Gọi ManHinhChinh ở đây. 
      // ManHinhChinh nằm BÊN TRONG MaterialApp => Dùng được Navigator.
      home: ManHinhChinh(), 
    );
  }
}