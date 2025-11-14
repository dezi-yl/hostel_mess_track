import 'package:hostel_mess_2/core/utils/snackbar_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/reports_page/bloc/reports_bloc.dart';
import 'package:hostel_mess_2/features/home_page/pages/reports_page/bloc/reports_event.dart';
import 'package:hostel_mess_2/features/home_page/pages/reports_page/bloc/reports_state.dart';
import 'package:intl/intl.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    context.read<ReportsBloc>().add(LoadInitialData(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReportsBloc, ReportsState>(
      listener: (context, state) {
        if (state is ReportExported) {
          SnackbarService.showSnackbar(context, state.message);
        } else if (state is ReportsError) {
          SnackbarService.showSnackbar(context, state.message, isError: true);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Reports"),
          actions: [
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: () {
                context.read<ReportsBloc>().add(ExportToCsv());
              },
            ),
          ],
        ),
        body: Column(
          children: [
            _buildDateFilter(),
            Expanded(
              child: BlocBuilder<ReportsBloc, ReportsState>(
                builder: (context, state) {
                  if (state is ReportsLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is ReportsLoaded) {
                    return _buildReportList(state);
                  } else if (state is ReportsError) {
                    return Center(child: Text(state.message));
                  }
                  return const Center(child: Text("No data"));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateFilter() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: _selectDate,
            child: Row(
              children: [
                const Icon(Icons.calendar_today),
                const SizedBox(width: 8),
                Text(DateFormat('MMMM yyyy').format(_selectedDate)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDatePickerMode: DatePickerMode.day,
    );
    if (!mounted) return;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      context.read<ReportsBloc>().add(LoadInitialData(picked));
    }
  }

  Widget _buildReportList(ReportsLoaded state) {
    if (state.reportData.rows.isEmpty) {
      return const Center(child: Text("No records for this month."));
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          defaultColumnWidth: const IntrinsicColumnWidth(),
          border: TableBorder(
            horizontalInside: BorderSide(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
              width: 1,
            ),
          ),
          children: [
            // Header row
            TableRow(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
              ),
              children: state.reportData.headers
                  .map(
                    (header) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        header,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            // Data rows
            ...state.reportData.rows.map((row) {
              return TableRow(
                children: row
                    .map(
                      (cell) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          cell,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              );
            }),
          ],
        ),
      ),
    );
  }
}
