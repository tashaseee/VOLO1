import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';

class EventReviewsPage extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const EventReviewsPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<EventReviewsPage> createState() => _EventReviewsPageState();
}

class _EventReviewsPageState extends State<EventReviewsPage> {
  final ApiService _apiService = ApiService();
  
  List<dynamic> _reviews = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.getEventReviews(widget.eventId);
      if (result['success'] == true) {
        setState(() {
          _reviews = result['data'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Не удалось загрузить отзывы';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Ошибка сети: $e';
        _isLoading = false;
      });
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 5.0;
    final total = _reviews.fold(0.0, (sum, r) => sum + (r['rating'] as num? ?? 0).toDouble());
    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF983296), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ОТЗЫВЫ ВОЛОНТЕРОВ',
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26), letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF983296)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReviews,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF983296)),
                child: Text('Повторить', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Отзывов пока нет',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey[500]),
              ),
              const SizedBox(height: 8),
              Text(
                'Волонтеры еще не оставили оценки для мероприятия:\n"${widget.eventTitle}"',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingHeader(_averageRating, _reviews.length),
        const Divider(height: 1, color: Color(0xFFF1F1F5)),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _reviews.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return _buildReviewCard(review);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRatingHeader(double avg, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFFBBC05).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Text(
                  avg.toStringAsFixed(1),
                  style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.w800, color: const Color(0xFFFBBC05)),
                ),
                Text(
                  'из 5',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFFFBBC05).withValues(alpha: 0.8)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Средняя оценка',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
                ),
                Text(
                  'На основе $count оценок волонтеров',
                  style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF95969D), fontWeight: FontWeight.w400),
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(5, (i) => Icon(
                    Icons.star_rounded, 
                    size: 18, 
                    color: i < avg.round() ? const Color(0xFFFBBC05) : const Color(0xFFE0E0E0)
                  )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(dynamic review) {
    final score = review['rating'] as int? ?? 5;
    final text = review['text'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                review['user_name'] ?? 'Волонтер',
                style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
              ),
              Text(
                _formatDate(review['created_at']),
                style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF95969D), fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (i) => Icon(
              Icons.star_rounded, 
              size: 16, 
              color: i < score ? const Color(0xFFFBBC05) : const Color(0xFFE0E0E0)
            )),
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              text,
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF6B6B7B), height: 1.4),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final year = dateTime.year;
      return '$day.$month.$year';
    } catch (_) {
      return '';
    }
  }
}
