import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/register/register_bloc.dart';
import 'blocs/register/register_event.dart';
import 'blocs/register/register_state.dart';
import 'services/api_service.dart';

import 'user_info_onboarding_page.dart';
import 'verification_code_page.dart';
import 'sign_in_page.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterBloc(apiService: ApiService()),
      child: const RegisterView(),
    );
  }
}

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _orgNameController = TextEditingController();
  final TextEditingController _binController = TextEditingController();

  bool _canRegister(RegisterState state) {
    bool basic = _emailController.text.isNotEmpty &&
           _passwordController.text.isNotEmpty &&
           _confirmPasswordController.text.isNotEmpty &&
           _passwordController.text == _confirmPasswordController.text &&
           _passwordController.text.length >= 8 &&
           _passwordController.text.contains(RegExp(r'[0-9]')) &&
           _passwordController.text.contains(RegExp(r'[A-Z]')) &&
           !state.isLoading;
    
    if (state.isOrganization) {
      return basic && _orgNameController.text.isNotEmpty && _binController.text.length == 12;
    }
    return basic;
  }

  void _onFormChanged() {
    context.read<RegisterBloc>().add(RegisterFormChanged());
  }

  void _register(RegisterState state) {
    if (_canRegister(state)) {
      context.read<RegisterBloc>().add(
        RegisterRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          isOrganization: state.isOrganization,
          orgName: _orgNameController.text.trim(),
          bin: _binController.text.trim(),
        )
      );
    }
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
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFD32F2F), // Material Red 700
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  Widget _buildCleanRequirement(String text, bool met) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: met ? const Color(0xFF983296).withOpacity(0.1) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: met ? const Color(0xFF983296) : Colors.transparent,
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: met ? FontWeight.w600 : FontWeight.w500,
          color: met ? const Color(0xFF983296) : Colors.grey[500],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgNameController.dispose();
    _binController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<RegisterBloc, RegisterState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            _showError(state.errorMessage!);
          }
          if (state.isSuccess) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerificationCodePage(
                  email: _emailController.text.trim(),
                  password: _passwordController.text,
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          final isOrg = state.isOrganization;

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.only(top: 16, left: 16),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: SvgPicture.asset(
                        'assets/images/left.svg',
                        width: 24,
                        height: 24,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Создайте аккаунт',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isOrg ? 'Зарегистрируйте организацию' : 'Присоединяйтесь к сообществу волонтеров',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Переключатель типа аккаунта
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.read<RegisterBloc>().add(const ChangeAccountType(false)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: !isOrg ? const Color(0xFF983296) : Colors.grey[200]!,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Волонтер',
                                    style: GoogleFonts.poppins(
                                      fontWeight: !isOrg ? FontWeight.w600 : FontWeight.w400,
                                      color: !isOrg ? const Color(0xFF983296) : Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => context.read<RegisterBloc>().add(const ChangeAccountType(true)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: isOrg ? const Color(0xFF983296) : Colors.grey[200]!,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'Организация',
                                    style: GoogleFonts.poppins(
                                      fontWeight: isOrg ? FontWeight.w600 : FontWeight.w400,
                                      color: isOrg ? const Color(0xFF983296) : Colors.grey[500],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      if (isOrg) ...[
                        TextField(
                          controller: _orgNameController,
                          onChanged: (_) => _onFormChanged(),
                          decoration: InputDecoration(
                            hintText: 'Название организации',
                            hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SvgPicture.asset(
                                'assets/images/name.svg', 
                                width: 24, height: 24, color: Colors.grey
                              ),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _binController,
                          onChanged: (_) => _onFormChanged(),
                          keyboardType: TextInputType.number,
                          maxLength: 12,
                          decoration: InputDecoration(
                            hintText: 'БИН (12 цифр)',
                            counterText: "",
                            hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
                            prefixIcon: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SvgPicture.asset(
                                'assets/images/application.svg', 
                                width: 24, height: 24, color: Colors.grey
                              ),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        onChanged: (_) => _onFormChanged(),
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'E-mail',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(
                              'assets/images/mail.svg',
                              width: 24,
                              height: 24,
                              color: Colors.grey,
                            ),
                          ),
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
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        onChanged: (_) => _onFormChanged(),
                        obscureText: !state.showPassword,
                        decoration: InputDecoration(
                          hintText: 'Пароль',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(
                              'assets/images/password.svg',
                              width: 24,
                              height: 24,
                              color: Colors.grey,
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              context.read<RegisterBloc>().add(TogglePasswordVisibility());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SvgPicture.asset(
                                state.showPassword
                                    ? 'assets/images/eye.svg'
                                    : 'assets/images/eye_off.svg',
                                width: 24,
                                height: 24,
                                color: Colors.grey,
                              ),
                            ),
                          ),
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
                      const SizedBox(height: 8),
                      const SizedBox(height: 12),
                      // Password Strength Indicators
                      Wrap(
                         spacing: 8,
                         runSpacing: 8,
                         children: [
                           _buildCleanRequirement('8+ символов', _passwordController.text.length >= 8),
                           _buildCleanRequirement('Цифра', _passwordController.text.contains(RegExp(r'[0-9]'))),
                           _buildCleanRequirement('Заглавная буква', _passwordController.text.contains(RegExp(r'[A-Z]'))),
                         ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmPasswordController,
                        onChanged: (_) => _onFormChanged(),
                        obscureText: !state.showConfirmPassword,
                        decoration: InputDecoration(
                          hintText: 'Подтвердите пароль',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[400],
                          ),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: SvgPicture.asset(
                              'assets/images/password.svg',
                              width: 24,
                              height: 24,
                              color: Colors.grey,
                            ),
                          ),
                          suffixIcon: GestureDetector(
                            onTap: () {
                              context.read<RegisterBloc>().add(ToggleConfirmPasswordVisibility());
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: SvgPicture.asset(
                                state.showConfirmPassword
                                    ? 'assets/images/eye.svg'
                                    : 'assets/images/eye_off.svg',
                                width: 24,
                                height: 24,
                                color: Colors.grey,
                              ),
                            ),
                          ),
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
                      if (_confirmPasswordController.text.isNotEmpty &&
                          _passwordController.text != _confirmPasswordController.text) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Пароли не совпадают',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _canRegister(state) ? () => _register(state) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF983296),
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: state.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  'Продолжить',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: _canRegister(state) ? Colors.white : Colors.grey[500],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SignInPage(),
                              ),
                            );
                          },
                          child: RichText(
                            text: TextSpan(
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              children: const [
                                TextSpan(text: 'Уже есть аккаунт? '),
                                TextSpan(
                                  text: 'Войти',
                                  style: TextStyle(
                                    color: Color(0xFF983296),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}