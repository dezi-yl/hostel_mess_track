import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/core/domain/entities/room_entity.dart';
import 'package:hostel_mess_2/core/domain/usecases/student_repo_usecase.dart';
import 'package:hostel_mess_2/core/utils/snackbar_service.dart';
import 'package:hostel_mess_2/features/home_page/pages/room_page/room_details_page.dart';
import 'package:hostel_mess_2/features/home_page/pages/students_page/bloc/students_page_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/students_page/bloc/students_page_event.dart';

// Events
abstract class RoomEvent {}

class LoadRooms extends RoomEvent {}

class AddRoom extends RoomEvent {
  final String name;
  AddRoom(this.name);
}

class ToggleSelectionMode extends RoomEvent {}

class ToggleRoomSelection extends RoomEvent {
  final int roomId;
  ToggleRoomSelection(this.roomId);
}

class DeleteSelectedRooms extends RoomEvent {}

class ClearSelection extends RoomEvent {}

class SelectAllRooms extends RoomEvent {}

// States
abstract class RoomState {}

class RoomInitial extends RoomState {}

class RoomLoading extends RoomState {}

class RoomLoaded extends RoomState {
  final Map<RoomEntity, int> roomStudentCounts;
  final bool isSelectionMode;
  final List<int> selectedRoomIds;

  RoomLoaded(
    this.roomStudentCounts, {
    this.isSelectionMode = false,
    this.selectedRoomIds = const [],
  });

  RoomLoaded copyWith({
    Map<RoomEntity, int>? roomStudentCounts,
    bool? isSelectionMode,
    List<int>? selectedRoomIds,
  }) {
    return RoomLoaded(
      roomStudentCounts ?? this.roomStudentCounts,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedRoomIds: selectedRoomIds ?? this.selectedRoomIds,
    );
  }
}

class RoomError extends RoomState {
  final String message;
  RoomError(this.message);
}

// BLoC
class RoomBloc extends Bloc<RoomEvent, RoomState> {
  final StudentOperationsUseCases _studentOperationsUseCases;

  RoomBloc(this._studentOperationsUseCases) : super(RoomInitial()) {
    on<LoadRooms>(_onLoadRooms);
    on<AddRoom>(_onAddRoom);
    on<ToggleSelectionMode>(_onToggleSelectionMode);
    on<ToggleRoomSelection>(_onToggleRoomSelection);
    on<DeleteSelectedRooms>(_onDeleteSelectedRooms);
    on<ClearSelection>(_onClearSelection);
    on<SelectAllRooms>(_onSelectAllRooms);
  }

  Future<void> _onLoadRooms(LoadRooms event, Emitter<RoomState> emit) async {
    if (state is RoomLoaded && (state as RoomLoaded).isSelectionMode) {
      final currentState = state as RoomLoaded;
      emit(RoomLoading());
      final rooms = await _studentOperationsUseCases.getAllRooms();
      final students = await _studentOperationsUseCases.getAllStudents();
      final roomStudentCounts = <RoomEntity, int>{};
      for (final room in rooms) {
        final count = students.where((s) => s.roomId == room.id).length;
        roomStudentCounts[room] = count;
      }
      emit(currentState.copyWith(roomStudentCounts: roomStudentCounts));
    } else {
      emit(RoomLoading());
      final rooms = await _studentOperationsUseCases.getAllRooms();
      final students = await _studentOperationsUseCases.getAllStudents();
      final roomStudentCounts = <RoomEntity, int>{};
      for (final room in rooms) {
        final count = students.where((s) => s.roomId == room.id).length;
        roomStudentCounts[room] = count;
      }
      emit(RoomLoaded(roomStudentCounts));
    }
  }

  Future<void> _onAddRoom(AddRoom event, Emitter<RoomState> emit) async {
    try {
      await _studentOperationsUseCases.addRoom(event.name);
      add(LoadRooms());
    } catch (e) {
      emit(RoomError(e.toString()));
    }
  }

  void _onToggleSelectionMode(
    ToggleSelectionMode event,
    Emitter<RoomState> emit,
  ) {
    if (state is RoomLoaded) {
      final currentState = state as RoomLoaded;
      emit(
        currentState.copyWith(
          isSelectionMode: !currentState.isSelectionMode,
          selectedRoomIds: [],
        ),
      );
    }
  }

  void _onToggleRoomSelection(
    ToggleRoomSelection event,
    Emitter<RoomState> emit,
  ) {
    if (state is RoomLoaded) {
      final currentState = state as RoomLoaded;
      final selectedIds = List<int>.from(currentState.selectedRoomIds);
      if (selectedIds.contains(event.roomId)) {
        selectedIds.remove(event.roomId);
      } else {
        selectedIds.add(event.roomId);
      }

      if (selectedIds.isEmpty) {
        emit(
          currentState.copyWith(isSelectionMode: false, selectedRoomIds: []),
        );
      } else {
        emit(currentState.copyWith(selectedRoomIds: selectedIds));
      }
    }
  }

  Future<void> _onDeleteSelectedRooms(
    DeleteSelectedRooms event,
    Emitter<RoomState> emit,
  ) async {
    if (state is RoomLoaded) {
      final currentState = state as RoomLoaded;
      try {
        for (final roomId in currentState.selectedRoomIds) {
          await _studentOperationsUseCases.deleteRoom(roomId);
        }
        add(LoadRooms());
      } catch (e) {
        emit(RoomError(e.toString()));
      }
    }
  }

  void _onClearSelection(ClearSelection event, Emitter<RoomState> emit) {
    if (state is RoomLoaded) {
      final currentState = state as RoomLoaded;
      emit(currentState.copyWith(selectedRoomIds: []));
    }
  }

  void _onSelectAllRooms(SelectAllRooms event, Emitter<RoomState> emit) {
    if (state is RoomLoaded) {
      final currentState = state as RoomLoaded;
      final allRoomIds = currentState.roomStudentCounts.keys
          .map((r) => r.id)
          .toList();
      if (currentState.selectedRoomIds.length == allRoomIds.length) {
        emit(currentState.copyWith(selectedRoomIds: []));
      } else {
        emit(currentState.copyWith(selectedRoomIds: allRoomIds));
      }
    }
  }
}

// UI
class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final state = context.read<RoomBloc>().state;
        if (state is RoomLoaded && state.isSelectionMode) {
          context.read<RoomBloc>().add(ToggleSelectionMode());
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<RoomBloc, RoomState>(
            builder: (context, state) {
              if (state is RoomLoaded && state.isSelectionMode) {
                return Text('${state.selectedRoomIds.length} selected');
              }
              return const Text('Rooms');
            },
          ),
          actions: [
            BlocBuilder<RoomBloc, RoomState>(
              builder: (context, state) {
                // 🟢 Selection mode
                if (state is RoomLoaded && state.isSelectionMode) {
                  final allSelected =
                      state.selectedRoomIds.length ==
                      state.roomStudentCounts.length;
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          allSelected ? Icons.deselect : Icons.select_all,
                        ),
                        tooltip: allSelected ? 'Deselect All' : 'Select All',
                        onPressed: () {
                          context.read<RoomBloc>().add(SelectAllRooms());
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete Selected',
                        onPressed: state.selectedRoomIds.isEmpty
                            ? null
                            : () {
                                context.read<RoomBloc>().add(
                                  DeleteSelectedRooms(),
                                );
                              },
                      ),
                    ],
                  );
                }

                // 🟢 Normal mode
                if (state is RoomLoaded) {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Room',
                        onPressed: () => _showAddRoomDialog(context),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                        onPressed: () {
                          context.read<RoomBloc>().add(LoadRooms());
                        },
                      ),
                    ],
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: BlocConsumer<RoomBloc, RoomState>(
          listener: (context, state) {
            if (state is RoomError) {
              SnackbarService.showSnackbar(
                context,
                state.message,
                isError: true,
              );
            }
          },
          builder: (context, state) {
            if (state is RoomLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is RoomError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading rooms',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        context.read<RoomBloc>().add(LoadRooms());
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (state is RoomLoaded) {
              if (state.roomStudentCounts.isEmpty) {
                return const Center(child: Text('No room added yet'));
              }
              return ListView.builder(
                itemCount: state.roomStudentCounts.length,
                itemBuilder: (context, index) {
                  final room = state.roomStudentCounts.keys.elementAt(index);
                  final studentCount = state.roomStudentCounts[room];
                  final isSelected = state.selectedRoomIds.contains(room.id);
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: isSelected
                        ? Theme.of(context).colorScheme.primaryContainer
                        : null,
                    child: ListTile(
                      leading: state.isSelectionMode
                          ? Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                context.read<RoomBloc>().add(
                                  ToggleRoomSelection(room.id),
                                );
                              },
                            )
                          : Icon(
                              Icons.meeting_room_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      title: Text(
                        room.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Students: $studentCount'),
                      onTap: () {
                        if (state.isSelectionMode) {
                          context.read<RoomBloc>().add(
                            ToggleRoomSelection(room.id),
                          );
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => RoomDetailsPage(room: room),
                            ),
                          );
                        }
                      },
                      onLongPress: () {
                        context.read<RoomBloc>().add(ToggleSelectionMode());
                        context.read<RoomBloc>().add(
                          ToggleRoomSelection(room.id),
                        );
                      },
                    ),
                  );
                },
              );
            }
            return const Center(child: Text('No rooms found.'));
          },
        ),
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    final nameController = TextEditingController();
    final errorNotifier = ValueNotifier<String?>(null);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Room'),
        content: ValueListenableBuilder<String?>(
          valueListenable: errorNotifier,
          builder: (context, error, child) {
            return TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Room Name',
                errorText: error,
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final roomName = nameController.text.toUpperCase();
              final RegExp regExp = RegExp(r'^\d{3}[AB]$');
              if (regExp.hasMatch(roomName)) {
                context.read<RoomBloc>().add(AddRoom(roomName));
                context.read<StudentBloc>().add(const LoadStudentsEvent());
                Navigator.pop(dialogContext);
              } else {
                errorNotifier.value = 'Invalid format. Use 001A, 102B, etc.';
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
