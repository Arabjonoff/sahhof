import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/model/author/author_model.dart';
import 'package:sahhof/src/model/http_result.dart';

class AuthorBloc{
  final Repository _repository = Repository();
  final _fetchAuthor = PublishSubject<List<AuthorResult>>();
  Stream<List<AuthorResult>> get getAuthorStream => _fetchAuthor.stream;

  getAllAuthor()async{
    HttpResult result = await _repository.getAuthors();
    if(result.isSuccess){
      AuthorModel model = AuthorModel.fromJson(result.result);
      _fetchAuthor.sink.add(model.results);
    }else{
      _fetchAuthor.sink.addError(result.result);
    }
  }
}
final authorBloc = AuthorBloc();