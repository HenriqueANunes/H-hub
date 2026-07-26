import 'package:flutter/material.dart';

import 'package:my_platform/themes/theme.dart';

import 'package:my_platform/pages/finance/finance.dart';
import 'package:my_platform/pages/finance/monthly_calculation.dart';
import 'package:my_platform/pages/finance/list_expenses.dart';
import 'package:my_platform/pages/sound/home.dart';
import 'package:my_platform/pages/sound/input.dart';
import 'package:my_platform/widgets/auth_gate.dart';

/// O `AuthGate` precisa esvaziar a pilha de telas quando a sessão cai, e isso
/// acontece fora de qualquer `BuildContext` de tela.
final appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App',
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: CustomTheme.lightThemeData(context),
      darkTheme: CustomTheme.darkThemeData(),
      home: const AuthGate(),
      routes: {
        '/finance/finance.dart': (context) => const FinancePage(),
        '/finance/monthly_calculation.dart': (context) => const MonthlyCalculationPage(),
        '/finance/list_expenses.dart': (context) => const ListExpensesPage(),
        '/sound/home.dart': (context) => const SoundPage(),
        '/sound/input.dart': (context) => const SoundInput(),
      },
    );
  }
}
