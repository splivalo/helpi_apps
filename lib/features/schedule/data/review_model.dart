/// Model jedne recenzije (student ocjenjuje seniora).
class ReviewModel {
  ReviewModel({
    this.id,
    this.jobInstanceId,
    required this.rating,
    this.comment = '',
    required this.date,
  });

  /// ID recenzije (potreban za submit).
  final int? id;

  /// ID job instance (sesija) na koju se odnosi.
  final int? jobInstanceId;

  /// Ocjena 1-5.
  final int rating;

  /// Opcionalni komentar.
  final String comment;

  /// Datum recenzije (dd.MM.yyyy format).
  final String date;
}
