import 'dart:convert';
List<BookMarkModel> bookMarkModelFromJson(String str) => List<BookMarkModel>.from(json.decode(str).map((x) => BookMarkModel.fromJson(x)));


class BookMarkModel {
  int id;
  Book book;
  DateTime createdAt;
  DateTime updatedAt;

  BookMarkModel({
    required this.id,
    required this.book,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BookMarkModel.fromJson(Map<String, dynamic> json) => BookMarkModel(
    id: json["id"]??0,
    book: json["book"]==null ? Book.fromJson({}):Book.fromJson(json["book"]),
    createdAt: json["created_at"] == null ? DateTime.now() : DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? DateTime.now() : DateTime.parse(json["updated_at"]),
  );

}

class Book {
  int id;
  String title;
  Author author;
  int price;
  String coverImage;
  DateTime createdAt;
  DateTime updatedAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.price,
    required this.coverImage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
    id: json["id"]??0,
    title: json["title"]??"",
    author: json["author"] == null ? Author.fromJson({}):Author.fromJson(json["author"]),
    price: json["price"]??0,
    coverImage: json["cover_image"]??"",
    createdAt: json["created_at"] == null ? DateTime.now():DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] == null ? DateTime.now():DateTime.parse(json["updated_at"]),
  );
}

class Author {
  int id;
  String fullName;
  String bio;
  String profilePicture;

  Author({
    required this.id,
    required this.fullName,
    required this.bio,
    required this.profilePicture,
  });

  factory Author.fromJson(Map<String, dynamic> json) => Author(
    id: json["id"]??0,
    fullName: json["full_name"]??"",
    bio: json["bio"]??"",
    profilePicture: json["profile_picture"]??"",
  );

}
