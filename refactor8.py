import os
import re

file_path = '/Users/aminakazanbasova/Desktop/VOLO/volo/lib/reset_password_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Imports
text = text.replace("import 'services/api_service.dart';", "import 'services/api_service.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport 'blocs/reset_password/reset_password_bloc.dart';")

# 2. Add BlocProvider wrapper
class_def = """class ResetPasswordPage extends StatelessWidget {
  final String email;
  const ResetPasswordPage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ResetPasswordBloc(apiService: ApiService()),
      child: ResetPasswordView(email: email),
    );
  }
}

class ResetPasswordView extends StatefulWidget {
  final String email;
  const ResetPasswordView({super.key, required this.email});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
"""

text = re.sub(
    r"class ResetPasswordPage extends StatefulWidget \{.*?(?=class _ResetPasswordPageState extends State<ResetPasswordPage> \{)",
    "",
    text,
    flags=re.DOTALL
)
text = text.replace("class _ResetPasswordPageState extends State<ResetPasswordPage> {\n", class_def)

# 3. Remove local state we moved to BLoC
text = re.sub(r"  final ApiService _apiService = ApiService\(\);\n", "", text)
text = re.sub(r"  bool _isLoading = false;\n", "", text)
text = re.sub(r"  bool _showPassword = false;\n", "", text)
text = re.sub(r"  bool _showConfirm = false;\n", "", text)

# 4. Refactor _resendCode
resend_old = """  Future<void> _resendCode() async {
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
  }"""
resend_new = """  void _resendCode() {
    if (!_canResend) return;
    context.read<ResetPasswordBloc>().add(ResendCodeRequested(widget.email));
    _startResendTimer();
  }"""
text = text.replace(resend_old, resend_new)

# 5. Refactor _reset
reset_old = """  Future<void> _reset() async {
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
  }"""
reset_new = """  void _reset() {
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

    context.read<ResetPasswordBloc>().add(ResetPasswordRequested(
      widget.email, 
      _codeController.text, 
      _passwordController.text
    ));
  }"""
text = text.replace(reset_old, reset_new)

# 6. Wrap build
build_old = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""
build_new = """  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ResetPasswordBloc, ResetPasswordState>(
      listener: (context, state) {
        if (state.errorMessage != null) _showError(state.errorMessage!);
        if (state.successMessage != null) _showSuccess(state.successMessage!);
        if (state.isSuccess) {
          Future.delayed(const Duration(seconds: 1), () {
            if (!mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SignInPage()),
              (route) => false,
            );
          });
        }
      },
      builder: (context, state) {
        return Scaffold("""
text = text.replace(build_old, build_new)

# Fix variables
text = text.replace("_isLoading", "state.isLoading")
text = text.replace("_showPassword", "state.showPassword")
text = text.replace("_showConfirm", "state.showConfirmPassword")

# Fix _buildPasswordField
text = re.sub(
    r"onVisibilityChanged: \(\) => setState\(\(\) => .*? = !.*?\)?,",
    "",
    text
)
fix_pass_toggle = """              _buildPasswordField(
                controller: _passwordController,
                hint: "Новый пароль",
                isVisible: state.showPassword,
                onVisibilityChanged: () => context.read<ResetPasswordBloc>().add(TogglePasswordVisibility()),
              ),"""
text = re.sub(r"              _buildPasswordField\(\s*controller: _passwordController,\s*hint: \"Новый пароль\",\s*isVisible: state.showPassword,\s*\),", fix_pass_toggle, text)

fix_conf_toggle = """              _buildPasswordField(
                controller: _confirmController,
                hint: "Подтвердите пароль",
                isVisible: state.showConfirmPassword,
                onVisibilityChanged: () => context.read<ResetPasswordBloc>().add(ToggleConfirmPasswordVisibility()),
              ),"""
text = re.sub(r"              _buildPasswordField\(\s*controller: _confirmController,\s*hint: \"Подтвердите пароль\",\s*isVisible: state.showConfirmPassword,\s*\),", fix_conf_toggle, text)

# Append closes
last_brace = text.rfind("}")
if last_brace != -1:
    text = text[:last_brace] + "      },\n    );\n  }\n}"

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)
