
import 'package:dartz/dartz.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  const LoginUseCase(this._repository);

  Future<Either<String, AuthUser>> call({
    required String email,
    required String password,
  }) =>
      _repository.login(email: email, password: password);
}