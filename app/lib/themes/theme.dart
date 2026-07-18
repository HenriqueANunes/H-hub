import 'package:flutter/material.dart';

class CustomTheme {
  static ThemeData lightThemeData(BuildContext context) {
    return ThemeData(
      brightness: Brightness.light,
    );
  }

  static ThemeData darkThemeData() {
    return ThemeData(
      cardColor: Colors.grey.shade900,
      splashColor: Colors.grey.shade800,
      colorScheme: ColorScheme.dark(
        surface: Color(0xFF121212),
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Colors.grey.shade500,
        tertiary: Colors.red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.grey.shade900,
        shadowColor: Colors.black,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      bottomAppBarTheme: BottomAppBarTheme(
        color: Colors.grey.shade900,
        height: 70,
        shadowColor: Colors.black,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: Colors.grey.shade900,
        splashColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
      ),
      buttonTheme: ButtonThemeData(
        buttonColor: Colors.grey.shade900,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.grey.shade900,
      ),
    );
  }
}
