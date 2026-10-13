import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VolunteerProfileDetailsPage extends StatelessWidget {
  final Map<String, dynamic> volunteerData;
  final String applicationDate;

  const VolunteerProfileDetailsPage({
    super.key,
    required this.volunteerData,
    required this.applicationDate,
  });

  @override
  Widget build(BuildContext context) {
    final profile = volunteerData['profile'] ?? {};
    final String name = profile['full_name'] ?? volunteerData['email'] ?? 'Волонтер';
    final String avatarUrl = profile['avatar_url'] ?? '';
    final int hours = profile['volo_hours'] ?? 0;
    final String bio = profile['bio'] ?? 'Информация не указана';
    final String skills = profile['skills'] ?? 'Не указаны';
    final String location = profile['city'] ?? 'Не указан';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D0D26), size: 16),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Анкета волонтера',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0D0D26),
          ),
        ),
        shape: const Border(
          bottom: BorderSide(color: Color(0xFFF1F0F5), width: 1.5),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar and Identity Card
            Center(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF5F5F8),
                      border: Border.all(color: const Color(0xFFF1F0F5), width: 2),
                    ),
                    child: ClipOval(
                      child: avatarUrl.isNotEmpty
                          ? Image.network(
                              avatarUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildPlaceholderAvatar(name),
                            )
                          : _buildPlaceholderAvatar(name),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0D0D26),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    volunteerData['email'] ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF95969D),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Stat Cards
            Row(
              children: [
                _buildStatCard('Volo-часы', hours.toString(), Icons.access_time_rounded),
                const SizedBox(width: 12),
                _buildStatCard('Заявка от', applicationDate, Icons.calendar_today_rounded),
              ],
            ),
            const SizedBox(height: 28),

            // Info Sections
            _buildInfoSection('О себе', bio, Icons.person_outline_rounded),
            const SizedBox(height: 20),
            _buildInfoSection('Навыки и интересы', skills, Icons.psychology_outlined),
            const SizedBox(height: 20),
            _buildInfoSection('Город', location, Icons.location_on_outlined),

            const SizedBox(height: 32),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF983296),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'НАПИСАТЬ СООБЩЕНИЕ',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderAvatar(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'B',
        style: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF983296),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D0D26).withValues(alpha: 0.015),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF983296)),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: const Color(0xFF0D0D26)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF95969D)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF983296)),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F0F5), width: 1.5),
          ),
          child: Text(
            content,
            style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF5D5E67), height: 1.5, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
