import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/debug_page/bloc/debug_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/debug_page/bloc/debug_event.dart';
import 'package:hostel_mess_2/features/home_page/pages/debug_page/bloc/debug_state.dart';

class DebugPage extends StatefulWidget {
  const DebugPage({super.key});

  @override
  State<DebugPage> createState() => _DebugPageState();
}

class _DebugPageState extends State<DebugPage> {
  @override
  void initState() {
    super.initState();
    context.read<DebugBloc>().add(LoadDebugDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Info'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<DebugBloc>().add(LoadDebugDataEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<DebugBloc, DebugState>(
        builder: (context, state) {
          if (state.status == DebugStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == DebugStatus.failure) {
            return Center(child: Text('Error: ${state.errorMessage}'));
          } else if (state.status == DebugStatus.success) {
            final Map<String, List<Map<String, dynamic>>> foodWiseRecords = {};
            for (var record in state.records) {
              final foodName = record['foodName'] as String;
              if (!foodWiseRecords.containsKey(foodName)) {
                foodWiseRecords[foodName] = [];
              }
              foodWiseRecords[foodName]!.add(record);
            }

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(
                          'Students (${state.students.length})',
                        ),
                        ...state.students.map((s) => Text(s.name)),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Rooms (${state.rooms.length})'),
                        ...state.rooms.map((r) => Text(r.name)),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Foods (${state.foods.length})'),
                        ...state.foods.map((f) => Text(f.name)),
                      ],
                    ),
                  ),
                ),
                Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Records (${state.records.length})'),
                        ...foodWiseRecords.entries.map((entry) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Text(
                                  entry.key,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ...entry.value.map(
                                (rec) => Text(
                                  '${rec['studentName']} - ${rec['date']}',
                                ),
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: Text('Press refresh to load data.'));
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
