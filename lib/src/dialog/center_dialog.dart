import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';

class CenterDialog{
  static showCenterDialog(BuildContext ctx,String content){
    showDialog(context: ctx, builder: (ctx){
      return AlertDialog(
        backgroundColor: AppColors.white,
        title: Center(child: Text("Xatolik",style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold))),
        content: Text(content,style: AppStyle.font500(AppColors.grey),),
      );
    });
  }
  static showLogoutDialog(BuildContext ctx, VoidCallback onConfirm) {
    showDialog(
      context: ctx,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Center(
            child: Text(
              "Tizimdan chiqish",
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          content: Text(
            "Haqiqatan ham tizimdan chiqmoqchimisiz?",
            textAlign: TextAlign.center,
            style: AppStyle.font500(AppColors.grey),
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Yo‘q",
                style: TextStyle(color: AppColors.grey, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm(); // tasdiqlansa bajariladigan funksiya
              },
              child: Text(
                "Ha, chiqish",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }


}