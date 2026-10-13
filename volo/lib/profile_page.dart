import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:volo/home_page.dart';
import 'package:volo/search_page.dart';
import 'package:volo/notifications_page.dart';
import 'package:volo/user_info_page.dart';
import 'package:volo/event_detail_page.dart';
import 'bottom_nav_bar.dart';
import 'chats_page.dart';
import 'services/api_service.dart';
import 'login_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/profile/profile_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'profile_settings_pages.dart';

class ProfilePage extends StatelessWidget {
  final bool? showNavBar;
  const ProfilePage({super.key, this.showNavBar});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(apiService: ApiService())..add(LoadProfile()),
      child: _ProfilePageView(showNavBar: showNavBar ?? true),
    );
  }
}

class _ProfilePageView extends StatefulWidget {
  final bool showNavBar;
  const _ProfilePageView({required this.showNavBar});

  @override
  State<_ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<_ProfilePageView> {
  int _selectedIndex = 4;
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();

  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    if (mounted) {
      context.read<ProfileBloc>().add(UpdateAvatar(image.path));
    }
  }


  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Хедер
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/VOLO-2.svg',
                        height: 21,
                        colorFilter: const ColorFilter.mode(
                            Color(0xFF983296), BlendMode.srcIn),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Профиль с аватаром
                  Row(
                    children: [
                      Stack(
                        children: [
                          ClipOval(
                            child: Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: state.avatarUrl != null && state.avatarUrl!.isNotEmpty
                                  ? FadeInImage.assetNetwork(
                                      placeholder: 'assets/images/us.png',
                                      image: ApiService.mediaUrl(state.avatarUrl),
                                      fit: BoxFit.cover,
                                      imageErrorBuilder: (context, error, stackTrace) {
                                        return Image.asset('assets/images/us.png', fit: BoxFit.cover);
                                      },
                                    )
                                  : Image.asset('assets/images/us.png', fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAndUploadImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/pen.svg',
                                  width: 14,
                                  height: 14,
                                  colorFilter: const ColorFilter.mode(
                                    Color(0xFF983296),
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.userName,
                              style: GoogleFonts.poppins(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0D0D26),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              state.userCity,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF95969D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Volo-часы
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF983296), Color(0xFF7B1FA2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF983296).withValues(alpha: 0.25),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Твои Volo-часы:',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.voloHours.toString(),
                                style: GoogleFonts.poppins(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/volo_history'),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Text(
                              'История',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF983296),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
 
                  // Личная информация
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserInfoPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF983296).withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.badge_outlined,
                              color: Color(0xFF983296),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Личная информация',
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0D0D26),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Управление вашими данными',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: const Color(0xFF95969D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Статистика
                  Text(
                    'Моя активность',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: _buildStatItem(state.eventsDone.toString(), 'Волонтер', Icons.volunteer_activism_rounded, const Color(0xFF983296))),
                        Expanded(child: _buildStatItem(state.ecoScore.toString(), 'Эко-баллы', Icons.eco_rounded, const Color(0xFF4CAF50))),
                        Expanded(child: _buildStatItem(state.sportScore.toString(), 'Спорт-баллы', Icons.sports_soccer_rounded, const Color(0xFFFF9800))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // События в процессе (Approved)
                  if (state.activeEvents.isNotEmpty) ...[
                    Text(
                      'Ваши активные ивенты',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.activeEvents.map((app) {
                       final event = app['event']; // Assuming nested event object from backend or need join
                       // Backend getMyApplications returns list of applications. Usually user applications include event data?
                       // Checking backend... ApplicationOut schema includes event: EventOut. Yes.
                       return Padding(
                         padding: const EdgeInsets.only(bottom: 12),
                         child: GestureDetector(
                          onTap: () {
                             // Navigate to Detail
                             if (event != null) {
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailPage(
                                    eventTitle: event['title'],
                                    organizer: event['organizer'] ?? 'Организатор',
                                    date: event['date_text'] ?? 'Дата',
                                    location: event['location'] ?? 'Локация',
                                    chatLink: event['chat_link'] ?? '',
                                    description: event['description'] ?? '',
                                    responsibilities: (event['responsibilities'] as String? ?? '').split('\n'),
                                    benefits: (event['benefits'] as String? ?? '').split('\n'),
                                    eventId: event['id'],
                                    imageUrl: event['image_url'],
                                    minAge: event['min_age'] ?? 0,
                                    chatId: event['chat_id'],
                                  ),
                                ),
                              );
                             }
                          },
                          child: _buildEventListItem(
                              event?['title'] ?? 'Ивент', 
                              event?['organizer'] ?? 'Организатор', 
                              event?['date_text'] ?? ''
                          ),
                        ),
                       );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Запланированные (Pending)
                  if (state.plannedEvents.isNotEmpty) ...[
                    Text(
                      'Заявки на рассмотрении',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.plannedEvents.map((app) {
                       final event = app['event'];
                       return Padding(
                         padding: const EdgeInsets.only(bottom: 12),
                         child: GestureDetector(
                           onTap: () {
                             if (event != null) {
                               Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventDetailPage(
                                    eventTitle: event['title'],
                                    organizer: event['organizer'] ?? '',
                                    date: event['date_text'] ?? '',
                                    location: event['location'] ?? '',
                                    chatLink: event['chat_link'] ?? '',
                                    description: event['description'] ?? '',
                                    responsibilities: (event['responsibilities'] as String? ?? '').split('\n'),
                                    benefits: (event['benefits'] as String? ?? '').split('\n'),
                                    eventId: event['id'],
                                    imageUrl: event['image_url'],
                                    minAge: event['min_age'] ?? 0,
                                    chatId: event['chat_id'],
                                  ),
                                ),
                              );
                             }
                           },
                           child: _buildEventListItem(
                              event?['title'] ?? 'Ивент', 
                              event?['organizer'] ?? 'Организатор', 
                              'Статус: Ожидание'
                          ),
                         ),
                       );
                    }),
                    const SizedBox(height: 24),
                  ],
                  const SizedBox(height: 24),

                  // Мои сертификаты
                  if (state.certificates.isNotEmpty) ...[
                    Text(
                      'Мои сертификаты',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: state.certificates.map((cert) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildCertificateCard(cert),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  
                  // Настройки
                  Row(
                    children: [
                      Text(
                        'Настройки',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Копка админ-панели (только для админов)
                  FutureBuilder<String?>(
                    future: SharedPreferences.getInstance().then((p) => p.getString('role')),
                    builder: (context, snapshot) {
                      if (snapshot.data == 'admin') {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildSettingItem(
                            title: 'Админ-панель',
                            subtitle: 'Управление заявками организаций',
                            onTap: () => Navigator.pushNamed(context, '/admin_panel'),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  _buildSettingItem(
                    title: 'Настройки уведомлений',
                    subtitle: 'Все уведомления включены',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsPage())),
                  ),
                  _buildSettingItem(
                    title: 'Помощь и поддержка',
                    subtitle: 'FAQ и контакты',
                    onTap: () => Navigator.pushNamed(context, '/help_support'),
                  ),
                  _buildSettingItem(
                    title: 'О приложении',
                    subtitle: 'Версия 1.0.0',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutVoloPage())),
                  ),
                  const SizedBox(height: 8),
                  _buildSettingItem(
                    title: 'Выйти',
                    subtitle: null,
                    onTap: () {
                      _showLogoutDialog();
                    },
                    isLogout: true,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showNavBar
          ? CustomBottomNavBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
            )
          : null,
    );
      },
    );
  }

  Widget _buildStatItem(String number, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          number,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D0D26),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isLogout ? Colors.red : Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isLogout ? Colors.red : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }



  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'О приложении',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'VOLO - Платформа для волонтеров',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Версия: 1.0.0',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              'Разработано в 2025',
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Закрыть',
              style: GoogleFonts.poppins(color: const Color(0xFF983296)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard(dynamic cert) {
    final imageUrl = ApiService.mediaUrl(cert['certificate_url']?.toString());
    final hasImage = imageUrl.isNotEmpty;
    final issueDate = cert['issue_date']?.toString() ?? '';
    final dateLabel = issueDate.length >= 10 ? issueDate.substring(0, 10) : issueDate;

    return GestureDetector(
      onTap: () => _openCertificateFromApi(cert),
      child: Container(
        width: hasImage ? 140 : 160,
        height: hasImage ? 180 : 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F1F5)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF983296).withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: hasImage
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined, color: Color(0xFF983296)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      cert['event_name'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF0D0D26),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF983296).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.workspace_premium_rounded, color: Color(0xFF983296), size: 24),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cert['event_name'] ?? '',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0D0D26),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dateLabel,
                          style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF95969D)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _openCertificateFromApi(dynamic cert) {
    final imageUrl = ApiService.mediaUrl(cert['certificate_url']?.toString());
    if (imageUrl.isEmpty) {
      _showCertificateDialog(
        cert['event_name'] ?? 'Мероприятие',
        cert['organizer_name'] ?? 'VOLO',
        cert['issue_date']?.toString().substring(0, 10) ?? '',
      );
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text(
                'Ваш сертификат',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
            if (cert['hours'] != null && cert['hours'] > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '+${cert['hours']} ч. волонтёрства',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF983296),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    final pdfUrl = imageUrl.replaceAll('.jpg', '.pdf');
                    final uri = Uri.parse(pdfUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } else {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Не удалось открыть ссылку на PDF')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf, color: Color(0xFF983296), size: 18),
                  label: Text(
                    'Скачать PDF',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF983296),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    'Закрыть',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Выйти из аккаунта?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Вы уверены, что хотите выйти?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Отмена',
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          TextButton(
            onPressed: () async {
              await _apiService.logout();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            child: Text(
              'Выйти',
              style: GoogleFonts.poppins(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _onItemTapped(int index) {

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const NotificationsPage(), transitionDuration: Duration.zero));
        break;
      case 1:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const SearchPage(), transitionDuration: Duration.zero));
        break;
      case 2:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => const HomePage(), transitionDuration: Duration.zero));
        break;
      case 3:
        Navigator.pushReplacement(context, PageRouteBuilder(pageBuilder: (_, __, ___) => ChatsPage(), transitionDuration: Duration.zero));
        break;
      case 4:
        break;
    }
  }

  Widget _buildEventListItem(String title, String organizer, String date) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: AssetImage('assets/images/photo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  organizer,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF983296),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedEventItem(String title, String organizer, String date, VoidCallback onCertificateTap) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
              image: const DecorationImage(
                image: AssetImage('assets/images/photo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  organizer,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onCertificateTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF983296).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF983296).withValues(alpha: 0.3)),
              ),
              child: Text(
                'Сертификат',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF983296),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCertificate(String eventName, String organizer, String date) {
    final eventKey = '$eventName-$organizer';
    final rated = context.read<ProfileBloc>().state.ratedEvents[eventKey] == true;
    if (rated) {
      _showCertificateDialog(eventName, organizer, date);
    } else {
      _showRatingDialog(eventName, organizer, date, eventKey);
    }
  }

  void _showRatingDialog(String eventName, String organizer, String date, String eventKey) {
    double eventRating = 0;
    double orgRating = 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  const Color(0xFF983296).withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF983296), Color(0xFFB856B8)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Оцените событие',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                
                // Оценка события
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF983296).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF983296),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.event,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Как вам событие?',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        eventName,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                eventRating = (index + 1).toDouble();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                index < eventRating ? Icons.star : Icons.star_border,
                                size: 24,
                                color: const Color(0xFF983296),
                              ),
                            ),
                          );
                        }),
                      ),
                      if (eventRating > 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${eventRating.toInt()} из 5',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF983296),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Оценка организатора
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF983296).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF983296),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.people,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Оцените организатора',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        organizer,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () {
                              setDialogState(() {
                                orgRating = (index + 1).toDouble();
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: Icon(
                                index < orgRating ? Icons.star : Icons.star_border,
                                size: 24,
                                color: const Color(0xFF983296),
                              ),
                            ),
                          );
                        }),
                      ),
                      if (orgRating > 0)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${orgRating.toInt()} из 5',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF983296),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Кнопки
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Отмена',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (eventRating > 0 && orgRating > 0) {
                            context.read<ProfileBloc>().add(RateEvent(eventKey));
                            Navigator.pop(context);
                            _showCertificateDialog(eventName, organizer, date);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Пожалуйста, поставьте обе оценки',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: const Color(0xFF983296),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF983296),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Подтвердить',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCertificateDialog(String eventName, String organizer, String date) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF983296), Color(0xFFB856B8)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(
                    'assets/images/gal.svg',
                    width: 40,
                    height: 40,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Сертификат получен!',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Спасибо за участие в событии',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Изображение сертификата
                // Изображение сертификата
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: const Color(0xFF983296).withValues(alpha: 0.3),
      width: 2,
    ),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.asset(
      'assets/images/sert.jpg',
      width: double.infinity,
      height: 250,
      fit: BoxFit.cover,
    ),
  ),
),
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF983296).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Организатор: $organizer',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'Дата: $date',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Text(
                          'Закрыть',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Логика для скачивания PDF
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Сертификат скачан!',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: const Color(0xFF983296),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF983296),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Скачать',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}