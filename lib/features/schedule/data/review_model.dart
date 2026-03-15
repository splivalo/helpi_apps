/// Model jedne recenzije (student ocjenjuje seniora).
class ReviewModel {
  ReviewModel({required this.rating, this.comment = '', required this.date});

  /// Ocjena 1-5.
  final int rating;

  /// Opcionalni komentar.
  final String comment;

  /// Datum recenzije (dd.MM.yyyy format).
  final String date;
}
