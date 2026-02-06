import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final ApiService _apiService = ApiService();
  bool _isEditing = false;
  bool _isLoading = true;

  // Данные пользователя
  String _fullName = '';
  String _birthDate = '';
  String _gender = '';
  String _city = '';
  String _phone = '';
  String _email = '';
  String? _avatarUrl;
  
  // Метрики
  int _voloHours = 0;
  int _eventsDone = 0;
  int _certificatesCount = 0;
  int _ecoScore = 0;
  int _socialScore = 0;
  int _sportScore = 0;
  int _culturalScore = 0;
  
  List<String> _interests = [];
  List<String> _skills = [];
  String _experience = '';
  String _motivation = '';

  // Контроллеры
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

  final Color _voloPurple = const Color(0xFF983296);

  @override
  void initState() {
    super.initState();
    _loadAllUserData();
  }

  Future<void> _loadAllUserData() async {
    setState(() => _isLoading = true);
    
    final profileResult = await _apiService.getUserProfile();
    final certsResult = await _apiService.getMyCertificates();

    if (profileResult['success']) {
      final data = profileResult['data'];
      final profile = data['profile'];
      
      setState(() {
        _fullName = profile?['full_name'] ?? 'Не указано';
        _birthDate = profile?['birth_date'] ?? 'Не указано';
        _gender = profile?['gender'] ?? 'Не указано';
        _city = profile?['city'] ?? 'Не указано';
        _phone = profile?['phone'] ?? 'Не указано';
        _email = data['email'] ?? '';
        _avatarUrl = profile?['avatar_url'];
        
        _voloHours = profile?['volo_hours'] ?? 0;
        _eventsDone = profile?['events_done'] ?? 0;
        _ecoScore = profile?['eco_score'] ?? 0;
        _socialScore = profile?['social_score'] ?? 0;
        _sportScore = profile?['sport_score'] ?? 0;
        _culturalScore = profile?['cultural_score'] ?? 0;

        _interests = (data['interests'] as List).map((e) => e['name'] as String).toList();
        _skills = (data['skills'] as List).map((e) => e['name'] as String).toList();
        _experience = profile?['experience'] ?? 'Волонтёр';
        _motivation = profile?['motivation'] ?? '';

        _nameController.text = _fullName;
        _phoneController.text = _phone;
        _emailController.text = _email;
        _motivationController.text = _motivation;
        _birthDateController.text = _birthDate;
        _genderController.text = _gender;
        _cityController.text = _city;
        _experienceController.text = _experience;
      });
    }

    if (certsResult['success']) {
      final List certs = certsResult['data'];
      setState(() => _certificatesCount = certs.length);
    }

    setState(() => _isLoading = false);
  }

  void _saveChanges() async {
    setState(() => _isLoading = true);
    
    final profileData = {
      'full_name': _nameController.text,
      'phone': _phoneController.text,
      'motivation': _motivationController.text,
      'interests': _interests,
      'skills': _skills,
      'city': _cityController.text,
      'gender': _genderController.text,
      'experience': _experienceController.text,
    };

    final result = await _apiService.updateProfile(profileData);
    
    if (result['success']) {
      setState(() {
        _fullName = _nameController.text;
        _phone = _phoneController.text;
        _email = _emailController.text;
        _motivation = _motivationController.text;
        _isEditing = false;
      });
      _showSnack('Данные успешно обновлены', false);
    } else {
      _showSnack(result['message'], true);
    }
    setState(() => _isLoading = false);
  }

  void _showSnack(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
        backgroundColor: isError ? Colors.red : _voloPurple,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/images/left.svg',
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(_voloPurple, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ЛИЧНАЯ ИНФОРМАЦИЯ',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isEditing ? _saveChanges : () => setState(() => _isEditing = true),
            child: Text(
              _isEditing ? 'ГОТОВО' : 'ИЗМЕНИТЬ',
              style: GoogleFonts.poppins(
                color: _voloPurple,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator(color: _voloPurple))
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // HEADER SECTION
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: _voloPurple.withOpacity(0.1), width: 1),
                      image: _avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(_avatarUrl!.startsWith('http') ? _avatarUrl! : '${ApiService.baseUrl}${_avatarUrl!}'),
                              fit: BoxFit.cover,
                            )
                          : const DecorationImage(
                              image: AssetImage('assets/images/us.png'),
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Column(
                    children: [
                      Text(
                        _fullName,
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        _email,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // METRICS Section
                _buildSectionHeader('СТАТИСТИКА'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: _premiumDecoration(),
                  child: Row(
                    children: [
                      _buildMetricItem(_voloHours.toString(), 'ЧАСЫ'),
                      _buildMetricDivider(),
                      _buildMetricItem(_eventsDone.toString(), 'ПРОЕКТЫ'),
                      _buildMetricDivider(),
                      _buildMetricItem(_certificatesCount.toString(), 'ГРАМОТЫ'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // PROFILE DETAILS
                _buildSectionHeader('ОСНОВНЫЕ ДАННЫЕ'),
                const SizedBox(height: 12),
                Container(
                  decoration: _premiumDecoration(),
                  child: Column(
                    children: [
                      _buildSimpleInput('assets/images/name.svg', 'Полное имя', _nameController, true),
                      _buildDivider(),
                      _buildSimpleInput('assets/images/calendar.svg', 'Дата рождения', _birthDateController, false),
                      _buildDivider(),
                      _buildSimpleInput('assets/images/heart.svg', 'Пол', _genderController, false),
                      _buildDivider(),
                      _buildSimpleInput('assets/images/gps.svg', 'Город', _cityController, true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // CATEGORIES (Monotone Style)
                _buildSectionHeader('КАТЕГОРИИ'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: _premiumDecoration(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildCleanScore('ЭКО', _ecoScore),
                      _buildCleanScore('СПОРТ', _sportScore),
                      _buildCleanScore('КУЛЬТ', _culturalScore),
                      _buildCleanScore('СОЦ', _socialScore),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // CONTACTS
                _buildSectionHeader('КОНТАКТЫ'),
                const SizedBox(height: 12),
                Container(
                  decoration: _premiumDecoration(),
                  child: Column(
                    children: [
                      _buildSimpleInput('assets/images/Phone.svg', 'Телефон', _phoneController, true),
                      _buildDivider(),
                      _buildSimpleInput('assets/images/mail.svg', 'E-mail', _emailController, true),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // TAGS SECTIONS
                _buildTagSection('ИНТЕРЕСЫ', _interests, _showInterestsDialog),
                const SizedBox(height: 32),
                _buildTagSection('НАВЫКИ', _skills, _showSkillsDialog),
                const SizedBox(height: 32),

                // SUMMARY
                _buildSectionHeader('МОТИВАЦИЯ'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: _premiumDecoration(),
                  child: TextField(
                    controller: _motivationController,
                    enabled: _isEditing,
                    maxLines: null,
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87, height: 1.6),
                    decoration: const InputDecoration(
                      hintText: 'Введите информацию о вашей мотивации...',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
    );
  }

  BoxDecoration _premiumDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[100]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildSimpleInput(String iconPath, String label, TextEditingController controller, bool editable) {
    final active = editable && _isEditing;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(_voloPurple.withOpacity(0.5), BlendMode.srcIn),
            placeholderBuilder: (BuildContext context) => const Icon(Icons.info_outline, size: 20, color: Colors.grey),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[400]),
                ),
                TextField(
                  controller: controller,
                  enabled: active,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: active ? _voloPurple : Colors.black87,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.only(top: 2),
                    border: InputBorder.none,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String val, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricDivider() => Container(height: 30, width: 1, color: Colors.grey[100]);

  Widget _buildCleanScore(String label, int val) {
    return Column(
      children: [
        Text(
          val.toString(),
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: _voloPurple),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildDivider() => Divider(height: 1, color: Colors.grey[100]!, indent: 60);

  Widget _buildTagSection(String title, List<String> items, VoidCallback onAdd) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(title),
            if (_isEditing)
              GestureDetector(
                onTap: onAdd,
                child: Text(
                  'ДОБАВИТЬ',
                  style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: _voloPurple),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((tag) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: _premiumDecoration(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tag.toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                  ),
                ),
                if (_isEditing) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => items.remove(tag)),
                    child: Icon(Icons.close, size: 14, color: Colors.grey[400]),
                  ),
                ],
              ],
            ),
          )).toList(),
        ),
      ],
    );
  }

  void _showInterestsDialog() {
    _showSearchablePicker('ВЫБЕРИТЕ ИНТЕРЕСЫ', ['Экология', 'Образование', 'Социальная помощь', 'Культура', 'Спорт', 'Медицина', 'Животные', 'Дети и молодежь'], _interests);
  }

  void _showSkillsDialog() {
    _showSearchablePicker('ВЫБЕРИТЕ НАВЫКИ', ['Организация', 'Коммуникация', 'SMM', 'Фотосъемка', 'Перевод', 'Первая помощь', 'Работа с детьми', 'IT', 'Творчество', 'Преподавание', 'Аналитика'], _skills);
  }

  void _showSearchablePicker(String title, List<String> all, List<String> selected) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: all.map((item) {
                      final isSel = selected.contains(item);
                      return GestureDetector(
                        onTap: () {
                          setState(() { if (isSel) selected.remove(item); else selected.add(item); });
                          setModalState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSel ? _voloPurple : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? _voloPurple : Colors.grey[200]!),
                          ),
                          child: Text(
                            item.toUpperCase(),
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: isSel ? Colors.white : Colors.black87),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(backgroundColor: _voloPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: Text('ПРИМЕНИТЬ', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }
}