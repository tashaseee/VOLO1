// volunteers_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VolunteersPage extends StatefulWidget {
  const VolunteersPage({super.key});

  @override
  State<VolunteersPage> createState() => _VolunteersPageState();
}

class _VolunteersPageState extends State<VolunteersPage> {
  final List<Map<String, dynamic>> applicants = [
    {'name': 'Амина Казанбасова', 'age': '25', 'phone': '+77771234567', 'email': 'amina@email.com', 'event': 'Концерт Тимати', 'status': 'Ожидает', 'id': '1'},
    {'name': 'John Doe', 'age': '28', 'phone': '+7777654321', 'email': 'john@email.com', 'event': 'Фестиваль Хастар', 'status': 'Принят', 'id': '2'},
    // Add more as needed
  ];

  String _filterStatus = 'Все';

  @override
  Widget build(BuildContext context) {
    final filteredApplicants = applicants.where((applicant) => _filterStatus == 'Все' || applicant['status'] == _filterStatus).toList();

    final statusCounts = {
      'Ожидает': applicants.where((a) => a['status'] == 'Ожидает').length,
      'Принят': applicants.where((a) => a['status'] == 'Принят').length,
      'Отклонён': applicants.where((a) => a['status'] == 'Отклонён').length,
    };

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF983296), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Волонтёры',
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26)),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Ожидает', statusCounts['Ожидает'].toString()),
                    _buildStatItem('Принят', statusCounts['Принят'].toString()),
                    _buildStatItem('Отклонён', statusCounts['Отклонён'].toString()),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _filterStatus,
                  items: ['Все', 'Ожидает', 'Принят', 'Отклонён'].map((status) => DropdownMenuItem(value: status, child: Text(status, style: GoogleFonts.poppins(fontSize: 14)))).toList(),
                  onChanged: (value) => setState(() => _filterStatus = value!),
                  decoration: InputDecoration(
                    labelText: 'Фильтр по статусу',
                    labelStyle: GoogleFonts.poppins(fontSize: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  style: GoogleFonts.poppins(fontSize: 14),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: filteredApplicants.length,
              itemBuilder: (context, index) {
                final applicant = filteredApplicants[index];
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(applicant['name'], style: GoogleFonts.poppins(fontSize: 16)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Возраст: ${applicant['age']}', style: GoogleFonts.poppins(fontSize: 14)),
                            Text('Телефон: ${applicant['phone']}', style: GoogleFonts.poppins(fontSize: 14)),
                            Text('Email: ${applicant['email']}', style: GoogleFonts.poppins(fontSize: 14)),
                            Text('Ивент: ${applicant['event']}', style: GoogleFonts.poppins(fontSize: 14)),
                            // Add more details if needed
                          ],
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Закрыть', style: GoogleFonts.poppins(fontSize: 14))),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 1))],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          radius: 20,
                          child: Text(applicant['name'][0], style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(applicant['name'], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
                              Text('Возраст: ${applicant['age']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                              Text(applicant['event'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        if (applicant['status'] == 'Ожидает') ...[
                          IconButton(
                            icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                            onPressed: () {
                              setState(() => applicant['status'] = 'Принят');
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Заявка принята', style: GoogleFonts.poppins(fontSize: 12))));
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                            onPressed: () {
                              setState(() => applicant['status'] = 'Отклонён');
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Заявка отклонена', style: GoogleFonts.poppins(fontSize: 12))));
                            },
                          ),
                        ] else Text(
                          applicant['status'],
                          style: GoogleFonts.poppins(fontSize: 12, color: applicant['status'] == 'Принят' ? Colors.green : Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF983296),
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}