import 'dart:convert';

import 'package:rxdart/rxdart.dart';
import 'package:sahhof/src/api/repository.dart';
import 'package:sahhof/src/model/banner/banner_model.dart';
import 'package:sahhof/src/model/http_result.dart';

class BannerBloc{
  final Repository _repository = Repository();
  final _fetchBannerInfo = PublishSubject<List<BannerModel>>();
  Stream<List<BannerModel>> get getBannerStream => _fetchBannerInfo.stream;

  getAllBanner()async{
    HttpResult res = await _repository.getBanner();
    if(res.isSuccess){
      _fetchBannerInfo.add(bannerModelFromJson(json.encode(res.result)));
    }else {
      _fetchBannerInfo.addError(res.result);
    }
  }
}

final bannerBloc = BannerBloc();