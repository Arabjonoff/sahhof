class BookModel {
  int count;
  String next;
  String previous;
  List<BookResult> results;

  BookModel({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
    count: json["count"]??0,
    next: json["next"]??"",
    previous: json["previous"]??"",
    results: List<BookResult>.from(json["results"].map((x) => BookResult.fromJson(x))),
  );

}

class BookResult {
  int id;
  Author author;
  String title;
  String format;
  String paymentType;
  String description;
  String coverImage;
  DateTime publishedDate;
  int price;
  String rating;
  int saved;
  int downloads;
  int views;
  int commentsCount;
  int buyCount;
  int audioDuration;
  String voice;
  bool active;
  int category;

  BookResult({
    required this.id,
    required this.author,
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
    required this.category,
  });

  factory BookResult.fromJson(Map<String, dynamic> json) => BookResult(
    id: json["id"]??0,
    author: json["author"] == null ? Author(id: 0, fullName: "", bio: "", profilePicture: "") :Author.fromJson(json["author"]),
    title: json["title"]??"",
    format: json["format"]??"",
    paymentType: json["payment_type"]??"",
    description: json["description"]??"",
    coverImage: json["cover_image"]??"",
    publishedDate: json["published_date"] == null ? DateTime.now() :DateTime.parse(json["published_date"]),
    price: json["price"]??0,
    rating: json["rating"]??0,
    saved: json["saved"]??0,
    downloads: json["downloads"]??0,
    views: json["views"]??0,
    commentsCount: json["comments_count"]??"",
    buyCount: json["buy_count"]??0,
    audioDuration: json["audio_duration"]??0,
    voice: json["voice"]??"",
    active: json["active"]??false,
    category: json["category"]??0,
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

  Map<String, dynamic> toJson() => {
    "id": id,
    "full_name": fullName,
    "bio": bio,
    "profile_picture": profilePicture,
  };
}
