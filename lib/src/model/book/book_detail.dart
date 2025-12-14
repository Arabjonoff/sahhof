// To parse this JSON data, do
//
//     final bookDetailModel = bookDetailModelFromJson(jsonString);

import 'package:meta/meta.dart';
import 'dart:convert';

BookDetailModel bookDetailModelFromJson(String str) => BookDetailModel.fromJson(json.decode(str));

String bookDetailModelToJson(BookDetailModel data) => json.encode(data.toJson());

class BookDetailModel {
  int id;
  dynamic pdfFile;
  List<Content> contents;
  List<Comment> comments;
  UserData userData;
  Author author;
  Category category;
  DateTime createdAt;
  DateTime updatedAt;
  String title;
  String language;
  String format;
  String paymentType;
  String description;
  String coverImage;
  dynamic publishedDate;
  int price;
  int pdf_total_pages;
  String rating;
  int saved;
  int downloads;
  int views;
  int commentsCount;
  int buyCount;
  int audioDuration;
  dynamic voice;
  bool active;
  int createdBy;
  int audio_duration;
  dynamic updatedBy;

  BookDetailModel({
    required this.id,
    required this.pdf_total_pages,
    required this.audio_duration,
    required this.pdfFile,
    required this.contents,
    required this.comments,
    required this.userData,
    required this.author,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.format,
    required this.paymentType,
    required this.description,
    required this.coverImage,
    required this.publishedDate,
    required this.price,
    required this.rating,
    required this.saved,
    required this.downloads,
    required this.views,
    required this.commentsCount,
    required this.buyCount,
    required this.audioDuration,
    required this.voice,
    required this.active,
    required this.createdBy,
    required this.updatedBy,
    required this.language,
  });

  factory BookDetailModel.fromJson(Map<String, dynamic> json) => BookDetailModel(
    id: json["id"]??0,
    pdfFile: json["pdf_file"],
    contents: json["contents"] ==null?[]:List<Content>.from(json["contents"].map((x) => Content.fromJson(x))),
    comments: json["comments"] ==null? []:List<Comment>.from(json["comments"].map((x) => Comment.fromJson(x))),
    userData: json["user_data"]==null? UserData.fromJson({}):UserData.fromJson(json["user_data"]),
    author: json["author"] == null? Author.fromJson({}):Author.fromJson(json["author"]),
    category: json["category"] == null? Category.fromJson({}):Category.fromJson(json["category"]),
    createdAt: json["created_at"] == null?  DateTime.now():DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] ==null? DateTime.now():DateTime.parse(json["updated_at"]),
    title: json["title"]??"",
    format: json["format"]??"",
    paymentType: json["payment_type"]??"",
    description: json["description"]??"",
    coverImage: json["cover_image"]??"",
    publishedDate: json["published_date"]??"",
    price: json["price"]??0,
    rating: json["rating"].toString().substring(0,3)??'',
    language: json["language"]??"",
    saved: json["saved"]??0,
    downloads: json["downloads"]??0,
    views: json["views"]??0,
    commentsCount: json["comments_count"]??0,
    buyCount: json["buy_count"]??0,
    audioDuration: json["audio_duration"]??0,
    voice: json["voice"]??"",
    active: json["active"]??false,
    createdBy: json["created_by"]??0,
    updatedBy: json["updated_by"]??0,
    audio_duration: json["audio_duration"]??0,
    pdf_total_pages: json["pdf_total_pages"]??0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "pdf_file": pdfFile,
    "contents": List<dynamic>.from(contents.map((x) => x.toJson())),
    "comments": List<dynamic>.from(comments.map((x) => x.toJson())),
    "user_data": userData.toJson(),
    "author": author.toJson(),
    "category": category.toJson(),
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
    "title": title,
    "format": format,
    "payment_type": paymentType,
    "description": description,
    "cover_image": coverImage,
    "published_date": publishedDate,
    "price": price,
    "rating": rating,
    "saved": saved,
    "downloads": downloads,
    "views": views,
    "comments_count": commentsCount,
    "buy_count": buyCount,
    "audio_duration": audioDuration,
    "voice": voice,
    "active": active,
    "created_by": createdBy,
    "updated_by": updatedBy,
  };
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

  Map<String, dynamic> toJson() => {
    "id": id,
    "full_name": fullName,
    "bio": bio,
    "profile_picture": profilePicture,
  };
}

class Category {
  int id;
  String name;
  String image;
  String description;
  int userCategory;

  Category({
    required this.id,
    required this.name,
    required this.image,
    required this.description,
    required this.userCategory,
  });

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json["id"]??0,
    name: json["name"]??"",
    image: json["image"]??"",
    description: json["description"]??"",
    userCategory: json["user_category"]??0,
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "image": image,
    "description": description,
    "user_category": userCategory,
  };
}

class Comment {
  int id;
  User user;
  int stars;
  String comment;
  DateTime createdAt;
  DateTime updatedAt;

  Comment({
    required this.id,
    required this.user,
    required this.stars,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
    id: json["id"]??0,
    user: json["user"] ==null?User.fromJson({}):User.fromJson(json["user"]),
    stars: json["stars"]??0,
    comment: json["comment"]??"",
    createdAt: json["created_at"] == null?  DateTime.now():DateTime.parse(json["created_at"]),
    updatedAt: json["updated_at"] ==null?  DateTime.now():DateTime.parse(json["updated_at"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "user": user.toJson(),
    "stars": stars,
    "comment": comment,
    "created_at": createdAt.toIso8601String(),
    "updated_at": updatedAt.toIso8601String(),
  };
}

class User {
  int id;
  String username;
  String firstName;
  String lastName;
  String role;

  User({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: json["id"],
    username: json["username"],
    firstName: json["first_name"],
    lastName: json["last_name"],
    role: json["role"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
    "first_name": firstName,
    "last_name": lastName,
    "role": role,
  };
}

class Content {
  int id;
  String name;
  List<FileElement> files;

  Content({
    required this.id,
    required this.name,
    required this.files,
  });

  factory Content.fromJson(Map<String, dynamic> json) => Content(
    id: json["id"],
    name: json["name"],
    files: List<FileElement>.from(json["files"].map((x) => FileElement.fromJson(x))),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "files": List<dynamic>.from(files.map((x) => x.toJson())),
  };
}

class FileElement {
  int id;
  String file;
  String fileType;
  int size;
  String fileFormat;

  FileElement({
    required this.id,
    required this.file,
    required this.fileType,
    required this.size,
    required this.fileFormat,
  });

  factory FileElement.fromJson(Map<String, dynamic> json) => FileElement(
    id: json["id"],
    file: json["file"],
    fileType: json["file_type"],
    size: json["size"],
    fileFormat: json["file_format"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "file": file,
    "file_type": fileType,
    "size": size,
    "file_format": fileFormat,
  };
}

class UserData {
  List<Comment> comments;
  dynamic rating;
  bool savedBook;
  bool downloadedBook;
  bool purchasedBook;
  bool viewedBook;

  UserData({
    required this.comments,
    required this.rating,
    required this.savedBook,
    required this.downloadedBook,
    required this.purchasedBook,
    required this.viewedBook,
  });

  factory UserData.fromJson(Map<String, dynamic> json) => UserData(
    comments: json["comments"] ==null? []:List<Comment>.from(json["comments"].map((x) => Comment.fromJson(x))),
    rating: json["rating"],
    savedBook: json["saved_book"]??false,
    downloadedBook: json["downloaded_book"]??false,
    purchasedBook: json["purchased_book"]??false,
    viewedBook: json["viewed_book"]??false,
  );

  Map<String, dynamic> toJson() => {
    "comments": List<dynamic>.from(comments.map((x) => x.toJson())),
    "rating": rating,
    "saved_book": savedBook,
    "downloaded_book": downloadedBook,
    "purchased_book": purchasedBook,
    "viewed_book": viewedBook,
  };
}
