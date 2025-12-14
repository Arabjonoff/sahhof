import 'dart:convert';

ProfileModel profileModelFromJson(String str) => ProfileModel.fromJson(json.decode(str));

String profileModelToJson(ProfileModel data) => json.encode(data.toJson());

class ProfileModel {
  int id;
  String username;
  String firstName;
  String lastName;
  String phone;
  String role;
  bool emailVerified;
  String email;
  bool isActiveUser;

  ProfileModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.role,
    required this.emailVerified,
    required this.email,
    required this.isActiveUser,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) => ProfileModel(
    id: json["id"],
    username: json["username"],
    firstName: json["first_name"],
    lastName: json["last_name"],
    phone: json["phone"],
    role: json["role"],
    emailVerified: json["email_verified"],
    email: json["email"],
    isActiveUser: json["is_active_user"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "username": username,
    "first_name": firstName,
    "last_name": lastName,
    "phone": phone,
    "role": role,
    "email_verified": emailVerified,
    "email": email,
    "is_active_user": isActiveUser,
  };
}
