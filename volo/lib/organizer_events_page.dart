import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/api_service.dart';
import 'organizer_event_applications_page.dart';
import 'event_reviews_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/organizer_events/organizer_events_bloc.dart';

class OrganizerEventsPage extends StatelessWidget {
  const OrganizerEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrganizerEventsBloc(apiService: ApiService())..add(LoadEvents()),
      child: const _OrganizerEventsView(),
    );
  }
}

class _OrganizerEventsView extends StatefulWidget {
  const _OrganizerEventsView();

  @override
  State<_OrganizerEventsView> createState() => _OrganizerEventsViewState();
}

class _OrganizerEventsViewState extends State<_OrganizerEventsView> {
  final TextEditingController _searchController = TextEditingController();

  Future<void> _loadEvents() async {
    context.read<OrganizerEventsBloc>().add(LoadEvents());
  }

  Future<void> _toggleStatus(int eventId) async {
    context.read<OrganizerEventsBloc>().add(ToggleEventStatusEvent(eventId));
  }

  Future<void> _finishEvent(int eventId) async {
    context.read<OrganizerEventsBloc>().add(FinishEventEvent(eventId));
  }

  Future<void> _showFinishDialog(int eventId, String title) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        title: Text(
          'Завершить ивент?',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF0D0D26),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Вы уверены, что хотите завершить "$title"?',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF95969D),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildCheckItem('Одобренным волонтерам начислятся часы'),
            const SizedBox(height: 8),
            _buildCheckItem('ИИ сгенерирует персональные сертификаты'),
            const SizedBox(height: 8),
            _buildCheckItem('Волонтеры получат уведомление и сертификат'),
            const SizedBox(height: 8),
            _buildCheckItem('Ивент перейдет в архив'),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: const BorderSide(color: Color(0xFFF1F0F5), width: 1.5),
                    ),
                  ),
                  child: Text(
                    'Отмена',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF95969D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _finishEvent(eventId);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00BFA5),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Завершить',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: Color(0xFF00BFA5), size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF5D5E67), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  void _showSuccessSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    _showSuccessSnackBar(message, Colors.redAccent);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizerEventsBloc, OrganizerEventsState>(
      listener: (context, state) {
        if (state.isSuccessAction && state.successMessage != null) {
          _showSuccessSnackBar(state.successMessage!, const Color(0xFF00BFA5));
        } else if (state.errorMessage != null) {
          _showErrorSnackBar(state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildSearchBar(state),
                _buildFilters(state),
                const SizedBox(height: 12),
                Expanded(
                  child: state.isLoading
                      ? _buildLoadingState()
                      : state.filteredEvents.isEmpty
                          ? _buildEmptyState()
                          : RefreshIndicator(
                              onRefresh: _loadEvents,
                              color: const Color(0xFF983296),
                              backgroundColor: Colors.white,
                              edgeOffset: 20,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100),
                                itemCount: state.filteredEvents.length,
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                itemBuilder: (context, index) {
                                  final event = state.filteredEvents[index];
                                  return _buildModernEventCard(event, index);
                                },
                              ),
                            ),
                ),
              ],
            ),
          ),
          floatingActionButton: state.isLoading ? null : _buildFAB(),
        );
      },
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20, right: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF983296),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF983296).withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/add_event').then((_) => _loadEvents()),
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Создать ивент',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SvgPicture.asset(
                'assets/images/VOLO-2.svg',
                height: 22,
                colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
              ),
              GestureDetector(
                onTap: () => _loadEvents(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                  ),
                  child: const Icon(Icons.refresh_rounded, color: Color(0xFF0D0D26), size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'МОИ ',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D0D26),
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'ИВЕНТЫ',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF983296),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Управление вашими мероприятиями',
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF95969D),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernEventCard(Map<String, dynamic> event, int index) {
    final bool isActive = event['is_active'] == true;
    final String title = event['title'] ?? 'Без названия';
    final String location = event['location'] ?? 'Локация не указана';
    final String date = event['date_text'] ?? 'Дата не указана';
    final String? imageUrl = event['image_url'];
    final int hours = event['hours'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D0D26).withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(22.5)),
                child: Container(
                  height: 180,
                  width: double.infinity,
                  color: const Color(0xFFF5F5F8),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          '${ApiService.baseUrl}$imageUrl',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
              ),
              // Status Badge
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isActive ? 'Активен' : 'В архиве',
                        style: GoogleFonts.poppins(
                          color: isActive ? Colors.green[800] : Colors.orange[800],
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Hours Badge
              Positioned(
                bottom: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF983296),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '+$hours ч',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              // Rating Badge for Archived Events
              if (!isActive)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBBC05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          (event['rating'] ?? 4.8).toString(),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Date Pill
              Positioned(
                bottom: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Text(
                    date,
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF983296),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content Section
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D0D26),
                    letterSpacing: -0.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isActive) ...[
                  const SizedBox(height: 14),
                  _buildRecruitmentProgress(event['approved_count'] ?? 0, event['volunteer_count'] ?? 10),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF95969D)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF95969D),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(height: 1, color: const Color(0xFFF1F0F5)),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  runSpacing: 12,
                  children: [
                    _buildStatItem(
                      isActive ? Icons.people_outline_rounded : Icons.star_outline_rounded,
                      isActive ? 'Заявки' : 'Отзывы',
                      isActive ? 'Управление' : '${event['reviews_count'] ?? 0} отзывов',
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (isActive) ...[
                          GestureDetector(
                            onTap: () => _showFinishDialog(event['id'], event['title'] ?? 'Ивент'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5F5F8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF95969D)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Завершить',
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF5D5E67),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToApplications(event),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF801B7F), Color(0xFF983296)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF983296).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Заявки',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          GestureDetector(
                            onTap: () => _toggleStatus(event['id']),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F0F5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF983296), size: 18),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _navigateToReviews(event),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF801B7F), Color(0xFF983296)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF983296).withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Отзывы',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecruitmentProgress(int approved, int total) {
    double progress = total > 0 ? (approved / total).clamp(0.0, 1.0) : 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Набрано волонтеров',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF95969D), fontWeight: FontWeight.w500),
            ),
            Text(
              '$approved / $total',
              style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF0D0D26), fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: const Color(0xFFF1F0F5),
            color: progress >= 1.0 ? Colors.green : const Color(0xFF983296),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F5F8),
      ),
      child: Center(
        child: Opacity(
          opacity: 0.15,
          child: SvgPicture.asset(
            'assets/images/mask.svg',
            colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF983296)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF95969D),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D0D26),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF983296).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_rounded,
                size: 64,
                color: Color(0xFF983296),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Нет событий',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D0D26),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте свое первое мероприятие и пригласите волонтеров прямо сейчас!',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF95969D),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/add_event').then((_) => _loadEvents()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF983296),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF983296).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Создать первый ивент',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        color: Color(0xFF983296),
        strokeWidth: 3,
      ),
    );
  }

  Future<void> _navigateToApplications(Map<String, dynamic> event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrganizerEventApplicationsPage(
          eventId: event['id'],
          eventTitle: event['title'],
        ),
      ),
    );
    if (result == true) {
      _loadEvents();
    }
  }

  void _navigateToReviews(Map<String, dynamic> event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventReviewsPage(
          eventId: event['id'] ?? 0,
          eventTitle: event['title'] ?? 'Без названия',
        ),
      ),
    );
  }

  Widget _buildSearchBar(OrganizerEventsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Color(0xFFA0A0AB), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) => context.read<OrganizerEventsBloc>().add(UpdateSearchQuery(value)),
                style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0D0D26), fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  hintText: 'Поиск по событиям...',
                  hintStyle: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFA0A0AB), fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (state.searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFFA0A0AB)),
                onPressed: () {
                  _searchController.clear();
                  context.read<OrganizerEventsBloc>().add(UpdateSearchQuery(''));
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(OrganizerEventsState state) {
    final filters = [
      {'label': 'Все', 'value': 'all'},
      {'label': 'Активные', 'value': 'active'},
      {'label': 'Архив', 'value': 'inactive'},
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final isSelected = state.filter == f['value'];
          return GestureDetector(
            onTap: () => context.read<OrganizerEventsBloc>().add(UpdateFilter(f['value']!)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF983296) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? const Color(0xFF983296) : const Color(0xFFF1F0F5),
                  width: 1.5,
                ),
              ),
              child: Text(
                f['label']!,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF95969D),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
