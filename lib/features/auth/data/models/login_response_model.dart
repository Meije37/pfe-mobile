
import '../../domain/entities/auth_user.dart';

class LoginResponseModel {
  final String token;
  final String email;
  final String role;

  const LoginResponseModel({
    required this.token,
    required this.email,
    required this.role,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) =>
      LoginResponseModel(
        token: json['token'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
      );

  // Convertit en entité du domaine
  AuthUser toEntity() => AuthUser(
        token: token,
        email: email,
        role: role,
      );
}