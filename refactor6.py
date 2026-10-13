import os
import re

file_path = '/Users/aminakazanbasova/Desktop/VOLO/volo/lib/profile_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Imports
text = text.replace("import 'login_page.dart';", "import 'login_page.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport 'blocs/profile/profile_bloc.dart';")

# 2. Class Signature
class_def = """class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProfileBloc(apiService: ApiService())..add(LoadProfile()),
      child: const _ProfilePageView(),
    );
  }
}

class _ProfilePageView extends StatefulWidget {
  const _ProfilePageView();

  @override
  State<_ProfilePageView> createState() => _ProfilePageViewState();
}

class _ProfilePageViewState extends State<_ProfilePageView> {"""
text = re.sub(
    r"class ProfilePage extends StatefulWidget \{.*?(?=class _ProfilePageState extends State<ProfilePage> \{)",
    "",
    text,
    flags=re.DOTALL
)
text = text.replace("class _ProfilePageState extends State<ProfilePage> {", class_def)

# 3. Variables & Api calls
vars_to_remove = """  final ApiService _apiService = ApiService();
  int _selectedIndex = 4;
  Map<String, bool> _ratedEvents = {};
  bool _isLoading = true;
  String _userName = 'Загрузка...';
  String _userCity = 'Загрузка...';
  int _voloHours = 0;
  int _eventsDone = 0;
  int _ecoScore = 0;
  int _socialScore = 0;
  int _sportScore = 0;
  List<dynamic> _certificates = [];
  List<dynamic> _activeEvents = []; 
  List<dynamic> _plannedEvents = [];
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();"""

text = text.replace(vars_to_remove, "  int _selectedIndex = 4;\n  final ImagePicker _picker = ImagePicker();\n  final ApiService _apiService = ApiService();")

# 4. Remove init state methods
methods_to_remove = r"  @override\s+void initState\(\).*?(?=  Future<void> _pickAndUploadImage\(\) async \{)"
text = re.sub(methods_to_remove, "", text, flags=re.DOTALL)

# 5. Fix pick image
pick_image_old = r"  Future<void> _pickAndUploadImage\(\) async \{.*?(?=\s+@override\n  Widget build\(BuildContext context\) \{)"
pick_image_new = """  Future<void> _pickAndUploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    if (mounted) {
      context.read<ProfileBloc>().add(UpdateAvatar(image.path));
    }
  }
"""
text = re.sub(pick_image_old, pick_image_new, text, flags=re.DOTALL)

# 6. Build method start
build_old = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""
build_new = """  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold("""
text = text.replace(build_old, build_new)

# Variables replacements
text = text.replace("_avatarUrl", "state.avatarUrl")
text = text.replace("_userName", "state.userName")
text = text.replace("_userCity", "state.userCity")
text = text.replace("_voloHours", "state.voloHours")
text = text.replace("_eventsDone", "state.eventsDone")
text = text.replace("_ecoScore", "state.ecoScore")
text = text.replace("_sportScore", "state.sportScore")
text = text.replace("_socialScore", "state.socialScore")
text = text.replace("_activeEvents", "state.activeEvents")
text = text.replace("_plannedEvents", "state.plannedEvents")
text = text.replace("_certificates", "state.certificates")

# Certificate handler
cert_method_old = r"  void _handleCertificate\(String eventName, String organizer, String date\) \{.*?  \}"
cert_method_new = """  void _handleCertificate(String eventName, String organizer, String date) {
    final eventKey = '$eventName-$organizer';
    final rated = context.read<ProfileBloc>().state.ratedEvents[eventKey] == true;
    if (rated) {
      _showCertificateDialog(eventName, organizer, date);
    } else {
      _showRatingDialog(eventName, organizer, date, eventKey);
    }
  }"""
text = re.sub(cert_method_old, cert_method_new, text, flags=re.DOTALL)

# Rating dialog replace setState
rating_set_state = """                            setState(() {
                              _ratedEvents[eventKey] = true;
                            });"""
rating_bloc = """                            context.read<ProfileBloc>().add(RateEvent(eventKey));"""
text = text.replace(rating_set_state, rating_bloc)

# Finally, append bracket back to close BlocBuilder at the very end
# Looking for the last `}`
last_brace_index = text.rfind("}")
if last_brace_index != -1:
    text = text[:last_brace_index] + "      },\n    );\n  }\n}"

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)
