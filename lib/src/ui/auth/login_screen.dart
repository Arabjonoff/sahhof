import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/dialog/center_dialog.dart';
import 'package:sahhof/src/model/http_result.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/auth/register_screen.dart';
import 'package:sahhof/src/ui/auth/verfication_screen.dart';
import 'package:sahhof/src/ui/main/main_screen.dart';
import 'package:sahhof/src/utils/cache.dart';
import 'package:sahhof/src/widget/button_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  TextEditingController loginController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoad = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0.spMin),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      SizedBox(height: 24.spMin,),
                      Center(
                        child: SizedBox(
                          width: 132.spMin,
                          height: 132.spMin,
                          child: Image.asset("assets/images/logo.png"),
                        ),
                      ),
                      SizedBox(height: 24.spMin,),
                      Center(child: Text(
                        "Buxoro sahiflari", style: AppStyle.heading1(AppColors.black),)),
                      SizedBox(height: 14.spMin,),
                      Center(
                        child: SizedBox(
                            width: 220.spMin,
                            child: Text(
                              "Ilovamiz bilan tanishish uchun hisob yarating yoki tizimga kiring",
                              textAlign: TextAlign.center,
                              style: AppStyle.font400(AppColors.grey),)),
                      ),
                      SizedBox(height: 34.spMin,),
                      Text("Foydalanuvchi nomi",
                        style: AppStyle.font500(AppColors.grey),),
                      SizedBox(height: 8.spMin,),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.spMin),
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        height: 48.spMin,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.grey, width: 0.4)
                        ),
                        child: TextField(
                          controller: loginController,
                          style: AppStyle.font500(AppColors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 12.spMin,),
                      Text("Parol", style: AppStyle.font500(AppColors.grey),),
                      SizedBox(height: 8.spMin,),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16.spMin),
                        width: MediaQuery
                            .of(context)
                            .size
                            .width,
                        height: 48.spMin,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.grey, width: 0.4)
                        ),
                        child: TextField(
                          controller: passwordController,
                          style: AppStyle.font500(AppColors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 18.spMin,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Akkautingz yoqmi? ",
                            style: AppStyle.font400(AppColors.black),),
                          SizedBox(width: 4.spMin,),
                          GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context, MaterialPageRoute(builder: (ctx) {
                                  return RegisterScreen();
                                }));
                              },
                              child: Text("Ro'yxatdan otish", style: AppStyle
                                  .font400(AppColors.primary),))
                        ],
                      ),
                      SizedBox(height: 4.spMin,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Parol esdan chiqdimi? ",
                            style: AppStyle.font400(AppColors.black),),
                          SizedBox(width: 4.spMin,),
                          GestureDetector(
                              onTap: () {
                                showResetPasswordDialog(context);
                              },
                              child: Text("Yangi parol", style: AppStyle
                                  .font400(AppColors.primary),))
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24.spMin,),
                ButtonWidget(isLoad: isLoad,
                    text: "Kirish",
                    textColor: AppColors.white,
                    backgroundColor: AppColors.primary,
                    onTap: () async {
                      setState(() {
                        isLoad = true;
                      });
                      Repository repository = Repository();
                      Map data = {
                        "username": loginController.text,
                        "password": passwordController.text
                      };
                      HttpResult res = await repository.login(data);
                      if (res.status >= 200 && res.status <= 299) {
                        // CacheService.saveUserId(res.result["id"]);
                        // CacheService.saveLogin(res.result["username"]);
                        // CacheService.saveUserFirstName(res.result["first_name"]);
                        CacheService.saveToken(res.result["access"]);
                        CacheService.refreshToken(res.result["refresh"]);
                        Navigator.popUntil(context, (predicate) => predicate.isFirst);
                        Navigator.pushReplacement(
                            context, MaterialPageRoute(builder: (ctx) {
                          return MainScreen();
                        }));
                      } else {
                        isLoad = false;
                        setState(() {});
                        CenterDialog.showCenterDialog(
                            context, res.result.toString());
                      }
                    })
              ],
            ),
          ),
        )
    );
  }
  showResetPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Center(
                child: Text(
                  "Parolni tiklash",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.black87,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Email manzilingizni kiriting, biz sizga parolni tiklash uchun kod yuboramiz:",
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              TextField(
                style: const TextStyle(color: Colors.black),
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "Email manzilingiz",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Bekor qilish",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async{
                      final email = emailController.text.trim();
                      if (email.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Iltimos, email manzilni kiriting!"),
                          ),
                        );
                        return;
                      }
                      HttpResult res = await Repository().resetPassword({
                        "email": emailController.text
                      });
                      if (res.status >= 200 && res.status <= 299) {
                        Navigator.push(
                            context, MaterialPageRoute(builder: (ctx) {
                          return VerificationScreen(id: res.result["id"], email: emailController.text,);
                        }));}
                      else{
                        CenterDialog.showCenterDialog(context, res.result.toString());
                      }
                    },
                    child: const Text(
                      "Yuborish",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

            ],
          ),
        );
      },
    );
  }


  @override
  void dispose() {
    loginController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}