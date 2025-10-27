import 'package:flutter/material.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/bloc/book/bookmark/bookmark_bloc.dart';
import 'package:sahhof/src/model/book/bookmark/book_mark_model.dart';
import 'package:sahhof/src/theme/app_colors.dart';
import 'package:sahhof/src/theme/app_style.dart';

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
            return ListView.builder(
              itemCount: data.length,
                itemBuilder: (ctx,index){
              return Text(data[index].book.title,style: AppStyle.font800(Colors.black),);
            });
          }else{
            return const Center(child: CircularProgressIndicator(),);
          }
        }
      ),
    );
  }
}
