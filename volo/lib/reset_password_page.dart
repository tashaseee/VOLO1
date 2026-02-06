import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'services/api_service.dart';
import 'sign_in_page.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  bool _canResend = false;
  int _timerSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _canResend = false;
      _timerSeconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerSeconds > 0) {
        setState(() => _timerSeconds--);
      } else {
        _timer?.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  Future<void> _resendCode() async {
    if (!_canResend) return;

    setState(() => _isLoading = true);
    final result = await _apiService.forgotPassword(widget.email);
    setState(() => _isLoading = false);

    if (result['success']) {
      _showSuccess('Код отправлен повторно');
      _startResendTimer();
    } else {
      _showError(result['message']);
    }
  }

  bool get _passwordsMatch => 
      _passwordController.text.isNotEmpty && 
      _passwordController.text == _confirmController.text;

  Future<void> _reset() async {
    if (_codeController.text.length != 6) {
      _showError('Введите корректный 6-значный код');
      return;
    }
    if (!_passwordsMatch) {
      _showError('Пароли не совпадают');
      return;
    }
    
    final pass = _passwordController.text;
    if (pass.length < 8 || !pass.contains(RegExp(r'[0-9]')) || !pass.contains(RegExp(r'[A-Z]'))) {
       _showError('Пароль не соответствует требованиям');
       return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.resetPassword(
      widget.email, 
      _codeController.text, 
      _passwordController.text
    );
    setState(() => _isLoading = false);

    if (result['success']) {
      if (!mounted) return;
      _showSuccess('Пароль успешно изменен');
      
      await Future.delayed(const Duration(seconds: 1));
      
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignInPage()),
        (route) => false,
      );
    } else {
      _showError(result['message']);
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
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF4CAF50),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/images/left.svg', 
            width: 24, 
            height: 24,
            colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Text(
                'Сброс пароля',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Введите код, отправленный на ${widget.email}',
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 40),
              
              // Code Input Section
              Text(
                "Код подтверждения",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(letterSpacing: 8, fontSize: 20, fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  hintText: '••••••',
                  hintStyle: GoogleFonts.poppins(letterSpacing: 8, fontSize: 20, color: Colors.grey[300]),
                  counterText: "",
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFF983296), width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              
              const SizedBox(height: 16),
              Center(
                child: _canResend
                  ? TextButton(
                      onPressed: _isLoading ? null : _resendCode,
                      child: Text(
                        "Отправить код повторно",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF983296),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Text(
                      "Отправить повторно через $_timerSeconds сек",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 32),

              // New Password Section
              Text(
                "Придумайте новый пароль",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const SizedBox(height: 8),
              _buildPasswordField(
                controller: _passwordController,
                hint: "Новый пароль",
                isVisible: _showPassword,
                onVisibilityChanged: () => setState(() => _showPassword = !_showPassword),
              ),
              const SizedBox(height: 16),
              
              _buildPasswordField(
                controller: _confirmController,
                hint: "Подтвердите пароль",
                isVisible: _showConfirm,
                onVisibilityChanged: () => setState(() => _showConfirm = !_showConfirm),
              ),

              const SizedBox(height: 20),
              
              // Clean Password Requirements
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                   _buildCleanRequirement('8+ символов', _passwordController.text.length >= 8),
                   _buildCleanRequirement('Цифра', _passwordController.text.contains(RegExp(r'[0-9]'))),
                   _buildCleanRequirement('A-Z', _passwordController.text.contains(RegExp(r'[A-Z]'))),
                   _buildCleanRequirement('Совпадение', _passwordsMatch && _passwordController.text.isNotEmpty),
                ],
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _reset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF983296),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24, 
                          width: 24, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Text(
                          'Сменить пароль',
                          style: GoogleFonts.poppins(
                              fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool isVisible,
    required VoidCallback onVisibilityChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: !isVisible,
      onChanged: (_) => setState(() {}),
      style: GoogleFonts.poppins(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
        filled: true,
        fillColor: Colors.grey[50],
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: SvgPicture.asset(
            'assets/images/password.svg', 
            width: 24, height: 24,
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn)
          ),
        ),
        suffixIcon: IconButton(
          icon: SvgPicture.asset(
            isVisible ? 'assets/images/eye.svg' : 'assets/images/eye_off.svg',
            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.srcIn),
          ),
          onPressed: onVisibilityChanged,
        ),
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
          borderSide: const BorderSide(color: Color(0xFF983296), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
}
