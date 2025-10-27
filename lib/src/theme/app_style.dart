import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppStyle{
  static TextStyle heading1(Color color){
    return TextStyle(
      color: color,
      fontSize: 42.spMin,
      fontWeight: FontWeight.bold,
    );
  }
  static TextStyle font500(Color color){
    return TextStyle(
      color: color,
      fontSize: 16.spMin,
      fontWeight: FontWeight.w500,
    );
  }
  static TextStyle font400(Color color){
    return TextStyle(
      color: color,
      fontSize: 12.spMin,
      fontWeight: FontWeight.w400,
    );
  }
  static TextStyle font600(Color color){
    return TextStyle(
      color: color,
      fontSize: 16.spMin,
      fontWeight: FontWeight.w600,
    );
  }
  static TextStyle font800(Color color){
    return TextStyle(
      color: color,
      fontSize: 16.spMin,
      fontWeight: FontWeight.w800,
    );
  }

}