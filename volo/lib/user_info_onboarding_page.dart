import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'welcome_animation_page.dart';
import 'sign_in_page.dart';

import 'services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/onboarding/user_onboarding_bloc.dart';

class UserInfoOnboardingPage extends StatelessWidget {
  const UserInfoOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserOnboardingBloc(apiService: ApiService()),
      child: const _UserInfoOnboardingView(),
    );
  }
}

class _UserInfoOnboardingView extends StatefulWidget {
  const _UserInfoOnboardingView();

  @override
  State<_UserInfoOnboardingView> createState() => _UserInfoOnboardingViewState();
}

class _UserInfoOnboardingViewState extends State<_UserInfoOnboardingView>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _progressController;

  // Данные пользователя
  String firstName = '';
  String lastName = '';
  DateTime? birthDate;
  String gender = '';
  String city = '';
  String phone = '';
  String email = '';
  List<String> interests = [];
  List<String> skills = [];
  String experience = '';
  String motivation = '';

  final List<String> availableInterests = [
    'Экология',
    'Образование',
    'Социальная помощь',
    'Культура',
    'Спорт',
    'Медицина',
    'Животные',
    'Дети и молодежь'
  ];

  final List<String> availableSkills = [
    'Организация',
    'Коммуникация',
    'Лидерство',
    'Творчество',
    'IT навыки',
    'Языки',
    'Фото/Видео',
    'Дизайн'
  ];

  final List<String> cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Караганда',
    'Актобе',
    'Тараз',
    'Павлодар',
    'Усть-Каменогорск',
    'Семей',
    'Костанай',
    'Кызылорда',
    'Атырау',
    'Актау',
    'Петропавловск',
    'Уральск',
    'Темиртау',
    'Туркестан',
    'Кокшетау'
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 5) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
        _progressController.forward(from: 0);
      });
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage--;
      });
    }
  }

  void _completeOnboarding() {
    context.read<UserOnboardingBloc>().add(UpdateField('firstName', firstName));
    context.read<UserOnboardingBloc>().add(UpdateField('lastName', lastName));
    if (birthDate != null) context.read<UserOnboardingBloc>().add(UpdateField('birthDate', birthDate));
    context.read<UserOnboardingBloc>().add(UpdateField('gender', gender));
    context.read<UserOnboardingBloc>().add(UpdateField('city', city));
    context.read<UserOnboardingBloc>().add(UpdateField('phone', phone));
    for(var item in interests) context.read<UserOnboardingBloc>().add(ToggleListField('interests', item));
    for(var item in skills) context.read<UserOnboardingBloc>().add(ToggleListField('skills', item));
    context.read<UserOnboardingBloc>().add(UpdateField('experience', experience));
    context.read<UserOnboardingBloc>().add(UpdateField('motivation', motivation));
    context.read<UserOnboardingBloc>().add(SubmitOnboarding());
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Выход', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Вы уверены, что хотите выйти?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Выйти', style: GoogleFonts.poppins(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService().logout();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (route) => false,
      );
    }
  }

  bool _canProceed() {
    switch (_currentPage) {
      case 0:
        return firstName.isNotEmpty && lastName.isNotEmpty && birthDate != null && gender.isNotEmpty;
      case 1:
        return city.isNotEmpty;
      case 2:
        return phone.isNotEmpty;
      case 3:
        return interests.isNotEmpty;
      case 4:
        return skills.isNotEmpty;
      case 5:
        return motivation.isNotEmpty;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserOnboardingBloc, UserOnboardingState>(
    listener: (context, state) {
      if (state.errorMessage != null) {
        _showError(state.errorMessage!);
      }
      if (state.isSuccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeAnimationPage()),
        );
      }
    },
    builder: (context, state) {
      final isLoading = state.isSubmitting;
      return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: _currentPage > 0
            ? IconButton(
                icon: SvgPicture.asset(
                  'assets/images/left.svg',
                  width: 24,
                  height: 24,
                  colorFilter:
                      const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                  placeholderBuilder: (_) =>
                      const Icon(Icons.arrow_back, color: Colors.black),
                ),
                onPressed: _previousPage,
              )
            : IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.black),
                onPressed: _logout,
              ),
        title: Text(
          'Расскажите о себе',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Прогресс-бар
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: List.generate(6, (index) {
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: index < 5 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: index <= _currentPage
                              ? const Color(0xFF983296)
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  'Шаг ${_currentPage + 1} из 6',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Контент
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildBasicInfoPage(),
                _buildLocationPage(),
                _buildContactPage(),
                _buildInterestsPage(),
                _buildSkillsPage(),
                _buildMotivationPage(),
              ],
            ),
          ),
          // Кнопка продолжить
          Padding(
            padding: const EdgeInsets.all(28),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : (_canProceed() ? _nextPage : null),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF983296),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _currentPage < 5 ? 'Продолжить' : 'Завершить',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 1. Основная информация
  // ──────────────────────────────────────────────────────────────
  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Container(
            height: 30,
            alignment: Alignment.centerLeft,
            child: SvgPicture.asset(
              'assets/images/VOLO-2.svg',
              height: 18,
            ),
          ),
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ДАВАЙТЕ ПОЗНАКОМИМСЯ ',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: 'ПОБЛИЖЕ',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFA63D9B),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Аватар убран по просьбе пользователя
          // Основная информация
          Text(
            'Основная информация',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 16),
          // Имя
          Text(
            'Имя',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => setState(() => firstName = value),
            decoration: InputDecoration(
              hintText: 'Введите ваше имя',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF983296), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Фамилия
          Text(
            'Фамилия',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => setState(() => lastName = value),
            decoration: InputDecoration(
              hintText: 'Введите вашу фамилию',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF983296), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Дата рождения
          Text(
            'Дата рождения',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime(2000),
                firstDate: DateTime(1950),
                lastDate: DateTime.now(),
                locale: const Locale('ru', 'RU'),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF983296),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => birthDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/calendar.svg',
                    width: 20,
                    height: 20,
                    colorFilter:
                        ColorFilter.mode(Colors.grey[600]!, BlendMode.srcIn),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    birthDate != null
                        ? '${birthDate!.day}.${birthDate!.month}.${birthDate!.year}'
                        : 'Выберите дату',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: birthDate != null ? Colors.black : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Пол
          Text(
            'Пол',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildGenderOption('Мужской', 'assets/images/an13.svg'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildGenderOption('Женский', 'assets/images/an12.svg'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGenderOption(String genderText, String imagePath) {
    final isSelected = gender == genderText;
    return GestureDetector(
      onTap: () => setState(() => gender = genderText),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF983296).withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF983296) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                genderText == 'Мужской' ? 'Мужчина' : 'Женщина',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? const Color(0xFF983296) : Colors.grey[600],
                ),
              ),
            ),
            if (genderText == 'Мужской')
              Positioned(
                left: 0,
                top: 0,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: SvgPicture.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
            if (genderText == 'Женский')
              Positioned(
                right: 0,
                top: 0,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: SvgPicture.asset(imagePath, fit: BoxFit.contain),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 2. Город
  // ──────────────────────────────────────────────────────────────
  Widget _buildLocationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ГДЕ ВЫ ',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: 'НАХОДИТЕСЬ?',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF983296),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите ваш город',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: cities.map((cityName) {
              final isSelected = city == cityName;
              return GestureDetector(
                onTap: () => setState(() => city = cityName),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF983296) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF983296) : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF983296).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SvgPicture.asset(
                            'assets/images/heart.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      Text(
                        cityName,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 3. Контакты
  // ──────────────────────────────────────────────────────────────
  Widget _buildContactPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'КОНТАКТНАЯ ',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: 'ИНФОРМАЦИЯ',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF983296),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Организаторы смогут с вами связаться',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 32),
          // Телефон
          Text(
            'Номер телефона',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (value) => setState(() => phone = value),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+7 (___) ___-__-__',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              prefixIcon: SvgPicture.asset(
                'assets/images/Phone.svg',
                width: 20,
                height: 20,
                colorFilter: const ColorFilter.mode(
                    Color(0xFF983296), BlendMode.srcIn),
                fit: BoxFit.scaleDown,
              ),
              suffixIcon: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: phone.length >= 10 
                    ? () {
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text('Код подтверждения отправлен на $phone', style: GoogleFonts.poppins()),
                           backgroundColor: const Color(0xFF983296),
                         ),
                       );
                    } : null,
                  child: Text(
                    'Подтвердить', 
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF983296), 
                      fontWeight: FontWeight.w600, 
                      fontSize: 12
                    ),
                  ),
                ),
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF983296), width: 2),
              ),
            ),
          ),
          // Email убран по просьбе пользователя
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF983296).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF983296),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.info, color: Colors.white, size: 14),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Эти данные видны только организаторам',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xFF983296),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 4. Интересы
  // ──────────────────────────────────────────────────────────────
  Widget _buildInterestsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ЧТО ВАМ ',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: 'ИНТЕРЕСНО?',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF983296),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Выберите области волонтерства (минимум 1)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: availableInterests.map((interest) {
              final isSelected = interests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      interests.remove(interest);
                    } else {
                      interests.add(interest);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF983296) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF983296) : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF983296).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SvgPicture.asset(
                            'assets/images/heart.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      Text(
                        interest,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 5. Навыки + Опыт волонтерства (галочка)
  // ──────────────────────────────────────────────────────────────
  Widget _buildSkillsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ВАШИ ',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: 'НАВЫКИ?',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF983296),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Чем вы можете быть полезны? (минимум 1)',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: availableSkills.map((skill) {
              final isSelected = skills.contains(skill);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      skills.remove(skill);
                    } else {
                      skills.add(skill);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF983296) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          isSelected ? const Color(0xFF983296) : Colors.grey[300]!,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color:
                                  const Color(0xFF983296).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SvgPicture.asset(
                            'assets/images/heart.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                                Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      Text(
                        skill,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          // Опыт волонтерства
          Text(
            'Опыт волонтерства',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              _buildExperienceOption('Впервые', 'Только начинаю свой путь'),
              const SizedBox(height: 8),
              _buildExperienceOption('Есть опыт',
                  'Участвовал в нескольких событиях'),
              const SizedBox(height: 8),
              _buildExperienceOption('Опытный',
                  'Регулярно участвую в волонтерстве'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceOption(String level, String description) {
    final isSelected = experience == level;
    return GestureDetector(
      onTap: () => setState(() => experience = level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF983296).withOpacity(0.1)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF983296) : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Галочка
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF983296) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF983296) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? const Color(0xFF983296)
                          : Colors.black,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  // 6. Мотивация
  // ──────────────────────────────────────────────────────────────
  Widget _buildMotivationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'ПОЧЕМУ ',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: 'ВОЛОНТЕРСТВО?',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF983296),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Расскажите о своей мотивации',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF888888),
            ),
          ),
          const SizedBox(height: 32),
          TextField(
            onChanged: (value) => setState(() => motivation = value),
            maxLines: 6,
            decoration: InputDecoration(
              hintText:
                  'Расскажите, что вас вдохновляет помогать другим...',
              hintStyle: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[400],
              ),
              filled: true,
              fillColor: Colors.grey[50],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: Color(0xFF983296), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF983296), Color(0xFFB856B8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.celebration, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  'Почти готово!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'После завершения вы сможете начать помогать и находить интересные события',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}