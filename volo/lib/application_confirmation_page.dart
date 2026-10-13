import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'blocs/application_confirmation/application_confirmation_bloc.dart';

class ApplicationConfirmationPage extends StatelessWidget {
  final String eventTitle;
  final String organizer;
  final String date;
  final String location;
  final int eventId;

  const ApplicationConfirmationPage({
    super.key,
    required this.eventTitle,
    required this.organizer,
    required this.date,
    required this.location,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ApplicationConfirmationBloc(apiService: ApiService()),
      child: _ApplicationConfirmationView(
        eventTitle: eventTitle,
        organizer: organizer,
        date: date,
        location: location,
        eventId: eventId,
      ),
    );
  }
}

class _ApplicationConfirmationView extends StatefulWidget {
  final String eventTitle;
  final String organizer;
  final String date;
  final String location;
  final int eventId;

  const _ApplicationConfirmationView({
    required this.eventTitle,
    required this.organizer,
    required this.date,
    required this.location,
    required this.eventId,
  });

  @override
  State<_ApplicationConfirmationView> createState() => _ApplicationConfirmationViewState();
}

class _ApplicationConfirmationViewState extends State<_ApplicationConfirmationView> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(color: Colors.white),
        ),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplicationConfirmationBloc, ApplicationConfirmationState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showErrorSnackBar(state.errorMessage!);
        } else if (state.isSuccess) {
          _animationController.forward();
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              Navigator.pop(context, true);
            }
          });
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent, // Background handled by barrierColor
          body: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: state.isSuccess ? _buildSuccessView() : _buildConfirmationView(state),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildConfirmationView(ApplicationConfirmationState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header Image/Icon Area
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: const BoxDecoration(
            color: Color(0xFFFAFAFA),
            border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.assignment_turned_in,
                  size: 40,
                  color: Color(0xFF983296),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Подтверждение',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                'Вы собираетесь подать заявку на участие в мероприятии:',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              
              // Event Summary Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFDFD),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.eventTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(Icons.calendar_today, widget.date),
                    const SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, widget.location),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // WARNING BLOCK
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCDD2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Внимание! В случае неявки на ивент после подтверждения без уведомления организатора, ваш аккаунт может быть заблокирован администрацией.',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFFD32F2F),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Agreement Checkbox
              GestureDetector(
                onTap: () => context.read<ApplicationConfirmationBloc>().add(ToggleAgreement()),
                child: Row(
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: state.agreed,
                        onChanged: (val) => context.read<ApplicationConfirmationBloc>().add(ToggleAgreement()),
                        activeColor: const Color(0xFF983296),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Я подтверждаю свое участие и обязуюсь прийти вовремя.',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Actions
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: state.isSubmitting ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Отмена',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (state.isSubmitting || !state.agreed) ? null : () => context.read<ApplicationConfirmationBloc>().add(SubmitApplication(widget.eventId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF983296),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        disabledForegroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: state.isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Подать заявку',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 64,
                color: Colors.green[600],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Успешно!',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ваша заявка отправлена.\nМы уведомим вас о решении.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[400]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey[700],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}