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

class LoadSupportRequests extends AdminEvent {}

class ReplyToSupportRequestEvent extends AdminEvent {
  final int id;
  final String replyText;
  ReplyToSupportRequestEvent(this.id, this.replyText);
}

class SwitchAdminTab extends AdminEvent {
  final int tabIndex;
  SwitchAdminTab(this.tabIndex);
}

// State
class AdminState {
  final List<dynamic> pendingOrgs;
  final List<dynamic> supportRequests;
  final bool isLoading;
  final String? message;
  final bool isError;
  final int activeTab; // 0 for Orgs, 1 for Support

  const AdminState({
    this.pendingOrgs = const [],
    this.supportRequests = const [],
    this.isLoading = true,
    this.message,
    this.isError = false,
    this.activeTab = 0,
  });

  AdminState copyWith({
    List<dynamic>? pendingOrgs,
    List<dynamic>? supportRequests,
    bool? isLoading,
    String? message,
    bool? isError,
    int? activeTab,
  }) {
    return AdminState(
      pendingOrgs: pendingOrgs ?? this.pendingOrgs,
      supportRequests: supportRequests ?? this.supportRequests,
      isLoading: isLoading ?? this.isLoading,
      message: message,
      isError: isError ?? this.isError,
      activeTab: activeTab ?? this.activeTab,
    );
  }
}

// Bloc
class AdminBloc extends Bloc<AdminEvent, AdminState> {
  final ApiService apiService;

  AdminBloc({required this.apiService}) : super(const AdminState()) {
    on<LoadPendingOrgs>(_onLoadOrgs);
    on<ApproveOrg>(_onApproveOrg);
    on<LoadSupportRequests>(_onLoadSupport);
    on<ReplyToSupportRequestEvent>(_onReplySupport);
    on<SwitchAdminTab>(_onSwitchTab);
  }

  Future<void> _onLoadOrgs(LoadPendingOrgs event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final result = await apiService.getPendingOrganizations();
      if (result['success'] == true) {
        emit(state.copyWith(isLoading: false, pendingOrgs: result['data']));
      } else {
        emit(state.copyWith(isLoading: false, message: result['message'], isError: true));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, message: 'Ошибка загрузки: $e', isError: true));
    }
  }

  Future<void> _onApproveOrg(ApproveOrg event, Emitter<AdminState> emit) async {
    final result = await apiService.approveOrganization(event.id);
    if (result['success'] == true) {
      emit(state.copyWith(message: 'Организация ${event.email} одобрена!', isError: false));
      if (!isClosed) add(LoadPendingOrgs());
    } else {
      emit(state.copyWith(message: result['message'], isError: true));
    }
  }

  Future<void> _onLoadSupport(LoadSupportRequests event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final result = await apiService.getAllSupportRequests();
      if (result['success'] == true) {
        emit(state.copyWith(isLoading: false, supportRequests: result['data']));
      } else {
        emit(state.copyWith(isLoading: false, message: result['message'], isError: true));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, message: 'Ошибка загрузки: $e', isError: true));
    }
  }

  Future<void> _onReplySupport(ReplyToSupportRequestEvent event, Emitter<AdminState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final result = await apiService.replyToSupportRequest(event.id, event.replyText);
      if (result['success'] == true) {
        emit(state.copyWith(message: 'Ответ успешно отправлен', isError: false));
        if (!isClosed) add(LoadSupportRequests());
      } else {
        emit(state.copyWith(isLoading: false, message: result['message'], isError: true));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, message: 'Ошибка отправки ответа: $e', isError: true));
    }
  }

  void _onSwitchTab(SwitchAdminTab event, Emitter<AdminState> emit) {
    emit(state.copyWith(activeTab: event.tabIndex));
    if (event.tabIndex == 0) {
      add(LoadPendingOrgs());
    } else {
      add(LoadSupportRequests());
    }
  }
}

