import 'package:equatable/equatable.dart';

class UnifiedReportData extends Equatable {
  final List<String> headers;
  final List<List<String>> rows;

  const UnifiedReportData({required this.headers, required this.rows});

  @override
  List<Object> get props => [headers, rows];
}

abstract class ReportsState extends Equatable {
  const ReportsState();

  @override
  List<Object> get props => [];
}

class ReportsInitial extends ReportsState {}

class ReportsLoading extends ReportsState {}

class ReportsLoaded extends ReportsState {
  final UnifiedReportData reportData;

  const ReportsLoaded({required this.reportData});

  @override
  List<Object> get props => [reportData];
}

class ReportsError extends ReportsState {
  final String message;

  const ReportsError(this.message);

  @override
  List<Object> get props => [message];
}

class ReportExported extends ReportsLoaded {
  final String message;

  const ReportExported({required this.message, required super.reportData});

  @override
  List<Object> get props => [message, reportData];
}
