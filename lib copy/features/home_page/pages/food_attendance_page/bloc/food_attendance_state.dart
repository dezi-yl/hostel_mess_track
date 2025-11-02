part of 'food_attendance_bloc.dart';

enum FoodAttendanceStatus { initial, loading, success, failure }

@immutable
class FoodAttendanceState {
  FoodAttendanceState({
    this.status = FoodAttendanceStatus.initial,
    this.foods = const [],
    this.attendanceCounts = const {},
    DateTime? selectedDate,
    this.errorMessage,
    this.successMessage,
    this.searchedStudents = const [],
    this.isSearching = false,
    this.studentsForFood = const [],
    this.totalUniqueStudents = 0,
  }) : selectedDate = selectedDate ?? DateTime.now();

  final FoodAttendanceStatus status;
  final List<FoodEntity> foods;
  final Map<int, int> attendanceCounts;
  final DateTime selectedDate;
  final String? errorMessage;
  final String? successMessage;
  final List<StudentEntity> searchedStudents;
  final bool isSearching;
  final List<StudentEntity> studentsForFood;
  final int totalUniqueStudents;

  FoodAttendanceState copyWith({
    FoodAttendanceStatus? status,
    List<FoodEntity>? foods,
    Map<int, int>? attendanceCounts,
    DateTime? selectedDate,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    List<StudentEntity>? searchedStudents,
    bool? isSearching,
    List<StudentEntity>? studentsForFood,
    int? totalUniqueStudents,
  }) {
    return FoodAttendanceState(
      status: status ?? this.status,
      foods: foods ?? this.foods,
      attendanceCounts: attendanceCounts ?? this.attendanceCounts,
      selectedDate: selectedDate ?? this.selectedDate,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      successMessage: clearSuccess
          ? null
          : successMessage ?? this.successMessage,
      searchedStudents: searchedStudents ?? this.searchedStudents,
      isSearching: isSearching ?? this.isSearching,
      studentsForFood: studentsForFood ?? this.studentsForFood,
      totalUniqueStudents: totalUniqueStudents ?? this.totalUniqueStudents,
    );
  }
}
