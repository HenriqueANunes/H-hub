import 'dart:io';

import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:my_platform/themes/theme.dart';

import 'package:my_platform/pages/home.dart';
import 'package:my_platform/pages/finance/finance.dart';
import 'package:my_platform/pages/finance/monthly_calculation.dart';
import 'package:my_platform/pages/finance/list_expenses.dart';
import 'package:my_platform/pages/sound/home.dart';
import 'package:my_platform/pages/sound/input.dart';

void main() {
  // Initialize FFI for desktop platforms if needed
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App',
      debugShowCheckedModeBanner: false,
      theme: CustomTheme.lightThemeData(context),
      darkTheme: CustomTheme.darkThemeData(),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/finance/finance.dart': (context) => const FinancePage(),
        '/finance/monthly_calculation.dart': (context) => const MonthlyCalculationPage(),
        '/finance/list_expenses.dart': (context) => const ListExpensesPage(),
        '/sound/home.dart': (context) => const SoundPage(),
        '/sound/input.dart': (context) => const SoundInput(),
      },
    );
  }
}
