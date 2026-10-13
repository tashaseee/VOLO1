import os
import re

file_path = '/Users/aminakazanbasova/Desktop/VOLO/volo/lib/user_info_onboarding_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Imports
text = text.replace("import 'services/api_service.dart';", "import 'services/api_service.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport 'blocs/onboarding/user_onboarding_bloc.dart';")

# 2. Class definition
class_def = """class UserInfoOnboardingPage extends StatelessWidget {
  const UserInfoOnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => UserOnboardingBloc(apiService: ApiService()),
      child: const _UserInfoOnboardingView(),
    );
  }
}

class _UserInfoOnboardingView extends StatefulWidget {
  const _UserInfoOnboardingView();

  @override
  State<_UserInfoOnboardingView> createState() => _UserInfoOnboardingViewState();
}

class _UserInfoOnboardingViewState extends State<_UserInfoOnboardingView>
    with TickerProviderStateMixin {"""
text = re.sub(
    r"class UserInfoOnboardingPage extends StatefulWidget \{.*?(?=class _UserInfoOnboardingPageState extends State<UserInfoOnboardingPage>\s*with TickerProviderStateMixin \{)",
    "",
    text,
    flags=re.DOTALL
)
text = text.replace("class _UserInfoOnboardingPageState extends State<UserInfoOnboardingPage>\n    with TickerProviderStateMixin {", class_def)
text = text.replace("class _UserInfoOnboardingPageState extends State<UserInfoOnboardingPage> with TickerProviderStateMixin {", class_def)

# 3. Handle complete onboarding
complete_regex = r"  void _completeOnboarding\(\) async \{.*?(?=  void _showError\(String message\))"
new_complete = """  void _completeOnboarding() {
    context.read<UserOnboardingBloc>().add(UpdateField('firstName', firstName));
    context.read<UserOnboardingBloc>().add(UpdateField('lastName', lastName));
    if (birthDate != null) context.read<UserOnboardingBloc>().add(UpdateField('birthDate', birthDate));
    context.read<UserOnboardingBloc>().add(UpdateField('gender', gender));
    context.read<UserOnboardingBloc>().add(UpdateField('city', city));
    context.read<UserOnboardingBloc>().add(UpdateField('phone', phone));
    for(var item in interests) context.read<UserOnboardingBloc>().add(ToggleListField('interests', item));
    for(var item in skills) context.read<UserOnboardingBloc>().add(ToggleListField('skills', item));
    context.read<UserOnboardingBloc>().add(UpdateField('experience', experience));
    context.read<UserOnboardingBloc>().add(UpdateField('motivation', motivation));
    context.read<UserOnboardingBloc>().add(SubmitOnboarding());
  }\n\n"""
text = re.sub(complete_regex, new_complete, text, flags=re.DOTALL)

# 4. Remove variables
text = text.replace("  final ApiService _apiService = ApiService();\n", "")
text = text.replace("  bool _isLoading = false;\n", "")

# 5. Build function wrap
build_old = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""

build_new = """  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UserOnboardingBloc, UserOnboardingState>(
    listener: (context, state) {
      if (state.errorMessage != null) {
        _showError(state.errorMessage!);
      }
      if (state.isSuccess) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const WelcomeAnimationPage()),
        );
      }
    },
    builder: (context, state) {
      final isLoading = state.isSubmitting;
      return Scaffold("""
text = text.replace(build_old, build_new)

text = text.replace("_isLoading", "isLoading")

last_brace_index = text.rfind("}")
if last_brace_index != -1:
    text = text[:last_brace_index] + "      },\n    );\n  }\n}"

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)
