
import 'package:dartz/dartz.dart';
import '../entities/auth_user.dart';

abstract class AuthRepository {
  Future<Either<String, AuthUser>> login({
    required String email,
    required String password,
  });

  Future<Either<String, String>> register({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
  });
}