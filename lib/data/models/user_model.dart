class UserModel {
  final String id;
  final String fullName;
  final String language;

  UserModel({required this.id, required this.fullName, this.language = 'es'});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      language: json['language'] ?? 'es',
    );
  }
}