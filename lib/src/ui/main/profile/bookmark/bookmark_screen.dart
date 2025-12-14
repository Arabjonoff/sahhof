import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/bloc/book/bookmark/bookmark_bloc.dart';
import 'package:sahhof/src/model/book/bookmark/book_mark_model.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';
import 'package:sahhof/src/ui/main/detail/detail_screen.dart';
import 'package:sahhof/src/widget/book_card_widget.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  final Repository _repository = Repository();
  @override
  void initState() {
    bookMarkBloc.getBookMark();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        centerTitle: true,
        title: const Text("Saqlanganlar"),
      ),
      body: StreamBuilder<List<BookMarkModel>>(
        stream: bookMarkBloc.getBookMarkStream,
        builder: (context, snapshot) {
          if(snapshot.hasData){
            var data = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: GridView.builder(
                itemCount: data.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2,childAspectRatio: 0.55.sp,), itemBuilder: (ctx,index){
                return BookCardWidget(image: data[index].book.coverImage, onTap: (){
                  Navigator.push(context, MaterialPageRoute(builder: (ctx){
                    return DetailScreen(id: data[index].book.id);
                  }));
                }, title: data[index].book.title, author: data[index].book.author.fullName, description: '', star: '');
              }),
            );
          }else{
            return const Center(child: CircularProgressIndicator(),);
          }
        }
      ),
    );
  }
}
