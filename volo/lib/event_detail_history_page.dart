import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/api_service.dart';

class EventDetailHistoryPage extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailHistoryPage({super.key, required this.event});

  @override
  State<EventDetailHistoryPage> createState() => _EventDetailHistoryPageState();
}

class _EventDetailHistoryPageState extends State<EventDetailHistoryPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _reviewTextController = TextEditingController();

  List<dynamic> _reviews = [];
  Map<String, dynamic>? _myReview;
  int _selectedRating = 0;
  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reviewTextController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventId = widget.event['id'] as int?;
      if (eventId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Load user profile to get current user ID
      final userResult = await _apiService.getUserProfile();
      if (userResult['success'] == true) {
        _currentUserId = userResult['data']?['id'] as int?;
      }

      // Load reviews
      final reviewsResult = await _apiService.getEventReviews(eventId);
      if (reviewsResult['success'] == true) {
        _reviews = reviewsResult['data'] ?? [];
        
        // Find if current user already left a review
        if (_currentUserId != null) {
          final myReviewList = _reviews.where((r) => r['user_id'] == _currentUserId).toList();
          if (myReviewList.isNotEmpty) {
            _myReview = myReviewList.first;
          }
        }
      }
    } catch (e) {
      print('Error loading event reviews: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submitReview() async {
    final eventId = widget.event['id'] as int?;
    if (eventId == null) return;

    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Пожалуйста, выберите оценку (от 1 до 5 звезд)', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red[400],
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final result = await _apiService.submitReview(
        eventId,
        _selectedRating,
        _reviewTextController.text.trim(),
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Отзыв успешно опубликован', style: GoogleFonts.poppins(color: Colors.white)),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );
        _reviewTextController.clear();
        _loadData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Ошибка отправки отзыва', style: GoogleFonts.poppins()),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка сети: $e', style: GoogleFonts.poppins()),
          backgroundColor: Colors.red[400],
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  double get _averageRating {
    if (_reviews.isEmpty) return 5.0; // Default rating if no reviews
    final total = _reviews.fold(0.0, (sum, item) => sum + (item['rating'] as num? ?? 0).toDouble());
    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isCompleted = event['status'] == 'completed';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF983296), size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: const SizedBox(), // Transparent/empty header
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Photo
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/photo.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      'Завершено',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(event['category']).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getCategoryColor(event['category']).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      event['category'] ?? 'Другое',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getCategoryColor(event['category']),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Title & Organizer
                  Text(
                    event['title'] ?? 'Без названия',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['organizer'] ?? 'Организатор не указан',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Event Stats
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.grey[200]!,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Статистика мероприятия',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Рейтинг', _isLoading ? '...' : _averageRating.toStringAsFixed(1)),
                            _buildStatItem('Часы', '+${event['hours']} ч'),
                            _buildStatItem('Волонтеры', '${event['volunteers']}'),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Info details list
                  Text(
                    'Детали',
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Дата проведения', event['date'] ?? 'Не указана'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Локация', event['location'] ?? 'Не указана'),

                  const SizedBox(height: 32),

                  // Description
                  Text(
                    'Описание',
                    style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.black),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    event['description'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700], height: 1.5),
                  ),

                  const SizedBox(height: 32),

                  // Certificate
                  if (event['hasCertificate'] == true) ...[
                    _buildCertificateSection(),
                    const SizedBox(height: 32),
                  ],

                  // Feedback Section
                  if (isCompleted) ...[
                    _buildFeedbackSection(),
                    const SizedBox(height: 32),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF983296)),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey[500]),
        ),
      ],
    );
  }

  Widget _buildCertificateSection() {
    final certUrl = widget.event['certificateUrl'] as String?;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_outlined, color: Color(0xFF983296), size: 24),
              const SizedBox(width: 10),
              Text(
                'Сертификат участника',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Certificate Preview Card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: certUrl != null
                  ? Image.network(
                      certUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDummyCertificate();
                      },
                    )
                  : _buildDummyCertificate(),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showCertificateFullScreen(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF983296),
                    side: const BorderSide(color: Color(0xFF983296), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Просмотреть',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Сертификат скачивается...', style: GoogleFonts.poppins()),
                        backgroundColor: const Color(0xFF4CAF50),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF983296),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Скачать',
                    style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDummyCertificate() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.workspace_premium_rounded, size: 48, color: Colors.grey[400]),
        const SizedBox(height: 8),
        Text(
          'Сертификат генерируется',
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[500], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF983296)));
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F1F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _myReview != null ? 'Ваш отзыв' : 'Оставить отзыв',
            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.black),
          ),
          const SizedBox(height: 16),
          if (_myReview != null) ...[
            Row(
              children: List.generate(5, (i) {
                final score = _myReview!['rating'] as num? ?? 0;
                return Icon(
                  Icons.star_rounded,
                  size: 24,
                  color: i < score ? Colors.amber : Colors.grey[300],
                );
              }),
            ),
            const SizedBox(height: 12),
            if (_myReview!['text'] != null && (_myReview!['text'] as String).isNotEmpty)
              Text(
                _myReview!['text']!,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[800], height: 1.4),
              )
            else
              Text(
                'Без текстового комментария',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400], fontStyle: FontStyle.italic),
              ),
          ] else ...[
            // Rating selector
            Row(
              children: List.generate(5, (i) {
                final starIndex = i + 1;
                final isSelected = starIndex <= _selectedRating;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedRating = starIndex;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(
                      Icons.star_rounded,
                      size: 32,
                      color: isSelected ? Colors.amber : Colors.grey[300],
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewTextController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Поделитесь вашим мнением о мероприятии...',
                hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
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
                  borderSide: const BorderSide(color: Color(0xFF983296), width: 1.5),
                ),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF983296),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Опубликовать отзыв',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showCertificateFullScreen() {
    final certUrl = widget.event['certificateUrl'] as String?;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Просмотр сертификата',
                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black),
                ),
                centerTitle: true,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: certUrl != null
                      ? Image.network(
                          certUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Image.asset('assets/images/sert.jpg');
                          },
                        )
                      : Image.asset('assets/images/sert.jpg'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String? category) {
    switch (category) {
      case 'Культура':
        return const Color(0xFFE91E63);
      case 'Экология':
        return const Color(0xFF4CAF50);
      case 'Спорт':
        return const Color(0xFF2196F3);
      case 'Образование':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFF983296);
    }
  }
}