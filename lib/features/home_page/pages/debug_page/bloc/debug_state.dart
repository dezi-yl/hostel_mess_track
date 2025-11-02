import 'package:hostel_mess_2/core/domain/entities/food_entity.dart';
import 'package:hostel_mess_2/core/domain/entities/room_entity.dart';
import 'package:hostel_mess_2/core/domain/entities/student_entity.dart';

enum DebugStatus { initial, loading, success, failure }

class DebugState {
  final DebugStatus status;
  final List<StudentEntity> students;
  final List<RoomEntity> rooms;
  final List<FoodEntity> foods;
  final List<Map<String, dynamic>> records; // Changed type
  final String? errorMessage;

  DebugState({
    this.status = DebugStatus.initial,
    this.students = const [],
    this.rooms = const [],
    this.foods = const [],
    this.records = const [], // Changed type
    this.errorMessage,
  });

  DebugState copyWith({
    DebugStatus? status,
    List<StudentEntity>? students,
    List<RoomEntity>? rooms,
    List<FoodEntity>? foods,
    List<Map<String, dynamic>>? records, // Changed type
    String? errorMessage,
  }) {
    return DebugState(
      status: status ?? this.status,
      students: students ?? this.students,
      rooms: rooms ?? this.rooms,
      foods: foods ?? this.foods,
      records: records ?? this.records,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
