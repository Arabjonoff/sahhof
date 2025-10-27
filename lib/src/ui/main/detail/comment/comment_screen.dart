import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/model/http_result.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/widget/button_widget.dart';

class CommentScreen extends StatefulWidget {
  final int id;
  const CommentScreen({super.key, required this.id});

  @override
  State<CommentScreen> createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  TextEditingController commentController = TextEditingController();
  int rating = 0;
  bool isLoad = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Izoh qoldirish"),
        backgroundColor: AppColors.background,),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h,),
                  Text("Kitob haqida reyting qoldiring",style: AppStyle.font600(AppColors.black),),
                  SizedBox(height: 16.h,),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(onPressed: (){
                        setState(() {
                          rating = 1;
                        });
                      }, icon: Icon(rating>=1?Icons.star:Icons.star_border,color: rating>=1?AppColors.orange:AppColors.greyAccent,size: 44.sp,),),
                      IconButton(onPressed: (){
                        setState(() {
                          rating = 2;
                        });
                      }, icon: Icon(rating>=1?Icons.star:Icons.star_border,color: rating>=2?AppColors.orange:AppColors.greyAccent,size: 44.sp,),),
                      IconButton(onPressed: (){
                        setState(() {
                          rating = 3;
                        });
                      }, icon: Icon(rating>=3?Icons.star:Icons.star_border,color: rating>=3?AppColors.orange:AppColors.greyAccent,size: 44.sp,),),
                      IconButton(onPressed: (){
                        setState(() {
                          rating = 4;
                        });
                      }, icon: Icon(rating>=4?Icons.star:Icons.star_border,color: rating>=4?AppColors.orange:AppColors.greyAccent,size: 44.sp,),),
                      IconButton(onPressed: (){
                        setState(() {
                          rating = 5;
                        });
                      }, icon: Icon(rating>=5?Icons.star:Icons.star_border,color: rating>=5?AppColors.orange:AppColors.greyAccent,size: 44.sp,),),
                    ],
                  ),
                  SizedBox(height: 16.h,),
                  Text("Kitob haqida izoh qoldiring",style: AppStyle.font600(AppColors.black),),
                  SizedBox(height: 8.h,),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w,vertical: 8.h),
                    width: MediaQuery.of(context).size.width,
                    height: 100.sp,
                    decoration: BoxDecoration(
                      color: AppColors.greyAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      maxLines: 5,
                      maxLength: 150,
                      style: AppStyle.font500(AppColors.black),
                      controller: commentController,
                      decoration: InputDecoration(
                        hintText: "Izohingizni kiriting",
                        hintStyle: AppStyle.font400(AppColors.grey),
                        border: InputBorder.none,
                      )
                    )
                  )
                ],
              ),
            ),
          ),
          ButtonWidget(isLoad: isLoad,text: "Tastiqlash", textColor: AppColors.white, backgroundColor: AppColors.blue, onTap: ()async{
            isLoad = true;
            setState(() {});
            Repository repository = Repository();
            HttpResult result = await repository.addCommentRating(widget.id, {"rating": rating.toString(), "comment": commentController.text});
            if(result.status == 200) {
              Navigator.pop(context);
            }else{
              isLoad = false;
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.result.toString())));
            }
          }),
          SizedBox(height: 34.h,)
        ],
      ),
    );
  }
}
