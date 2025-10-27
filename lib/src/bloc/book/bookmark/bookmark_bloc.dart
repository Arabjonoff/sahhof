import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/model/book/bookmark/book_mark_model.dart';
import 'package:sahhof/src/model/http_result.dart';

class BookMarkBloc{
  final Repository _repository = Repository();
  final _fetchBookMarkInfo = PublishSubject<List<BookMarkModel>>();
  Stream<List<BookMarkModel>> get getBookMarkStream => _fetchBookMarkInfo.stream;

   getBookMark()async{
     HttpResult result = await _repository.getBookMark();
     if(result.status >=200 && result.status <300){
       var data = bookMarkModelFromJson(jsonEncode(result.result));
       _fetchBookMarkInfo.add(data);
     }
  }
}
final bookMarkBloc = BookMarkBloc();