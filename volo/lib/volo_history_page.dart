import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volo/event_detail_history_page.dart';
import 'blocs/volo_history/volo_history_bloc.dart';
import 'services/api_service.dart';

class VoloHistoryPage extends StatefulWidget {
  const VoloHistoryPage({super.key});
  @override
  State<VoloHistoryPage> createState() => _VoloHistoryPageState();
}

class _VoloHistoryPageState extends State<VoloHistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => VoloHistoryBloc(apiService: ApiService())..add(LoadHistoryData()),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: SvgPicture.asset(
              'assets/images/left.svg',
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: const SizedBox(),
          centerTitle: true,
        ),
        body: BlocBuilder<VoloHistoryBloc, VoloHistoryState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF983296)),
                ),
              );
            }

            if (state.isError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(
                        'Не удалось загрузить историю',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.read<VoloHistoryBloc>().add(LoadHistoryData()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF983296),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          'Повторить',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final filtered = state.selectedFilter == 'Все'
                ? state.events
                : state.events.where((e) => e['category'] == state.selectedFilter).toList();

            return RefreshIndicator(
              onRefresh: () async {
                context.read<VoloHistoryBloc>().add(LoadHistoryData());
              },
              color: const Color(0xFF983296),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFF1F1F5)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Текущий баланс',
                            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey[500]),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '${state.voloHours}',
                                style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.w700, color: const Color(0xFF983296)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'часов',
                                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(height: 1, color: Color(0xFFF1F1F5)),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStatItem('${state.completedCount}', 'Завершено'),
                              _buildStatItem('${state.upcomingCount}', 'Предстоит'),
                              _buildStatItem('${state.workedHours} ч', 'Отработано'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Категории',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _chip(context, 'Все', state.selectedFilter),
                                _chip(context, 'Культура', state.selectedFilter),
                                _chip(context, 'Экология', state.selectedFilter),
                                _chip(context, 'Спорт', state.selectedFilter),
                                _chip(context, 'Образование', state.selectedFilter),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFF983296),
                        unselectedLabelColor: Colors.grey[600],
                        indicatorColor: const Color(0xFF983296),
                        indicatorWeight: 3,
                        labelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                        tabs: const [Tab(text: 'Все'), Tab(text: 'Завершенные'), Tab(text: 'Предстоящие')],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(context, filtered),
                          _buildList(context, filtered.where((e) => e['status'] == 'completed').toList()),
                          _buildList(context, filtered.where((e) => e['status'] == 'upcoming').toList()),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
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
        child: Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.grey[700]),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
              child: Icon(Icons.event_busy, size: 40, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'Нет событий',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final event = list[index];
        final isCompleted = event['status'] == 'completed';
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailHistoryPage(event: event))),
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(image: AssetImage('assets/images/photo.png'), fit: BoxFit.cover),
                        ),
                        child: isCompleted
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFF983296).withValues(alpha: 0.9),
                                ),
                                child: const Center(child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 36)),
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: _getCategoryColor(event['category']), borderRadius: BorderRadius.circular(6)),
                                  child: Text(
                                    event['category'],
                                    style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white),
                                  ),
                                ),
                                const Spacer(),
                                if (isCompleted && event['eventRating'] != null)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${event['eventRating']}',
                                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event['title'],
                              style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(event['organizer'], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey[200]),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/clock.svg',
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                event['date'],
                                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/name.svg',
                              width: 16,
                              height: 16,
                              colorFilter: ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn),
                            ),
                            const SizedBox(width: 6),
                            Text('${event['volunteers']}', style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: const Color(0xFF983296).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                        child: Text(
                          '+${event['hours']} ч',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF983296)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Культура':
        return const Color(0xFFE91E63);
      case 'Экология':
        return const Color(0xFF4CAF50);
      case 'Спорт':
        return const Color(0xFF2196F3);
      case 'Образование':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF983296);
    }
  }
}