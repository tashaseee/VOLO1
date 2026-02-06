import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrganizerProfilePage extends StatefulWidget {
  const OrganizerProfilePage({super.key});

  @override
  State<OrganizerProfilePage> createState() => _OrganizerProfilePageState();
}

class _OrganizerProfilePageState extends State<OrganizerProfilePage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String _orgName = 'Загрузка...';
  String _orgDesc = ''; // Для описания
  int _eventsCount = 0;
  int _appsCount = 0;
  double _rating = 0.0;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();

  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  bool _isEditing = false; // Режим редактирования (открывается в диалоге или листе)

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final result = await _apiService.getUserProfile();
    final eventsResult = await _apiService.getMyEvents();
    
    if (mounted) {
       setState(() {
        if (result['success']) {
          final data = result['data'];
          final profile = data['org_profile'];
          _orgName = profile?['full_name'] ?? 'Организация';
          _orgDesc = profile?['description'] ?? '';
          _avatarUrl = profile?['avatar_url'];
          
          _nameController.text = _orgName;
          _descController.text = _orgDesc;
          _phoneController.text = profile?['phone'] ?? '';
          _websiteController.text = profile?['website'] ?? '';
        }
        
        if (eventsResult['success']) {
          final events = eventsResult['data'] as List;
          _eventsCount = events.length;
          _appsCount = events.fold(0, (sum, e) => sum + (e['applications_count'] as int? ?? 0));
          // Fake rating calculation
          _rating = 4.8; 
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _pickAvatar() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    // В идеале тут нужен вызов API для загрузки аватара
    // Пока просто имитируем локально или используем existing uploadAvatar если он поддерживает оргов
    // Предположим, что uploadAvatar универсален
    // final result = await _apiService.uploadAvatar(image.path);
    
    // Пока локально
    setState(() {
      _avatarUrl = null; // сброс
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Функция загрузки фото в разработке')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   const SizedBox(height: 40),
                  // Header
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/images/VOLO-2.svg',
                        height: 21,
                        colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Profile Header (Avatar + Name)
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.grey[200],
                            ),
                            child: ClipOval(
                              child: _avatarUrl != null
                                  ? Image.network(
                                      'http://127.0.0.1:8000$_avatarUrl',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_,__,___) => Image.asset('assets/images/org.png', fit: BoxFit.cover),
                                    )
                                  : Image.asset('assets/images/org.png', fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickAvatar,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: SvgPicture.asset(
                                  'assets/images/pen.svg',
                                  width: 14,
                                  height: 14,
                                  colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
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
                              _orgName,
                              style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26)),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Организатор',
                              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w400, color: const Color(0xFF95969D)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Main Stats Block (Gradient)
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF983296), Color(0xFFB856B8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF983296).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn(_eventsCount.toString(), 'Ивентов'),
                        Container(width: 1, height: 40, color: Colors.white30),
                        _buildStatColumn(_rating.toString(), 'Рейтинг'),
                        Container(width: 1, height: 40, color: Colors.white30),
                        _buildStatColumn(_appsCount.toString(), 'Заявок'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Edit Info Button
                  GestureDetector(
                    onTap: _showEditDialog,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF983296).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF983296).withOpacity(0.1)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF983296).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SvgPicture.asset(
                              'assets/images/pen.svg',
                              width: 22,
                              height: 22,
                              colorFilter: const ColorFilter.mode(Color(0xFF983296), BlendMode.srcIn),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Данные организации',
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black),
                                ),
                                Text(
                                  'Изменить описание и контакты',
                                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF983296)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Settings / Info
                  _buildSectionTitle('Настройки'),
                  _buildSettingItem(
                    title: 'Уведомления',
                    subtitle: 'Включены',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    title: 'Помощь и поддержка',
                    subtitle: 'Связаться с нами',
                    onTap: () {},
                  ),
                  _buildSettingItem(
                    title: 'О приложении',
                    subtitle: 'Версия 1.0.0',
                    onTap: () {},
                  ),
                  
                  const SizedBox(height: 8),
                  
                  _buildSettingItem(
                    title: 'Выйти',
                    subtitle: null,
                    isDestructive: true,
                    onTap: _showLogoutDialog,
                  ),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
      ),
    );
  }

  Widget _buildSettingItem({required String title, String? subtitle, required VoidCallback onTap, bool isDestructive = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
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
                      fontWeight: FontWeight.w500,
                      color: isDestructive ? Colors.red : const Color(0xFF0D0D26),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF95969D)),
                    ),
                  ]
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  void _showEditDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Редактировать', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildTextField('Название', _nameController),
                    const SizedBox(height: 16),
                    _buildTextField('Описание', _descController, maxLines: 4),
                    const SizedBox(height: 16),
                    _buildTextField('Телефон', _phoneController),
                    const SizedBox(height: 16),
                    _buildTextField('Вебсайт', _websiteController),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () async {
                           // Save logic here (call API updateOrgProfile)
                           Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF983296),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text('Сохранить', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF0D0D26))),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF9F9FA),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выйти?'),
        content: const Text('Вы уверены что хотите выйти из аккаунта?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Отмена')),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
            },
            child: const Text('Выйти', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}