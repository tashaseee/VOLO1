// volunteers_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Events
abstract class VolunteersEvent {}
class ChangeVolunteerFilter extends VolunteersEvent {
  final String status;
  ChangeVolunteerFilter(this.status);
}
class UpdateVolunteerStatus extends VolunteersEvent {
  final int index;
  final String status;
  UpdateVolunteerStatus(this.index, this.status);
}

// State
class VolunteersState {
  final String filterStatus;
  final List<Map<String, dynamic>> applicants;
  const VolunteersState({this.filterStatus = 'Все', this.applicants = const []});
  VolunteersState copyWith({String? filterStatus, List<Map<String, dynamic>>? applicants}) =>
      VolunteersState(filterStatus: filterStatus ?? this.filterStatus, applicants: applicants ?? this.applicants);
}

// Bloc
class VolunteersBloc extends Bloc<VolunteersEvent, VolunteersState> {
  VolunteersBloc() : super(VolunteersState(applicants: [
    {'name': 'Амина Казанбасова', 'age': '25', 'phone': '+77771234567', 'email': 'amina@email.com', 'event': 'Концерт Тимати', 'status': 'Ожидает', 'id': '1'},
    {'name': 'John Doe', 'age': '28', 'phone': '+7777654321', 'email': 'john@email.com', 'event': 'Фестиваль Хастар', 'status': 'Принят', 'id': '2'},
  ])) {
    on<ChangeVolunteerFilter>((event, emit) => emit(state.copyWith(filterStatus: event.status)));
    on<UpdateVolunteerStatus>((event, emit) {
      final updated = List<Map<String, dynamic>>.from(state.applicants.map((a) => Map<String, dynamic>.from(a)));
      updated[event.index]['status'] = event.status;
      emit(state.copyWith(applicants: updated));
    });
  }
}

// Page
class VolunteersPage extends StatelessWidget {
  const VolunteersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VolunteersBloc(),
      child: const _VolunteersView(),
    );
  }
}

class _VolunteersView extends StatelessWidget {
  const _VolunteersView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VolunteersBloc, VolunteersState>(
      builder: (context, state) {
        final filtered = state.applicants.where((a) => state.filterStatus == 'Все' || a['status'] == state.filterStatus).toList();
        final counts = {
          'Ожидает': state.applicants.where((a) => a['status'] == 'Ожидает').length,
          'Принят': state.applicants.where((a) => a['status'] == 'Принят').length,
          'Отклонён': state.applicants.where((a) => a['status'] == 'Отклонён').length,
        };

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white, elevation: 0,
            leading: IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF983296), size: 20), onPressed: () => Navigator.pop(context)),
            title: Text('Волонтёры', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26))),
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                  _statItem('Ожидает', counts['Ожидает'].toString()),
                  _statItem('Принят', counts['Принят'].toString()),
                  _statItem('Отклонён', counts['Отклонён'].toString()),
                ]),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: state.filterStatus,
                  items: ['Все', 'Ожидает', 'Принят', 'Отклонён'].map((s) => DropdownMenuItem(value: s, child: Text(s, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
                  onChanged: (v) => context.read<VolunteersBloc>().add(ChangeVolunteerFilter(v!)),
                  decoration: InputDecoration(labelText: 'Фильтр по статусу', labelStyle: GoogleFonts.poppins(fontSize: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final applicant = filtered[index];
                  final globalIndex = state.applicants.indexOf(applicant);
                  return GestureDetector(
                    onTap: () => showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: Text(applicant['name'], style: GoogleFonts.poppins(fontSize: 16)),
                      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Возраст: ${applicant['age']}', style: GoogleFonts.poppins(fontSize: 14)),
                        Text('Телефон: ${applicant['phone']}', style: GoogleFonts.poppins(fontSize: 14)),
                        Text('Email: ${applicant['email']}', style: GoogleFonts.poppins(fontSize: 14)),
                        Text('Ивент: ${applicant['event']}', style: GoogleFonts.poppins(fontSize: 14)),
                      ]),
                      actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Закрыть', style: GoogleFonts.poppins(fontSize: 14)))],
                    )),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 1))]),
                      child: Row(children: [
                        CircleAvatar(backgroundColor: Colors.grey[300], radius: 20, child: Text(applicant['name'][0], style: GoogleFonts.poppins(color: Colors.white, fontSize: 14))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(applicant['name'], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                          Text('Возраст: ${applicant['age']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                          Text(applicant['event'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                        ])),
                        if (applicant['status'] == 'Ожидает') ...[
                          IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20), onPressed: () {
                            context.read<VolunteersBloc>().add(UpdateVolunteerStatus(globalIndex, 'Принят'));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Заявка принята', style: GoogleFonts.poppins(fontSize: 12))));
                          }),
                          IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20), onPressed: () {
                            context.read<VolunteersBloc>().add(UpdateVolunteerStatus(globalIndex, 'Отклонён'));
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Заявка отклонена', style: GoogleFonts.poppins(fontSize: 12))));
                          }),
                        ] else
                          Text(applicant['status'], style: GoogleFonts.poppins(fontSize: 12, color: applicant['status'] == 'Принят' ? Colors.green : Colors.red)),
                      ]),
                    ),
                  );
                },
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _statItem(String label, String value) => Column(children: [
    Text(value, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF983296))),
    Text(label, style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
  ]);
}