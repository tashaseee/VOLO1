import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:ui';
import 'services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/add_event/add_event_bloc.dart';

class AddEventPage extends StatelessWidget {
  const AddEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddEventBloc(apiService: ApiService()),
      child: const _AddEventView(),
    );
  }
}

class _AddEventView extends StatefulWidget {
  const _AddEventView({super.key});

  @override
  State<_AddEventView> createState() => _AddEventViewState();
}

class _AddEventViewState extends State<_AddEventView> {
  final PageController _pageController = PageController();
  // State is now managed by AddEventBloc

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
    _titleController.addListener(() => context.read<AddEventBloc>().add(UpdateEventData(title: _titleController.text)));
    _descController.addListener(() => context.read<AddEventBloc>().add(UpdateEventData(description: _descController.text)));
    _addressController.addListener(() => context.read<AddEventBloc>().add(UpdateEventData(address: _addressController.text)));
    _chatController.addListener(() => context.read<AddEventBloc>().add(UpdateEventData(chatLink: _chatController.text)));
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

  void _nextPage(AddEventState state) {
    if (state.currentPage < state.totalPages - 1) {
      context.read<AddEventBloc>().add(NextStepEvent());
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<AddEventBloc>().add(PublishEvent());
    }
  }

  void _previousPage(AddEventState state) {
    if (state.currentPage > 0) {
      context.read<AddEventBloc>().add(PreviousStepEvent());
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
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

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      if (mounted) context.read<AddEventBloc>().add(UpdateEventData(posterImage: File(result.files.single.path!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddEventBloc, AddEventState>(
      listener: (context, state) {
        if (state.isLoading) {
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
        } else {
          // If a dialog is open (like loading), close it
          if (Navigator.canPop(context) && state.isLoading == false) {
             // We pop but wait, managing dialogs via pure BlocListener is a bit tricky, better to just pop if we succeed
          }
        }

        if (state.isSuccess) {
          Navigator.pop(context); // Close loading
          _showSuccessDialog();
        } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
           Navigator.pop(context); // Close loading
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Ошибка: ${state.errorMessage}', style: GoogleFonts.poppins()),
               backgroundColor: Colors.redAccent,
               behavior: SnackBarBehavior.floating,
             ),
           );
        }
      },
      builder: (context, state) {
        return Scaffold(
      backgroundColor: Colors.white,
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
                _buildHeader(state),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1Category(state),
                      _buildStep2Image(state),
                      _buildStep3Info(state),
                      _buildStep4DateTime(state),
                      _buildStep5Volunteers(state),
                      _buildStep6Review(state),
                    ],
                  ),
                ),
                _buildBottomBar(state),
              ],
            ),
          ),
        ],
      ),
    );
      },
    );
  }

  Widget _buildHeader(AddEventState state) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), // Reduced top padding from 50 to 10
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (state.currentPage > 0)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  color: const Color(0xFF0D0D26),
                  onPressed: () => _previousPage(state),
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
                  children: List.generate(state.totalPages, (index) {
                    final isCompleted = index < state.currentPage;
                    final isCurrent = index == state.currentPage;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (index <= state.currentPage) {
                            // setState(() => state.currentPage = index); // handled by step change
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 6,
                          margin: EdgeInsets.only(right: index < state.totalPages - 1 ? 6 : 0),
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
                      'ШАГ ${state.currentPage + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF983296),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'ИЗ $state.totalPages',
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

  Widget _buildBottomBar(AddEventState state) {
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
              onPressed: state.isCurrentStepValid ? () => _nextPage(state) : null,
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
                  state.currentPage < state.totalPages - 1 ? 'Продолжить' : 'Опубликовать',
                  key: ValueKey(state.currentPage),
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
  Widget _buildStep1Category(AddEventState state) {
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
              final isSelected = state.eventType == cat;
              return GestureDetector(
                onTap: () => context.read<AddEventBloc>().add(UpdateEventData(eventType: cat)),
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
  Widget _buildStep2Image(AddEventState state) {
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
                image: state.posterImage != null
                    ? DecorationImage(image: FileImage(state.posterImage!), fit: BoxFit.cover)
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: state.posterImage == null
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
  Widget _buildStep3Info(AddEventState state) {
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

  Widget _buildStep4DateTime(AddEventState state) {
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
                      text: state.selectedDate == null 
                          ? '01.01' 
                          : '${state.selectedDate!.day.toString().padLeft(2,'0')}.${state.selectedDate!.month.toString().padLeft(2,'0')}',
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) context.read<AddEventBloc>().add(UpdateEventData(selectedDate: date));
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
                      text: state.selectedTime == null 
                          ? '--:--' 
                          : state.selectedTime!.format(context),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) context.read<AddEventBloc>().add(UpdateEventData(selectedTime: time));
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
                      text: state.selectedEndTime == null 
                          ? '--:--' 
                          : state.selectedEndTime!.format(context),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: state.selectedTime ?? TimeOfDay.now(),
                        );
                        if (time != null) context.read<AddEventBloc>().add(UpdateEventData(selectedEndTime: time));
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('Город'),
          _buildDropdownField(state),
          const SizedBox(height: 24),
          _buildSectionLabel('Точный адрес'),
          _buildPremiumField(_addressController, 'Улица, дом, офис...'),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStep5Volunteers(AddEventState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('ВОЛОНТЕРЫ', 'И ЗАДАЧИ', 'Кто вам нужен и что они получат?'),
          const SizedBox(height: 32),
          _buildSectionLabel('Количество волонтеров'),
          _buildCounter(state),
          const SizedBox(height: 32),
          _buildSectionLabel('Обязанности'),
          _buildChipCloud(responsibilityOptions, state.responsibilities, true),
          const SizedBox(height: 32),
          _buildSectionLabel('Бонусы для участников'),
          _buildChipCloud(benefitOptions, state.benefits, false),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStep6Review(AddEventState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('ПРОВЕРЬТЕ', 'ВСЕ', 'Почти готово! Внимательно проверьте данные'),
          const SizedBox(height: 32),
          if (state.posterImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(state.posterImage!, height: 200, width: double.infinity, fit: BoxFit.cover),
            ),
          const SizedBox(height: 24),
          _buildReviewCard(state),
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

  Widget _buildDropdownField(AddEventState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F5)),
      ),
      child: DropdownButton<String>(
        value: state.location.isEmpty ? null : state.location,
        hint: Text('Выберите город', style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFFBDBDBD))),
        isExpanded: true,
        underline: const SizedBox(),
        items: cities.map((city) {
          return DropdownMenuItem(
            value: city,
            child: Text(city, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500)),
          );
        }).toList(),
        onChanged: (val) => context.read<AddEventBloc>().add(UpdateEventData(location: val!)),
      ),
    );
  }

  Widget _buildCounter(AddEventState state) {
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
            if (state.volunteerCount > 0) context.read<AddEventBloc>().add(UpdateEventData(volunteerCount: state.volunteerCount - 1));
          }),
          Text(
            '$state.volunteerCount',
            style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26)),
          ),
          _buildCounterBtn(Icons.add_rounded, () {
            context.read<AddEventBloc>().add(UpdateEventData(volunteerCount: state.volunteerCount + 1));
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

  Widget _buildChipCloud(List<String> options, List<String> selections, bool isResponsibilities) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((opt) {
        final isSelected = selections.contains(opt);
        return GestureDetector(
          onTap: () {
            List<String> newSelections = List.from(selections);
            if (isSelected) newSelections.remove(opt);
            else newSelections.add(opt);
            if (isResponsibilities) {
              context.read<AddEventBloc>().add(UpdateEventData(responsibilities: newSelections));
            } else {
              context.read<AddEventBloc>().add(UpdateEventData(benefits: newSelections));
            }
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

  Widget _buildReviewCard(AddEventState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFF1F1F5)),
      ),
      child: Column(
        children: [
          _buildReviewItem(Icons.category_rounded, 'Категория', state.eventType),
          _buildReviewItem(Icons.title_rounded, 'Название', _titleController.text),
          _buildReviewItem(Icons.calendar_month_rounded, 'Дата', 
              state.selectedDate != null ? '${state.selectedDate!.day}.${state.selectedDate!.month}.${state.selectedDate!.year}' : ''),
          _buildReviewItem(Icons.location_on_rounded, 'Место', '${state.location}, ${_addressController.text}'),
          _buildReviewItem(Icons.group_rounded, 'Волонтеры', '$state.volunteerCount человек'),
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