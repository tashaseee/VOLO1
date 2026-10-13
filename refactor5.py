import os
import re

file_path = '/Users/aminakazanbasova/Desktop/VOLO/volo/lib/organizer_event_applications_page.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Imports
text = text.replace("import 'volunteer_profile_details_page.dart';", "import 'volunteer_profile_details_page.dart';\nimport 'package:flutter_bloc/flutter_bloc.dart';\nimport 'blocs/organizer_event_applications/organizer_event_applications_bloc.dart';")

# 2. Class Signature
class_def = """class OrganizerEventApplicationsPage extends StatelessWidget {
  final int eventId;
  final String eventTitle;

  const OrganizerEventApplicationsPage({
    super.key,
    required this.eventId,
    required this.eventTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrganizerEventAppsBloc(apiService: ApiService())..add(LoadEventApps(eventId)),
      child: _OrganizerEventApplicationsView(eventId: eventId, eventTitle: eventTitle),
    );
  }
}

class _OrganizerEventApplicationsView extends StatefulWidget {
  final int eventId;
  final String eventTitle;

  const _OrganizerEventApplicationsView({
    required this.eventId,
    required this.eventTitle,
  });

  @override
  State<_OrganizerEventApplicationsView> createState() => _OrganizerEventApplicationsViewState();
}

class _OrganizerEventApplicationsViewState extends State<_OrganizerEventApplicationsView> with SingleTickerProviderStateMixin {"""
text = re.sub(
    r"class OrganizerEventApplicationsPage extends StatefulWidget \{.*?(?=class _OrganizerEventApplicationsPageState extends State<OrganizerEventApplicationsPage> with SingleTickerProviderStateMixin \{)",
    "",
    text,
    flags=re.DOTALL
)
text = text.replace("class _OrganizerEventApplicationsPageState extends State<OrganizerEventApplicationsPage> with SingleTickerProviderStateMixin {", class_def)

# 3. Variables
vars_to_remove = """  final ApiService _apiService = ApiService();
  List<dynamic> _applications = [];
  Map<String, dynamic>? _event;
  bool _isLoading = true;
"""
text = text.replace(vars_to_remove, "")

# 4. _loadApplications
load_apps_old = r"  Future<void> _loadApplications\(\) async \{.*?(?=  Future<void> _updateStatus)"
load_apps_new = """  Future<void> _loadApplications() async {
    context.read<OrganizerEventAppsBloc>().add(LoadEventApps(widget.eventId));
  }\n\n"""
text = re.sub(load_apps_old, load_apps_new, text, flags=re.DOTALL)

# 5. _updateStatus
update_status_old = r"  Future<void> _updateStatus\(\w+ applicationId, String status, \{Map<String, dynamic>\? app\}\) async \{.*?(?=  Future<void> _finishEvent)"
update_status_new = """  Future<void> _updateStatus(int applicationId, String status, {Map<String, dynamic>? app}) async {
    context.read<OrganizerEventAppsBloc>().add(UpdateAppStatus(
      eventId: widget.eventId,
      applicationId: applicationId,
      status: status,
      appData: app,
    ));
  }\n\n"""
text = re.sub(update_status_old, update_status_new, text, flags=re.DOTALL)

# 6. _finishEvent
finish_event_old = r"  Future<void> _finishEvent\(\) async \{.*?(?=  void _showAcceptanceDialog)"
finish_event_new = """  Future<void> _finishEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Завершить ивент?', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text(
          'Это действие начислит часы всем принятым волонтерам и закроет возможность подачи заявок. Вы уверены?',
          style: GoogleFonts.poppins(),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Отмена', style: GoogleFonts.poppins(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Завершить', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      context.read<OrganizerEventAppsBloc>().add(FinishEvent(widget.eventId));
    }
  }\n\n"""
text = re.sub(finish_event_old, finish_event_new, text, flags=re.DOTALL)

# 7. Acceptance Dialog Params
text = text.replace("void _showAcceptanceDialog(Map<String, dynamic>? user) {", "void _showAcceptanceDialog(Map<String, dynamic>? user, Map<String, dynamic>? event) {")
text = text.replace("_event?['chat_link']", "event?['chat_link']")

# 8. Remove Getters
text = text.replace("List<dynamic> get pendingApplications =>\n      _applications.where((a) => a['status'] == 'pending').toList();", "")
text = text.replace("List<dynamic> get approvedApplications =>\n      _applications.where((a) => a['status'] == 'approved').toList();", "")
text = text.replace("List<dynamic> get rejectedApplications =>\n      _applications.where((a) => a['status'] == 'rejected').toList();", "")

# 9. Build method refactor
old_build = """  @override
  Widget build(BuildContext context) {
    return Scaffold("""
new_build = """  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizerEventAppsBloc, OrganizerEventAppsState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          _showErrorSnackBar(state.errorMessage!);
        } else if (state.isSuccessAction && state.successMessage != null) {
          _showSuccessSnackBar(state.successMessage!, Colors.green);
        }
        if (state.showAcceptanceDialog && state.acceptedUser != null) {
          _showAcceptanceDialog(state.acceptedUser, state.event);
        }
      },
      builder: (context, state) {
        final pendingApplications = state.applications.where((a) => a['status'] == 'pending').toList();
        final approvedApplications = state.applications.where((a) => a['status'] == 'approved').toList();
        final rejectedApplications = state.applications.where((a) => a['status'] == 'rejected').toList();

        return Scaffold("""
text = text.replace(old_build, new_build)

text = text.replace("                _buildTabSection(),", "                _buildTabSection(pendingApplications, approvedApplications, rejectedApplications),")
text = text.replace("                  child: _isLoading\n                      ?", "                  child: state.isLoading\n                      ?")

# Close BlocConsumer properly
text = text.replace("""                  child: state.isLoading
                      ? _buildLoadingState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildApplicationsList(pendingApplications, 'pending'),
                            _buildApplicationsList(approvedApplications, 'approved'),
                            _buildApplicationsList(rejectedApplications, 'rejected'),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }""", """                  child: state.isLoading
                      ? _buildLoadingState()
                      : TabBarView(
                          controller: _tabController,
                          children: [
                            _buildApplicationsList(pendingApplications, 'pending'),
                            _buildApplicationsList(approvedApplications, 'approved'),
                            _buildApplicationsList(rejectedApplications, 'rejected'),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  },
  );
}""")

# buildTabSection definition
text = text.replace("Widget _buildTabSection() {", "Widget _buildTabSection(List pendingApplications, List approvedApplications, List rejectedApplications) {")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(text)
