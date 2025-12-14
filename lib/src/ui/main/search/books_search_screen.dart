import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/bloc/book/book_bloc.dart';
import 'package:sahhof/src/model/book/book_model.dart';
import 'package:sahhof/src/model/search/search_model.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/ui/main/detail/detail_screen.dart';
import 'package:sahhof/src/widget/book_card_widget.dart';
import 'package:sahhof/src/widget/shimmer_widget.dart';

class BooksSearchScreen extends StatefulWidget {
  const BooksSearchScreen({super.key});

  @override
  State<BooksSearchScreen> createState() => _BooksSearchScreenState();
}

class _BooksSearchScreenState extends State<BooksSearchScreen> {
  @override
  void initState() {
    bookBloc.searchBooks('');
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Kitoblar"),
        centerTitle: true,
        backgroundColor: AppColors.background,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: TextField(
              style: TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Kitoblar qidirish...',
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16.sp,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey[600],
                  size: 24.sp,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              onChanged: (value) {
                bookBloc.searchBooks(value);
              },
            ),
          ),
          Expanded(child: StreamBuilder<List<SearchResult>>(
              stream: bookBloc.getSearchStream,
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
                  return CustomShimmer(
                    child: GridView.builder(
                        itemCount: 10,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,childAspectRatio: 0.55.sp,), itemBuilder: (ctx,index){
                      return Padding(
                        padding: EdgeInsets.only(left: 16.0.sp),
                        child: BookCardWidget(image: '', onTap: () {}, title: '', author: '', description: '',star: '',)
                      );
                    }),
                  );
                }
              }
          ))
        ],
      ),
    );
  }
}
