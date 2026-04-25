import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// Events
abstract class AdminEvent {}
class LoadPendingOrgs extends AdminEvent {}
class ApproveOrg extends AdminEvent {
  final int id;
  final String email;
  ApproveOrg(this.id, this.email);
}

// State
class AdminState {
  final List<dynamic> pendingOrgs;
  final bool isLoading;
  final String? message;
  final bool isError;

  const AdminState({
    this.pendingOrgs = const [],
    this.isLoading = true,
    this.message,
    this.isError = false,
  });

  AdminState copyWith({List<dynamic>? pendingOrgs, bool? isLoading, String? message, bool? isError}) {
    return AdminState(
      pendingOrgs: pendingOrgs ?? this.pendingOrgs,
      isLoading: isLoading ?? this.isLoading,
      message: message,
      isError: isError ?? this.isError,
    );
  }
}

// Bloc
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final ApiService apiService;

  AdminBloc({required this.apiService}) : super(const AdminState()) {
    on<LoadPendingOrgs>(_onLoad);
    on<ApproveOrg>(_onApprove);
  }

  Future<void> _onLoad(LoadPendingOrgs event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final result = await apiService.getPendingOrganizations();
      if (result['success'] == true) {
        emit(state.copyWith(isLoading: false, pendingOrgs: result['data']));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, message: 'Ошибка загрузки: $e', isError: true));
    }
  }

  Future<void> _onApprove(ApproveOrg event, Emitter<AdminState> emit) async {
    final result = await apiService.approveOrganization(event.id);
    if (result['success'] == true) {
      emit(state.copyWith(message: 'Организация ${event.email} одобрена!', isError: false));
      add(LoadPendingOrgs());
    } else {
      emit(state.copyWith(message: result['message'], isError: true));
    }
  }
}
