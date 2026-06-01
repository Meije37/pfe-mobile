
import 'package:dartz/dartz.dart';
import '../repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository _repository;
  const RegisterUseCase(this._repository);

  Future<Either<String, String>> call({
    required String nom,
    required String prenom,
    required String email,
    required String telephone,
    required String password,
  }) =>
      _repository.register(
        nom: nom,
        prenom: prenom,
        email: email,
        telephone: telephone,
        password: password,
      );
}