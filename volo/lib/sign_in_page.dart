import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'blocs/sign_in/sign_in_bloc.dart';
import 'blocs/sign_in/sign_in_event.dart';
import 'blocs/sign_in/sign_in_state.dart';
import 'services/api_service.dart';

import 'register_page.dart';
import 'home_page.dart'; // Для обычных пользователей
import 'organizer_home_page.dart'; // Для организаторов
import 'pending_approval_page.dart';
import 'forgot_password_page.dart';

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Обернём локальный стейт логина в BlocProvider
    return BlocProvider(
      create: (context) => SignInBloc(apiService: ApiService()),
      child: const SignInView(),
    );
  }
}

class SignInView extends StatefulWidget {
  const SignInView({super.key});

  @override
  State<SignInView> createState() => _SignInViewState();
}

class _SignInViewState extends State<SignInView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    context.read<SignInBloc>().add(
      SignInRequested(_emailController.text, _passwordController.text),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: BlocConsumer<SignInBloc, SignInState>(
        listener: (context, state) {
          // Выводим ошибки в снекбар
          if (state.errorMessage != null) {
            _showError(state.errorMessage!);
          }
          
          // Обрабатываем успешный вход
          if (state.isSuccess && state.userData != null) {
            final role = state.userData['role'];
            final isApproved = state.userData['is_approved'] ?? false;

            if (role == 'organizer' && !isApproved) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const PendingApprovalPage()),
                (route) => false,
              );
            } else {
              String targetRoute = (role == 'organizer') ? '/organizer_home' : '/home';
              Navigator.pushNamedAndRemoveUntil(
                context,
                targetRoute,
                (route) => false,
              );
            }
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 60),
                if (Navigator.of(context).canPop())
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
                const SizedBox(height: 120),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'С возвращением!',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ваша следующая миссия ждёт вас!',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 28),
                      TextField(
                        controller: _emailController,
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
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
                          suffixIcon: IconButton(
                            icon: SvgPicture.asset(
                              state.showPassword ? 'assets/images/eye_off.svg' : 'assets/images/eye.svg',
                              width: 24,
                              height: 24,
                              color: Colors.grey,
                            ),
                            onPressed: () => context.read<SignInBloc>().add(TogglePasswordVisibility()),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: state.isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF983296),
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
                                  'Войти',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Забыли пароль?',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF983296),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 60),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
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
                                TextSpan(text: 'Нет аккаунта? '),
                                TextSpan(
                                  text: 'Регистрация',
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