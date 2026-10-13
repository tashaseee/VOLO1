import os
import re

file_path = '/Users/aminakazanbasova/Desktop/VOLO/volo/lib/organizer_events_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add imports
text = text.replace("import 'event_reviews_page.dart';", "import 'event_reviews_page.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport 'blocs/organizer_events/organizer_events_bloc.dart';")

# 2. Change class to StatelessWidget and add BlocProvider
class_def = """class OrganizerEventsPage extends StatelessWidget {
  const OrganizerEventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrganizerEventsBloc(apiService: ApiService())..add(LoadEvents()),
      child: const _OrganizerEventsView(),
    );
  }
}

class _OrganizerEventsView extends StatefulWidget {
  const _OrganizerEventsView({super.key});

  @override
  State<_OrganizerEventsView> createState() => _OrganizerEventsViewState();
}

class _OrganizerEventsViewState extends State<_OrganizerEventsView> {"""

text = re.sub(
    r"class OrganizerEventsPage extends StatefulWidget \{.*?(?=class _OrganizerEventsPageState extends State<OrganizerEventsPage> \{)",
    "",
    text,
    flags=re.DOTALL
)
text = text.replace("class _OrganizerEventsPageState extends State<OrganizerEventsPage> {", class_def)

# 3. Remove state variables and api service from View logic
vars_to_remove = """  final ApiService _apiService = ApiService();
  List<dynamic> _events = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, active, inactive
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';"""

vars_to_keep = """  final TextEditingController _searchController = TextEditingController();"""
text = text.replace(vars_to_remove, vars_to_keep)

# 4. Remove initState and _loadEvents() & getters since they are in Bloc
text = re.sub(r"  @override\s+void initState\(\).*?(?=  Future<void> _showFinishDialog)", "", text, flags=re.DOTALL)

# Add back _loadEvents (just to dispatch) since refresh indicator needs it
refresh_method = """
  Future<void> _loadEvents() async {
    context.read<OrganizerEventsBloc>().add(LoadEvents());
  }

  Future<void> _toggleStatus(int eventId) async {
    context.read<OrganizerEventsBloc>().add(ToggleEventStatusEvent(eventId));
  }

  Future<void> _finishEvent(int eventId) async {
    context.read<OrganizerEventsBloc>().add(FinishEventEvent(eventId));
  }
"""
text = text.replace("  Future<void> _showFinishDialog", refresh_method + "\n  Future<void> _showFinishDialog")

# remove _showSuccessSnackBar and _showErrorSnackBar because BLoC handles it?
# Actually, BLoC emits isSuccessAction, the Consumer will handle it.

# 5. Fix build method
old_build = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""

new_build = """  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizerEventsBloc, OrganizerEventsState>(
      listener: (context, state) {
        if (state.isSuccessAction && state.successMessage != null) {
          _showSuccessSnackBar(state.successMessage!, const Color(0xFF00BFA5));
        } else if (state.errorMessage != null) {
          _showErrorSnackBar(state.errorMessage!);
        }
      },
      builder: (context, state) {
        return Scaffold("""
text = text.replace(old_build, new_build)

text = text.replace("floatingActionButton: _isLoading ? null : _buildFAB(),\n    );", "floatingActionButton: state.isLoading ? null : _buildFAB(),\n        );\n      },\n    );")

# 6. Replace references to state variables
text = text.replace("_isLoading", "state.isLoading")
text = text.replace("filteredEvents", "state.filteredEvents")
text = text.replace("_filter = f['value']!", "context.read<OrganizerEventsBloc>().add(UpdateFilter(f['value']!))")
text = text.replace("setState(() => _searchQuery = value)", "context.read<OrganizerEventsBloc>().add(UpdateSearchQuery(value))")
text = text.replace("setState(() => _searchQuery = '')", "context.read<OrganizerEventsBloc>().add(UpdateSearchQuery(''))")

text = text.replace("final isSelected = _filter ==", "final isSelected = state.filter ==")
text = text.replace("_searchQuery.isNotEmpty", "state.searchQuery.isNotEmpty")

# 7. Update UI methods to accept state
text = text.replace("Widget _buildFilters()", "Widget _buildFilters(OrganizerEventsState state)")
text = text.replace("Widget _buildSearchBar()", "Widget _buildSearchBar(OrganizerEventsState state)")

text = text.replace("_buildFilters(),", "_buildFilters(state),")
text = text.replace("_buildSearchBar(),", "_buildSearchBar(state),")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)
