import 'package:equatable/equatable.dart';

abstract class ReportsEvent extends Equatable {
  const ReportsEvent();

  @override
  List<Object> get props => [];
}

class LoadInitialData extends ReportsEvent {
  final DateTime date;

  const LoadInitialData(this.date);

  @override
  List<Object> get props => [date];
}

class ExportToCsv extends ReportsEvent {}
