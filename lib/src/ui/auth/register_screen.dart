import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/dialog/center_dialog.dart';
import 'package:sahhof/src/model/http_result.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/auth/login_screen.dart';
import 'package:sahhof/src/ui/auth/verfication_screen.dart';
import 'package:sahhof/src/utils/cache.dart';
import 'package:sahhof/src/widget/button_widget.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  TextEditingController loginController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoad = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child:Padding(
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
                    Center(child: Text("Sahhof",style: AppStyle.heading1(AppColors.black),)),
                    SizedBox(height: 14.spMin,),
                    Center(
                      child: SizedBox(
                        width: 220.spMin,
                          child: Text("Ilovamiz bilan tanishish uchun hisob yarating yoki tizimga kiring",textAlign: TextAlign.center,style: AppStyle.font400(AppColors.grey),)),
                    ),
                    SizedBox(height: 34.spMin,),
                    Text("Foydalanuvchi nomi",style: AppStyle.font500(AppColors.grey),),
                    SizedBox(height: 8.spMin,),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.spMin),
                      width: MediaQuery.of(context).size.width,
                      height: 48.spMin,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.grey,width: 0.4)
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
                    Text("Elektron pochta",style: AppStyle.font500(AppColors.grey),),
                    SizedBox(height: 8.spMin,),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.spMin),
                      width: MediaQuery.of(context).size.width,
                      height: 48.spMin,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.grey,width: 0.4)
                      ),
                      child: TextField(
                        controller: emailController,
                        style: AppStyle.font500(AppColors.black),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    SizedBox(height: 12.spMin,),
                    Text("Parol",style: AppStyle.font500(AppColors.grey),),
                    SizedBox(height: 8.spMin,),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.spMin),
                      width: MediaQuery.of(context).size.width,
                      height: 48.spMin,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.grey,width: 0.4)
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
                        Text("Akkautingz bormi? ",style: AppStyle.font400(AppColors.black),),
                        SizedBox(width: 4.spMin,),
                        GestureDetector(
                            onTap: (){
                              Navigator.push(context, MaterialPageRoute(builder: (ctx){
                                return LoginScreen();
                              }));
                            },
                            child: Text("Kirish",style: AppStyle.font400(AppColors.primary),))
                      ],
                    )
                  ],
                ),
              ),
              SizedBox(height: 24.spMin,),
              ButtonWidget(isLoad: isLoad,text: "Ro'yxatdan o'tish", textColor: AppColors.white, backgroundColor: AppColors.primary, onTap: ()async{
                setState(() {
                  isLoad = true;
                });
                Repository repository = Repository();
                Map data = {
                  "username": loginController.text,
                  "email": emailController.text,
                  "password": passwordController.text
                };
                HttpResult res = await repository.register(data);
                if(res.status >= 200 && res.status <= 299){
                  CacheService.saveUserId(res.result["id"]);
                  CacheService.saveLogin(res.result["username"]);
                  // CacheService.saveAvatar(res.result["avatar"]);
                  CacheService.saveUserFirstName(res.result["first_name"]);
                  CacheService.saveUserLastName(res.result["last_name"]);
                  Navigator.push(context, MaterialPageRoute(builder: (ctx){
                    return VerificationScreen(id: res.result["id"], email: res.result["email"],);
                  }));
                }else{
                  isLoad = false;
                  setState(() {});
                  CenterDialog.showCenterDialog(context, res.result.toString());
                }
              })
            ],
          ),
        ),
      )
    );
  }
}
