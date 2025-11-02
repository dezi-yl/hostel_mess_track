class StudentFoodRecordEntity {
  final int id;
  final int studentId;
  final int foodId;
  final DateTime date;

  StudentFoodRecordEntity({
    required this.id,
    required this.studentId,
    required this.foodId,
    required this.date,
  });
}
