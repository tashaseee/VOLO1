import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'blocs/filter/filter_bloc.dart';

class FilterPage extends StatelessWidget {
  final Function(Map<String, List<String>>)? onFiltersApplied;
  const FilterPage({super.key, this.onFiltersApplied});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FilterBloc(),
      child: _FilterView(onFiltersApplied: onFiltersApplied),
    );
  }
}

class _FilterView extends StatelessWidget {
  final Function(Map<String, List<String>>)? onFiltersApplied;
  const _FilterView({this.onFiltersApplied});

  static const List<String> volunteerTypes = ['Экология и природа', 'Социальная помощь', 'Образование', 'Культура и искусство', 'Спорт и здоровье', 'Медицина', 'Животные', 'Дети и молодежь'];
  static const List<String> locations = ['Алматы', 'Нур-Султан', 'Шымкент', 'Актау', 'Атырау', 'Караганда', 'Усть-Каменогорск', 'Уральск'];
  static const List<String> durations = ['Однодневное', 'Несколько дней', 'Неделя', 'Месяц', 'Длительное'];
  static const List<String> eventTypes = ['Массовое событие', 'Регулярное волонтерство', 'Эко-акция', 'Благотворительность', 'Образовательное', 'Спортивное'];
  static const List<String> benefits = ['Питание', 'Трансфер', 'Проживание', 'Сертификат', 'Мерч', 'Оплачиваемое', 'Без опыта'];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FilterBloc, FilterState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white, elevation: 0,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Padding(padding: const EdgeInsets.all(12.0),
                child: SvgPicture.asset('assets/images/left.svg', width: 20, height: 20,
                  colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn))),
            ),
            centerTitle: true,
            title: Text('Фильтр', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black)),
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(context, 'Тип волонтерства', volunteerTypes, state.volunteerTypes, 'volunteerTypes'),
                  const SizedBox(height: 24),
                  _buildSection(context, 'Город', locations, state.locations, 'locations'),
                  const SizedBox(height: 24),
                  _buildSection(context, 'Продолжительность', durations, state.durations, 'durations'),
                  const SizedBox(height: 24),
                  _buildSection(context, 'Тип мероприятия', eventTypes, state.eventTypes, 'eventTypes'),
                  const SizedBox(height: 24),
                  _buildSection(context, 'Что предоставляется', benefits, state.benefits, 'benefits'),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        onFiltersApplied?.call(state.toMap());
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF983296), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: Text('Применить фильтры', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: OutlinedButton(
                      onPressed: () => context.read<FilterBloc>().add(ResetFilters()),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF983296)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                      child: Text('Сбросить все', style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 16, color: const Color(0xFF983296))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, List<String> options, List<String> selected, String category) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return GestureDetector(
              onTap: () => context.read<FilterBloc>().add(ToggleFilterItem(category, option)),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF983296) : Colors.white,
                  border: Border.all(color: isSelected ? const Color(0xFF983296) : Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(option, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? Colors.white : Colors.grey[600])),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}