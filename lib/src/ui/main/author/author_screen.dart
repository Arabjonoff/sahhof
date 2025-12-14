import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/bloc/book/book_bloc.dart';
import 'package:sahhof/src/model/book/book_model.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/detail_screen.dart';
import 'package:sahhof/src/widget/book_card_widget.dart';
import 'package:sahhof/src/widget/shimmer_widget.dart';

import '../../../model/author/author_model.dart' show AuthorResult;

class AuthorScreen extends StatefulWidget {
  final AuthorResult author;
  const AuthorScreen({super.key, required this.author});

  @override
  State<AuthorScreen> createState() => _AuthorScreenState();
}

class _AuthorScreenState extends State<AuthorScreen> {
  @override
  void initState() {
    bookBloc.getAuthorId(widget.author.id);
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0,right: 16),
              child: authorWidget(
                widget.author.fullName,
                widget.author.bio.isEmpty?"Muallif":widget.author.bio,
                "http://example.com/muhammadjon.jpg",
              ),
            ),
            Expanded(child: StreamBuilder<List<BookResult>>(
                stream: bookBloc.getAuthorStream,
                builder: (context, snapshot) {
                  if(snapshot.hasData){
                    var data = snapshot.data!;
                    return GridView.builder(
                        itemCount: data.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,childAspectRatio: 0.55.sp,), itemBuilder: (ctx,index){
                      return Padding(
                        padding: EdgeInsets.only(left: 16.0.sp),
                        child: BookCardWidget(image: data[index].coverImage, onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DetailScreen(id: data[index].id,)));
                        }, title: data[index].title, author: data[index].author.toString(), description: "", star: data[index].rating.toString(),),
                      );
                    });
                  }else{
                    return CustomShimmer(child: ListView.builder(
                        padding: EdgeInsets.only(left: 16.w),
                        scrollDirection: Axis.horizontal,
                        itemCount: 3,
                        itemBuilder: (ctx,index){
                          return BookCardWidget(image: '', onTap: () {  }, title: '', author: '', description: '',star: '',);
                        }));
                  }
                }
            ))
          ],
        ),
      )
    );
  }
  Widget authorWidget(fullName,bio,profilePicture){
    return Row(
      children: [
        // Ism va bio
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: AppStyle.font600(AppColors.black).copyWith(fontSize: 14.sp),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 4.h),
              Text(
                "$bio",
                style: AppStyle.font400(AppColors.grey).copyWith(fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
