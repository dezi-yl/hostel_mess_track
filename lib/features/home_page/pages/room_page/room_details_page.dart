import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/core/domain/entities/room_entity.dart';
import 'package:hostel_mess_2/core/domain/entities/student_entity.dart';
import 'package:hostel_mess_2/core/domain/usecases/student_repo_usecase.dart';
import 'package:hostel_mess_2/core/di/dependency_injection.dart';

// Events
abstract class RoomDetailsEvent {}

class LoadStudentsInRoom extends RoomDetailsEvent {
  final int roomId;
  LoadStudentsInRoom(this.roomId);
}

// States
abstract class RoomDetailsState {}

class RoomDetailsInitial extends RoomDetailsState {}

class RoomDetailsLoading extends RoomDetailsState {}

class RoomDetailsLoaded extends RoomDetailsState {
  final List<StudentEntity> students;
  RoomDetailsLoaded(this.students);
}

class RoomDetailsError extends RoomDetailsState {
  final String message;
  RoomDetailsError(this.message);
}

// BLoC
class RoomDetailsBloc extends Bloc<RoomDetailsEvent, RoomDetailsState> {
  final StudentOperationsUseCases _studentOperationsUseCases;

  RoomDetailsBloc(this._studentOperationsUseCases)
    : super(RoomDetailsInitial()) {
    on<LoadStudentsInRoom>(_onLoadStudentsInRoom);
  }

  Future<void> _onLoadStudentsInRoom(
    LoadStudentsInRoom event,
    Emitter<RoomDetailsState> emit,
  ) async {
    emit(RoomDetailsLoading());
    try {
      final students = await _studentOperationsUseCases.getAllStudentsInRoom(
        event.roomId,
      );
      emit(RoomDetailsLoaded(students));
    } catch (e) {
      emit(RoomDetailsError(e.toString()));
    }
  }
}

// UI
class RoomDetailsPage extends StatelessWidget {
  final RoomEntity room;

  const RoomDetailsPage({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          RoomDetailsBloc(locator<StudentOperationsUseCases>())
            ..add(LoadStudentsInRoom(room.id)),
      child: Scaffold(
        appBar: AppBar(title: Text('Room ${room.name}')),
        body: BlocBuilder<RoomDetailsBloc, RoomDetailsState>(
          builder: (context, state) {
            if (state is RoomDetailsLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is RoomDetailsLoaded) {
              if (state.students.isEmpty) {
                return const Center(child: Text('No students in this room.'));
              }
              return ListView.builder(
                itemCount: state.students.length,
                itemBuilder: (context, index) {
                  final student = state.students[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(child: Text(student.name[0])),
                      title: Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text('Reg: ${student.reg}'),
                    ),
                  );
                },
              );
            }
            if (state is RoomDetailsError) {
              return Center(child: Text(state.message));
            }
            return const Center(child: Text('Select a room to see students.'));
          },
        ),
      ),
    );
  }
}
