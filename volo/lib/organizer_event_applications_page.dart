import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/organizer_event_applications/organizer_event_applications_bloc.dart';

class OrganizerEventApplicationsPage extends StatelessWidget {
  final int eventId;
  final String eventTitle;

  const OrganizerEventApplicationsPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrganizerEventAppsBloc(apiService: ApiService())..add(LoadEventApps(eventId)),
      child: _OrganizerEventApplicationsView(eventId: eventId, eventTitle: eventTitle),
    );
  }
}

class _OrganizerEventApplicationsView extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const _OrganizerEventApplicationsView({
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<_OrganizerEventApplicationsView> createState() => _OrganizerEventApplicationsViewState();
}

class _OrganizerEventApplicationsViewState extends State<_OrganizerEventApplicationsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _updatingAppIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadApplications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadApplications() async {
    context.read<OrganizerEventAppsBloc>().add(LoadEventApps(widget.eventId));
  }

  Future<void> _updateStatus(int applicationId, String status, {Map<String, dynamic>? app}) async {
    if (_updatingAppIds.contains(applicationId)) return;
    setState(() {
      _updatingAppIds.add(applicationId);
    });
    context.read<OrganizerEventAppsBloc>().add(UpdateAppStatus(
      eventId: widget.eventId,
      applicationId: applicationId,
      status: status,
      appData: app,
    ));
  }

  Future<void> _finishEvent() async {
    final confirmed = await showDialog<bool>(
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
        content: Text(
          'Одобренным волонтерам начислятся часы, ИИ сгенерирует персональные сертификаты на вашем шаблоне и отправит их в профиль. Ивент перейдет в архив.',
          style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF95969D), height: 1.45),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
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
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
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

    if (confirmed == true) {
      context.read<OrganizerEventAppsBloc>().add(FinishEvent(widget.eventId));
    }
  }

  void _showAcceptanceDialog(Map<String, dynamic>? user, Map<String, dynamic>? event) {
    final profile = user?['profile'];
    final name = profile?['full_name'] ?? user?['email'] ?? 'Волонтер';
    final chatLinkStr = event?['chat_link'] ?? '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF983296).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF983296), size: 56),
            ),
            const SizedBox(height: 20),
            Text(
              'Волонтер принят!',
              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26)),
            ),
            const SizedBox(height: 12),
            Text(
              'Вы приняли $name. Волонтер добавлен в чат ивента в VOLO и получил уведомление.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF95969D), height: 1.5),
            ),
            if (chatLinkStr.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Доп. чат: $chatLinkStr',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF95969D), fontWeight: FontWeight.w600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF983296),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                ),
                child: Text(
                  'ОТЛИЧНО',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizerEventAppsBloc, OrganizerEventAppsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _updatingAppIds.clear();
          _showErrorSnackBar(state.errorMessage!);
        } else if (!state.isLoading && !state.showAcceptanceDialog && !state.isSuccessAction) {
          _updatingAppIds.clear();
        }
        if (state.isSuccessAction && state.successMessage != null) {
          _showSuccessSnackBar(state.successMessage!, const Color(0xFF00BFA5));
        }
        if (state.showAcceptanceDialog && state.acceptedUser != null) {
          _showAcceptanceDialog(state.acceptedUser, state.event);
        }
      },
      builder: (context, state) {
        final pendingApplications = state.applications.where((a) => a['status'] == 'pending').toList();
        final approvedApplications = state.applications.where((a) => a['status'] == 'approved').toList();
        final rejectedApplications = state.applications.where((a) => a['status'] == 'rejected').toList();

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                _buildTabSection(pendingApplications, approvedApplications, rejectedApplications),
                const SizedBox(height: 12),
                Expanded(
                  child: state.isLoading
                      ? _buildLoadingState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildApplicationsList(pendingApplications, 'pending'),
                            _buildApplicationsList(approvedApplications, 'approved'),
                            _buildApplicationsList(rejectedApplications, 'rejected'),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context, true),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D0D26), size: 16),
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: _finishEvent,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.15), width: 1.5),
                      ),
                      child: const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 18),
                    ),
                  ),
                  GestureDetector(
                    onTap: _loadApplications,
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
            ],
          ),
          const SizedBox(height: 24),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ЗАЯВКИ ',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0D0D26),
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'ВОЛОНТЕРОВ',
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
            widget.eventTitle.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF95969D),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection(List pendingApplications, List approvedApplications, List rejectedApplications) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D0D26).withValues(alpha: 0.015),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: const Color(0xFF983296),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF95969D),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700),
        unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.all(4),
        tabs: [
          _buildTabItem('Новые', pendingApplications.length),
          _buildTabItem('Приняты', approvedApplications.length),
          _buildTabItem('Отказ', rejectedApplications.length),
        ],
      ),
    );
  }

  Widget _buildTabItem(String label, int count) {
    return Tab(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsList(List<dynamic> applications, String status) {
    if (applications.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: const Color(0xFF983296),
      backgroundColor: Colors.white,
      edgeOffset: 20,
      child: ListView.builder(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 100, top: 8),
        itemCount: applications.length,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemBuilder: (context, index) {
          final app = applications[index];
          return GestureDetector(
            onTap: () => _showVolunteerModal(context, app['user']),
            child: _buildModernApplicationCard(app, status),
          );
        },
      ),
    );
  }

  Widget _buildModernApplicationCard(Map<String, dynamic> app, String status) {
    final user = app['user'];
    final profile = user?['profile'];
    final String name = profile?['full_name'] ?? user?['email'] ?? 'Аноним';
    final String avatarUrl = profile?['avatar_url'] ?? '';
    final String date = app['created_at'] != null ? _formatDate(app['created_at']) : 'Сегодня';
    
    // Новые поля для детального просмотра
    final String phone = profile?['phone_number'] ?? '';
    final String aboutMe = profile?['about_me'] ?? '';
    final String skillsStr = profile?['skills'] ?? '';
    final List<String> skills = skillsStr.isNotEmpty ? skillsStr.split(',').map((s) => s.trim()).toList() : [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: status == 'pending' ? const Color(0xFF983296).withValues(alpha: 0.15) : const Color(0xFFF1F0F5), 
          width: status == 'pending' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: status == 'pending' ? const Color(0xFF983296).withValues(alpha: 0.05) : const Color(0xFF0D0D26).withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: avatarUrl.isNotEmpty
                        ? Image.network(
                            avatarUrl.startsWith('http') ? avatarUrl : '${ApiService.baseUrl}$avatarUrl',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(name),
                          )
                        : _buildAvatarPlaceholder(name),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0D0D26),
                          letterSpacing: -0.4,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, size: 12, color: Color(0xFF95969D)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user?['email'] ?? '',
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
                      if (phone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 12, color: Color(0xFF95969D)),
                            const SizedBox(width: 4),
                            Text(
                              phone,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF95969D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF983296).withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF983296)),
                                const SizedBox(width: 4),
                                Text(
                                  date,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    color: const Color(0xFF983296),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (status != 'pending') 
                  _buildStatusPill(status),
              ],
            ),
            
            // Информация о волонтере
            if (aboutMe.isNotEmpty || skills.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F0F5), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (aboutMe.isNotEmpty) ...[
                      Text(
                        'О себе',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF95969D), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        aboutMe,
                        style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF0D0D26), height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (aboutMe.isNotEmpty && skills.isNotEmpty) const SizedBox(height: 12),
                    if (skills.isNotEmpty) ...[
                      Text(
                        'Навыки',
                        style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF95969D), letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: skills.take(4).map((skill) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Text(
                            skill,
                            style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF4B5563), fontWeight: FontWeight.w600),
                          ),
                        )).toList()..addAll(skills.length > 4 ? [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                            child: Text('+${skills.length - 4}', style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w700)),
                          )
                        ] : []),
                      ),
                    ]
                  ],
                ),
              ),
            ],

            if (status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      'Отклонить',
                      Colors.white,
                      const Color(0xFF95969D),
                      () => _updateStatus(app['id'], 'rejected'),
                      icon: Icons.close_rounded,
                      borderSide: const BorderSide(color: Color(0xFFF1F0F5), width: 1.5),
                      isLoading: _updatingAppIds.contains(app['id']),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      'Принять',
                      const Color(0xFF983296),
                      Colors.white,
                      () => _updateStatus(app['id'], 'approved', app: app),
                      icon: Icons.check_rounded,
                      isLoading: _updatingAppIds.contains(app['id']),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'A',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF983296),
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    bool isApproved = status == 'approved';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: (isApproved ? Colors.green : Colors.red).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: (isApproved ? Colors.green : Colors.red).withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Text(
        isApproved ? 'Принят' : 'Отказ',
        style: GoogleFonts.poppins(
          color: isApproved ? Colors.green[800] : Colors.red[800],
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color bgColor, Color textColor, VoidCallback onTap, {IconData? icon, BorderSide? borderSide, bool isLoading = false}) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isLoading ? bgColor.withValues(alpha: 0.5) : bgColor,
          border: borderSide != null ? Border.fromBorderSide(borderSide) : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: !isLoading && bgColor == const Color(0xFF983296) ? [
            BoxShadow(
              color: const Color(0xFF983296).withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: textColor,
                ),
              ),
              const SizedBox(width: 8),
            ] else if (icon != null) ...[
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    IconData icon;
    String text;
    String subtext;
    switch (status) {
      case 'approved':
        icon = Icons.verified_user_rounded;
        text = 'НЕТ ПРИНЯТЫХ';
        subtext = 'Здесь появятся волонтеры, которых вы подтвердите для участия в ивенте';
        break;
      case 'rejected':
        icon = Icons.person_off_rounded;
        text = 'НЕТ ОТКЛОНЕННЫХ';
        subtext = 'Здесь будут отображаться заявки, которые не прошли отбор';
        break;
      default:
        icon = Icons.mail_rounded;
        text = 'НОВЫХ ЗАЯВОК НЕТ';
        subtext = 'Как только кто-то захочет присоединиться, вы увидите это здесь';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF983296).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: const Color(0xFF983296)),
            ),
            const SizedBox(height: 24),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0D0D26),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtext,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF95969D),
                height: 1.5,
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

  String _formatDate(String dateStr) {
    try {
      DateTime date;
      if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
         date = DateTime.parse('${dateStr}Z').toLocal();
      } else {
         date = DateTime.parse(dateStr).toLocal();
      }

      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} мин назад';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} ч назад';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} дн назад';
      } else {
        return '${date.day}.${date.month}.${date.year}';
      }
    } catch (_) {
      return 'Сегодня';
    }
  }

  void _showVolunteerModal(BuildContext context, Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _VolunteerModalBottomSheet(user: user),
    );
  }
}

class _VolunteerModalBottomSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  
  const _VolunteerModalBottomSheet({required this.user});

  @override
  Widget build(BuildContext context) {
    final profile = user['profile'];
    final name = profile?['full_name'] ?? user['email'] ?? 'Аноним';
    final avatarUrl = profile?['avatar_url'] ?? '';
    final phone = profile?['phone_number'] ?? '';
    final aboutMe = profile?['about_me'] ?? '';
    final skillsStr = profile?['skills'] ?? '';
    final List<String> skills = skillsStr.isNotEmpty ? skillsStr.split(',').map((s) => s.trim()).toList() : [];
    
    // Подсчет возраста
    String ageText = 'Возраст не указан';
    if (profile?['birth_date'] != null) {
      try {
        final birthDate = DateTime.parse(profile['birth_date']);
        final today = DateTime.now();
        int age = today.year - birthDate.year;
        if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        ageText = '$age лет';
      } catch (_) {}
    }

    // Расчет шкалы опыта
    final voloHours = (profile?['volo_hours'] ?? 0) as int;
    final karma = (profile?['karma'] ?? 0) as int;
    final currentLevel = (voloHours / 20).floor() + 1;
    final nextLevelXP = currentLevel * 20;
    final progress = (voloHours % 20) / 20;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 24),
            width: 48,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(left: 24, right: 24, bottom: 40),
              physics: const BouncingScrollPhysics(),
              children: [
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF983296).withValues(alpha: 0.2), width: 3),
                      image: avatarUrl.isNotEmpty ? DecorationImage(
                        image: NetworkImage(avatarUrl.startsWith('http') ? avatarUrl : '${ApiService.baseUrl}$avatarUrl'),
                        fit: BoxFit.cover,
                      ) : null,
                    ),
                    child: avatarUrl.isEmpty ? const Icon(Icons.person, size: 40, color: Color(0xFF983296)) : null,
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    name,
                    style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26), letterSpacing: -0.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    ageText,
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF95969D), fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),

                // Шкала опыта (Premium UI)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF983296), Color(0xFF6B21A8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF983296).withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Уровень $currentLevel', style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('$voloHours / $nextLevelXP часов', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.7))),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text('$karma Кармы', style: GoogleFonts.poppins(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                if (phone.isNotEmpty || user['email'] != null) ...[
                  Text('Контакты', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26))),
                  const SizedBox(height: 12),
                  if (phone.isNotEmpty) _buildInfoTile(Icons.phone_rounded, phone),
                  if (user['email'] != null) _buildInfoTile(Icons.email_rounded, user['email']),
                  const SizedBox(height: 32),
                ],

                if (skills.isNotEmpty) ...[
                  Text('Навыки', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26))),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: skills.map((s) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: const Color(0xFFF5F5F8), borderRadius: BorderRadius.circular(12)),
                      child: Text(s, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF4B5563))),
                    )).toList(),
                  ),
                  const SizedBox(height: 32),
                ],

                if (aboutMe.isNotEmpty) ...[
                  Text('О себе', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26))),
                  const SizedBox(height: 12),
                  Text(
                    aboutMe,
                    style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF5D5E67), height: 1.6),
                  ),
                  const SizedBox(height: 32),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF5F5F8), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: const Color(0xFF983296)),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0D0D26)))),
        ],
      ),
    );
  }
}
