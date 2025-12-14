import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/model/author/author_model.dart';
import 'package:sahhof/src/model/book/book_model.dart';
import 'package:sahhof/src/model/http_result.dart';

import '../../model/search/search_model.dart';

class BookBloc{
  final Repository _repository = Repository();
  final _fetchBookInfo = PublishSubject<List<BookResult>>();
  final _fetchSearchInfo = PublishSubject<List<SearchResult>>();
  final _fetchAuthorInfo = PublishSubject<List<BookResult>>();
  Stream<List<BookResult>> get getBookStream => _fetchBookInfo.stream;
  Stream<List<SearchResult>> get getSearchStream => _fetchSearchInfo.stream;
  Stream<List<BookResult>> get getAuthorStream => _fetchAuthorInfo.stream;

  Future<void> getBooks(id)async{
    HttpResult result = await _repository.getBooks(id);
    if(result.isSuccess){
      var data = BookModel.fromJson(result.result);
      _fetchBookInfo.add(data.results);
    }else{
      _fetchBookInfo.addError(result.result);
    }
  }
  Future<void> searchBooks(id)async{
    HttpResult result = await _repository.searchBook(id);
    if(result.isSuccess){
      var data = SearchModel.fromJson(result.result);
      _fetchSearchInfo.add(data.books);
    }else{
      _fetchSearchInfo.addError(result.result);
    }
  }
  Future<void> getAuthorId(id)async{
    HttpResult result = await _repository.getAuthorId(id);
    if(result.isSuccess){
      var data = BookModel.fromJson(result.result);
      _fetchAuthorInfo.add(data.results);
    }else{
      _fetchAuthorInfo.addError(result.result);
    }
  }
}
final bookBloc = BookBloc();