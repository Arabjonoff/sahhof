import 'dart:convert';

List<BannerModel> bannerModelFromJson(String str) => List<BannerModel>.from(json.decode(str).map((x) => BannerModel.fromJson(x)));
class BannerModel {
  int id;
  String text;
  String image;

  BannerModel({
    required this.id,
    required this.text,
    required this.image,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) => BannerModel(
    id: json["id"]??0,
    text: json["text"]??"",
    image: json["image"]??"",
  );
}
