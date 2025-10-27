import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pinput/pinput.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/dialog/center_dialog.dart';
import 'package:sahhof/src/model/http_result.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/home/home_screen.dart';
import 'package:sahhof/src/ui/main/main_screen.dart';
import 'package:sahhof/src/widget/button_widget.dart';

import '../../utils/cache.dart';

class VerificationScreen extends StatefulWidget {
  final int id;
  final String email;
  const VerificationScreen({super.key, required this.id, required this.email});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  TextEditingController controller =  TextEditingController();
  bool isLoad = false;
  final defaultPinTheme = PinTheme(
    width: 56,
    height: 56,
    textStyle: TextStyle(
        fontSize: 20,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.grey.withOpacity(0.5)),
      borderRadius: BorderRadius.circular(10),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (){
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text("Tasdiqlash"),
            backgroundColor: AppColors.background,
          ),
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    children: [
                      SizedBox(
                        height: 34.spMin,
                      ),
                      Container(
                          margin: EdgeInsets.only(bottom: 54.spMin),
                          width: 131.spMin,
                          height: 131.spMin,
                          child: Image.asset("assets/images/logo.png"),),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 38.0),
                        child: Text("${maskEmail(widget.email)} manziliga yuborgan tasdiqlash kodini kiriting.",style: AppStyle.font400(AppColors.grey),textAlign: TextAlign.center,),
                      ),
                      SizedBox(height: 22.spMin,),
                      Center(
                        child: Pinput(
                          controller: controller,
                          length: 6,
                          defaultPinTheme: defaultPinTheme,
                          onCompleted: (pin) => print(pin),
                        ),
                      ),
                    ],
                  ),
                ),
                ButtonWidget(isLoad: isLoad,text: "Tasdiqlash", textColor: AppColors.white, backgroundColor: AppColors.primary, onTap: ()async{
                  setState(() {
                    isLoad = true;
                  });
                  Repository repository = Repository();
                  HttpResult res = await repository.verification(widget.id, controller.text);
                  if(res.status >= 200 && res.status <= 299){
                    CacheService.saveToken(res.result["access"]);
                    CacheService.refreshToken(res.result["refresh"]);
                    Navigator.popUntil(context, (predicate) => predicate.isFirst);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (ctx){
                      return MainScreen();
                    }));
                  }else{
                    isLoad = false;
                    setState(() {});
                    CenterDialog.showCenterDialog(context, res.result.toString());
                  }
                })
              ],
            ),
          )),
    );
  }
  String maskEmail(String email) {
    if (!email.contains('@')) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;
    String local = parts[0];
    String domain = parts[1].toLowerCase();
    if (domain == 'gamil.com') {
      domain = 'gmail.com';
    }
    if (local.length <= 2) {
      final start = local.isNotEmpty ? local[0] : '';
      final stars = '*' * (local.length - start.length).clamp(0, 1000);
      local = '$start$stars';
    } else if (local.length <= 4) {
      final start = local.substring(0, 1);
      final end = local.substring(local.length - 1);
      final stars = '*' * (local.length - 2);
      local = '$start$stars$end';
    } else {
      final start = local.substring(0, 2);
      final end = local.substring(local.length - 2);
      final stars = '*' * (local.length - 4);
      local = '$start$stars$end';
    }
    return '$local@$domain';
  }
}
