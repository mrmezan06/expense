import 'dart:convert';

class User {
  String email;
  String password;
  String id;

  User({
    required this.email,
    required this.password,
    required this.id,
  });

  factory User.fromRawJson(String str) => User.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());

  factory User.fromJson(Map<String, dynamic> json) => User(
        email: json["email"],
        password: json["password"],
        id: json["_id"],
      );

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "_id": id,
      };
}
