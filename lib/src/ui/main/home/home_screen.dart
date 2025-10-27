import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/bloc/banner/banner_bloc.dart';
import 'package:sahhof/src/bloc/book/book_bloc.dart';
import 'package:sahhof/src/bloc/category/category_bloc.dart';
import 'package:sahhof/src/model/banner/banner_model.dart';
import 'package:sahhof/src/model/book/book_model.dart';
import 'package:sahhof/src/model/category/category_model.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/detail_screen.dart';
import 'package:sahhof/src/ui/main/profile/profile_screen.dart';
import 'package:sahhof/src/utils/cache.dart';
import 'package:sahhof/src/widget/banner_widget.dart';
import 'package:sahhof/src/widget/book_card_widget.dart';
import 'package:sahhof/src/widget/shimmer_widget.dart';

import '../../../theme/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    categoryBloc.getCategory();
    bookBloc.getBooks(0);
    bannerBloc.getAllBanner();
    super.initState();
  }
  int selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.white,
        centerTitle: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: CircleAvatar(
              backgroundColor: AppColors.white,
              child: IconButton(onPressed: (){
                Navigator.push(context, MaterialPageRoute(builder: (ctx){
                  return ProfileScreen();
                }));
              }, icon: Icon(Icons.person,color: AppColors.primary,))),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Assalomu alayakum",style: TextStyle(fontSize: 18),),
            Text(CacheService.getLogin(),style: TextStyle(fontSize: 18,color: AppColors.grey),),
          ],
        ),
        actions: [
          IconButton(onPressed: (){}, icon: Icon(Icons.notifications,color: AppColors.primary,))
        ],
      ),
      backgroundColor: AppColors.background,
      body: ListView(
        children: [
          StreamBuilder<List<BannerModel>>(
            stream: bannerBloc.getBannerStream,
            builder: (context, snapshot) {
              if(snapshot.hasData && snapshot.data!.isNotEmpty){
                var data = snapshot.data!;
                return AnimatedBannerWidget(
                  bannerItems: data,
                  height: 150.sp,
                  autoPlayDuration: const Duration(seconds: 4),
                  animationDuration: const Duration(milliseconds: 800),
                  borderRadius: BorderRadius.circular(16),
                );
              }else{
                return CustomShimmer(child: AnimatedBannerWidget(
                  bannerItems: [BannerModel(id: 0, text: "", image: "")],
                  height: 250.sp,
                  autoPlayDuration: const Duration(seconds: 4),
                  animationDuration: const Duration(milliseconds: 800),
                  borderRadius: BorderRadius.circular(16),
                ),);
              }
            }
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            margin: EdgeInsets.symmetric(horizontal: 16.w,vertical: 16.h),
            width: MediaQuery.of(context).size.width,
            height: 50.h,
            decoration: BoxDecoration(
              color: AppColors.blue.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: TextField(
                textCapitalization: TextCapitalization.sentences,
                cursorColor: AppColors.black,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.search,
                style: TextStyle(
                  color: AppColors.black,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "Kitoblar yoki Mualliflarni qidirish...",
                  hintStyle: TextStyle(
                    color: AppColors.grey,
                  )
                )
              ),
            ),
          ),
          SizedBox(
            height: 40.sp,
            child: StreamBuilder<List<CategoryResult>>(
              stream: categoryBloc.getCategoryStream,
              builder: (context, snapshot) {
                if(snapshot.hasData){
                  var data = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.only(left: 16.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: data.length,
                      itemBuilder: (ctx,index){
                        return GestureDetector(
                          onTap: (){
                            bookBloc.getBooks(data[index].id);
                            setState(() {
                              selectedIndex = index;
                            });
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 10.w),
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(horizontal: 16.w,vertical: 0.h),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selectedIndex == index ?Colors.transparent: AppColors.grey.withOpacity(0.3)),
                                color: selectedIndex == index ? AppColors.primary : AppColors.white
                              ),
                              child: Text(data[index].name,style: TextStyle(color: selectedIndex == index ? Colors.white:AppColors.black),)),
                        );
                      });
                }
                bookBloc.getBooks(2);
                return CustomShimmer(
                  child: ListView.builder(
                      padding: EdgeInsets.only(left: 16.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: 6,
                      itemBuilder: (ctx,index){
                        return Container(
                            margin: EdgeInsets.only(right: 10.w),
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(horizontal: 16.w,vertical: 0.h),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: selectedIndex == index ?Colors.transparent: AppColors.grey.withOpacity(0.3)),
                                color: selectedIndex == index ? AppColors.primary : AppColors.white
                            ),
                            child: Text("                             ",style: TextStyle(color: selectedIndex == index ? Colors.white:AppColors.black),));
                      }),
                );
              }
            ),
          ),
          SizedBox(height: 8.sp,),
          Container(
            color: AppColors.white,
            height: 320.spMax,
            child: StreamBuilder<List<BookResult>>(
              stream: bookBloc.getBookStream,
              builder: (context, snapshot) {
                if(snapshot.hasData){
                  var data = snapshot.data!;
                  return ListView.builder(
                      padding: EdgeInsets.only(left: 16.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: data.length,
                      itemBuilder: (ctx,index){
                        return BookCardWidget(image: data[index].coverImage, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(id: data[index].id,)));
                        }, title: data[index].title, author: data[index].author.fullName.toString(), description: data[index].description,);
                      });
                }else{
                  return CustomShimmer(child: ListView.builder(
                      padding: EdgeInsets.only(left: 16.w),
                      scrollDirection: Axis.horizontal,
                      itemCount: 3,
                      itemBuilder: (ctx,index){
                        return BookCardWidget(image: '', onTap: () {  }, title: '', author: '', description: '',);
                      }));
                }
              }
            )
          ),
          ListTile(
            title: Text("Yangi qo'shilgan kitoblar",style: AppStyle.font600(AppColors.black),),
            trailing: TextButton(onPressed: (){}, child: Text("Batafsil",style: AppStyle.font400(AppColors.blue),)),
          ),
          // Container(
          //     color: AppColors.white,
          //     height: 340.spMax,
          //     child: ListView.builder(
          //         padding: EdgeInsets.only(left: 16.w),
          //         scrollDirection: Axis.horizontal,
          //         itemCount: 3,
          //         itemBuilder: (ctx,index){
          //           return BookCardWidget();
          //         })
          // ),
        ],
      ),
    );
  }
}


