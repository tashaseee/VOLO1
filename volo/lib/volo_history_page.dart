import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volo/event_detail_history_page.dart';
import 'blocs/volo_history/volo_history_bloc.dart';

class VoloHistoryPage extends StatefulWidget {
  const VoloHistoryPage({super.key});
  @override
  State<VoloHistoryPage> createState() => _VoloHistoryPageState();
}

class _VoloHistoryPageState extends State<VoloHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> events = [
    {'title': 'Массовка в фильме', 'organizer': 'EventWave Kazakhstan', 'date': '23-25 Окт 2025', 'hours': 12, 'status': 'completed', 'category': 'Культура', 'location': 'Киностудия \"Казахфильм\", Алматы', 'volunteers': 45, 'eventRating': 4.8, 'organizerRating': 4.9, 'description': 'Прими участие в съёмках нового казахстанского фильма!', 'responsibilities': ['участие в массовых сценах', 'следование указаниям режиссёра'], 'benefits': ['Участие в фильме', 'Питание', 'Трансфер'], 'hasCertificate': true},
    {'title': 'Посадка деревьев', 'organizer': 'Eco Group', 'date': '25 Окт 2025', 'hours': 4, 'status': 'completed', 'category': 'Экология', 'location': 'Парк Первого Президента, Нур-Султан', 'volunteers': 28, 'eventRating': 4.9, 'organizerRating': 5.0, 'description': 'Озеленение города!', 'responsibilities': ['подготовка почвы', 'посадка саженцев'], 'benefits': ['Сертификат', 'Питание'], 'hasCertificate': true},
    {'title': 'Матч ХК "Барыс"', 'organizer': 'Barys Volunteers', 'date': '28 Ноя 2025', 'hours': 6, 'status': 'upcoming', 'category': 'Спорт', 'location': 'Дворец спорта "Барыс"', 'volunteers': 32, 'eventRating': null, 'organizerRating': null, 'description': 'Помоги на матче!', 'responsibilities': ['встреча гостей'], 'benefits': ['Бесплатный вход'], 'hasCertificate': false},
    {'title': 'Экологическая акция', 'organizer': 'Astana Zhastar', 'date': '2 Дек 2025', 'hours': 5, 'status': 'upcoming', 'category': 'Экология', 'location': 'Набережная реки Есиль', 'volunteers': 50, 'eventRating': null, 'organizerRating': null, 'description': 'Озеленение!', 'responsibilities': ['работа с саженцами'], 'benefits': ['Сертификат'], 'hasCertificate': false},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int get totalHours => events.where((e) => e['status'] == 'completed').fold(0, (sum, e) => sum + (e['hours'] as int));
  int get completedEvents => events.where((e) => e['status'] == 'completed').length;
  int get upcomingEvents => events.where((e) => e['status'] == 'upcoming').length;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VoloHistoryBloc(),
      child: BlocBuilder<VoloHistoryBloc, VoloHistoryState>(
        builder: (context, state) {
          final filtered = state.selectedFilter == 'Все'
              ? events
              : events.where((e) => e['category'] == state.selectedFilter).toList();

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white, elevation: 0,
              leading: IconButton(
                icon: SvgPicture.asset('assets/images/left.svg', width: 24, height: 24, colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn)),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text('История Volo-часов', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
              centerTitle: true,
            ),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFFB856B8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: const Color(0xFF983296).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Текущий баланс', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('2328', style: GoogleFonts.poppins(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white, height: 1)),
                        const SizedBox(width: 8),
                        Padding(padding: const EdgeInsets.only(bottom: 8), child: Text('часов', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white70))),
                      ]),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(child: _buildStatItem('$completedEvents', 'Завершено')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatItem('$upcomingEvents', 'Предстоит')),
                        const SizedBox(width: 12),
                        Expanded(child: _buildStatItem('$totalHours ч', 'Отработано')),
                      ]),
                    ]),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Категории', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(children: [
                          _chip(context, 'Все', state.selectedFilter),
                          _chip(context, 'Культура', state.selectedFilter),
                          _chip(context, 'Экология', state.selectedFilter),
                          _chip(context, 'Спорт', state.selectedFilter),
                          _chip(context, 'Образование', state.selectedFilter),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: const Color(0xFF983296), unselectedLabelColor: Colors.grey[600],
                      indicatorColor: const Color(0xFF983296), indicatorWeight: 3,
                      labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                      unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                      tabs: const [Tab(text: 'Все'), Tab(text: 'Завершенные'), Tab(text: 'Предстоящие')],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: TabBarView(controller: _tabController, children: [
                      _buildList(context, filtered),
                      _buildList(context, filtered.where((e) => e['status'] == 'completed').toList()),
                      _buildList(context, filtered.where((e) => e['status'] == 'upcoming').toList()),
                    ]),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(BuildContext context, String label, String selected) {
    final isSelected = selected == label;
    return GestureDetector(
      onTap: () => context.read<VoloHistoryBloc>().add(ChangeHistoryFilter(label)),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF983296) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF983296) : Colors.grey[300]!),
        ),
        child: Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.grey[700])),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3))),
      child: Column(children: [
        Text(value, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w400, color: Colors.white.withOpacity(0.9)), textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> list) {
    if (list.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: Icon(Icons.event_busy, size: 40, color: Colors.grey[400])),
      const SizedBox(height: 16),
      Text('Нет событий', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600])),
    ]));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final event = list[index];
        final isCompleted = event['status'] == 'completed';
        return GestureDetector(
          onTap: isCompleted ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailHistoryPage(event: event))) : null,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))]),
            child: Column(children: [
              Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), image: const DecorationImage(image: AssetImage('assets/images/photo.png'), fit: BoxFit.cover)),
                  child: isCompleted ? Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: const Color(0xFF983296).withOpacity(0.9)),
                    child: const Center(child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 36))) : null,
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: _getCategoryColor(event['category']), borderRadius: BorderRadius.circular(6)),
                      child: Text(event['category'], style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white))),
                    const Spacer(),
                    if (isCompleted && event['eventRating'] != null)
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Row(children: [const Icon(Icons.star_rounded, color: Colors.amber, size: 14), const SizedBox(width: 4),
                          Text('${event['eventRating']}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]))])),
                  ]),
                  const SizedBox(height: 8),
                  Text(event['title'], style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(event['organizer'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                ])),
              ])),
              Divider(height: 1, color: Colors.grey[200]),
              Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                Expanded(flex: 2, child: Row(children: [
                  SvgPicture.asset('assets/images/clock.svg', width: 16, height: 16, colorFilter: ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn)),
                  const SizedBox(width: 6),
                  Expanded(child: Text(event['date'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]), overflow: TextOverflow.ellipsis)),
                ])),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: Row(children: [
                  SvgPicture.asset('assets/images/name.svg', width: 16, height: 16, colorFilter: ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn)),
                  const SizedBox(width: 6),
                  Text('${event['volunteers']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                ])),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: const Color(0xFF983296).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Text('+${event['hours']} ч', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF983296))),
                ),
              ])),
            ]),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Культура': return const Color(0xFFE91E63);
      case 'Экология': return const Color(0xFF4CAF50);
      case 'Спорт': return const Color(0xFF2196F3);
      case 'Образование': return const Color(0xFFFF9800);
      default: return const Color(0xFF983296);
    }
  }
}