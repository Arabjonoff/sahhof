import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/model/book/book_detail.dart';
import 'package:sahhof/src/model/http_result.dart';

class BookDetailBloc{
  final Repository _repository = Repository();
  final _fetchBookDetailInfo = PublishSubject<BookDetailModel>();
  Stream<BookDetailModel> get getBookDetailStream => _fetchBookDetailInfo.stream;

  getBookDetail(int id)async{
    HttpResult result = await _repository.getBookById(id);
    if(result.isSuccess){
      var data = BookDetailModel.fromJson(result.result);
      _fetchBookDetailInfo.add(data);
    }
    else{
      _fetchBookDetailInfo.addError(result.result);
    }
  }
}
final bookDetailBloc = BookDetailBloc();