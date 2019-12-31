import 'package:flutter/material.dart';

ThemeData _androidThem = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.deepOrange,
  accentColor: Colors.deepPurple,
  //fontFamily: 'Oswald'
);

ThemeData _iosThem = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.deepOrange,
  accentColor: Colors.deepPurple,
  //fontFamily: 'Oswald'
);
ThemeData getAdaptiveTheme(context) {
  return Theme.of(context).platform == TargetPlatform.iOS
      ? _iosThem
      : _androidThem;
}
