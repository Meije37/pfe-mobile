class CommentaireModel {
  final int id;
  final String contenu;
  final String visibilite;
  final DateTime dateCommentaire;
  final String auteurNom;
  final String auteurRole;
  final int auteurId;

  CommentaireModel({
    required this.id,
    required this.contenu,
    required this.visibilite,
    required this.dateCommentaire,
    required this.auteurNom,
    required this.auteurRole,
    required this.auteurId,
  });

  factory CommentaireModel.fromJson(Map<String, dynamic> json) {
    return CommentaireModel(
      id: json['id'] as int,
      contenu: json['contenu'] as String? ?? '',
      visibilite: json['visibilite'] as String? ?? 'PUBLIC',
      dateCommentaire: DateTime.parse(json['dateCommentaire'] as String),
      auteurNom: json['auteurNom'] as String? ?? 'Utilisateur',
      auteurRole: json['auteurRole'] as String? ?? '',
      auteurId: json['auteurId'] as int? ?? 0,
    );
  }
}