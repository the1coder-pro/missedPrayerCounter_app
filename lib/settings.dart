import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Dark/Light Theme

class TheThemePreference {
  // ignore: constant_identifier_names
  static const THEME_STATUS = "THEMESTATUS";
  static const FONT_SIZE = "FONTSIZE";
  static const PERSONNAME = "PERSONNAME";
  static const UILANGUAGE = "UILANGUAGE";

  setDarkTheme(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(THEME_STATUS, value);
  }

  Future<bool> getTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(THEME_STATUS) ?? false;
  }

  setFontSize(double size) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setDouble(FONT_SIZE, size);
  }

  Future<double> getFontSize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(FONT_SIZE) ?? 27;
  }

  setPersonName(String name) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(PERSONNAME, name);
  }

  Future<String> getPersonName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(PERSONNAME) ?? 'ME';
  }

  setUILanguage(String language) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(UILANGUAGE, language);
  }

  Future<String> getUILanguage() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(UILANGUAGE) ?? 'ar';
  }
}

class TheThemeProvider with ChangeNotifier {
  TheThemePreference preference = TheThemePreference();
  bool _darkTheme = false;

  bool get darkTheme => _darkTheme;

  set darkTheme(bool value) {
    _darkTheme = value;
    preference.setDarkTheme(value);
    notifyListeners();
  }

  double _fontSize = 27;
  double get fontSize => _fontSize;

  set fontSize(double value) {
    _fontSize = value;
    preference.setFontSize(value);
    notifyListeners();
  }

  String _personName = 'ME';
  String get personName => _personName;

  set personName(String name) {
    _personName = name;
    preference.setPersonName(name);
    notifyListeners();
  }

  String _language = 'ar';
  String get language => _language;

  set language(String language) {
    _language = language;
    preference.setUILanguage(language);
    notifyListeners();
  }
}

// Color Theme

class TheColorThemePreference {
  // ignore: constant_identifier_names
  static const THEME_COLOR = "THEMECOLOR";

  setThemeColor(int color) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt(THEME_COLOR, color);
  }

  Future<int> getThemeColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getInt(THEME_COLOR) ?? 0;
  }
}

class ThemeColorProvider with ChangeNotifier {
  TheColorThemePreference colorThemePreference = TheColorThemePreference();
  int _colorTheme = 0;

  int get colorTheme => _colorTheme;

  set colorTheme(int color) {
    _colorTheme = color;
    colorThemePreference.setThemeColor(color);
    notifyListeners();
  }
}
