
class AuthUser {
  final String token;
  final String email;
  final String role;

  const AuthUser({
    required this.token,
    required this.email,
    required this.role,
  });
}