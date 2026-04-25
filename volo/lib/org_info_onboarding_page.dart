import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
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
          appBar: AppBar(
            title: Text('О профиле организации', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: SvgPicture.asset('assets/images/left.svg', width: 24, height: 24),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Расскажите о себе',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Эта информация поможет волонтерам узнать больше о вашей деятельности и доверии к вам.',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Описание организации',
                  hint: 'Чем вы занимаетесь?',
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _websiteController,
                  label: 'Веб-сайт или соцсети',
                  hint: 'https://example.com',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _addressController,
                  label: 'Адрес офиса',
                  hint: 'г. Алматы, ул. Абая, 1',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _phoneController,
                  label: 'Контактный телефон',
                  hint: '+7 (707) 123 45 67',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () {
                      context.read<OrgOnboardingBloc>().add(SubmitOrgOnboarding(
                        description: _descriptionController.text.trim(),
                        website: _websiteController.text.trim(),
                        address: _addressController.text.trim(),
                        phone: _phoneController.text.trim(),
                      ));
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF983296),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Завершить',
                            style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                  ),
                ),
              ],
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
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF983296), width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
