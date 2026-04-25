import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class VoloHistoryEvent {}
class ChangeHistoryFilter extends VoloHistoryEvent {
  final String filter;
  ChangeHistoryFilter(this.filter);
}

// State
class VoloHistoryState {
  final String selectedFilter;
  const VoloHistoryState({this.selectedFilter = 'Все'});
  VoloHistoryState copyWith({String? selectedFilter}) =>
      VoloHistoryState(selectedFilter: selectedFilter ?? this.selectedFilter);
}

// Bloc
class VoloHistoryBloc extends Bloc<VoloHistoryEvent, VoloHistoryState> {
  VoloHistoryBloc() : super(const VoloHistoryState()) {
    on<ChangeHistoryFilter>((event, emit) => emit(state.copyWith(selectedFilter: event.filter)));
  }
}
