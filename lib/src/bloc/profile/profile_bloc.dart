import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/model/http_result.dart';
import 'package:sahhof/src/model/profile/profile_model.dart';

class ProfileBloc{
  final Repository _repository = Repository();
  final _fetchProfile = BehaviorSubject<ProfileModel>();
  Stream<ProfileModel> get getProfileStream => _fetchProfile.stream;

  getAllProfile()async{
    HttpResult result = await _repository.getProfile();
    if(result.isSuccess){
      ProfileModel data = ProfileModel.fromJson(result.result);
      _fetchProfile.sink.add(data);
    }else{
    }
  }
}
final ProfileBloc profileBloc = ProfileBloc();