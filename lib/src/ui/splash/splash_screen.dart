import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/auth/login_screen.dart';
import 'package:sahhof/src/ui/auth/register_screen.dart';


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.only(top: 130.sp),
                width: 132.spMin,
                height: 132.spMin,
                child: Image.asset("assets/images/logo.png"),
              ),
            ),
            const Spacer(),
            Text(
              "Version 1.0.0\nPowered by NaqshSoft",
              textAlign: TextAlign.center,
              style: AppStyle.font400(AppColors.blue),
            ),
          ],
        ),
      ),
    );
  }
}
