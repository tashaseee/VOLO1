import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'blocs/organizer_profile/organizer_profile_bloc.dart';
import 'profile_settings_pages.dart';

class OrganizerProfilePage extends StatelessWidget {
  const OrganizerProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OrganizerProfileBloc(apiService: ApiService())..add(LoadOrganizerProfile()),
      child: const _OrganizerProfileView(),
    );
  }
}

class _OrganizerProfileView extends StatefulWidget {
  const _OrganizerProfileView();

  @override
  State<_OrganizerProfileView> createState() => _OrganizerProfileViewState();
}

class _OrganizerProfileViewState extends State<_OrganizerProfileView> {
  final ImagePicker _picker = ImagePicker();

  final List<Map<String, dynamic>> _themes = [
    {
      'id': 'style:classic',
      'name': 'Классический',
      'desc': 'Строгий центр',
      'bg1': const Color(0xFFFFFFFF),
      'accent': const Color(0xFF983296),
      'textColor': const Color(0xFF0D0D26),
    },
    {
      'id': 'style:modern_left',
      'name': 'Асимметрия',
      'desc': 'Текст слева',
      'bg1': const Color(0xFFFAF9FC),
      'accent': const Color(0xFF983296),
      'textColor': const Color(0xFF0D0D26),
    },
    {
      'id': 'style:minimal_bottom',
      'name': 'Минимализм',
      'desc': 'Минимализм по углам',
      'bg1': const Color(0xFFFFFFFF),
      'accent': const Color(0xFF983296),
      'textColor': const Color(0xFF0D0D26),
    },
  ];

  void _showThemeSelectionBottomSheet(BuildContext context, String? currentThemeId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
      ),
      builder: (bctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Шаблон сертификата',
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(bctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Выберите готовый дизайн или загрузите свой фон:',
                      style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF95969D)),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _themes.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 16),
                        itemBuilder: (context, index) {
                          final theme = _themes[index];
                          final isSelected = currentThemeId == theme['id'];
                          return GestureDetector(
                            onTap: () {
                              setModalState(() {
                                currentThemeId = theme['id'];
                              });
                              bctx.read<OrganizerProfileBloc>().add(
                                UpdateOrganizerProfile({'certificate_template_url': theme['id']}),
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 250,
                              decoration: BoxDecoration(
                                color: theme['bg1'],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF983296) : const Color(0xFFF1F0F5),
                                  width: isSelected ? 3 : 1.5,
                                ),
                                boxShadow: [
                                  if (isSelected)
                                    BoxShadow(
                                      color: const Color(0xFF983296).withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 6),
                                    )
                                  else
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.02),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                ],
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(13),
                                    child: _buildCertificatePreview(theme['id']),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 10,
                                      right: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF983296),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 10),
                                      ),
                                    ),
                                  Positioned(
                                    top: 0,
                                    left: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isSelected ? const Color(0xFF983296) : theme['accent'].withValues(alpha: 0.1),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(13),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        theme['name'],
                                        style: GoogleFonts.poppins(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected ? Colors.white : theme['accent'],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF983296).withValues(alpha: 0.08),
                          foregroundColor: const Color(0xFF983296),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.pop(bctx);
                          _pickCertificateTemplate(context);
                        },
                        icon: const Icon(Icons.cloud_upload_rounded),
                        label: Text(
                          'Загрузить свой фон (JPG, PNG)',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  Future<void> _pickAvatar(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    if (context.mounted) {
      context.read<OrganizerProfileBloc>().add(UpdateAvatar(image.path));
    }
  }

  Future<void> _pickCertificateTemplate(BuildContext context) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    if (context.mounted) {
      context.read<OrganizerProfileBloc>().add(UploadCertificateTemplate(image.path));
    }
  }

  Widget _buildCertificatePreview(String themeId) {
    final Map<String, dynamic> theme;
    if (themeId == 'style:modern_left') {
      theme = {
        'id': 'style:modern_left',
        'name': 'Асимметрия',
        'desc': 'Текст слева',
        'bg1': const Color(0xFFFAF9FC),
        'accent': const Color(0xFF983296),
        'textColor': const Color(0xFF0D0D26),
      };
      return _buildModernLeftPreview(theme);
    } else if (themeId == 'style:minimal_bottom') {
      theme = {
        'id': 'style:minimal_bottom',
        'name': 'Минимализм',
        'desc': 'Минимализм по углам',
        'bg1': const Color(0xFFFFFFFF),
        'accent': const Color(0xFF983296),
        'textColor': const Color(0xFF0D0D26),
      };
      return _buildMinimalBottomPreview(theme);
    } else {
      theme = {
        'id': 'style:classic',
        'name': 'Классический',
        'desc': 'Строгий центр',
        'bg1': const Color(0xFFFFFFFF),
        'accent': const Color(0xFF983296),
        'textColor': const Color(0xFF0D0D26),
      };
      return _buildClassicPreview(theme);
    }
  }

  Widget _buildClassicPreview(Map<String, dynamic> theme) {
    return Container(
      color: theme['bg1'],
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(border: Border.all(color: theme['accent'].withValues(alpha: 0.5), width: 1.5), borderRadius: BorderRadius.circular(8)),
            ),
          ),
          Positioned.fill(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border.all(color: theme['accent'].withValues(alpha: 0.2), width: 1), borderRadius: BorderRadius.circular(4)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: 244,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('СЕРТИФИКАТ', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: theme['accent'], letterSpacing: 2)),
                    const SizedBox(height: 8),
                    Container(width: 50, height: 1.5, color: theme['accent'].withValues(alpha: 0.5)),
                    const SizedBox(height: 8),
                    Text('ИМЯ ВОЛОНТЕРА', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: theme['textColor'])),
                    const SizedBox(height: 4),
                    Text('За активное участие в проекте', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 8, color: theme['textColor'].withValues(alpha: 0.7))),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(width: 40, height: 1, color: theme['textColor'].withValues(alpha: 0.3)),
                            const SizedBox(height: 4),
                            Text('Подпись', style: GoogleFonts.poppins(fontSize: 6, color: theme['textColor'].withValues(alpha: 0.5))),
                          ],
                        ),
                        Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme['accent'], width: 1.5)),
                          child: Center(child: Icon(Icons.stars_rounded, size: 16, color: theme['accent'])),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLeftPreview(Map<String, dynamic> theme) {
    return Container(
      color: theme['bg1'],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('СЕРТИФИКАТ', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: theme['accent'], letterSpacing: 1)),
                      const SizedBox(height: 12),
                      Text('ИМЯ ВОЛОНТЕРА', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w800, color: theme['textColor'])),
                      const SizedBox(height: 4),
                      Text('За участие в проекте', style: GoogleFonts.poppins(fontSize: 8, color: theme['textColor'].withValues(alpha: 0.7))),
                      const SizedBox(height: 20),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(color: theme['accent'].withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                            child: Center(child: Icon(Icons.verified_rounded, size: 14, color: theme['accent'])),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(width: 40, height: 1, color: theme['textColor'].withValues(alpha: 0.3)),
                              const SizedBox(height: 4),
                              Text('Подпись', style: GoogleFonts.poppins(fontSize: 6, color: theme['textColor'].withValues(alpha: 0.5))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                color: theme['accent'],
                borderRadius: const BorderRadius.only(topRight: Radius.circular(16), bottomRight: Radius.circular(16)),
              ),
              child: Center(
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text('VOLO APPROVED', style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalBottomPreview(Map<String, dynamic> theme) {
    return Container(
      color: theme['bg1'],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0, left: 0,
              child: Text('СЕРТИФИКАТ', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w900, color: theme['accent'])),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomRight,
                child: SizedBox(
                  width: 180,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ИМЯ ВОЛОНТЕРА', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: theme['textColor'])),
                      const SizedBox(height: 4),
                      Text('За вклад в проект', style: GoogleFonts.poppins(fontSize: 8, color: theme['textColor'].withValues(alpha: 0.7))),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(width: 40, height: 1, color: theme['textColor'].withValues(alpha: 0.3)),
                              const SizedBox(height: 4),
                              Text('Подпись', style: GoogleFonts.poppins(fontSize: 6, color: theme['textColor'].withValues(alpha: 0.5))),
                            ],
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: theme['accent'], width: 1.5)),
                            child: Center(child: Icon(Icons.volunteer_activism_rounded, size: 12, color: theme['accent'])),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Выйти из аккаунта?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Вы уверены, что хотите выйти из профиля организации?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Отмена', style: GoogleFonts.poppins(color: Colors.grey[600], fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (ctx.mounted) Navigator.pushNamedAndRemoveUntil(ctx, '/login', (route) => false);
            },
            child: Text('Выйти', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, OrganizerProfileState state) {
    _nameController.text = state.orgName;
    _descController.text = state.orgDesc;
    _phoneController.text = state.phone;
    _websiteController.text = state.website;
    _addressController.text = state.address;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        height: MediaQuery.of(bottomSheetContext).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 16),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Редактировать профиль',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.pop(bottomSheetContext),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildTextField('Название организации', _nameController, icon: Icons.business_rounded),
                    const SizedBox(height: 16),
                    _buildTextField('БИН (Идентификационный номер)', null, initialText: state.bin, isReadOnly: true, icon: Icons.fingerprint_rounded),
                    const SizedBox(height: 16),
                    _buildTextField('Адрес офиса / филиала', _addressController, icon: Icons.map_rounded),
                    const SizedBox(height: 16),
                    _buildTextField('Описание деятельности', _descController, maxLines: 4, icon: Icons.description_rounded),
                    const SizedBox(height: 16),
                    _buildTextField('Контактный телефон', _phoneController, icon: Icons.phone_rounded),
                    const SizedBox(height: 16),
                    _buildTextField('Официальный сайт', _websiteController, icon: Icons.language_rounded),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                           context.read<OrganizerProfileBloc>().add(UpdateOrganizerProfile({
                             'full_name': _nameController.text,
                             'description': _descController.text,
                             'phone': _phoneController.text,
                             'website': _websiteController.text,
                             'address': _addressController.text,
                           }));
                           Navigator.pop(bottomSheetContext);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF983296),
                          elevation: 4,
                          shadowColor: const Color(0xFF983296).withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Сохранить изменения',
                          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController? controller, {String? initialText, bool isReadOnly = false, int maxLines = 1, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26).withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: isReadOnly,
          maxLines: maxLines,
          style: GoogleFonts.poppins(fontSize: 14, fontWeight: isReadOnly ? FontWeight.w600 : FontWeight.w400),
          decoration: InputDecoration(
            filled: true,
            fillColor: isReadOnly ? const Color(0xFFF3F3F5) : const Color(0xFFF8F8FA),
            prefixIcon: Icon(icon, color: const Color(0xFF983296).withValues(alpha: 0.6), size: 20),
            hintText: initialText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF983296), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OrganizerProfileBloc, OrganizerProfileState>(
      listener: (context, state) {
        if (state.message != null && state.isSuccessAction) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              backgroundColor: const Color(0xFF983296),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.white,
          body: state.isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF983296)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Curved Premium Header Background
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1E212A), Color(0xFF2A2D3A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                            ),
                            child: SafeArea(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/VOLO-2.svg',
                                      height: 24,
                                      colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          // Right-aligned Avatar positioned half outside
                          Positioned(
                            bottom: -35,
                            right: 24,
                            child: Stack(
                              children: [
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0D0D26).withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipOval(
                                    child: state.avatarUrl != null && state.avatarUrl!.isNotEmpty
                                        ? FadeInImage.assetNetwork(
                                            placeholder: 'assets/images/org.png',
                                            image: ApiService.mediaUrl(state.avatarUrl),
                                            fit: BoxFit.cover,
                                            imageErrorBuilder: (_,__,___) => Image.asset('assets/images/org.png', fit: BoxFit.cover),
                                          )
                                        : Image.asset('assets/images/org.png', fit: BoxFit.cover),
                                  ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: GestureDetector(
                                    onTap: () => _pickAvatar(context),
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF2A2D3A),
                                        shape: BoxShape.circle,
                                      ),
                                      child: SvgPicture.asset(
                                        'assets/images/pen.svg',
                                        width: 10,
                                        height: 10,
                                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      // Organization Title & Subtitle
                      Padding(
                        padding: const EdgeInsets.only(left: 24, right: 100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.orgName,
                              style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
                              textAlign: TextAlign.left,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Организатор волонтерских инициатив',
                              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: const Color(0xFF95969D)),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        ),
                      ),
                                  const SizedBox(height: 24),
                      // Premium Unified White Stats Container
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D0D26).withValues(alpha: 0.015),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                          child: Row(
                            children: [
                              _buildUnifiedStatItem(
                                'Ивенты', 
                                state.eventsCount.toString(), 
                                Icons.event_available_rounded, 
                                const Color(0xFF983296),
                              ),
                              _buildVerticalDivider(),
                              _buildUnifiedStatItem(
                                'Рейтинг', 
                                state.rating.toString(), 
                                Icons.star_rounded, 
                                const Color(0xFFFF9C00),
                              ),
                              _buildVerticalDivider(),
                              _buildUnifiedStatItem(
                                'Заявки', 
                                state.appsCount.toString(), 
                                Icons.people_outline_rounded, 
                                const Color(0xFF00BFA5),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Dynamic Company Info Card (Stunning and Premium Details View)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D0D26).withValues(alpha: 0.01),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Сведения об организации',
                                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => _showEditDialog(context, state),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF983296).withValues(alpha: 0.06),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.edit_rounded, color: Color(0xFF983296), size: 12),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Редактировать',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF983296),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              
                              if (state.orgDesc.isNotEmpty) ...[
                                Text(
                                  state.orgDesc,
                                  style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700], height: 1.5),
                                ),
                                const SizedBox(height: 16),
                                Divider(color: Colors.grey[100]),
                                const SizedBox(height: 12),
                              ],

                              _buildDetailRow(Icons.fingerprint_rounded, 'БИН:', state.bin.isNotEmpty ? state.bin : 'Не указан'),
                              const SizedBox(height: 12),
                              _buildDetailRow(Icons.map_rounded, 'Адрес:', state.address.isNotEmpty ? state.address : 'Не указан'),
                              const SizedBox(height: 12),
                              _buildDetailRow(Icons.phone_rounded, 'Телефон:', state.phone.isNotEmpty ? state.phone : 'Не указан'),
                              const SizedBox(height: 12),
                              _buildDetailRow(Icons.language_rounded, 'Сайт:', state.website.isNotEmpty ? state.website : 'Не указан'),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Dynamic Certificate Template Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D0D26).withValues(alpha: 0.01),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Шаблон сертификата волонтера',
                                      style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => _showThemeSelectionBottomSheet(context, state.certificateTemplateUrl),
                                child: Container(
                                  height: state.certificateTemplateUrl != null ? 160 : 110,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFAF9FC),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF983296).withValues(alpha: 0.15), width: 1.5),
                                  ),
                                  child: state.certificateTemplateUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(18.5),
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              state.certificateTemplateUrl!.startsWith('style:')
                                                  ? _buildCertificatePreview(state.certificateTemplateUrl!)
                                                  : Image.network(
                                                      ApiService.mediaUrl(state.certificateTemplateUrl),
                                                      fit: BoxFit.cover,
                                                    ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [Colors.black.withValues(alpha: 0.4), Colors.transparent],
                                                    begin: Alignment.bottomCenter,
                                                    end: Alignment.topCenter,
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 12,
                                                right: 12,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.circular(12),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black.withValues(alpha: 0.1),
                                                        blurRadius: 8,
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      const Icon(Icons.sync_rounded, color: Color(0xFF983296), size: 14),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        'Изменить',
                                                        style: GoogleFonts.poppins(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w700,
                                                          color: const Color(0xFF983296),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF983296).withValues(alpha: 0.06),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.cloud_upload_rounded, color: Color(0xFF983296), size: 24),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Загрузить фирменный бланк',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                                color: const Color(0xFF983296),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Поддерживаются форматы JPG, PNG',
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xFF95969D),
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Settings List Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0D0D26).withValues(alpha: 0.01),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Column(
                            children: [
                              _buildSettingItem(
                                title: 'Настройки уведомлений',
                                subtitle: 'Все уведомления включены',
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsPage())),
                              ),
                               _buildSettingItem(
                                title: 'Помощь и поддержка',
                                subtitle: 'FAQ и контакты',
                                onTap: () => Navigator.pushNamed(context, '/help_support'),
                              ),
                              _buildSettingItem(
                                title: 'О приложении',
                                subtitle: 'Версия 1.0.0',
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutVoloPage())),
                              ),
                              _buildSettingItem(
                                title: 'Выйти из аккаунта',
                                subtitle: null,
                                isLogout: true,
                                onTap: () => _showLogoutDialog(context),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 48),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildUnifiedStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D0D26),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0D0D26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1.5,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F0F5),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF983296).withValues(alpha: 0.6), size: 18),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF95969D)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0D0D26)),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isLogout ? Colors.red : Colors.black,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isLogout ? Colors.red : Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}