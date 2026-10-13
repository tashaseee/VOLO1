import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// Events
abstract class VoloHistoryEvent {}

class ChangeHistoryFilter extends VoloHistoryEvent {
  final String filter;
  ChangeHistoryFilter(this.filter);
}

class LoadHistoryData extends VoloHistoryEvent {}

// State
class VoloHistoryState {
  final String selectedFilter;
  final bool isLoading;
  final bool isError;
  final String errorMessage;
  final int voloHours;
  final int completedCount;
  final int upcomingCount;
  final int workedHours;
  final List<Map<String, dynamic>> events;

  const VoloHistoryState({
    this.selectedFilter = 'Все',
    this.isLoading = false,
    this.isError = false,
    this.errorMessage = '',
    this.voloHours = 0,
    this.completedCount = 0,
    this.upcomingCount = 0,
    this.workedHours = 0,
    this.events = const [],
  });

  VoloHistoryState copyWith({
    String? selectedFilter,
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    int? voloHours,
    int? completedCount,
    int? upcomingCount,
    int? workedHours,
    List<Map<String, dynamic>>? events,
  }) {
    return VoloHistoryState(
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      voloHours: voloHours ?? this.voloHours,
      completedCount: completedCount ?? this.completedCount,
      upcomingCount: upcomingCount ?? this.upcomingCount,
      workedHours: workedHours ?? this.workedHours,
      events: events ?? this.events,
    );
  }
}

// Bloc
class VoloHistoryBloc extends Bloc<VoloHistoryEvent, VoloHistoryState> {
  final ApiService apiService;

  VoloHistoryBloc({required this.apiService}) : super(const VoloHistoryState()) {
    on<ChangeHistoryFilter>((event, emit) => emit(state.copyWith(selectedFilter: event.filter)));

    on<LoadHistoryData>((event, emit) async {
      emit(state.copyWith(isLoading: true, isError: false));
      try {
        final results = await Future.wait([
          apiService.getUserProfile(),
          apiService.getMyApplications(),
          apiService.getMyCertificates(),
        ]);

        final profileResult = results[0];
        final appsResult = results[1];
        final certsResult = results[2];

        if (!profileResult['success'] || !appsResult['success']) {
          emit(state.copyWith(
            isLoading: false,
            isError: true,
            errorMessage: profileResult['message'] ?? appsResult['message'] ?? 'Ошибка загрузки данных',
          ));
          return;
        }

        final profileData = profileResult['data'];
        final profile = profileData?['profile'];
        final int voloHours = profile?['volo_hours'] ?? 0;

        final rawApps = appsResult['data'] as List<dynamic>;
        final certs = certsResult['success'] ? (certsResult['data'] as List<dynamic>) : [];

        // Map raw applications to the format expected by the VoloHistoryPage UI
        final List<Map<String, dynamic>> mappedEvents = [];
        int completedCount = 0;
        int upcomingCount = 0;
        int workedHours = 0;

        for (var app in rawApps) {
          final eventData = app['event'];
          if (eventData == null) continue;

          final status = app['status'] ?? 'pending';
          final isCompleted = status == 'completed';
          final isUpcoming = status == 'approved' || status == 'pending';

          if (isCompleted) {
            completedCount++;
            workedHours += (eventData['hours'] as num? ?? 0).toInt();
          } else if (isUpcoming) {
            upcomingCount++;
          }

          // Parse responsibilities list
          List<String> responsibilities = [];
          if (eventData['responsibilities'] != null) {
            final respRaw = eventData['responsibilities'];
            if (respRaw is List) {
              responsibilities = List<String>.from(respRaw);
            } else if (respRaw is String) {
              responsibilities = respRaw
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          }

          // Parse benefits list
          List<String> benefits = [];
          if (eventData['benefits'] != null) {
            final benRaw = eventData['benefits'];
            if (benRaw is List) {
              benefits = List<String>.from(benRaw);
            } else if (benRaw is String) {
              benefits = benRaw
                  .split(',')
                  .map((s) => s.trim())
                  .where((s) => s.isNotEmpty)
                  .toList();
            }
          }

          // Find certificate matching event_id
          String? certificateUrl;
          final int? eventId = eventData['id'] as int?;
          if (eventId != null) {
            final matchingCertList = certs.where((c) => c['event_id'] == eventId).toList();
            if (matchingCertList.isNotEmpty) {
              final matchingCert = matchingCertList.first;
              if (matchingCert['certificate_url'] != null) {
                certificateUrl = ApiService.mediaUrl(matchingCert['certificate_url'] as String);
              }
            }
          }

          mappedEvents.add({
            'id': eventId,
            'title': eventData['title'] ?? 'Без названия',
            'organizer': eventData['organizer'] ?? 'Организатор не указан',
            'date': eventData['date_text'] ?? 'Дата не указана',
            'hours': eventData['hours'] ?? 0,
            'status': isCompleted ? 'completed' : 'upcoming',
            'category': eventData['category'] ?? 'Другое',
            'location': eventData['location'] ?? 'Локация не указана',
            'volunteers': eventData['volunteer_count'] ?? 0,
            'eventRating': 5.0, // Default rating as backend doesn't store review averages yet
            'organizerRating': 5.0,
            'description': eventData['description'] ?? '',
            'responsibilities': responsibilities,
            'benefits': benefits,
            'hasCertificate': isCompleted,
            'certificateUrl': certificateUrl,
          });
        }

        emit(state.copyWith(
          isLoading: false,
          voloHours: voloHours,
          completedCount: completedCount,
          upcomingCount: upcomingCount,
          workedHours: workedHours,
          events: mappedEvents,
        ));
      } catch (e) {
        emit(state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: 'Произошла ошибка: $e',
        ));
      }
    });
  }
}

