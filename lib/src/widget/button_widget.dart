import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';

class ButtonWidget extends StatelessWidget {
  final String text;
  final Color textColor,backgroundColor;
  final Function() onTap;
  final bool isLoad;
  const ButtonWidget({super.key, required this.text, required this.textColor, required this.backgroundColor, required this.onTap, this.isLoad = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: 16.spMin,right: 16.spMin,bottom: 32.spMin),
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width,
        height: 56.spMin,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(10.spMin),
        ),
        child: isLoad ? CircularProgressIndicator(color: AppColors.white,) : Text(text,style: AppStyle.font500(textColor),),
      ),
    );
  }
}
