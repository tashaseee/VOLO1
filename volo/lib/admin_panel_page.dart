import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
            leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF983296), size: 20), onPressed: () => Navigator.pop(context)),
            actions: [
              IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF983296)), onPressed: () => context.read<AdminBloc>().add(LoadPendingOrgs())),
            ],
          ),
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
              : RefreshIndicator(
                  onRefresh: () async => context.read<AdminBloc>().add(LoadPendingOrgs()),
                  color: const Color(0xFF983296),
                  child: CustomScrollView(slivers: [
                    SliverToBoxAdapter(
                      child: Padding(padding: const EdgeInsets.all(24.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Новые заявки', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26))),
                        const SizedBox(height: 8),
                        Text('У вас ${state.pendingOrgs.length} ожидающих подтверждения организаций', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[500])),
                        const SizedBox(height: 12),
                        Container(height: 4, width: 60, decoration: BoxDecoration(color: const Color(0xFF983296), borderRadius: BorderRadius.circular(2))),
                      ])),
                    ),
                    if (state.pendingOrgs.isEmpty)
                      SliverFillRemaining(child: _buildEmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(delegate: SliverChildBuilderDelegate((context, index) => _buildOrgCard(context, state.pendingOrgs[index]), childCount: state.pendingOrgs.length)),
                      ),
                    const SliverToBoxAdapter(child: SizedBox(height: 40)),
                  ]),
                ),
        );
      },
    );
  }

  Widget _buildEmptyState() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
      child: Icon(Icons.check_circle_outline_rounded, size: 64, color: Colors.grey[300])),
    const SizedBox(height: 24),
    Text('Все заявки обработаны', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.grey[400])),
    const SizedBox(height: 8),
    Text('Новых организаций пока нет', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[400])),
  ]);

  Widget _buildOrgCard(BuildContext context, dynamic org) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(20), child: Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFF983296).withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.business_rounded, color: Color(0xFF983296), size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(org['org_name'] ?? 'Без названия', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('БИН: ${org['bin']}', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF983296))),
          ])),
          IconButton(icon: const Icon(Icons.info_outline_rounded, color: Colors.grey), onPressed: () => _showOrgDetails(context, org)),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(color: Colors.grey[50], borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20))),
          child: Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: () => context.read<AdminBloc>().add(ApproveOrg(org['id'], org['email'])),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF983296), foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(vertical: 12)),
              child: Text('ОДОБРИТЬ', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
            )),
          ]),
        ),
      ]),
    );
  }

  void _showOrgDetails(BuildContext context, dynamic org) {
    showModalBottomSheet(context: context, backgroundColor: Colors.white, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (_) => Container(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        SizedBox(width: double.infinity, height: 56,
          child: ElevatedButton(
            onPressed: () { Navigator.pop(context); context.read<AdminBloc>().add(ApproveOrg(org['id'], org['email'])); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF983296), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text('ОДОБРИТЬ СЕЙЧАС', style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.white)),
          )),
        const SizedBox(height: 16),
      ])),
    );
  }

  Widget _detailItem(String label, String? value) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1)),
      const SizedBox(height: 6),
      Text(value ?? 'Не указано', style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26))),
    ]),
  );
}
