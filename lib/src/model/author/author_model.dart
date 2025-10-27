class AuthorModel {
  int count;
  String next;
  String previous;
  List<AuthorResult> results;

  AuthorModel({
    required this.count,
    required this.next,
    required this.previous,
    required this.results,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) => AuthorModel(
    count: json["count"]??0,
    next: json["next"]??"",
    previous: json["previous"]??"",
    results: List<AuthorResult>.from(json["results"].map((x) => AuthorResult.fromJson(x))),
  );

}

class AuthorResult {
  int id;
  String fullName;
  String bio;
  String profilePicture;

  AuthorResult({
    required this.id,
    required this.fullName,
    required this.bio,
    required this.profilePicture,
  });

  factory AuthorResult.fromJson(Map<String, dynamic> json) => AuthorResult(
    id: json["id"]??0,
    fullName: json["full_name"]??"",
    bio: json["bio"]??"",
    profilePicture: json["profile_picture"]??"",
  );
}
