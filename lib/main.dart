import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/beranda_page.dart';
import 'viewmodels/catatan_view_model.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CatatanViewModel()..muatUlang(),
      child: const StudyLogApp(),
    ),
  );
}

class StudyLogApp extends StatelessWidget {
  const StudyLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'StudyLog',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const BerandaPage(),
    );
  }
}