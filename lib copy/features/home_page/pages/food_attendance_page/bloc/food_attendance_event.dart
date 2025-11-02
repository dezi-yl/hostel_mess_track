part of 'food_attendance_bloc.dart';

@immutable
abstract class FoodAttendanceEvent {}

class LoadFoodData extends FoodAttendanceEvent {}

class ChangeDate extends FoodAttendanceEvent {
  final DateTime newDate;
  ChangeDate(this.newDate);
}

class AddFood extends FoodAttendanceEvent {
  final String foodName;
  AddFood(this.foodName);
}

class DeleteFood extends FoodAttendanceEvent {
  final int foodId;
  DeleteFood(this.foodId);
}

class SearchStudent extends FoodAttendanceEvent {
  final String query;
  SearchStudent({required this.query});
}

class ClearSearch extends FoodAttendanceEvent {}

class MarkAttendance extends FoodAttendanceEvent {
  final int studentId;
  final int foodId;
  MarkAttendance({required this.studentId, required this.foodId});
}

class LoadStudentsForFood extends FoodAttendanceEvent {
  final int foodId;
  final DateTime date;
  LoadStudentsForFood({required this.foodId, required this.date});
}

class FoodAttendanceError extends FoodAttendanceEvent {
  final String errorMessage;
  FoodAttendanceError({required this.errorMessage});
}

class ScanAndMarkAttendance extends FoodAttendanceEvent {
  final String qrCode;
  final int foodId;
  ScanAndMarkAttendance({required this.qrCode, required this.foodId});
}

class ClearFoodAttendanceMessages extends FoodAttendanceEvent {}
