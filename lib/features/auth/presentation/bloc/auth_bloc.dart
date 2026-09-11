import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';
import '../../../../core/network/notification_socket_service.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase    _loginUseCase;
  final RegisterUseCase _registerUseCase;

  AuthBloc({
    required LoginUseCase loginUseCase,
    required RegisterUseCase registerUseCase,
  })  : _loginUseCase = loginUseCase,
        _registerUseCase = registerUseCase,
        super(AuthInitial()) {
    on<LoginSubmitted>(_onLogin);
    on<RegisterSubmitted>(_onRegister);
  }

Future<void> _onLogin(
  LoginSubmitted event,
  Emitter<AuthState> emit,
) async {
  emit(AuthLoading());
  final result = await _loginUseCase(
    email: event.email,
    password: event.password,
  );
  result.fold(
    (error) => emit(AuthFailure(error)),
    (user) {
      NotificationSocketService.instance.connecter();
      emit(AuthLoginSuccess(user));
    },
  );
}
  Future<void> _onRegister(
    RegisterSubmitted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    final result = await _registerUseCase(
      nom: event.nom,
      prenom: event.prenom,
      email: event.email,
      telephone: event.telephone,
      password: event.password,
    );
    result.fold(
      (error) => emit(AuthFailure(error)),
      (email) => emit(AuthRegisterSuccess(email)),
    );
  }
}