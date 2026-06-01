
import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_user.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthLoginSuccess extends AuthState {
  final AuthUser user;
  AuthLoginSuccess(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthRegisterSuccess extends AuthState {
  final String email;
  AuthRegisterSuccess(this.email);
  @override
  List<Object?> get props => [email];
}

class AuthFailure extends AuthState {
  final String message;
  AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}