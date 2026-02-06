import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventReviewsPage extends StatelessWidget {
  final String eventTitle;

  const EventReviewsPage({super.key, required this.eventTitle});

  @override
  Widget build(BuildContext context) {
    // Dummy reviews for demonstration
    final List<Map<String, dynamic>> reviews = [
      {'user': 'Айгерим М.', 'rating': 5, 'text': 'Все было супер! Отличная организация и вкусный перекус.', 'date': '2 дня назад'},
      {'user': 'Данияр К.', 'rating': 4, 'text': 'Немного задержали начало, но в целом очень полезный опыт.', 'date': '5 дней назад'},
      {'user': 'Марина С.', 'rating': 5, 'text': 'Лучший ивент, на котором я была. Команда организаторов — профи!', 'date': '1 неделю назад'},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D0D26), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ОТЗЫВЫ ВОЛОНТЕРОВ',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26), letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingHeader(4.8, reviews.length),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
              itemCount: reviews.length,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final review = reviews[index];
                return _buildReviewCard(review);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingHeader(double avg, int count) {
    return Container(
      padding: const EdgeInsets.all(28),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBC05).withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  avg.toString(),
                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFFFBBC05)),
                ),
                Text(
                  'из 5',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFFBBC05).withOpacity(0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Средний рейтинг',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
                ),
                Text(
                  'На основе $count отзывов волонтеров',
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF95969D), fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) => Icon(
                    Icons.star_rounded, 
                    size: 18, 
                    color: i < 4 ? const Color(0xFFFBBC05) : const Color(0xFFE0E0E0)
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review['user'],
                style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
              ),
              Text(
                review['date'],
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF95969D), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (i) => Icon(
              Icons.star_rounded, 
              size: 14, 
              color: i < review['rating'] ? const Color(0xFFFBBC05) : const Color(0xFFE0E0E0)
            )),
          ),
          const SizedBox(height: 12),
          Text(
            review['text'],
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B6B7B), height: 1.5),
          ),
        ],
      ),
    );
  }
}
