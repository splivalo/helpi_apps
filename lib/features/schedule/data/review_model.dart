/// Model for one review (student rates senior).
class ReviewModel {
  ReviewModel({
    this.id,
    this.jobInstanceId,
    required this.rating,
    this.comment = '',
    required this.date,
  });

  /// Review ID (needed for submit).
  final int? id;

  /// ID job instance (sesija) na koju se odnosi.
  final int? jobInstanceId;

  /// Rating 1-5.
  final int rating;

  /// Opcionalni komentar.
  final String comment;

  /// Review date (dd.MM.yyyy format).
  final String date;
}
