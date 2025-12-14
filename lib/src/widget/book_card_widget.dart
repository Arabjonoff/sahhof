import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
class BookCardWidget extends StatelessWidget {
  final String image;
  final String title,description,star;
  final String author;
  final Function() onTap;
  final bool isVertical;
  const BookCardWidget({super.key, required this.image, required this.onTap, required this.title, required this.author, this.isVertical = true, required this.description, required this.star});

  @override
  Widget build(BuildContext context) {
    if(isVertical){
      return GestureDetector(
        onTap: onTap,
        child: Stack(
          children: [
            Container(
              margin: EdgeInsets.only(right: 16.w),
              width: 160.sp,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 16.h),
                    height: 234.spMin,
                    decoration: BoxDecoration(
                      color: AppColors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: CachedNetworkImage(imageUrl: image,fit: BoxFit.cover,)),
                  ),
                  Text(title,style: AppStyle.font800(AppColors.black),),
                  SizedBox(height: 4,),
                  Text(author,style: AppStyle.font400(AppColors.blue),),
                ],
              ),
            ),
            Positioned(
              right: 37.sp,
              top: 18.sp,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.orange
                ),
                padding: EdgeInsets.symmetric(vertical: 4,horizontal: 8),
                child: Row(
                  children: [
                    Icon(Icons.star,color: AppColors.white,size: 16.sp,),
                    SizedBox(width: 4,),
                    Text(star,style: AppStyle.font500(AppColors.white),),
                  ],
                ),
              ),
            )
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: 16.w,bottom: 10),
        width: 290.sp,
        height: 140.sp,
        decoration: BoxDecoration(
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 0,
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.symmetric(vertical: 16.h,horizontal: 16.w),
              width: 77.sp,
              height: 110.sp,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(imageUrl: image,fit: BoxFit.cover,)),
            ),
            SizedBox(width: 16.w,),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16.sp,),
                SizedBox(
                  width: 140.sp,
                    child: Text(title,style: AppStyle.font800(AppColors.black),)),
                SizedBox(height: 4,),
                Text(author,style: AppStyle.font400(AppColors.blue),),
                SizedBox(height: 4,),
                SizedBox(
                  width: 140.sp,
                    child: Text(description,maxLines: 2,style: AppStyle.font400(AppColors.black),)),
                Spacer(),
                Row(
                  children: [
                    Container(
                        padding: EdgeInsets.symmetric(vertical:5),
                        height: 30.sp,
                        width: 70.sp,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 0.1,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ]
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Image.asset("assets/images/book.png"),
                          ],
                        )
                    ),
                    SizedBox(width: 8,),
                    Container(
                        padding: EdgeInsets.symmetric(vertical:5),
                        height: 30.sp,
                        width: 70.sp,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: AppColors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 0.5,
                                blurRadius: 7,
                                offset: Offset(0, 3),
                              ),
                            ]
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star,color: AppColors.orange,size: 16.sp,),
                            SizedBox(width: 4,),
                            Text("4.5",style: AppStyle.font400(AppColors.black),)
                          ],
                        )
                    ),
                  ],
                ),
                SizedBox(height: 8.sp,),
              ],
            ),
          ],
        ),
      ),
    );

  }
}
