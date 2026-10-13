import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'pending_approval_page.dart';
import 'blocs/onboarding/org_onboarding_bloc.dart';

class OrgInfoOnboardingPage extends StatelessWidget {
  const OrgInfoOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrgOnboardingBloc(apiService: ApiService()),
      child: const _OrgInfoOnboardingView(),
    );
  }
}

class _OrgInfoOnboardingView extends StatefulWidget {
  const _OrgInfoOnboardingView();

  @override
  State<_OrgInfoOnboardingView> createState() => _OrgInfoOnboardingViewState();
}

class _OrgInfoOnboardingViewState extends State<_OrgInfoOnboardingView> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _selectedTheme = 'style:classic';

  final List<Map<String, dynamic>> _themes = [
    {
      'id': 'style:classic',
      'name': 'Классический',
      'desc': 'Строгий центр',
      'bg1': const Color(0xFFFFFFFF),
      'accent': const Color(0xFF983296),
      'textColor': const Color(0xFF0D0D26),
    },
    {
      'id': 'style:modern_left',
      'name': 'Асимметрия',
      'desc': 'Текст слева',
      'bg1': const Color(0xFFFAF9FC),
      'accent': const Color(0xFF983296),
      'textColor': const Color(0xFF0D0D26),
    },
    {
      'id': 'style:minimal_bottom',
      'name': 'Минимализм',
      'desc': 'Минимализм по углам',
      'bg1': const Color(0xFFFFFFFF),
      'accent': const Color(0xFF983296),
      'textColor': const Color(0xFF0D0D26),
    },
  ];

  Widget _buildCertificatePreview(Map<String, dynamic> theme) {
    if (theme['id'] == 'style:modern_left') {
      return _buildModernLeftPreview(theme);
    } else if (theme['id'] == 'style:minimal_bottom') {
      return _buildMinimalBottomPreview(theme);
    }
    return _buildClassicPreview(theme);
  }

  Widget _buildClassicPreview(Map<String, dynamic> theme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border.all(color: theme['accent'].withValues(alpha: 0.5), width: 1.5), borderRadius: BorderRadius.circular(8)),
          ),
        ),
        Positioned.fill(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border.all(color: theme['accent'].withValues(alpha: 0.2), width: 1), borderRadius: BorderRadius.circular(4)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(28),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 244,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('СЕРТИФИКАТ', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: theme['accent'], letterSpacing: 2)),
                  const SizedBox(height: 12),
                  Container(width: 60, height: 1.5, color: theme['accent'].withValues(alpha: 0.5)),
                  const SizedBox(height: 12),
                  Text('ИМЯ ВОЛОНТЕРА', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: theme['textColor'])),
                  const SizedBox(height: 6),
                  Text('За активное участие в волонтерском проекте', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 9, color: theme['textColor'].withValues(alpha: 0.7))),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 50, height: 1, color: theme['textColor'].withValues(alpha: 0.3)),
                          const SizedBox(height: 4),
                          Text('Подпись', style: GoogleFonts.poppins(fontSize: 7, color: theme['textColor'].withValues(alpha: 0.5))),
                        ],
                      ),
                      Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme['accent'], width: 1.5)),
                        child: Center(child: Icon(Icons.stars_rounded, size: 20, color: theme['accent'])),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModernLeftPreview(Map<String, dynamic> theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 180,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('СЕРТИФИКАТ', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w900, color: theme['accent'], letterSpacing: 1)),
                    const SizedBox(height: 16),
                    Text('ИМЯ ВОЛОНТЕРА', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: theme['textColor'])),
                    const SizedBox(height: 6),
                    Text('За участие в волонтерском проекте', style: GoogleFonts.poppins(fontSize: 9, color: theme['textColor'].withValues(alpha: 0.7))),
                    const SizedBox(height: 32),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: theme['accent'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Icon(Icons.verified_rounded, size: 18, color: theme['accent'])),
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 50, height: 1, color: theme['textColor'].withValues(alpha: 0.3)),
                            const SizedBox(height: 4),
                            Text('Подпись', style: GoogleFonts.poppins(fontSize: 7, color: theme['textColor'].withValues(alpha: 0.5))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            decoration: BoxDecoration(
              color: theme['accent'],
              borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
            ),
            child: Center(
              child: RotatedBox(
                quarterTurns: 3,
                child: Text('VOLO APPROVED', style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 4)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalBottomPreview(Map<String, dynamic> theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: 0, left: 0,
            child: Text('СЕРТИФИКАТ', style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w900, color: theme['accent'])),
          ),
          Positioned(
            bottom: 0, right: 0,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomRight,
              child: SizedBox(
                width: 200,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('ИМЯ ВОЛОНТЕРА', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: theme['textColor'])),
                    const SizedBox(height: 4),
                    Text('За выдающийся вклад в проект', style: GoogleFonts.poppins(fontSize: 9, color: theme['textColor'].withValues(alpha: 0.7))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(width: 50, height: 1, color: theme['textColor'].withValues(alpha: 0.3)),
                            const SizedBox(height: 4),
                            Text('Подпись', style: GoogleFonts.poppins(fontSize: 7, color: theme['textColor'].withValues(alpha: 0.5))),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme['accent'], width: 1.5)),
                          child: Center(child: Icon(Icons.volunteer_activism_rounded, size: 16, color: theme['accent'])),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrgOnboardingBloc, OrgOnboardingState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showError(state.errorMessage!);
        }
        if (state.isSuccess) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const PendingApprovalPage()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final isLoading = state.isSubmitting;
        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F8FA),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Color(0xFF0D0D26)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF983296).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.business_rounded, color: Color(0xFF983296), size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Профиль партнера',
                              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Заполните данные о вашей организации',
                              style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF95969D), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 36),

                  // Game-like Theme Selection
                  Text(
                    'Шаблон сертификата',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Выберите дизайн (верстку), который будут получать ваши волонтеры.',
                    style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF95969D)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 220,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _themes.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 20),
                      itemBuilder: (context, index) {
                        final theme = _themes[index];
                        final isSelected = _selectedTheme == theme['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedTheme = theme['id']!;
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 300,
                            decoration: BoxDecoration(
                              color: theme['bg1'],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF983296) : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: const Color(0xFF983296).withValues(alpha: 0.2),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  )
                                else
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  )
                              ],
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(17),
                                  child: _buildCertificatePreview(theme),
                                ),
                                // Selection Checkmark Overlay
                                if (isSelected)
                                  Positioned(
                                    top: 14,
                                    right: 14,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF983296),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                                    ),
                                  ),
                                // Theme name label at top left
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF983296) : theme['accent'].withValues(alpha: 0.1),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(17),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      theme['name'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected ? Colors.white : theme['accent'],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Form Fields
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFF1F0F5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: _descriptionController,
                          label: 'Описание деятельности',
                          hint: 'Расскажите о ваших добрых инициативах...',
                          icon: Icons.description_rounded,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _websiteController,
                          label: 'Официальный веб-сайт',
                          hint: 'https://example.com',
                          icon: Icons.language_rounded,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _addressController,
                          label: 'Адрес офиса',
                          hint: 'г. Алматы, пр. Абая, 52',
                          icon: Icons.map_rounded,
                        ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          controller: _phoneController,
                          label: 'Контактный телефон',
                          hint: '+7 (777) 123-45-67',
                          icon: Icons.phone_rounded,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6B1F6A), Color(0xFF983296)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF983296).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                context.read<OrgOnboardingBloc>().add(SubmitOrgOnboarding(
                                      description: _descriptionController.text.trim(),
                                      website: _websiteController.text.trim(),
                                      address: _addressController.text.trim(),
                                      phone: _phoneController.text.trim(),
                                      certificateTemplateUrl: _selectedTheme,
                                    ));
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Завершить регистрацию',
                                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0D0D26)),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            prefixIcon: Icon(icon, color: const Color(0xFF0D0D26).withValues(alpha: 0.5), size: 20),
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[400], fontWeight: FontWeight.w400),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF983296), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
