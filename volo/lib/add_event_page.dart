import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'services/api_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/add_event/add_event_bloc.dart';
import 'chat_room_page.dart';

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
  const _AddEventView();

  @override
  State<_AddEventView> createState() => _AddEventViewState();
}

class _AddEventViewState extends State<_AddEventView> {
  final PageController _pageController = PageController();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _certTitleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  bool _certTitleSynced = true;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  // State variables for exact address suggestions and quick time selection
  Timer? _debounceTimer;
  List<dynamic> _addressSuggestions = [];
  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;
  int? _selectedDurationHours;

  // State variables for custom responsibilities and benefits inline additions
  bool _isAddingCustomResponsibility = false;
  bool _isAddingCustomBenefit = false;
  final TextEditingController _customResponsibilityController = TextEditingController();
  final TextEditingController _customBenefitController = TextEditingController();

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

  List<String> responsibilityOptions = [
    'Встреча гостей',
    'Регистрация',
    'Координация',
    'Фотосъемка',
    'Навигация',
    'Монтаж',
    'Кейтеринг',
  ];

  List<String> benefitOptions = [
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
    _titleController.addListener(() {
      final bloc = context.read<AddEventBloc>();
      if (_certTitleSynced) {
        _certTitleController.text = _titleController.text;
        bloc.add(
          UpdateEventData(
            title: _titleController.text,
            certificateTitle: _certTitleController.text,
          ),
        );
      } else {
        bloc.add(UpdateEventData(title: _titleController.text));
      }
    });
    _certTitleController.addListener(() {
      _certTitleSynced = false;
      context.read<AddEventBloc>().add(
        UpdateEventData(certificateTitle: _certTitleController.text),
      );
    });
    _descController.addListener(
      () => context.read<AddEventBloc>().add(
        UpdateEventData(description: _descController.text),
      ),
    );
    _addressController.addListener(
      () => context.read<AddEventBloc>().add(
        UpdateEventData(address: _addressController.text),
      ),
    );
    _chatController.addListener(
      () => context.read<AddEventBloc>().add(
        UpdateEventData(chatLink: _chatController.text),
      ),
    );
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _customResponsibilityController.dispose();
    _customBenefitController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _certTitleController.dispose();
    _descController.dispose();
    _addressController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _submitCustomOption(bool isResponsibilities) {
    final controller = isResponsibilities ? _customResponsibilityController : _customBenefitController;
    final val = controller.text.trim();
    if (val.isEmpty) return;

    setState(() {
      if (isResponsibilities) {
        if (!responsibilityOptions.contains(val)) {
          responsibilityOptions.add(val);
        }
        _isAddingCustomResponsibility = false;
        
        final currentSelections = context.read<AddEventBloc>().state.responsibilities;
        if (!currentSelections.contains(val)) {
          List<String> newSelections = List.from(currentSelections)..add(val);
          context.read<AddEventBloc>().add(UpdateEventData(responsibilities: newSelections));
        }
      } else {
        if (!benefitOptions.contains(val)) {
          benefitOptions.add(val);
        }
        _isAddingCustomBenefit = false;
        
        final currentSelections = context.read<AddEventBloc>().state.benefits;
        if (!currentSelections.contains(val)) {
          List<String> newSelections = List.from(currentSelections)..add(val);
          context.read<AddEventBloc>().add(UpdateEventData(benefits: newSelections));
        }
      }
      controller.clear();
    });
  }

  // --- TIME HELPERS ---
  TimeOfDay _addHours(TimeOfDay time, int hours) {
    int totalMinutes = time.hour * 60 + time.minute + hours * 60;
    int nextHour = (totalMinutes ~/ 60) % 24;
    int nextMinute = totalMinutes % 60;
    return TimeOfDay(hour: nextHour, minute: nextMinute);
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  int _calculateHoursDiff(TimeOfDay start, TimeOfDay end) {
    double startTime = start.hour + start.minute / 60.0;
    double endTime = end.hour + end.minute / 60.0;
    if (endTime < startTime) endTime += 24;
    return (endTime - startTime).ceil();
  }

  // --- ADDRESS AUTOCOMPLETE HELPERS ---
  void _onAddressChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (query.trim().length < 3) {
      setState(() {
        _addressSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _fetchAddressSuggestions(query);
    });
  }

  Future<void> _fetchAddressSuggestions(String query) async {
    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestions = true;
    });

    try {
      final currentCity = context.read<AddEventBloc>().state.location;
      final searchQuery = currentCity.isNotEmpty
          ? '$currentCity, $query'
          : query;

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchQuery)}&format=json&limit=5&addressdetails=1&accept-language=ru',
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'VoloApp/1.0 (voloapp.kz)'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          _addressSuggestions = data;
          _isLoadingSuggestions = false;
        });
      } else {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingSuggestions = false;
      });
      print('Error fetching suggestions: $e');
    }
  }

  String _formatSuggestion(Map<String, dynamic> item) {
    final address = item['address'] as Map<String, dynamic>?;
    if (address == null) return item['display_name'] ?? '';

    final road =
        address['road'] ??
        address['pedestrian'] ??
        address['suburb'] ??
        address['neighbourhood'] ??
        '';
    final houseNumber = address['house_number'] ?? '';

    if (road.isNotEmpty && houseNumber.isNotEmpty) {
      return '$road, $houseNumber';
    } else if (road.isNotEmpty) {
      return road;
    }

    final displayName = item['display_name'] ?? '';
    final parts = displayName.split(',');
    if (parts.length > 2) {
      return parts.sublist(0, 2).join(',').trim();
    }
    return displayName;
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

  void _showSuccessDialog(AddEventState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Beautiful paper airplane Lottie animation (slightly smaller)
              Lottie.asset(
                'assets/animation/fly.json',
                height: 110,
                repeat: true,
              ),
              const SizedBox(height: 8),
              // Premium styling for Title
              Text(
                'ИВЕНТ ОПУБЛИКОВАН!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF983296),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Проект успешно запущен и виден волонтерам.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF6B6B7B),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              // Compact Ticket card
              _buildTicketCard(state),
              const SizedBox(height: 20),
              if (state.createdChatId != null) ...[
                Container(
                  width: double.infinity,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF801B7F), Color(0xFF983296)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF983296).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).pop(); // Close dialog
                        Navigator.of(context).pop(); // Close page
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => ChatRoomPage(chatId: state.createdChatId!, chatName: state.title)
                        ));
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'В ЧАТ КОМАНДЫ',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close page
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFF1F0F5), width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'НА ГЛАВНУЮ',
                    style: GoogleFonts.poppins(
                      color: const Color(0xFF95969D),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(AddEventState state) {
    final dateStr = state.selectedDate != null
        ? '${state.selectedDate!.day.toString().padLeft(2, '0')}.${state.selectedDate!.month.toString().padLeft(2, '0')}.${state.selectedDate!.year}'
        : 'Дата не указана';
    final timeStr = state.selectedTime != null
        ? '${state.selectedTime!.hour.toString().padLeft(2, '0')}:${state.selectedTime!.minute.toString().padLeft(2, '0')}'
        : '--:--';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.2),
      ),
      child: Column(
        children: [
          // Shorter, sharper Event Poster / Category Header
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(10.5), topRight: Radius.circular(10.5)),
            child: Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF983296).withValues(alpha: 0.04),
                image: state.posterImage != null
                    ? DecorationImage(image: FileImage(state.posterImage!), fit: BoxFit.cover)
                    : null,
              ),
              child: state.posterImage == null
                  ? Center(
                      child: Icon(_getCategoryIcon(state.eventType), color: const Color(0xFF983296), size: 28),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.black.withValues(alpha: 0.5), Colors.transparent],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
            ),
          ),
          // Short, clean Ticket Details
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF983296).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          state.eventType,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF983296),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 10, color: Color(0xFF95969D)),
                        const SizedBox(width: 4),
                        Text(
                          '$dateStr | $timeStr',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF95969D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  state.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D0D26),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 10, color: Color(0xFF983296)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${state.location}, ${state.address}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF6B6B7B),
                        ),
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

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null) {
      if (mounted)
        context.read<AddEventBloc>().add(
          UpdateEventData(posterImage: File(result.files.single.path!)),
        );
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
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const CircularProgressIndicator(
                  color: Color(0xFF983296),
                  strokeWidth: 3,
                ),
              ),
            ),
          );
        }

        if (state.isSuccess) {
          Navigator.pop(context); // Close loading
          _showSuccessDialog(state);
        } else if (state.errorMessage != null &&
            state.errorMessage!.isNotEmpty) {
          Navigator.pop(context); // Close loading
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ошибка: ${state.errorMessage}',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
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
        );
      },
    );
  }

  Widget _buildHeader(AddEventState state) {
    final stepTitles = [
      'Категория',
      'Постер',
      'Детали',
      'Дата и место',
      'Волонтёры',
      'Проверка',
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (state.currentPage > 0)
                InkWell(
                  onTap: () => _previousPage(state),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: Color(0xFF0D0D26),
                    ),
                  ),
                )
              else
                const SizedBox(width: 38),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF983296).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${state.currentPage + 1} / ${state.totalPages}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF983296),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 22,
                    color: Color(0xFF95969D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (state.currentPage + 1) / state.totalPages,
                minHeight: 5,
                backgroundColor: const Color(0xFFF1F0F5),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF983296),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              stepTitles[state.currentPage],
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF95969D),
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AddEventState state) {
    final isLast = state.currentPage == state.totalPages - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F0F5), width: 1.5)),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: state.isCurrentStepValid
              ? const LinearGradient(
                  colors: [Color(0xFF801B7F), Color(0xFF983296)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: state.isCurrentStepValid ? null : const Color(0xFFF5F5F8),
          boxShadow: state.isCurrentStepValid
              ? [
                  BoxShadow(
                    color: const Color(0xFF983296).withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: state.isCurrentStepValid ? () => _nextPage(state) : null,
            borderRadius: BorderRadius.circular(18),
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLast ? 'Опубликовать' : 'Далее',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: state.isCurrentStepValid
                          ? Colors.white
                          : const Color(0xFFBDBDBD),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLast
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                    size: 18,
                    color: state.isCurrentStepValid
                        ? Colors.white
                        : const Color(0xFFBDBDBD),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepTitle(String part1, String part2, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '$part1 ',
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0D0D26),
                  height: 1.2,
                ),
              ),
              TextSpan(
                text: part2,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF983296),
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF95969D),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  // STEP 1: Category
  Widget _buildStep1Category(AddEventState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'ВЫБЕРИТЕ',
            'КАТЕГОРИЮ',
            'Выберите направление вашего мероприятия',
          ),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
            ),
            itemCount: eventCategories.length,
            itemBuilder: (context, index) {
              final cat = eventCategories[index];
              final isSelected = state.eventType == cat;
              return GestureDetector(
                onTap: () => context.read<AddEventBloc>().add(
                  UpdateEventData(eventType: cat),
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            colors: [Color(0xFF801B7F), Color(0xFF983296)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isSelected ? null : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : const Color(0xFFF1F0F5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected
                            ? const Color(0xFF983296).withValues(alpha: 0.18)
                            : const Color(0xFF0D0D26).withValues(alpha: 0.015),
                        blurRadius: isSelected ? 16 : 8,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.18)
                              : const Color(0xFF983296).withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getCategoryIcon(cat),
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF983296),
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          cat,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF0D0D26),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'экология':
        return Icons.eco_rounded;
      case 'социальное':
        return Icons.people_rounded;
      case 'животные':
        return Icons.pets_rounded;
      case 'культура':
        return Icons.theater_comedy_rounded;
      case 'спорт':
        return Icons.sports_basketball_rounded;
      case 'образование':
        return Icons.school_rounded;
      default:
        return Icons.volunteer_activism_rounded;
    }
  }

  // STEP 2: Image
  Widget _buildStep2Image(AddEventState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'ДОБАВЬТЕ',
            'ПОСТЕР',
            'Яркая картинка поможет привлечь больше волонтеров',
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                image: state.posterImage != null
                    ? DecorationImage(
                        image: FileImage(state.posterImage!),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D0D26).withValues(alpha: 0.02),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
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
                            color: const Color(0xFF983296).withValues(alpha: 0.06),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_rounded,
                            size: 32,
                            color: Color(0xFF983296),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нажмите для выбора фото',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
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
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 18,
                              color: Color(0xFF983296),
                            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'ОСНОВНАЯ',
            'ИНФО',
            'Расскажите подробнее о вашем мероприятии',
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('Название ивента'),
          _buildPremiumField(_titleController, 'Пример: Эко-субботник в парке'),
          const SizedBox(height: 20),
          _buildSectionLabel('Текст на сертификате'),
          _buildPremiumField(
            _certTitleController,
            'Как будет напечатано на сертификате',
          ),
          const SizedBox(height: 8),
          _buildCertificatePreviewHint(state),
          const SizedBox(height: 20),
          _buildSectionLabel('Описание'),
          _buildPremiumField(
            _descController,
            'Расскажите о целях и программе...',
            maxLines: 5,
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStep4DateTime(AddEventState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle('КОГДА И', 'ГДЕ', 'Укажите время и место проведения'),
          const SizedBox(height: 24),
          _buildSectionLabel('Дата'),
          _buildDateTimeCard(
            icon: Icons.calendar_today_rounded,
            text: state.selectedDate == null
                ? 'Выберите дату'
                : '${state.selectedDate!.day.toString().padLeft(2, '0')}.${state.selectedDate!.month.toString().padLeft(2, '0')}.${state.selectedDate!.year}',
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: Color(0xFF983296),
                        onPrimary: Colors.white,
                        surface: Colors.white,
                        onSurface: Color(0xFF0D0D26),
                      ),
                      datePickerTheme: DatePickerThemeData(
                        headerBackgroundColor: Colors.white,
                        headerForegroundColor: const Color(0xFF0D0D26),
                        backgroundColor: Colors.white,
                        dividerColor: const Color(0xFFF1F0F5),
                        dayStyle: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                        headerHeadlineStyle: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0D0D26),
                        ),
                        headerHelpStyle: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF95969D),
                        ),
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF983296),
                          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                        ),
                      ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null && mounted) {
                context.read<AddEventBloc>().add(
                  UpdateEventData(selectedDate: date),
                );
              }
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
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
                          initialEntryMode: TimePickerEntryMode.input,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF983296),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Color(0xFF0D0D26),
                                ),
                                timePickerTheme: TimePickerThemeData(
                                  backgroundColor: Colors.white,
                                  hourMinuteColor: const Color(0xFF983296).withValues(alpha: 0.06),
                                  hourMinuteTextColor: const Color(0xFF983296),
                                  hourMinuteTextStyle: GoogleFonts.poppins(fontSize: 44, fontWeight: FontWeight.w800),
                                  dayPeriodColor: const Color(0xFF983296).withValues(alpha: 0.06),
                                  dayPeriodTextColor: const Color(0xFF983296),
                                  dayPeriodTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                  dialHandColor: const Color(0xFF983296),
                                  dialBackgroundColor: const Color(0xFFF1F0F5),
                                  dialTextColor: const Color(0xFF0D0D26),
                                  entryModeIconColor: const Color(0xFF983296),
                                  inputDecorationTheme: InputDecorationTheme(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFF1F0F5), width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFF1F0F5), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFF983296), width: 2),
                                    ),
                                    fillColor: const Color(0xFF983296).withValues(alpha: 0.04),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF983296),
                                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                  ),
                                ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null && mounted) {
                          context.read<AddEventBloc>().add(
                            UpdateEventData(selectedTime: time),
                          );
                          if (_selectedDurationHours != null) {
                            final newEndTime = _addHours(
                              time,
                              _selectedDurationHours!,
                            );
                            context.read<AddEventBloc>().add(
                              UpdateEventData(selectedEndTime: newEndTime),
                            );
                          }
                        }
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
                          initialEntryMode: TimePickerEntryMode.input,
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF983296),
                                  onPrimary: Colors.white,
                                  surface: Colors.white,
                                  onSurface: Color(0xFF0D0D26),
                                ),
                                timePickerTheme: TimePickerThemeData(
                                  backgroundColor: Colors.white,
                                  hourMinuteColor: const Color(0xFF983296).withValues(alpha: 0.06),
                                  hourMinuteTextColor: const Color(0xFF983296),
                                  hourMinuteTextStyle: GoogleFonts.poppins(fontSize: 44, fontWeight: FontWeight.w800),
                                  dayPeriodColor: const Color(0xFF983296).withValues(alpha: 0.06),
                                  dayPeriodTextColor: const Color(0xFF983296),
                                  dayPeriodTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                  dialHandColor: const Color(0xFF983296),
                                  dialBackgroundColor: const Color(0xFFF1F0F5),
                                  dialTextColor: const Color(0xFF0D0D26),
                                  entryModeIconColor: const Color(0xFF983296),
                                  inputDecorationTheme: InputDecorationTheme(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFF1F0F5), width: 1.5),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFFF1F0F5), width: 1.5),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: Color(0xFF983296), width: 2),
                                    ),
                                    fillColor: const Color(0xFF983296).withValues(alpha: 0.04),
                                    filled: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                ),
                                textButtonTheme: TextButtonThemeData(
                                  style: TextButton.styleFrom(
                                    foregroundColor: const Color(0xFF983296),
                                    textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                                  ),
                                ), dialogTheme: DialogThemeData(backgroundColor: Colors.white),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (time != null && mounted) {
                          setState(() {
                            _selectedDurationHours = null;
                          });
                          context.read<AddEventBloc>().add(
                            UpdateEventData(selectedEndTime: time),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          _buildQuickTimeSelectors(state),
          const SizedBox(height: 20),
          _buildSectionLabel('Город'),
          _buildDropdownField(state),
          const SizedBox(height: 16),
          _buildSectionLabel('Точный адрес'),
          _buildAddressFieldWithSuggestions(state),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildQuickTimeSelectors(AddEventState state) {
    final quickStartTimes = [
      '08:00',
      '09:00',
      '10:00',
      '12:00',
      '14:00',
      '16:00',
      '18:00',
    ];
    final quickDurations = [
      {'label': '+1 ч', 'hours': 1},
      {'label': '+2 ч', 'hours': 2},
      {'label': '+3 ч', 'hours': 3},
      {'label': '+4 ч', 'hours': 4},
      {'label': '+6 ч', 'hours': 6},
      {'label': '+8 ч', 'hours': 8},
    ];

    final currentStartStr = state.selectedTime != null
        ? '${state.selectedTime!.hour.toString().padLeft(2, '0')}:${state.selectedTime!.minute.toString().padLeft(2, '0')}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildSectionLabel('Быстрый выбор начала'),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: quickStartTimes.length,
            itemBuilder: (context, index) {
              final timeStr = quickStartTimes[index];
              final isSelected = currentStartStr == timeStr;

              return GestureDetector(
                onTap: () {
                  final parts = timeStr.split(':');
                  final hour = int.parse(parts[0]);
                  final minute = int.parse(parts[1]);
                  final newTime = TimeOfDay(hour: hour, minute: minute);

                  final bloc = context.read<AddEventBloc>();
                  bloc.add(UpdateEventData(selectedTime: newTime));

                  if (_selectedDurationHours != null) {
                    final newEndTime = _addHours(
                      newTime,
                      _selectedDurationHours!,
                    );
                    bloc.add(UpdateEventData(selectedEndTime: newEndTime));
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF983296) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF983296)
                          : const Color(0xFFF1F0F5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    timeStr,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF95969D),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildSectionLabel('Быстрый выбор длительности'),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: quickDurations.length,
            itemBuilder: (context, index) {
              final dur = quickDurations[index];
              final label = dur['label'] as String;
              final hours = dur['hours'] as int;
              final isSelected = _selectedDurationHours == hours;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDurationHours = hours;
                  });
                  final baseStart =
                      state.selectedTime ?? const TimeOfDay(hour: 9, minute: 0);
                  if (state.selectedTime == null) {
                    context.read<AddEventBloc>().add(
                      UpdateEventData(selectedTime: baseStart),
                    );
                  }
                  final newEndTime = _addHours(baseStart, hours);
                  context.read<AddEventBloc>().add(
                    UpdateEventData(selectedEndTime: newEndTime),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF983296) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF983296)
                          : const Color(0xFFF1F0F5),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF95969D),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (state.selectedTime != null && state.selectedEndTime != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF983296).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF983296).withValues(alpha: 0.12),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF983296),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Выбранное время: ${_formatTimeOfDay(state.selectedTime!)} - ${_formatTimeOfDay(state.selectedEndTime!)} (${_calculateHoursDiff(state.selectedTime!, state.selectedEndTime!)} ч.)',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF983296),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAddressFieldWithSuggestions(AddEventState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D0D26).withValues(alpha: 0.015),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: TextField(
            controller: _addressController,
            onChanged: _onAddressChanged,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFF0D0D26),
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Улица, дом, офис...',
              hintStyle: GoogleFonts.poppins(
                color: const Color(0xFFBDBDBD),
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: const Icon(
                Icons.location_pin,
                color: Color(0xFF983296),
                size: 20,
              ),
              suffixIcon: _addressController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear_rounded,
                        size: 18,
                        color: Color(0xFF95969D),
                      ),
                      onPressed: () {
                        _addressController.clear();
                        setState(() {
                          _addressSuggestions = [];
                          _showSuggestions = false;
                        });
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ),
        if (_showSuggestions &&
            (_isLoadingSuggestions || _addressSuggestions.isNotEmpty))
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0D0D26).withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _isLoadingSuggestions
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Color(0xFF983296),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _addressSuggestions.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: Color(0xFFF1F0F5), height: 1),
                    itemBuilder: (context, index) {
                      final item =
                          _addressSuggestions[index] as Map<String, dynamic>;
                      final formatted = _formatSuggestion(item);
                      return ListTile(
                        leading: const Icon(
                          Icons.location_on_outlined,
                          color: Color(0xFF983296),
                          size: 20,
                        ),
                        title: Text(
                          formatted,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: const Color(0xFF0D0D26),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: item['display_name'] != null
                            ? Text(
                                item['display_name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF95969D),
                                ),
                              )
                            : null,
                        dense: true,
                        onTap: () {
                          setState(() {
                            _addressController.text = formatted;
                            _showSuggestions = false;
                            _addressSuggestions = [];
                          });
                        },
                      );
                    },
                  ),
          ),
      ],
    );
  }

  Widget _buildStep5Volunteers(AddEventState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'ВОЛОНТЕРЫ',
            'И ЗАДАЧИ',
            'Кто вам нужен и что они получат?',
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('Количество волонтеров'),
          _buildCounter(state),
          const SizedBox(height: 24),
          _buildSectionLabel('Возрастное ограничение'),
          _buildAgeDropdownField(state),
          const SizedBox(height: 24),
          _buildSectionLabel('Обязанности'),
          _buildChipCloud(responsibilityOptions, state.responsibilities, true),
          const SizedBox(height: 24),
          _buildSectionLabel('Бонусы для участников'),
          _buildChipCloud(benefitOptions, state.benefits, false),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStep6Review(AddEventState state) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStepTitle(
            'ПРОВЕРЬТЕ',
            'ВСЕ',
            'Почти готово! Внимательно проверьте данные',
          ),
          const SizedBox(height: 24),
          if (state.posterImage != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.file(
                state.posterImage!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 20),
          _buildReviewCard(state),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildCertificatePreviewHint(AddEventState state) {
    final certText = state.certificateTitle.isNotEmpty
        ? state.certificateTitle
        : (state.title.isNotEmpty ? state.title : 'Название мероприятия');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF983296).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF983296).withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: Color(0xFF983296),
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Превью на сертификате',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF983296),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '«$certText»',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D0D26),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '+ имя каждого волонтёра — ИИ впишет на ваш шаблон после завершения ивента',
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: const Color(0xFF95969D),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF0D0D26),
        ),
      ),
    );
  }

  Widget _buildPremiumField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D0D26).withValues(alpha: 0.015),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.poppins(
          fontSize: 14,
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildDateTimeCard({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF983296)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D0D26),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeDropdownField(AddEventState state) {
    final ageOptions = [
      {'value': 0, 'label': 'Без ограничений'},
      {'value': 12, 'label': '12+'},
      {'value': 14, 'label': '14+'},
      {'value': 16, 'label': '16+'},
      {'value': 18, 'label': '18+'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: state.minAge,
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          items: ageOptions.map((opt) {
            return DropdownMenuItem<int>(
              value: opt['value'] as int,
              child: Text(
                opt['label'] as String,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0D0D26),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              context.read<AddEventBloc>().add(UpdateEventData(minAge: val));
            }
          },
        ),
      ),
    );
  }

  Widget _buildDropdownField(AddEventState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: state.location.isEmpty ? null : state.location,
          hint: Text(
            'Выберите город',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: const Color(0xFFBDBDBD),
            ),
          ),
          isExpanded: true,
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(16),
          items: cities.map((city) {
            return DropdownMenuItem(
              value: city,
              child: Text(
                city,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF0D0D26),
                ),
              ),
            );
          }).toList(),
          onChanged: (val) =>
              context.read<AddEventBloc>().add(UpdateEventData(location: val!)),
        ),
      ),
    );
  }

  Widget _buildCounter(AddEventState state) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCounterBtn(Icons.remove_rounded, () {
            if (state.volunteerCount > 0)
              context.read<AddEventBloc>().add(
                UpdateEventData(volunteerCount: state.volunteerCount - 1),
              );
          }),
          Text(
            '${state.volunteerCount}',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D0D26),
            ),
          ),
          _buildCounterBtn(Icons.add_rounded, () {
            context.read<AddEventBloc>().add(
              UpdateEventData(volunteerCount: state.volunteerCount + 1),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
        ),
        child: Icon(icon, color: const Color(0xFF0D0D26), size: 20),
      ),
    );
  }

  Widget _buildChipCloud(
    List<String> options,
    List<String> selections,
    bool isResponsibilities,
  ) {
    final isAddingCustom = isResponsibilities ? _isAddingCustomResponsibility : _isAddingCustomBenefit;
    final controller = isResponsibilities ? _customResponsibilityController : _customBenefitController;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...options.map((opt) {
          final isSelected = selections.contains(opt);
          return GestureDetector(
            onTap: () {
              List<String> newSelections = List.from(selections);
              if (isSelected)
                newSelections.remove(opt);
              else
                newSelections.add(opt);
              if (isResponsibilities) {
                context.read<AddEventBloc>().add(
                  UpdateEventData(responsibilities: newSelections),
                );
              } else {
                context.read<AddEventBloc>().add(
                  UpdateEventData(benefits: newSelections),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF983296) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF983296)
                      : const Color(0xFFF1F0F5),
                  width: 1.5,
                ),
              ),
              child: Text(
                opt,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected ? Colors.white : const Color(0xFF95969D),
                ),
              ),
            ),
          );
        }).toList(),
        
        // Inline "+ Custom option" chip
        if (isAddingCustom)
          Container(
            width: 180,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF983296), width: 1.5),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF0D0D26),
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Свой вариант...',
                      hintStyle: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFFBDBDBD)),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onSubmitted: (val) => _submitCustomOption(isResponsibilities),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check_rounded, color: Color(0xFF983296), size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _submitCustomOption(isResponsibilities),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF95969D), size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    setState(() {
                      if (isResponsibilities) {
                        _isAddingCustomResponsibility = false;
                      } else {
                        _isAddingCustomBenefit = false;
                      }
                      controller.clear();
                    });
                  },
                ),
              ],
            ),
          )
        else
          GestureDetector(
            onTap: () {
              setState(() {
                if (isResponsibilities) {
                  _isAddingCustomResponsibility = true;
                } else {
                  _isAddingCustomBenefit = true;
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF983296).withValues(alpha: 0.3),
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: Color(0xFF983296), size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Свой вариант',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF983296),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(AddEventState state) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
      ),
      child: Column(
        children: [
          _buildReviewItem(
            Icons.category_rounded,
            'Категория',
            state.eventType,
          ),
          _buildReviewItem(
            Icons.title_rounded,
            'Название',
            _titleController.text,
          ),
          _buildReviewItem(
            Icons.workspace_premium_rounded,
            'На сертификате',
            _certTitleController.text,
          ),
          _buildReviewItem(
            Icons.calendar_month_rounded,
            'Дата',
            state.selectedDate != null
                ? '${state.selectedDate!.day}.${state.selectedDate!.month}.${state.selectedDate!.year}'
                : '',
          ),
          _buildReviewItem(
            Icons.location_on_rounded,
            'Место',
            '${state.location}, ${_addressController.text}',
          ),
          _buildReviewItem(
            Icons.group_rounded,
            'Волонтеры',
            '${state.volunteerCount} человек',
          ),
          _buildReviewItem(
            Icons.child_care_rounded,
            'Возраст',
            state.minAge == 0 ? 'Без ограничений' : '${state.minAge}+',
          ),
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
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF95969D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF0D0D26),
                    fontWeight: FontWeight.w700,
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
