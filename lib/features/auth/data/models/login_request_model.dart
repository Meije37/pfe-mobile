
class LoginRequestModel {
  final String email;
  final String motDePasse;

  const LoginRequestModel({
    required this.email,
    required this.motDePasse,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'motDePasse': motDePasse,
      };
}