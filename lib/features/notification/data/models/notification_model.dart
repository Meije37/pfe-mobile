class NotificationModel {
  final int id;
  final String titre;
  final String message;
  final String? type;
  final bool lu;
  final DateTime dateEnvoi;
  final int? reclamationId;

  NotificationModel({
    required this.id,
    required this.titre,
    required this.message,
    required this.lu,
    required this.dateEnvoi,
    this.type,
    this.reclamationId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      titre: json['titre'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String?,
      lu: json['lu'] as bool? ?? false,
      dateEnvoi: DateTime.tryParse(json['dateEnvoi'] as String? ?? '') ?? DateTime.now(),
      reclamationId: json['reclamationId'] as int?,
    );
  }

  NotificationModel copierAvecLu(bool nouvelleValeur) {
    return NotificationModel(
      id: id,
      titre: titre,
      message: message,
      type: type,
      lu: nouvelleValeur,
      dateEnvoi: dateEnvoi,
      reclamationId: reclamationId,
    );
  }
}