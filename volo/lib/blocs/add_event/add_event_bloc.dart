import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';

// --- EVENTS ---
abstract class AddEventEvent {}

class NextStepEvent extends AddEventEvent {}

class PreviousStepEvent extends AddEventEvent {}

class UpdateEventData extends AddEventEvent {
  final String? eventType;
  final File? posterImage;
  final String? title;
  final String? description;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final TimeOfDay? selectedEndTime;
  final String? location;
  final String? address;
  final int? volunteerCount;
  final String? chatLink;
  final List<String>? responsibilities;
  final List<String>? benefits;

  UpdateEventData({
    this.eventType,
    this.posterImage,
    this.title,
    this.description,
    this.selectedDate,
    this.selectedTime,
    this.selectedEndTime,
    this.location,
    this.address,
    this.volunteerCount,
    this.chatLink,
    this.responsibilities,
    this.benefits,
  });
}

class PublishEvent extends AddEventEvent {}

// --- STATE ---
class AddEventState {
  final int currentPage;
  final int totalPages;
  final String eventType;
  final File? posterImage;
  final String title;
  final String description;
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final TimeOfDay? selectedEndTime;
  final String location;
  final String address;
  final int volunteerCount;
  final String chatLink;
  final List<String> responsibilities;
  final List<String> benefits;
  
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  AddEventState({
    this.currentPage = 0,
    this.totalPages = 6,
    this.eventType = '',
    this.posterImage,
    this.title = '',
    this.description = '',
    this.selectedDate,
    this.selectedTime,
    this.selectedEndTime,
    this.location = '',
    this.address = '',
    this.volunteerCount = 5,
    this.chatLink = '',
    this.responsibilities = const [],
    this.benefits = const [],
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  bool get isCurrentStepValid {
    switch (currentPage) {
      case 0: return eventType.isNotEmpty;
      case 1: return posterImage != null;
      case 2: return title.isNotEmpty && description.isNotEmpty;
      case 3: return selectedDate != null && selectedTime != null && location.isNotEmpty;
      case 4: return volunteerCount > 0 && responsibilities.isNotEmpty;
      case 5: return true;
      default: return false;
    }
  }

  AddEventState copyWith({
    int? currentPage,
    String? eventType,
    File? posterImage,
    String? title,
    String? description,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    TimeOfDay? selectedEndTime,
    String? location,
    String? address,
    int? volunteerCount,
    String? chatLink,
    List<String>? responsibilities,
    List<String>? benefits,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return AddEventState(
      currentPage: currentPage ?? this.currentPage,
      totalPages: this.totalPages,
      eventType: eventType ?? this.eventType,
      posterImage: posterImage ?? this.posterImage,
      title: title ?? this.title,
      description: description ?? this.description,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: selectedTime ?? this.selectedTime,
      selectedEndTime: selectedEndTime ?? this.selectedEndTime,
      location: location ?? this.location,
      address: address ?? this.address,
      volunteerCount: volunteerCount ?? this.volunteerCount,
      chatLink: chatLink ?? this.chatLink,
      responsibilities: responsibilities ?? this.responsibilities,
      benefits: benefits ?? this.benefits,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

// --- BLOC ---
class AddEventBloc extends Bloc<AddEventEvent, AddEventState> {
  final ApiService apiService;

  AddEventBloc({required this.apiService}) : super(AddEventState()) {
    on<NextStepEvent>((event, emit) {
      if (state.currentPage < state.totalPages - 1) {
        emit(state.copyWith(currentPage: state.currentPage + 1));
      }
    });

    on<PreviousStepEvent>((event, emit) {
      if (state.currentPage > 0) {
        emit(state.copyWith(currentPage: state.currentPage - 1));
      }
    });

    on<UpdateEventData>((event, emit) {
      emit(state.copyWith(
        eventType: event.eventType,
        posterImage: event.posterImage,
        title: event.title,
        description: event.description,
        selectedDate: event.selectedDate,
        selectedTime: event.selectedTime,
        selectedEndTime: event.selectedEndTime,
        location: event.location,
        address: event.address,
        volunteerCount: event.volunteerCount,
        chatLink: event.chatLink,
        responsibilities: event.responsibilities,
        benefits: event.benefits,
      ));
    });

    on<PublishEvent>((event, emit) async {
      emit(state.copyWith(isLoading: true, errorMessage: null));

      try {
        int duration = 4; // Default
        if (state.selectedTime != null && state.selectedEndTime != null) {
          double start = state.selectedTime!.hour + state.selectedTime!.minute / 60.0;
          double end = state.selectedEndTime!.hour + state.selectedEndTime!.minute / 60.0;
          if (end < start) end += 24; 
          duration = (end - start).ceil();
          if (duration < 1) duration = 1;
        }

        final eventData = {
          'title': state.title,
          'description': state.description,
          'location': '${state.location}, ${state.address}',
          'date_text': state.selectedDate != null 
              ? '${state.selectedDate!.day.toString().padLeft(2,'0')}.${state.selectedDate!.month.toString().padLeft(2,'0')}.${state.selectedDate!.year} | ${state.selectedTime?.hour.toString().padLeft(2,'0')}:${state.selectedTime?.minute.toString().padLeft(2,'0')}' 
              : '',
          'hours': duration, 
          'category': state.eventType,
          'chat_link': state.chatLink,
          'volunteer_count': state.volunteerCount,
          'responsibilities': state.responsibilities.join(', '),
          'benefits': state.benefits.join(', '),
        };

        final result = await apiService.createEvent(eventData, imageFile: state.posterImage);

        if (result['success'] == true || result['success'] == 'true') {
          emit(state.copyWith(isLoading: false, isSuccess: true));
        } else {
          emit(state.copyWith(isLoading: false, errorMessage: result['message']?.toString() ?? 'Неизвестная ошибка'));
        }
      } catch (e) {
        emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
      }
    });
  }
}
