import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/dialog/center_dialog.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/auth/login_screen.dart';
import 'package:sahhof/src/ui/main/profile/bookmark/bookmark_screen.dart';
import 'package:sahhof/src/utils/cache.dart';
import 'package:sahhof/src/widget/button_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        centerTitle: true,
        title: const Text("Profil"),
      ),
      body: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 16.sp),
                  height: 104.sp,
                  width: double.infinity,
                  color: AppColors.white,
                  child: Row(
                    children: [
                      Container(
                        margin: EdgeInsets.only(left: 32.w),
                        width: 72.r,
                        height: 72.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.grey.withOpacity(0.1),
                        ),
                      ),
                      const SizedBox(width: 16,),
                      Expanded(child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("data",style: AppStyle.font600(AppColors.black),),
                          const SizedBox(height: 12,),
                          Text("Profilni ko'rish",style: AppStyle.font400(AppColors.blue),)
                        ],
                      ))
                    ],
                  ),
                ),
                Container(
                  color: AppColors.white,
                  width: double.infinity,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("Tilni o'zgartirish",style: AppStyle.font600(AppColors.black),),
                      ),
                      ListTile(
                        title: Text("Ulangan qurilmalar",style: AppStyle.font600(AppColors.black),),
                      ),
                      ListTile(
                        title: Text("Premium",style: AppStyle.font600(AppColors.black),),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 16.sp),
                  color: AppColors.white,
                  width: double.infinity,
                  child: Column(
                    children: [
                      ListTile(
                        title: Text("Mavzu",style: AppStyle.font600(AppColors.black),),
                      ),
                      ListTile(
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (ctx){
                            return BookmarkScreen();
                          }));
                        },
                        title: Text("Saqlanganlar",style: AppStyle.font600(AppColors.black),),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ButtonWidget(text: "Chiqish", textColor: AppColors.white, backgroundColor: AppColors.red, onTap: (){
            CenterDialog.showLogoutDialog(context, (){
              CacheService.clear();
              Navigator.popUntil(context, (predicate) => predicate.isFirst);
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx){
                return LoginScreen();
              }));
            });
          }),
          const SizedBox(height: 36,),
        ],
      ),
    );
  }
}
