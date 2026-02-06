import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:ui';
import 'services/api_service.dart';

class AddEventPage extends StatefulWidget {
  const AddEventPage({super.key});

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  final PageController _pageController = PageController();
  final ApiService _apiService = ApiService();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Event Data
  String eventType = '';
  File? posterImage;
  String title = '';
  String description = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime; // Added
  String location = '';
  String address = '';
  int volunteerCount = 5;
  String chatLink = '';
  List<String> responsibilities = [];
  List<String> benefits = [];

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  // Constants
  final List<String> eventCategories = [
    'Экология',
    'Социальная помощь',
    'Образование',
    'Культура',
    'Спорт',
    'Медицина',
    'Животные',
    'Урбанистика',
  ];

  final List<String> cities = [
    'Алматы',
    'Астана',
    'Шымкент',
    'Караганда',
    'Актобе',
    'Тараз',
  ];

  final List<String> responsibilityOptions = [
    'Встреча гостей',
    'Регистрация',
    'Координация',
    'Фотосъемка',
    'Навигация',
    'Монтаж',
    'Кейтеринг',
  ];

  final List<String> benefitOptions = [
    'Питание',
    'Трансфер',
    'Сертификат',
    'Мерч',
    'Благодарственное письмо',
    'Часы волонтерства',
  ];

  @override
  void initState() {
    super.initState();
    // Rebuild on every change to enable/disable the "Continue" button
    _titleController.addListener(_updateState);
    _descController.addListener(_updateState);
    _addressController.addListener(_updateState);
    _chatController.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _publishEvent();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _publishEvent() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
          child: const CircularProgressIndicator(color: Color(0xFF983296), strokeWidth: 3),
        ),
      ),
    );

    // Calculate duration
    int duration = 4;
    if (selectedTime != null && selectedEndTime != null) {
      double start = selectedTime!.hour + selectedTime!.minute / 60.0;
      double end = selectedEndTime!.hour + selectedEndTime!.minute / 60.0;
      if (end < start) end += 24; // Handles overnight events roughly
      duration = (end - start).ceil();
      if (duration < 1) duration = 1;
    }

    // Prepare data for API
    final eventData = {
      'title': _titleController.text,
      'description': _descController.text,
      'location': '$location, ${_addressController.text}',
      'date_text': selectedDate != null 
          ? '${selectedDate!.day.toString().padLeft(2,'0')}.${selectedDate!.month.toString().padLeft(2,'0')}.${selectedDate!.year} | ${selectedTime?.format(context) ?? ''}' 
          : '',
      'hours': duration, 
      'category': eventType,
      'chat_link': _chatController.text,
      'volunteer_count': volunteerCount,
      'responsibilities': responsibilities.join(', '),
      'benefits': benefits.join(', '),
    };

    final result = await _apiService.createEvent(eventData, imageFile: posterImage);

    if (mounted) {
      Navigator.pop(context); // Close loading dialog
      if (result['success']) {
        _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: ${result['message']}', style: GoogleFonts.poppins()),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF983296).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF983296), size: 64),
            ),
            const SizedBox(height: 24),
            Text('ОПУБЛИКОВАНО!', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26))),
            const SizedBox(height: 12),
            Text('Ваш ивент успешно создан и теперь виден всем волонтерам.', 
              textAlign: TextAlign.center, 
              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B6B7B))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(); // Close page
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF983296), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('ОТЛИЧНО', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isStepValid() {
    switch (_currentPage) {
      case 0:
        return eventType.isNotEmpty;
      case 1:
        return posterImage != null;
      case 2:
        return _titleController.text.isNotEmpty && _descController.text.isNotEmpty;
      case 3:
        return selectedDate != null && selectedTime != null && location.isNotEmpty;
      case 4:
        return volunteerCount > 0 && responsibilities.isNotEmpty;
      case 5:
        return true;
      default:
        return false;
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => posterImage = File(result.files.single.path!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          // Background Decorative Elements
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF983296).withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF983296).withOpacity(0.02),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1Category(),
                      _buildStep2Image(),
                      _buildStep3Info(),
                      _buildStep4DateTime(),
                      _buildStep5Volunteers(),
                      _buildStep6Review(),
                    ],
                  ),
                ),
                _buildBottomBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), // Reduced top padding from 50 to 10
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (_currentPage > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: const Color(0xFF0D0D26),
                  onPressed: _previousPage,
                )
              else
                const SizedBox(width: 48),
              
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 26),
                color: const Color(0xFF95969D),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                Row(
                  children: List.generate(_totalPages, (index) {
                    final isCompleted = index < _currentPage;
                    final isCurrent = index == _currentPage;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (index <= _currentPage) {
                            setState(() => _currentPage = index);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 6,
                          margin: EdgeInsets.only(right: index < _totalPages - 1 ? 6 : 0),
                          decoration: BoxDecoration(
                            color: isCompleted || isCurrent 
                                ? const Color(0xFF983296) 
                                : const Color(0xFFF1F1F5),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isCurrent ? [
                              BoxShadow(
                                color: const Color(0xFF983296).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ] : [],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ШАГ ${_currentPage + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF983296),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'ИЗ $_totalPages',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF95969D),
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 10, 28, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isStepValid() ? _nextPage : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF983296),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFF1F1F5),
                disabledForegroundColor: const Color(0xFFBDBDBD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                shadowColor: const Color(0xFF983296).withOpacity(0.4),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _currentPage < _totalPages - 1 ? 'Продолжить' : 'Опубликовать',
                  key: ValueKey(_currentPage),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTitle(String part1, String part2, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$part1 ',
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D0D26),
                  height: 1.1,
                ),
              ),
              TextSpan(
                text: part2,
                style: GoogleFonts.poppins(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF983296),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B6B7B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  // STEP 1: Category
  Widget _buildStep1Category() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('ВЫБЕРИТЕ', 'КАТЕГОРИЮ', 'Выберите направление вашего будущего мероприятия'),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.3,
            ),
            itemCount: eventCategories.length,
            itemBuilder: (context, index) {
              final cat = eventCategories[index];
              final isSelected = eventType == cat;
              return GestureDetector(
                onTap: () => setState(() => eventType = cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF983296) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : const Color(0xFFF1F1F5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? const Color(0xFF983296).withOpacity(0.3) : Colors.black.withOpacity(0.04),
                        blurRadius: isSelected ? 16 : 10,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Placeholder icon based on category logic could be here
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.2) : const Color(0xFFF9F9F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(cat),
                          color: isSelected ? Colors.white : const Color(0xFF983296),
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          cat,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF0D0D26),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'экология': return Icons.eco_rounded;
      case 'социальное': return Icons.people_rounded;
      case 'животные': return Icons.pets_rounded;
      case 'культура': return Icons.theater_comedy_rounded;
      case 'спорт': return Icons.sports_basketball_rounded;
      case 'образование': return Icons.school_rounded;
      default: return Icons.volunteer_activism_rounded;
    }
  }
  // STEP 2: Image
  Widget _buildStep2Image() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('ДОБАВЬТЕ', 'ПОСТЕР', 'Яркая картинка поможет привлечь больше волонтеров'),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 350,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: const Color(0xFFF1F1F5),
                  width: 2,
                ),
                image: posterImage != null
                    ? DecorationImage(image: FileImage(posterImage!), fit: BoxFit.cover)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: posterImage == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF983296).withOpacity(0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add_photo_alternate_rounded, 
                            size: 40, color: Color(0xFF983296)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Нажмите, чтобы выбрать фото',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF95969D),
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned(
                          top: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit_rounded, size: 20, color: Color(0xFF983296)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // STEP 3: Info
  Widget _buildStep3Info() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('ОСНОВНАЯ', 'ИНФО', 'Расскажите подробнее о вашем мероприятии'),
          const SizedBox(height: 32),
          _buildSectionLabel('Название ивента'),
          _buildPremiumField(_titleController, 'Пример: Эко-субботник в парке'),
          const SizedBox(height: 24),
          _buildSectionLabel('Описание'),
          _buildPremiumField(_descController, 'Расскажите о целях и программе...', maxLines: 6),
          const SizedBox(height: 24),
          _buildSectionLabel('Ссылка на чат (Telegram/WhatsApp)'),
          _buildPremiumField(_chatController, 'https://t.me/...'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStep4DateTime() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('КОГДА И', 'ГДЕ', 'Укажите время и место проведения встречи'),
          const SizedBox(height: 32),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Дата'),
                    _buildDateTimeCard(
                      icon: Icons.calendar_today_rounded,
                      text: selectedDate == null 
                          ? '01.01' 
                          : '${selectedDate!.day.toString().padLeft(2,'0')}.${selectedDate!.month.toString().padLeft(2,'0')}',
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) setState(() => selectedDate = date);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Начало'),
                    _buildDateTimeCard(
                      icon: Icons.access_time_rounded,
                      text: selectedTime == null 
                          ? '--:--' 
                          : selectedTime!.format(context),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) setState(() => selectedTime = time);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Конец'),
                    _buildDateTimeCard(
                      icon: Icons.access_time_filled_rounded,
                      text: selectedEndTime == null 
                          ? '--:--' 
                          : selectedEndTime!.format(context),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) setState(() => selectedEndTime = time);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('Город'),
          _buildDropdownField(),
          const SizedBox(height: 24),
          _buildSectionLabel('Точный адрес'),
          _buildPremiumField(_addressController, 'Улица, дом, офис...'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStep5Volunteers() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('ВОЛОНТЕРЫ', 'И ЗАДАЧИ', 'Кто вам нужен и что они получат?'),
          const SizedBox(height: 32),
          _buildSectionLabel('Количество волонтеров'),
          _buildCounter(),
          const SizedBox(height: 32),
          _buildSectionLabel('Обязанности'),
          _buildChipCloud(responsibilityOptions, responsibilities),
          const SizedBox(height: 32),
          _buildSectionLabel('Бонусы для участников'),
          _buildChipCloud(benefitOptions, benefits),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStep6Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('ПРОВЕРЬТЕ', 'ВСЕ', 'Почти готово! Внимательно проверьте данные'),
          const SizedBox(height: 32),
          if (posterImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(posterImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          _buildReviewCard(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // UI Helper Components
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0D0D26).withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildPremiumField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: controller.text.isNotEmpty ? const Color(0xFF983296).withOpacity(0.3) : const Color(0xFFF1F1F5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: controller.text.isNotEmpty 
                ? const Color(0xFF983296).withOpacity(0.05) 
                : Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          fontSize: 15, 
          color: const Color(0xFF0D0D26),
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.poppins(
            color: const Color(0xFFBDBDBD), 
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateTimeCard({required IconData icon, required String text, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F1F5)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF983296)),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D0D26),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F5)),
      ),
      child: DropdownButton<String>(
        value: location.isEmpty ? null : location,
        hint: Text('Выберите город', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFBDBDBD))),
        isExpanded: true,
        underline: const SizedBox(),
        items: cities.map((city) {
          return DropdownMenuItem(
            value: city,
            child: Text(city, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          );
        }).toList(),
        onChanged: (val) => setState(() => location = val!),
      ),
    );
  }

  Widget _buildCounter() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCounterBtn(Icons.remove_rounded, () {
            if (volunteerCount > 0) setState(() => volunteerCount--);
          }),
          Text(
            '$volunteerCount',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26)),
          ),
          _buildCounterBtn(Icons.add_rounded, () {
            setState(() => volunteerCount++);
          }),
        ],
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF983296).withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: const Color(0xFF983296), size: 24),
      ),
    );
  }

  Widget _buildChipCloud(List<String> options, List<String> selections) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selections.contains(opt);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) selections.remove(opt);
              else selections.add(opt);
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF983296) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? const Color(0xFF983296) : const Color(0xFFF1F1F5),
              ),
            ),
            child: Text(
              opt,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF6B6B7B),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReviewCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F1F5)),
      ),
      child: Column(
        children: [
          _buildReviewItem(Icons.category_rounded, 'Категория', eventType),
          _buildReviewItem(Icons.title_rounded, 'Название', _titleController.text),
          _buildReviewItem(Icons.calendar_month_rounded, 'Дата', 
              selectedDate != null ? '${selectedDate!.day}.${selectedDate!.month}.${selectedDate!.year}' : ''),
          _buildReviewItem(Icons.location_on_rounded, 'Место', '$location, ${_addressController.text}'),
          _buildReviewItem(Icons.group_rounded, 'Волонтеры', '$volunteerCount человек'),
        ],
      ),
    );
  }

  Widget _buildReviewItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFF983296)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF95969D), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF0D0D26), fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}