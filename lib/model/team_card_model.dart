class TeamCard {
  final String teamCardId;
  final String cardName;
  final String? cardType;
  final String? cardDescription;
  final int? teamCardStatus;
  final String? teamType;

  TeamCard({
    required this.teamCardId,
    required this.cardName,
    this.cardType,
    this.cardDescription,
    this.teamCardStatus,
    this.teamType,
  });

  factory TeamCard.fromJson(Map<String, dynamic> json) {
    return TeamCard(
      teamCardId: json['team_card_id'] as String,
      cardName: (json['card_name'] ?? '').toString(),
      cardType: json['card_type']?.toString(),
      cardDescription: json['card_description']?.toString(),
      teamCardStatus: json['team_card_status'] is int
          ? json['team_card_status'] as int
          : int.tryParse(json['team_card_status']?.toString() ?? ''),
      teamType: json['team_type']?.toString(),
    );
  }
}


