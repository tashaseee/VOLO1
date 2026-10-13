import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'blocs/admin/admin_bloc.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AdminBloc(apiService: ApiService())..add(LoadPendingOrgs()),
      child: const _AdminPanelView(),
    );
  }
}

class _AdminPanelView extends StatelessWidget {
  const _AdminPanelView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AdminBloc, AdminState>(
      listener: (context, state) {
        if (state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.message!, style: GoogleFonts.poppins()),
            backgroundColor: state.isError ? Colors.red : const Color(0xFF983296),
            behavior: SnackBarBehavior.floating,
          ));
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: Text('МОДЕРАЦИЯ', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.black)),
            centerTitle: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF983296), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF983296)),
                onPressed: () {
                  if (state.activeTab == 0) {
                    context.read<AdminBloc>().add(LoadPendingOrgs());
                  } else {
                    context.read<AdminBloc>().add(LoadSupportRequests());
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Premium Segment Selector
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.read<AdminBloc>().add(SwitchAdminTab(0)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: state.activeTab == 0 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: state.activeTab == 0
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Text(
                            'Заявки организаций',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: state.activeTab == 0 ? FontWeight.w700 : FontWeight.w500,
                              color: state.activeTab == 0 ? const Color(0xFF983296) : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => context.read<AdminBloc>().add(SwitchAdminTab(1)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: state.activeTab == 1 ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: state.activeTab == 1
                                ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]
                                : null,
                          ),
                          child: Text(
                            'Техподдержка',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: state.activeTab == 1 ? FontWeight.w700 : FontWeight.w500,
                              color: state.activeTab == 1 ? const Color(0xFF983296) : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (state.activeTab == 0) {
                            context.read<AdminBloc>().add(LoadPendingOrgs());
                          } else {
                            context.read<AdminBloc>().add(LoadSupportRequests());
                          }
                        },
                        color: const Color(0xFF983296),
                        child: state.activeTab == 0
                            ? _buildOrgsSection(context, state)
                            : _buildSupportSection(context, state),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrgsSection(BuildContext context, AdminState state) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Новые заявки', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26))),
                const SizedBox(height: 8),
                Text('У вас ${state.pendingOrgs.length} ожидающих подтверждения организаций', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 12),
                Container(height: 4, width: 60, decoration: BoxDecoration(color: const Color(0xFF983296), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
        ),
        if (state.pendingOrgs.isEmpty)
          SliverFillRemaining(child: _buildEmptyState('Все заявки обработаны', 'Новых организаций пока нет'))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildOrgCard(context, state.pendingOrgs[index]),
                childCount: state.pendingOrgs.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildSupportSection(BuildContext context, AdminState state) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Техподдержка', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26))),
                const SizedBox(height: 8),
                Text('Всего обращений: ${state.supportRequests.length}', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
                const SizedBox(height: 12),
                Container(height: 4, width: 60, decoration: BoxDecoration(color: const Color(0xFF983296), borderRadius: BorderRadius.circular(2))),
              ],
            ),
          ),
        ),
        if (state.supportRequests.isEmpty)
          SliverFillRemaining(child: _buildEmptyState('Нет запросов', 'Запросов в техподдержку пока нет'))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSupportCard(context, state.supportRequests[index]),
                childCount: state.supportRequests.length,
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
            child: Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey[300]),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[400]),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400]),
          ),
        ],
      );

  Widget _buildOrgCard(BuildContext context, dynamic org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(color: const Color(0xFF983296).withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.business_rounded, color: Color(0xFF983296), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        org['org_name'] ?? 'Без названия',
                        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'БИН: ${org['bin']}',
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF983296)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.grey),
                  onPressed: () => _showOrgDetails(context, org),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.read<AdminBloc>().add(ApproveOrg(org['id'], org['email'])),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF983296),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('ОДОБРИТЬ', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard(BuildContext context, dynamic ticket) {
    final isResolved = ticket['status'] == 'resolved';
    final hasReply = ticket['reply'] != null && (ticket['reply'] as String).isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isResolved ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isResolved ? 'Отвечено' : 'Ожидает ответа',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isResolved ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDate(ticket['created_at']),
                      style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ticket['user_name'] ?? 'Пользователь',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26)),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 28.0),
                  child: Text(
                    ticket['user_email'] ?? '',
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[500]),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Вопрос:',
                  style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[400]),
                ),
                const SizedBox(height: 4),
                Text(
                  ticket['message'] ?? '',
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
                ),
                if (hasReply) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE1BEE7)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ответ поддержки:',
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF983296)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ticket['reply']!,
                          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isResolved)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showReplyBottomSheet(context, ticket),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF983296),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('ОТВЕТИТЬ', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showOrgDetails(BuildContext context, dynamic org) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 32),
            Text('Детали организации', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26))),
            const SizedBox(height: 32),
            _detailItem('Название', org['org_name']),
            _detailItem('E-mail', org['email']),
            _detailItem('БИН', org['bin']),
            _detailItem('Телефон', org['phone']),
            _detailItem('Сайт', org['website']),
            _detailItem('Описание', org['description']),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<AdminBloc>().add(ApproveOrg(org['id'], org['email']));
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF983296), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: Text('ОДОБРИТЬ СЕЙЧАС', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showReplyBottomSheet(BuildContext context, dynamic ticket) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (bottomSheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(
                'Ответ пользователю',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26)),
              ),
              const SizedBox(height: 8),
              Text(
                'Кому: ${ticket['user_name']} (${ticket['user_email']})',
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Вопрос пользователя:',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ticket['message'] ?? '',
                      style: GoogleFonts.poppins(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: textController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Введите ваш ответ...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey[400], fontSize: 13),
                  filled: true,
                  fillColor: Colors.grey[50],
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
                    borderSide: const BorderSide(color: Color(0xFF983296), width: 1.5),
                  ),
                ),
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final replyText = textController.text.trim();
                    if (replyText.isNotEmpty) {
                      Navigator.pop(bottomSheetContext);
                      context.read<AdminBloc>().add(ReplyToSupportRequestEvent(ticket['id'], replyText));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF983296),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text(
                    'ОТПРАВИТЬ ОТВЕТ',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.white, fontSize: 14, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1)),
            const SizedBox(height: 6),
            Text(value ?? 'Не указано', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26))),
          ],
        ),
      );

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateStr).toLocal();
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$day.$month $hour:$minute';
    } catch (_) {
      return '';
    }
  }
}
