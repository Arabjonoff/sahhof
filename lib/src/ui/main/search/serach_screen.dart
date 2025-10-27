import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/bloc/author/author_bloc.dart';
import 'package:sahhof/src/model/author/author_model.dart';
import 'package:sahhof/src/ui/main/search/books_search_screen.dart';

import '../../../bloc/category/category_bloc.dart';
import '../../../theme/app_colors.dart';
import '../../../widget/shimmer_widget.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  @override
  void initState() {
    authorBloc.getAllAuthor();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: 20.h),
            _buildSearchField(),
            SizedBox(height: 30.h),
            _buildCategoriesSection(),
          ],
        ),
      ),
    );
  }


  Widget _buildHeader() {
    return Text(
      'Qidiruv',
      style: TextStyle(
        fontSize: 28.sp,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSearchField() {
    return GestureDetector(
      onTap: (){
        Navigator.push(context, MaterialPageRoute(builder: (builder){
          return BooksSearchScreen();
        }));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: TextField(
          enabled: false,
          decoration: InputDecoration(
            hintText: 'Kitoblar yoki Mualliflarni qidirish...',
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
            // Qidiruv logikasi
          },
        ),
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mualliflar',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: MediaQuery.of(context).size.height*0.55,
          child: StreamBuilder<List<AuthorResult>>(
              stream: authorBloc.getAuthorStream,
              builder: (context, snapshot) {
                if(snapshot.hasData){
                  var data = snapshot.data!;
                  return GridView.builder(
                    itemCount: data.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,childAspectRatio: 3.5.sp,crossAxisSpacing: 10.w,mainAxisSpacing: 10.h), itemBuilder: (ctx,index){
                    return GestureDetector(
                      onTap: (){
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 2.w,vertical: 4.h),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color:AppColors.grey.withOpacity(0.3)),
                              color: AppColors.white
                          ),
                          child: Text(data[index].fullName,textAlign: TextAlign.center,style: TextStyle(color:AppColors.black),)),
                    );
                  });
                }
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
                                border: Border.all(color: AppColors.grey.withOpacity(0.3)),
                                color:AppColors.white
                            ),
                            child: Text("                             ",style: TextStyle(color:AppColors.black),));
                      }),
                );
              }
          ),
        ),

      ],
    );
  }



  Widget _buildBookCard(BookItem book) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Book cover
          Container(
            width: 60.w,
            height: 80.h,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              image: DecorationImage(
                image: NetworkImage(book.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // Book details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Text(
                  book.author,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  book.listeners,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[500],
                  ),
                ),
                SizedBox(height: 8.h),

                // Rating and actions
                Row(
                  children: [
                    // Star rating
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < book.rating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                          size: 16.sp,
                        );
                      }),
                    ),
                    Spacer(),

                    // Action buttons
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.indigo[50],
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.headphones,
                        color: Colors.indigo,
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Icon(
                        Icons.download_outlined,
                        color: Colors.grey[600],
                        size: 16.sp,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: Colors.orange,
                          size: 16.sp,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          book.rating.toString(),
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Models
class CategoryItem {
  final IconData icon;
  final String title;

  CategoryItem({
    required this.icon,
    required this.title,
  });
}

class BookItem {
  final String title;
  final String author;
  final String listeners;
  final double rating;
  final String imageUrl;

  BookItem({
    required this.title,
    required this.author,
    required this.listeners,
    required this.rating,
    required this.imageUrl,
  });
}

// Ishlatish misoli
class SearchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Search Screen',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        fontFamily: 'Roboto',
      ),
      home: SearchScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}