import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class NavEvent {}
class ChangeNavIndex extends NavEvent {
  final int index;
  ChangeNavIndex(this.index);
}

// State
class NavState {
  final int selectedIndex;
  const NavState({this.selectedIndex = 2});
  NavState copyWith({int? selectedIndex}) => NavState(selectedIndex: selectedIndex ?? this.selectedIndex);
}

// Bloc
class NavBloc extends Bloc<NavEvent, NavState> {
  NavBloc() : super(const NavState()) {
    on<ChangeNavIndex>((event, emit) => emit(state.copyWith(selectedIndex: event.index)));
  }
}
