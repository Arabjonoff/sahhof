import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/model/category/category_model.dart';
import 'package:sahhof/src/model/http_result.dart';

class CategoryBloc{
  final Repository _repository = Repository();
  final _fetchCategoryInfo = PublishSubject<List<CategoryResult>>();
  Stream<List<CategoryResult>> get getCategoryStream => _fetchCategoryInfo.stream;

  getCategory()async{
    HttpResult res = await _repository.getCategories();
    if(res.status >= 200 && res.status < 300){
      CategoryModel model = CategoryModel.fromJson(res.result);
      _fetchCategoryInfo.add(model.results);
    }else{
      _fetchCategoryInfo.addError(res.result);
    }
  }
}
final categoryBloc = CategoryBloc();