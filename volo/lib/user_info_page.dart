import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'blocs/user_info/user_info_bloc.dart';

class UserInfoPage extends StatelessWidget {
  const UserInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserInfoBloc(apiService: ApiService())..add(LoadUserInfo()),
      child: const _UserInfoView(),
    );
  }
}

class _UserInfoView extends StatefulWidget {
  const _UserInfoView();

  @override
  State<_UserInfoView> createState() => _UserInfoViewState();
}

class _UserInfoViewState extends State<_UserInfoView> {
  final Color _voloPurple = const Color(0xFF983296);
  bool _isEditing = false;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _motivationController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();

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

  void _syncControllers(Map<String, dynamic> data) {
    if (!_isEditing) {
      _nameController.text = data['full_name'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _emailController.text = data['email'] ?? '';
      _motivationController.text = data['motivation'] ?? '';
      _birthDateController.text = data['birth_date'] ?? '';
      _genderController.text = data['gender'] ?? '';
      _cityController.text = data['city'] ?? '';
      _experienceController.text = data['experience'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserInfoBloc, UserInfoState>(
      listener: (context, state) {
        if (state.isSuccessAction && state.message != null) {
          _showSnack(state.message!, state.isError);
          if (!state.isError) {
            setState(() => _isEditing = false);
          }
        }
      },
      builder: (context, state) {
        if (!state.isLoading && !_isEditing && state.rawProfile.isNotEmpty) {
          _syncControllers(state.rawProfile);
        }

        final data = state.rawProfile;

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
                onPressed: () {
                  if (_isEditing) {
                    context.read<UserInfoBloc>().add(SaveUserInfo(
                      fullName: _nameController.text,
                      phone: _phoneController.text,
                      motivation: _motivationController.text,
                      city: _cityController.text,
                      gender: _genderController.text,
                      experience: _experienceController.text,
                    ));
                  } else {
                    setState(() => _isEditing = true);
                  }
                },
                child: state.isSaving
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(
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
          body: state.isLoading 
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
                          border: Border.all(color: _voloPurple.withValues(alpha: 0.1), width: 1),
                          image: data['avatar_url'] != null
                              ? DecorationImage(
                                  image: NetworkImage(data['avatar_url'].startsWith('http') ? data['avatar_url'] : '${ApiService.baseUrl}${data['avatar_url']}'),
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
                            data['full_name'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            data['email'] ?? '',
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
                          _buildMetricItem((data['volo_hours'] ?? 0).toString(), 'ЧАСЫ'),
                          _buildMetricDivider(),
                          _buildMetricItem((data['events_done'] ?? 0).toString(), 'ПРОЕКТЫ'),
                          _buildMetricDivider(),
                          _buildMetricItem(state.certificatesCount.toString(), 'ГРАМОТЫ'),
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
                          _buildCleanScore('ЭКО', data['eco_score'] ?? 0),
                          _buildCleanScore('СПОРТ', data['sport_score'] ?? 0),
                          _buildCleanScore('КУЛЬТ', data['cultural_score'] ?? 0),
                          _buildCleanScore('СОЦ', data['social_score'] ?? 0),
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
                          _buildSimpleInput('assets/images/mail.svg', 'E-mail', _emailController, true), // email read only but let's keep editable true in UI logic visually
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // TAGS SECTIONS
                    _buildTagSection('ИНТЕРЕСЫ', state.interests, () => _showInterestsDialog(state.interests), 'interest'),
                    const SizedBox(height: 32),
                    _buildTagSection('НАВЫКИ', state.skills, () => _showSkillsDialog(state.skills), 'skill'),
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
      },
    );
  }

  BoxDecoration _premiumDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey[100]!),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.02),
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
            colorFilter: ColorFilter.mode(_voloPurple.withValues(alpha: 0.5), BlendMode.srcIn),
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

  Widget _buildTagSection(String title, List<String> items, VoidCallback onAdd, String type) {
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
                    onTap: () => context.read<UserInfoBloc>().add(RemoveCategory(type, tag)),
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

  void _showInterestsDialog(List<String> selected) {
    _showSearchablePicker('ВЫБЕРИТЕ ИНТЕРЕСЫ', ['Экология', 'Образование', 'Социальная помощь', 'Культура', 'Спорт', 'Медицина', 'Животные', 'Дети и молодежь'], selected, 'interest');
  }

  void _showSkillsDialog(List<String> selected) {
    _showSearchablePicker('ВЫБЕРИТЕ НАВЫКИ', ['Организация', 'Коммуникация', 'SMM', 'Фотосъемка', 'Перевод', 'Первая помощь', 'Работа с детьми', 'IT', 'Творчество', 'Преподавание', 'Аналитика'], selected, 'skill');
  }

  void _showSearchablePicker(String title, List<String> all, List<String> initialSelected, String type) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            // Need to read from the provider above the modal correctly. 
            // We'll dispatch events to the bloc from the main context.
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
                  const SizedBox(height: 24),
                  BlocBuilder<UserInfoBloc, UserInfoState>(
                    bloc: context.read<UserInfoBloc>(),
                    builder: (context, state) {
                      final currentSelected = type == 'interest' ? state.interests : state.skills;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: all.map((item) {
                          final isSel = currentSelected.contains(item);
                          return GestureDetector(
                            onTap: () {
                              context.read<UserInfoBloc>().add(ToggleCategory(type, item));
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
                      );
                    }
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(bottomSheetContext),
                      style: ElevatedButton.styleFrom(backgroundColor: _voloPurple, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: Text('ПРИМЕНИТЬ', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.white)),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(bottomSheetContext).viewInsets.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }
}