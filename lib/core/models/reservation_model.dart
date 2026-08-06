class ReservationModel {
  final String id;
  final String hebergementId;
  final String visiteurId;
  final String proprietaireId;
  final DateTime dateDebut;
  final DateTime dateFin;
  final int nbPersonnes;
  final String? message;
  final String statut;
  final DateTime? dateReponse;
  final DateTime createdAt;

  ReservationModel({
    required this.id,
    required this.hebergementId,
    required this.visiteurId,
    required this.proprietaireId,
    required this.dateDebut,
    required this.dateFin,
    this.nbPersonnes = 1,
    this.message,
    this.statut = 'en_attente',
    this.dateReponse,
    required this.createdAt,
  });

  bool get enAttente => statut == 'en_attente';
  bool get confirmee  => statut == 'confirmee';
  bool get refusee    => statut == 'refusee';
  bool get annulee    => statut == 'annulee';

  int get nombreDeNuits => dateFin.difference(dateDebut).inDays;

  factory ReservationModel.fromMap(Map<String, dynamic> map) {
    return ReservationModel(
      id: map['id'] ?? '',
      hebergementId: map['hebergement_id'] ?? '',
      visiteurId: map['visiteur_id'] ?? '',
      proprietaireId: map['proprietaire_id'] ?? '',
      dateDebut: DateTime.parse(map['date_debut']),
      dateFin: DateTime.parse(map['date_fin']),
      nbPersonnes: map['nb_personnes'] ?? 1,
      message: map['message'],
      statut: map['statut'] ?? 'en_attente',
      dateReponse: map['date_reponse'] != null
          ? DateTime.parse(map['date_reponse'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'hebergement_id': hebergementId,
      'visiteur_id': visiteurId,
      'proprietaire_id': proprietaireId,
      'date_debut': dateDebut.toIso8601String().split('T').first,
      'date_fin': dateFin.toIso8601String().split('T').first,
      'nb_personnes': nbPersonnes,
      'message': message,
    };
  }
}
