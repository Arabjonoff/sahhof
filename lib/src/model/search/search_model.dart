// To parse this JSON data, do
//
//     final searchModel = searchModelFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

SearchModel searchModelFromJson(String str) => SearchModel.fromJson(json.decode(str));

String searchModelToJson(SearchModel data) => json.encode(data.toJson());

class SearchModel {
  bool success;
  List<SearchResult> books;

  SearchModel({
    required this.success,
    required this.books,
  });

  factory SearchModel.fromJson(Map<String, dynamic> json) => SearchModel(
    success: json["success"],
    books: List<SearchResult>.from(json["books"].map((x) => SearchResult.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "success": success,
    "books": List<dynamic>.from(books.map((x) => x.toJson())),
  };
}

class SearchResult {
  int id;
  String title;
  num rating;
  String author;
  String coverImage;
  int price;

  SearchResult({
    required this.id,
    required this.title,
    required this.author,
    required this.coverImage,
    required this.price,
    required this.rating,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    id: json["id"],
    title: json["title"],
    author: json["author"],
    coverImage: json["cover_image"],
    price: json["price"],
    rating: json["rating"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "author": author,
    "cover_image": coverImage,
    "price": price,
  };
}
