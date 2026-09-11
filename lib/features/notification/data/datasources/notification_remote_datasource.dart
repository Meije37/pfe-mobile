import 'package:dio/dio.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/dio_client.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  final Dio _dio = DioClient.instance.dio;

  /// GET /api/notifications — mes notifications, la plus récente en premier
  Future<List<NotificationModel>> getMesNotifications() async {
    final response = await _dio.get(AppConstants.notifications);
    final liste = response.data as List<dynamic>;
    return liste
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/notifications/non-lues/count
  Future<int> getNombreNonLues() async {
    final response = await _dio.get(AppConstants.notificationsNonLuesCount);
    return (response.data as Map<String, dynamic>)['count'] as int? ?? 0;
  }

  /// PATCH /api/notifications/{id}/lu
  Future<void> marquerCommeLue(int id) async {
    await _dio.patch('${AppConstants.notifications}/$id/lu');
  }

  /// PATCH /api/notifications/lu-toutes
  Future<void> marquerToutesCommeLues() async {
    await _dio.patch(AppConstants.notificationsLuToutes);
  }
}