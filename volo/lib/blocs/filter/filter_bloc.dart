import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class FilterEvent {}
class ToggleFilterItem extends FilterEvent {
  final String category;
  final String value;
  ToggleFilterItem(this.category, this.value);
}
class ResetFilters extends FilterEvent {}

// State
class FilterState {
  final List<String> volunteerTypes;
  final List<String> locations;
  final List<String> durations;
  final List<String> eventTypes;
  final List<String> benefits;

  const FilterState({
    this.volunteerTypes = const [],
    this.locations = const [],
    this.durations = const [],
    this.eventTypes = const [],
    this.benefits = const [],
  });

  FilterState copyWith({
    List<String>? volunteerTypes,
    List<String>? locations,
    List<String>? durations,
    List<String>? eventTypes,
    List<String>? benefits,
  }) {
    return FilterState(
      volunteerTypes: volunteerTypes ?? this.volunteerTypes,
      locations: locations ?? this.locations,
      durations: durations ?? this.durations,
      eventTypes: eventTypes ?? this.eventTypes,
      benefits: benefits ?? this.benefits,
    );
  }

  Map<String, List<String>> toMap() => {
    'volunteerTypes': volunteerTypes,
    'locations': locations,
    'durations': durations,
    'eventTypes': eventTypes,
    'benefits': benefits,
  };
}

// Bloc
class FilterBloc extends Bloc<FilterEvent, FilterState> {
  FilterBloc() : super(const FilterState()) {
    on<ToggleFilterItem>(_onToggle);
    on<ResetFilters>((_, emit) => emit(const FilterState()));
  }

  void _onToggle(ToggleFilterItem event, Emitter<FilterState> emit) {
    List<String> _toggle(List<String> list, String val) {
      final copy = List<String>.from(list);
      if (copy.contains(val)) { copy.remove(val); } else { copy.add(val); }
      return copy;
    }

    switch (event.category) {
      case 'volunteerTypes': emit(state.copyWith(volunteerTypes: _toggle(state.volunteerTypes, event.value))); break;
      case 'locations': emit(state.copyWith(locations: _toggle(state.locations, event.value))); break;
      case 'durations': emit(state.copyWith(durations: _toggle(state.durations, event.value))); break;
      case 'eventTypes': emit(state.copyWith(eventTypes: _toggle(state.eventTypes, event.value))); break;
      case 'benefits': emit(state.copyWith(benefits: _toggle(state.benefits, event.value))); break;
    }
  }
}
