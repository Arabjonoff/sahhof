import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/model/book/book_model.dart';
import 'package:sahhof/src/model/http_result.dart';

class BookBloc{
  final Repository _repository = Repository();
  final _fetchBookInfo = PublishSubject<List<BookResult>>();
  Stream<List<BookResult>> get getBookStream => _fetchBookInfo.stream;

  Future<void> getBooks(id)async{
    HttpResult result = await _repository.getBooks(id);
    if(result.isSuccess){
      var data = BookModel.fromJson(result.result);
      _fetchBookInfo.add(data.results);
    }else{
      _fetchBookInfo.addError(result.result);
    }
  }
}
final bookBloc = BookBloc();