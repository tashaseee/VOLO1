import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// Events
abstract class SearchEvent {}

class LoadSearchEvents extends SearchEvent {}

class SearchQueryChanged extends SearchEvent {
  final String query;
  SearchQueryChanged(this.query);
}

class SearchCategoryChanged extends SearchEvent {
  final String category;
  SearchCategoryChanged(this.category);
}

// State
class SearchState {
  final List<dynamic> allEvents;
  final List<dynamic> filteredEvents;
  final bool isLoading;
  final String selectedCategory;
  final String query;

  const SearchState({
    this.allEvents = const [],
    this.filteredEvents = const [],
    this.isLoading = true,
    this.selectedCategory = 'Все',
    this.query = '',
  });

  SearchState copyWith({
    List<dynamic>? allEvents,
    List<dynamic>? filteredEvents,
    bool? isLoading,
    String? selectedCategory,
    String? query,
  }) {
    return SearchState(
      allEvents: allEvents ?? this.allEvents,
      filteredEvents: filteredEvents ?? this.filteredEvents,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      query: query ?? this.query,
    );
  }
}

// Bloc
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  final ApiService apiService;

  SearchBloc({required this.apiService}) : super(const SearchState()) {
    on<LoadSearchEvents>(_onLoad);
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchCategoryChanged>(_onCategoryChanged);
  }

  List<dynamic> _applyFilters(List<dynamic> all, String query, String category) {
    return all.where((event) {
      final matchesSearch = query.isEmpty ||
          (event['title'] ?? '').toLowerCase().contains(query.toLowerCase()) ||
          (event['organizer'] ?? '').toLowerCase().contains(query.toLowerCase());
      final matchesCategory = category == 'Все' || (event['category'] ?? '') == category;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  Future<void> _onLoad(LoadSearchEvents event, Emitter<SearchState> emit) async {
    emit(state.copyWith(isLoading: true));
    final result = await apiService.getEvents();
    if (result['success'] == true) {
      final all = result['data'] as List<dynamic>;
      emit(state.copyWith(
        isLoading: false,
        allEvents: all,
        filteredEvents: _applyFilters(all, state.query, state.selectedCategory),
      ));
    } else {
      emit(state.copyWith(isLoading: false));
    }
  }

  void _onQueryChanged(SearchQueryChanged event, Emitter<SearchState> emit) {
    emit(state.copyWith(
      query: event.query,
      filteredEvents: _applyFilters(state.allEvents, event.query, state.selectedCategory),
    ));
  }

  void _onCategoryChanged(SearchCategoryChanged event, Emitter<SearchState> emit) {
    emit(state.copyWith(
      selectedCategory: event.category,
      filteredEvents: _applyFilters(state.allEvents, state.query, event.category),
    ));
  }
}
