import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:volo/home_page.dart';
import 'package:volo/my_applications_page.dart';
import 'package:volo/profile_page.dart';
import 'package:volo/notifications_page.dart';
import 'package:volo/event_detail_page.dart';
import 'package:volo/filter_page.dart';
import 'package:volo/chats_page.dart';
import 'bottom_nav_bar.dart';
import 'services/api_service.dart';
import 'blocs/search/search_bloc.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SearchBloc(apiService: ApiService())..add(LoadSearchEvents()),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> categories = ['Все', 'Экология', 'Социальные', 'Образование', 'Культура', 'Спорт'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const NotificationsPage(), transitionDuration: Duration.zero)); break;
      case 1: break;
      case 2: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const HomePage(), transitionDuration: Duration.zero)); break;
      case 3: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ChatsPage(), transitionDuration: Duration.zero)); break;
      case 4: Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const ProfilePage(), transitionDuration: Duration.zero)); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchBloc, SearchState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: [
                    SvgPicture.asset('assets/images/VOLO-2.svg', height: 21,
                      colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn)),
                    const Spacer(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Search bar + filter button
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  SvgPicture.asset('assets/images/search.svg', width: 18, height: 18,
                                    colorFilter: ColorFilter.mode(Colors.grey[500]!, BlendMode.srcIn)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      onChanged: (v) => context.read<SearchBloc>().add(SearchQueryChanged(v)),
                                      decoration: InputDecoration(
                                        hintText: 'Поиск событий...',
                                        hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500]),
                                        border: InputBorder.none,
                                      ),
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (context) => FilterPage(
                                  onFiltersApplied: (filters) => context.read<SearchBloc>().add(LoadSearchEvents()),
                                ),
                              ));
                            },
                            child: Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF983296),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: SvgPicture.asset('assets/images/filter.svg', width: 18, height: 18,
                                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Category chips
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: categories.map((category) {
                            final isSelected = state.selectedCategory == category;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => context.read<SearchBloc>().add(SearchCategoryChanged(category)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF983296) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? const Color(0xFF983296) : Colors.grey[300]!,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                  child: Text(
                                    category,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white : Colors.grey[600],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Популярные события', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black)),
                      const SizedBox(height: 16),
                      state.isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: state.filteredEvents.length,
                              itemBuilder: (context, index) {
                                final event = state.filteredEvents[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _buildEventListItem(
                                    context: context,
                                    title: event['title'],
                                    organizer: event['organizer'] ?? 'Организатор',
                                    date: event['date_text'] ?? 'Скоро',
                                    onTap: () {
                                      Navigator.push(context, MaterialPageRoute(
                                        builder: (context) => EventDetailPage(
                                          eventTitle: event['title'],
                                          organizer: event['organizer'] ?? 'Организатор',
                                          date: event['date_text'] ?? 'Скоро',
                                          location: event['location'] ?? 'Онлайн',
                                          chatLink: event['chat_link'] ?? '',
                                          description: event['description'] ?? '',
                                          responsibilities: (event['responsibilities'] as String? ?? '').split(', '),
                                          benefits: (event['benefits'] as String? ?? '').split(', '),
                                          eventId: event['id'],
                                        ),
                                      ));
                                    },
                                  ),
                                );
                              },
                            ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: CustomBottomNavBar(currentIndex: 1, onTap: _onItemTapped),
        );
      },
    );
  }

  Widget _buildEventListItem({
    required BuildContext context,
    required String title,
    required String organizer,
    required String date,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 60, height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(8),
                image: const DecorationImage(image: AssetImage('assets/images/photo.png'), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black)),
                  const SizedBox(height: 4),
                  Text(organizer, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w400, color: Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text(date, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF983296))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}