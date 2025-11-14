import 'package:hostel_mess_2/core/utils/snackbar_service.dart';
import 'package:flutter/services.dart';
// lib/features/home_page/pages/students_page/students_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:collection/collection.dart';
import 'package:hostel_mess_2/core/domain/entities/room_entity.dart';
import 'package:hostel_mess_2/core/domain/entities/student_entity.dart';
import 'bloc/students_page_bloc.dart';
import 'bloc/students_page_event.dart';
import 'bloc/students_page_state.dart';
import 'package:hostel_mess_2/features/home_page/pages/room_page/rooms_page.dart';

class StudentsPage extends StatelessWidget {
  const StudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        final state = context.read<StudentBloc>().state;
        if (state is StudentLoaded && state.isSelectionMode) {
          context.read<StudentBloc>().add(const ToggleSelectionModeEvent());
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<StudentBloc, StudentState>(
            builder: (context, state) {
              if (state is StudentLoaded && state.isSelectionMode) {
                return Text('${state.selectedStudentIds.length} selected');
              }
              return const Text('Students');
            },
          ),
          actions: [
            BlocBuilder<StudentBloc, StudentState>(
              builder: (context, state) {
                if (state is StudentLoaded && state.isSelectionMode) {
                  final allSelected =
                      state.selectedStudentIds.length ==
                      state.filteredStudents.length;
                  return Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          context.read<StudentBloc>().add(
                            const SelectAllStudentsEvent(),
                          );
                        },
                        child: Text(
                          allSelected ? 'Deselect All' : 'Select All',
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          context.read<StudentBloc>().add(
                            DeleteSelectedStudentsEvent(
                              state.selectedStudentIds,
                            ),
                          );
                        },
                      ),
                    ],
                  );
                }

                // 🟢 Normal mode — show Refresh + Add buttons
                if (state is StudentLoaded) {
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.add),
                        tooltip: 'Add Student',
                        onPressed: () => _showAddStudentDialog(context, state),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          context.read<StudentBloc>().add(
                            const LoadStudentsEvent(),
                          );
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
        body: BlocConsumer<StudentBloc, StudentState>(
          listener: (context, state) {
            if (state is StudentError) {
              SnackbarService.showSnackbar(
                context,
                state.message,
                isError: true,
              );
            }
          },
          builder: (context, state) {
            if (state is StudentLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StudentLoaded) {
              return Column(
                children: [
                  if (state.yearGroups.isNotEmpty)
                    _buildYearGroupsSection(context, state),
                  _buildStudentsHeader(context, state),
                  Expanded(
                    child: state.filteredStudents.isEmpty
                        ? _buildEmptyState(context)
                        : _buildStudentsList(context, state),
                  ),
                ],
              );
            }
            if (state is StudentError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<StudentBloc>().add(
                          const LoadStudentsEvent(),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: Text('Something went wrong'));
          },
        ),
      ),
    );
  }

  Widget _buildYearGroupsSection(BuildContext context, StudentLoaded state) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Year Groups',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              if (state.yearFilter != null)
                TextButton(
                  onPressed: () {
                    context.read<StudentBloc>().add(const ClearFilterEvent());
                  },
                  child: const Text('Show All'),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: state.yearGroups.length,
              itemBuilder: (context, index) {
                final year = state.yearGroups.keys.toList()[index];
                final count = state.yearGroups[year]!;
                final isSelected = state.yearFilter == year;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text('Year $year ($count)'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (isSelected) {
                        context.read<StudentBloc>().add(
                          const ClearFilterEvent(),
                        );
                      } else {
                        context.read<StudentBloc>().add(
                          FilterByYearGroupEvent(year),
                        );
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsHeader(BuildContext context, StudentLoaded state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            state.yearFilter != null
                ? 'Year ${state.yearFilter} Students (${state.filteredStudents.length})'
                : 'All Students (${state.students.length})',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return const Center(child: Text('No students found.'));
  }

  Widget _buildStudentsList(BuildContext context, StudentLoaded state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.filteredStudents.length,
      itemBuilder: (context, index) {
        final student = state.filteredStudents[index];
        final room = state.rooms.firstWhere(
          (r) => r.id == student.roomId,
          orElse: () => RoomEntity(id: 0, name: 'No Room'),
        );
        final isSelected = state.selectedStudentIds.contains(student.id);

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: ListTile(
            leading: state.isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      context.read<StudentBloc>().add(
                        ToggleStudentSelectionEvent(student.id),
                      );
                    },
                  )
                : CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      student.name.substring(0, 1),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
            title: Text(
              student.name,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text('Reg: ${student.reg}\nRoom: ${room.name}'),
            onTap: () {
              if (state.isSelectionMode) {
                context.read<StudentBloc>().add(
                  ToggleStudentSelectionEvent(student.id),
                );
              }
            },
            onLongPress: () {
              context.read<StudentBloc>().add(const ToggleSelectionModeEvent());
              context.read<StudentBloc>().add(
                ToggleStudentSelectionEvent(student.id),
              );
            },
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'update_room') {
                  _showUpdateRoomDialog(context, student, state.rooms);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'update_room',
                  child: Text('Update Room'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showUpdateRoomDialog(
    BuildContext context,
    StudentEntity student,
    List<RoomEntity> rooms,
  ) {
    RoomEntity? selectedRoom = rooms.firstWhereOrNull(
      (r) => r.id == student.roomId,
    );

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update Room for ${student.name}'),
        content: DropdownButtonFormField<RoomEntity>(
          value: selectedRoom,
          items: rooms
              .map(
                (room) => DropdownMenuItem(value: room, child: Text(room.name)),
              )
              .toList(),
          onChanged: (room) => selectedRoom = room,
          decoration: const InputDecoration(labelText: 'Room'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<StudentBloc>().add(
                UpdateStudentRoomEvent(
                  studentId: student.id,
                  roomId: selectedRoom?.id,
                ),
              );
              context.read<RoomBloc>().add(LoadRooms());
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAddStudentDialog(BuildContext context, StudentLoaded state) {
    final nameController = TextEditingController();
    final regController = TextEditingController();
    RoomEntity? selectedRoom;

    final nameErrorNotifier = ValueNotifier<String?>(null);
    final regErrorNotifier = ValueNotifier<String?>(null);
    final regLengthNotifier = ValueNotifier<int>(0);

    regController.addListener(() {
      regLengthNotifier.value = regController.text.length;
    });

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name Field
              ValueListenableBuilder<String?>(
                valueListenable: nameErrorNotifier,
                builder: (context, error, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                          softWrap: true,
                          maxLines: 3,
                          overflow: TextOverflow.visible,
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Registration Field with dynamic 0/10 counter hint
              ValueListenableBuilder<String?>(
                valueListenable: regErrorNotifier,
                builder: (context, error, child) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ValueListenableBuilder<int>(
                        valueListenable: regLengthNotifier,
                        builder: (context, length, _) {
                          return TextField(
                            controller: regController,
                            keyboardType: TextInputType.number,
                            maxLength: 10,
                            decoration: InputDecoration(
                              labelText: 'Registration Number',
                              counterText: '',
                              suffixText: '$length/10',
                              suffixStyle: TextStyle(
                                color: length > 10
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).hintColor,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                          softWrap: true,
                          maxLines: 3,
                          overflow: TextOverflow.visible,
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),

              // Room (Optional)
              DropdownButtonFormField<RoomEntity>(
                value: selectedRoom,
                items: state.rooms
                    .map(
                      (room) =>
                          DropdownMenuItem(value: room, child: Text(room.name)),
                    )
                    .toList(),
                onChanged: (room) => selectedRoom = room,
                decoration: const InputDecoration(labelText: 'Room (Optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final name = nameController.text.trim();
              final reg = regController.text.trim();

              nameErrorNotifier.value = null;
              regErrorNotifier.value = null;
              bool hasError = false;

              // Validation
              if (name.isEmpty) {
                nameErrorNotifier.value = 'Name cannot be empty';
                hasError = true;
              } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
                nameErrorNotifier.value =
                    'Name must contain only letters and spaces (e.g., Ravi Raj).';
                hasError = true;
              }

              if (reg.isEmpty) {
                regErrorNotifier.value = 'Registration number cannot be empty';
                hasError = true;
              } else if (!RegExp(r'^\d{10}$').hasMatch(reg)) {
                regErrorNotifier.value =
                    'Please enter a valid 10-digit registration number.';
                hasError = true;
              }

              if (hasError) return;

              // Add Student
              context.read<StudentBloc>().add(
                AddStudentEvent(name: name, reg: reg, roomId: selectedRoom?.id),
              );

              if (selectedRoom?.id != null) {
                context.read<RoomBloc>().add(LoadRooms());
              }

              Navigator.of(dialogContext).pop();
            },
            child: const Text('Add Student'),
          ),
        ],
      ),
    );
  }
}
