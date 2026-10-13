import os
import re

file_path = "/Users/aminakazanbasova/Desktop/VOLO/volo/lib/add_event_page.dart"
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Imports
content = content.replace(
    "import 'services/api_service.dart';",
    "import 'services/api_service.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport 'blocs/add_event/add_event_bloc.dart';"
)

# 2. Convert AddEventPage to StatelessWidget & create _AddEventView
class_def = """class AddEventPage extends StatelessWidget {
  const AddEventPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AddEventBloc(apiService: ApiService()),
      child: const _AddEventView(),
    );
  }
}

class _AddEventView extends StatefulWidget {
  const _AddEventView({super.key});

  @override
  State<_AddEventView> createState() => _AddEventViewState();
}

class _AddEventViewState extends State<_AddEventView> {"""

content = re.sub(
    r"class AddEventPage extends StatefulWidget \{.*?(?=class _AddEventPageState extends State<AddEventPage> \{)",
    "",
    content,
    flags=re.DOTALL
)
content = content.replace("class _AddEventPageState extends State<AddEventPage> {", class_def)

# 3. Remove native state vars (we keep controllers)
state_vars_to_remove = """  final ApiService _apiService = ApiService();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Event Data
  String eventType = '';
  File? posterImage;
  String title = '';
  String description = '';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  TimeOfDay? selectedEndTime; // Added
  String location = '';
  String address = '';
  int volunteerCount = 5;
  String chatLink = '';
  List<String> responsibilities = [];
  List<String> benefits = [];"""

content = content.replace(state_vars_to_remove, "  // State is now managed by AddEventBloc")

# 4. update initState
old_init_state = """  @override
  void initState() {
    super.initState();
    // Rebuild on every change to enable/disable the "Continue" button
    _titleController.addListener(_updateState);
    _descController.addListener(_updateState);
    _addressController.addListener(_updateState);
    _chatController.addListener(_updateState);
  }

  void _updateState() {
    if (mounted) setState(() {});
  }"""

new_init_state = """  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => context.read<AddEventBloc>().add(UpdateEventData(title: _titleController.text)));
    _descController.addListener(() => context.read<AddEventBloc>().add(UpdateEventData(description: _descController.text)));
    _addressController.addListener(() => context.read<AddEventBloc>().add(UpdateEventData(address: _addressController.text)));
    _chatController.addListener(() => context.read<AddEventBloc>().add(UpdateEventData(chatLink: _chatController.text)));
  }"""

content = content.replace(old_init_state, new_init_state)

# 5. refactor _nextPage & _previousPage
old_next_prev = """  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _publishEvent();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    } else {
      Navigator.pop(context);
    }
  }"""

new_next_prev = """  void _nextPage(AddEventState state) {
    if (state.currentPage < state.totalPages - 1) {
      context.read<AddEventBloc>().add(NextStepEvent());
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<AddEventBloc>().add(PublishEvent());
    }
  }

  void _previousPage(AddEventState state) {
    if (state.currentPage > 0) {
      context.read<AddEventBloc>().add(PreviousStepEvent());
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }"""

content = content.replace(old_next_prev, new_next_prev)

# 6. completely remove _publishEvent & _isStepValid since it's in bloc
content = re.sub(r"  Future<void> _publishEvent\(\) async \{.*?(?=  void _showSuccessDialog\(\) \{)", "", content, flags=re.DOTALL)
content = re.sub(r"  bool _isStepValid\(\) \{.*?(?=  Future<void> _pickImage\(\) async \{)", "", content, flags=re.DOTALL)

# 7. adjust _pickImage
old_pick_image = """  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() => posterImage = File(result.files.single.path!));
    }
  }"""

new_pick_image = """  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      if (mounted) context.read<AddEventBloc>().add(UpdateEventData(posterImage: File(result.files.single.path!)));
    }
  }"""
content = content.replace(old_pick_image, new_pick_image)

# 8. wrap build scaffold inside BlocConsumer 
old_build = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""

new_build = """  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddEventBloc, AddEventState>(
      listener: (context, state) {
        if (state.isLoading) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32)),
                child: const CircularProgressIndicator(color: Color(0xFF983296), strokeWidth: 3),
              ),
            ),
          );
        } else {
          // If a dialog is open (like loading), close it
          if (Navigator.canPop(context) && state.isLoading == false) {
             // We pop but wait, managing dialogs via pure BlocListener is a bit tricky, better to just pop if we succeed
          }
        }

        if (state.isSuccess) {
          Navigator.pop(context); // Close loading
          _showSuccessDialog();
        } else if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
           Navigator.pop(context); // Close loading
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text('Ошибка: ${state.errorMessage}', style: GoogleFonts.poppins()),
               backgroundColor: Colors.redAccent,
               behavior: SnackBarBehavior.floating,
             ),
           );
        }
      },
      builder: (context, state) {
        return Scaffold("""
content = content.replace(old_build, new_build)

# wrap end of Scaffold
content = content.replace("    );\n  }\n\n  Widget _buildHeader", "    );\n      },\n    );\n  }\n\n  Widget _buildHeader")

# 9. modify UI methods to accept 'state' to read values instead of widget props
content = content.replace("Widget _buildHeader() {", "Widget _buildHeader(AddEventState state) {")
content = content.replace("Widget _buildBottomBar() {", "Widget _buildBottomBar(AddEventState state) {")
content = content.replace("Widget _buildStep1Category() {", "Widget _buildStep1Category(AddEventState state) {")
content = content.replace("Widget _buildStep2Image() {", "Widget _buildStep2Image(AddEventState state) {")
content = content.replace("Widget _buildStep3Info() {", "Widget _buildStep3Info(AddEventState state) {")
content = content.replace("Widget _buildStep4DateTime() {", "Widget _buildStep4DateTime(AddEventState state) {")
content = content.replace("Widget _buildStep5Volunteers() {", "Widget _buildStep5Volunteers(AddEventState state) {")
content = content.replace("Widget _buildStep6Review() {", "Widget _buildStep6Review(AddEventState state) {")
content = content.replace("Widget _buildReviewCard() {", "Widget _buildReviewCard(AddEventState state) {")
content = content.replace("Widget _buildDropdownField() {", "Widget _buildDropdownField(AddEventState state) {")
content = content.replace("Widget _buildCounter() {", "Widget _buildCounter(AddEventState state) {")

content = content.replace("_buildHeader(),", "_buildHeader(state),")
content = content.replace("_buildBottomBar(),", "_buildBottomBar(state),")
content = content.replace("_buildStep1Category(),", "_buildStep1Category(state),")
content = content.replace("_buildStep2Image(),", "_buildStep2Image(state),")
content = content.replace("_buildStep3Info(),", "_buildStep3Info(state),")
content = content.replace("_buildStep4DateTime(),", "_buildStep4DateTime(state),")
content = content.replace("_buildStep5Volunteers(),", "_buildStep5Volunteers(state),")
content = content.replace("_buildStep6Review(),", "_buildStep6Review(state),")
content = content.replace("_buildReviewCard(),", "_buildReviewCard(state),")
content = content.replace("_buildDropdownField(),", "_buildDropdownField(state),")
content = content.replace("_buildCounter(),", "_buildCounter(state),")

# replace references inside UI to use state
content = re.sub(r"(?<!\w)_currentPage", "state.currentPage", content)
content = re.sub(r"(?<!\w)_totalPages", "state.totalPages", content)

content = content.replace("setState(() => _currentPage = index);", "/* handled by bloc if needed, but tap to jump step disabled to avoid skipping */")

content = content.replace("_previousPage,", "() => _previousPage(state),")
content = content.replace("_nextPage : null", "() => _nextPage(state) : null")
content = content.replace("_isStepValid()", "state.isCurrentStepValid")


content = content.replace("eventType.isNotEmpty", "state.eventType.isNotEmpty")
content = content.replace("eventType = cat;", "context.read<AddEventBloc>().add(UpdateEventData(eventType: cat));")
content = content.replace("eventType == cat", "state.eventType == cat")
content = content.replace("eventType,", "state.eventType,")

content = content.replace("posterImage", "state.posterImage")
content = content.replace("selectedDate", "state.selectedDate")
content = content.replace("selectedTime", "state.selectedTime")
content = content.replace("selectedEndTime", "state.selectedEndTime")
content = content.replace("location", "state.location")

content = content.replace("setState(() => state.selectedDate = date);", "context.read<AddEventBloc>().add(UpdateEventData(selectedDate: date));")
content = content.replace("setState(() => state.selectedTime = time);", "context.read<AddEventBloc>().add(UpdateEventData(selectedTime: time));")
content = content.replace("setState(() => state.selectedEndTime = time);", "context.read<AddEventBloc>().add(UpdateEventData(selectedEndTime: time));")
content = content.replace("setState(() => state.location = val!);", "context.read<AddEventBloc>().add(UpdateEventData(location: val!));")

content = content.replace("volunteerCount", "state.volunteerCount")
content = content.replace("setState(() => state.volunteerCount--);", "context.read<AddEventBloc>().add(UpdateEventData(volunteerCount: state.volunteerCount - 1));")
content = content.replace("setState(() => state.volunteerCount++);", "context.read<AddEventBloc>().add(UpdateEventData(volunteerCount: state.volunteerCount + 1));")

content = content.replace("responsibilities.isNotEmpty", "state.responsibilities.isNotEmpty")
content = content.replace("responsibilities.join", "state.responsibilities.join")
content = content.replace("benefits.join", "state.benefits.join")

content = content.replace("Widget _buildChipCloud(List<String> options, List<String> selections)", "Widget _buildChipCloud(List<String> options, List<String> selections, bool isResponsibilities)")
content = content.replace("_buildChipCloud(responsibilityOptions, state.responsibilities)", "_buildChipCloud(responsibilityOptions, state.responsibilities, true)")
content = content.replace("_buildChipCloud(benefitOptions, state.benefits)", "_buildChipCloud(benefitOptions, state.benefits, false)")

chip_old = """            setState(() {
              if (isSelected) selections.remove(opt);
              else selections.add(opt);
            });"""
chip_new = """            List<String> newSelections = List.from(selections);
            if (isSelected) newSelections.remove(opt);
            else newSelections.add(opt);
            if (isResponsibilities) {
              context.read<AddEventBloc>().add(UpdateEventData(responsibilities: newSelections));
            } else {
              context.read<AddEventBloc>().add(UpdateEventData(benefits: newSelections));
            }"""
content = content.replace(chip_old, chip_new)


with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)
