import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/bloc/pdf/pdf_bloc.dart';
import 'package:sahhof/src/bloc/profile/profile_bloc.dart';
import 'package:sahhof/src/database/database_helper.dart';
import 'package:sahhof/src/dialog/center_dialog.dart';
import 'package:sahhof/src/model/http_result.dart';
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
  final Repository _repository = Repository();
  @override
  void initState() {
    profileBloc.getAllProfile();
    super.initState();
  }

  // Tilni o'zgartirish dialogi
  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            "Tilni tanlang",
            style: AppStyle.font600(AppColors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Text("🇺🇿", style: TextStyle(fontSize: 24)),
                title: Text("O'zbekcha", style: AppStyle.font400(AppColors.black)),
                onTap: () {
                  // Tilni o'zgartirish logikasi
                  Navigator.pop(context);
                  _showSuccessSnackbar("Til o'zbekchaga o'zgartirildi");
                },
              ),
              ListTile(
                leading: const Text("🇷🇺", style: TextStyle(fontSize: 24)),
                title: Text("Русский", style: AppStyle.font400(AppColors.black)),
                onTap: () {
                  // Tilni o'zgartirish logikasi
                  Navigator.pop(context);
                  _showSuccessSnackbar("Язык изменен на русский");
                },
              ),
              ListTile(
                leading: const Text("🇬🇧", style: TextStyle(fontSize: 24)),
                title: Text("English", style: AppStyle.font400(AppColors.black)),
                onTap: () {
                  // Tilni o'zgartirish logikasi
                  Navigator.pop(context);
                  _showSuccessSnackbar("Language changed to English");
                },
              ),
              ListTile(
                leading: const Text("🇹🇷", style: TextStyle(fontSize: 24)),
                title: Text("Türkçe", style: AppStyle.font400(AppColors.black)),
                onTap: () {
                  // Tilni o'zgartirish logikasi
                  Navigator.pop(context);
                  _showSuccessSnackbar("Dil Türkçe olarak değiştirildi");
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Bekor qilish", style: AppStyle.font400(AppColors.blue)),
            ),
          ],
        );
      },
    );
  }

  // Parolni o'zgartirish bottom dialog
  void _showChangePasswordDialog() {
    final TextEditingController oldPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;

    showModalBottomSheet(
      backgroundColor: AppColors.white,
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16.w,
                right: 16.w,
                top: 20.h,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: AppColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Parolni o'zgartirish",
                    style: AppStyle.font600(AppColors.black).copyWith(fontSize: 20.sp),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    "Eski parol",
                    style: AppStyle.font600(AppColors.black),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    style: TextStyle(color: Colors.black),
                    controller: oldPasswordController,
                    obscureText: obscureOld,
                    decoration: InputDecoration(
                      hintText: "Eski parolni kiriting",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureOld ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureOld = !obscureOld;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Yangi parol",
                    style: AppStyle.font600(AppColors.black),
                  ),
                  SizedBox(height: 8.h),
                  TextField(
                    style: TextStyle(color: Colors.black),
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      hintText: "Yangi parolni kiriting",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNew ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            "Bekor qilish",
                            style: AppStyle.font600(AppColors.blue),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async{
                            if (oldPasswordController.text.isEmpty ||
                                newPasswordController.text.isEmpty) {
                              _showErrorSnackbar("Iltimos, barcha maydonlarni to'ldiring");
                              return;
                            }
                            Map data = {
                              "old_password": oldPasswordController.text,
                              "new_password": newPasswordController.text
                            };
                            HttpResult res = await _repository.changePassword(data);
                            if(res.status >=200&& res.status<299){
                              Navigator.pop(context);
                              _showSuccessSnackbar("Parol muvaffaqiyatli o'zgartirildi");
                            }else{
                              Navigator.pop(context);
                              _showSuccessSnackbar(res.result);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.blue,
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          child: Text(
                            "Saqlash",
                            style: AppStyle.font600(AppColors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Yangi parol olish dialogi
  void _showResetPasswordDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppColors.white,
          title: Text(
            "Yangi parol olish",
            style: AppStyle.font600(AppColors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Email manzilingizni kiriting. Sizga parolni tiklash uchun havola yuboramiz.",
                style: AppStyle.font400(AppColors.grey),
              ),
              SizedBox(height: 16.h),
              TextField(
                style: TextStyle(color: Colors.black),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "Email",
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Bekor qilish", style: AppStyle.font400(AppColors.grey)),
            ),
            ElevatedButton(
              onPressed: () async{
                if (emailController.text.isEmpty) {
                  _showErrorSnackbar("Iltimos, email kiriting");
                  return;
                }
                if (!emailController.text.contains('@')) {
                  _showErrorSnackbar("Noto'g'ri email format");
                  return;
                }
                Map data = {
                  "email": emailController.text
                };
                HttpResult res = await _repository.resetPassword(data);
                if(res.status >= 200 && res.status<299){
                  Navigator.pop(context);
                  _showSuccessSnackbar("Email manzilingizga havola yuborildi");
                }else{
                  _showSuccessSnackbar(res.result);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
              ),
              child: Text("Yuborish", style: AppStyle.font600(AppColors.white)),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

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
                StreamBuilder(
                  stream: profileBloc.getProfileStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Container(
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
                              child: const Icon(Icons.person),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    snapshot.data!.username,
                                    style: AppStyle.font600(AppColors.black),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    snapshot.data!.email,
                                    style: AppStyle.font400(AppColors.blue),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    } else {
                      return Container(
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "User",
                                    style: AppStyle.font600(AppColors.black),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Profilni ko'rish",
                                    style: AppStyle.font400(AppColors.blue),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    }
                  },
                ),
                Container(
                  color: AppColors.white,
                  width: double.infinity,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: _showLanguageDialog,
                        title: Text(
                          "Tilni o'zgartirish",
                          style: AppStyle.font600(AppColors.black),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      ListTile(
                        onTap: _showChangePasswordDialog,
                        title: Text(
                          "Parolni o'zgartirish",
                          style: AppStyle.font600(AppColors.black),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                      ListTile(
                        onTap: _showResetPasswordDialog,
                        title: Text(
                          "Yangi parol olish",
                          style: AppStyle.font600(AppColors.black),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: AppColors.white,
                  width: double.infinity,
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (ctx) {
                            return BookmarkScreen();
                          }));
                        },
                        title: Text(
                          "Saqlangan kitoblar",
                          style: AppStyle.font600(AppColors.black),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ButtonWidget(
            text: "Chiqish",
            textColor: AppColors.white,
            backgroundColor: AppColors.red,
            onTap: () {
              DatabaseHelper _base = DatabaseHelper();
              _base.clearAllDownloads();
              CenterDialog.showLogoutDialog(context, () async {
                await _base.clearAllDownloads();
                CacheService.clear();
                Navigator.popUntil(context, (predicate) => predicate.isFirst);
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx) {
                  return LoginScreen();
                }));
              });
            },
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}