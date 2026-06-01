
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;

  LoginSubmitted({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String password;

  RegisterSubmitted({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.password,
  });

  @override
  List<Object?> get props => [nom, prenom, email, telephone, password];
}

class AuthLogoutRequested extends AuthEvent {}