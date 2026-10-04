import 'package:flutter/material.dart';

// Text styles have no fixed color for bold/semi-bold text, so they follow the
// light/dark theme (black in light mode, white in dark mode).
class AppWidget{
  static TextStyle boldTextFeildStyle(){
    return TextStyle(
            fontSize: 25.0,
            fontWeight: FontWeight.bold
    );
  }

  // grey that reads well on both light and dark backgrounds
  static TextStyle lightTextFeildStyle(){
    return TextStyle(
      color: Color(0xFF8E8E93),fontSize: 20.0,fontWeight: FontWeight.w500,
    );
  }

  static TextStyle semiBoldTextFeildStyle(){
    return TextStyle(
      fontSize: 20.0,
      fontWeight: FontWeight.bold,
    );
  }
}
