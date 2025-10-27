import 'dart:convert';

CategoryModel categoryModelFromJson(String str) => CategoryModel.fromJson(json.decode(str));


class CategoryModel {
  int count;
  dynamic next;
  dynamic previous;
  List<CategoryResult> results;

  CategoryModel({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
    count: json["count"]??0,
    next: json["next"]??0,
    previous: json["previous"]??0,
    results: List<CategoryResult>.from(json["results"].map((x) => CategoryResult.fromJson(x))),
  );
}

class CategoryResult {
  int id;
  DateTime createdAt;
  DateTime updatedAt;
  String name;
  String image;
  String description;
  int createdBy;
  dynamic updatedBy;
  int userCategory;

  CategoryResult({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.image,
    required this.description,
    required this.createdBy,
    required this.updatedBy,
    required this.userCategory,
  });

  factory CategoryResult.fromJson(Map<String, dynamic> json) => CategoryResult(
    id: json["id"]??0,
    createdAt: json["created_at"] == null ? DateTime.now() :DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? DateTime.now() :DateTime.parse(json["updated_at"]),
    name: json["name"]??"",
    image: json["image"]??"",
    description: json["description"]??"",
    createdBy: json["created_by"]??0,
    updatedBy: json["updated_by"]??0,
    userCategory: json["user_category"]??0,
  );
}
