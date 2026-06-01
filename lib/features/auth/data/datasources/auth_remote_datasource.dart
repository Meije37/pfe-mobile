import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';

abstract class AuthRemoteDataSource {
  Future<LoginResponseModel> login(LoginRequestModel request);
  Future<String> register(Map<String, dynamic> body);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    final response = await _dio.post(
      AppConstants.loginEndpoint,
      data: request.toJson(),
    );
    return LoginResponseModel.fromJson(response.data as Map<String, dynamic>);
  }



@override
Future<String> register(Map<String, dynamic> body) async {
  final response = await _dio.post(
    AppConstants.registerEndpoint,
    data: body,
  );
  final data = response.data as Map<String, dynamic>;
  return data['message'] as String? ?? data['email'] as String? ?? 'success';
}
}