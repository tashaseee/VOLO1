import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class FilterPage extends StatefulWidget {
  final Function(Map<String, List<String>>)? onFiltersApplied;

  const FilterPage({super.key, this.onFiltersApplied});

  @override
  State<FilterPage> createState() => _FilterPageState();
}

class _FilterPageState extends State<FilterPage> {
  List<String> selectedVolunteerTypes = [];
  List<String> selectedLocations = [];
  List<String> selectedDurations = [];
  List<String> selectedEventTypes = [];
  List<String> selectedBenefits = [];

  final List<String> volunteerTypes = [
    'Экология и природа',
    'Социальная помощь',
    'Образование',
    'Культура и искусство',
    'Спорт и здоровье',
    'Медицина',
    'Животные',
    'Дети и молодежь'
  ];

  final List<String> locations = [
    'Алматы',
    'Нур-Султан',
    'Шымкент',
    'Актау',
    'Атырау',
    'Караганда',
    'Усть-Каменогорск',
    'Уральск'
  ];

  final List<String> durations = [
    'Однодневное',
    'Несколько дней',
    'Неделя',
    'Месяц',
    'Длительное'
  ];

  final List<String> eventTypes = [
    'Массовое событие',
    'Регулярное волонтерство',
    'Эко-акция',
    'Благотворительность',
    'Образовательное',
    'Спортивное'
  ];

  final List<String> benefits = [
    'Питание',
    'Трансфер',
    'Проживание',
    'Сертификат',
    'Мерч',
    'Оплачиваемое',
    'Без опыта'
  ];

  void _applyFilters() {
    final filters = {
      'volunteerTypes': selectedVolunteerTypes,
      'locations': selectedLocations,
      'durations': selectedDurations,
      'eventTypes': selectedEventTypes,
      'benefits': selectedBenefits,
    };
    
    widget.onFiltersApplied?.call(filters);
    Navigator.pop(context);
  }

  void _resetAllFilters() {
    setState(() {
      selectedVolunteerTypes.clear();
      selectedLocations.clear();
      selectedDurations.clear();
      selectedEventTypes.clear();
      selectedBenefits.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SvgPicture.asset(
              'assets/images/left.svg',
              width: 20, // Уменьшен размер
              height: 20, // Уменьшен размер
              colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Фильтр',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterSection(
                'Тип волонтерства',
                volunteerTypes,
                selectedVolunteerTypes,
                (value) {
                  setState(() {
                    if (selectedVolunteerTypes.contains(value)) {
                      selectedVolunteerTypes.remove(value);
                    } else {
                      selectedVolunteerTypes.add(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildFilterSection(
                'Город',
                locations,
                selectedLocations,
                (value) {
                  setState(() {
                    if (selectedLocations.contains(value)) {
                      selectedLocations.remove(value);
                    } else {
                      selectedLocations.add(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildFilterSection(
                'Продолжительность',
                durations,
                selectedDurations,
                (value) {
                  setState(() {
                    if (selectedDurations.contains(value)) {
                      selectedDurations.remove(value);
                    } else {
                      selectedDurations.add(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildFilterSection(
                'Тип мероприятия',
                eventTypes,
                selectedEventTypes,
                (value) {
                  setState(() {
                    if (selectedEventTypes.contains(value)) {
                      selectedEventTypes.remove(value);
                    } else {
                      selectedEventTypes.add(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 24),
              _buildFilterSection(
                'Что предоставляется',
                benefits,
                selectedBenefits,
                (value) {
                  setState(() {
                    if (selectedBenefits.contains(value)) {
                      selectedBenefits.remove(value);
                    } else {
                      selectedBenefits.add(value);
                    }
                  });
                },
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF983296),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Применить фильтры',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _resetAllFilters,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF983296)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Сбросить все',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: const Color(0xFF983296),
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

  Widget _buildFilterSection(
    String title,
    List<String> options,
    List<String> selectedValues,
    Function(String) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF983296) : Colors.white,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF983296) : Colors.grey[300]!,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  option,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.grey[600],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}