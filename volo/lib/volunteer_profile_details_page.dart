import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with Avatar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF983296),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient or Image Background
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF983296), Color(0xFF662265)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.1,
                      child: SvgPicture.asset(
                        'assets/images/mask.svg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Avatar and Name
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Hero(
                        tag: 'avatar_${volunteerData['id']}',
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: ClipOval(
                            child: avatarUrl.isNotEmpty
                                ? Image.network(avatarUrl, fit: BoxFit.cover)
                                : Container(
                                    color: Colors.white.withOpacity(0.2),
                                    child: Center(
                                      child: Text(
                                        name[0].toUpperCase(),
                                        style: GoogleFonts.poppins(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        volunteerData['email'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stat Cards
                  Row(
                    children: [
                      _buildStatCard('Volo-часы', hours.toString(), Icons.timer_outlined),
                      const SizedBox(width: 16),
                      _buildStatCard('Заявка от', applicationDate, Icons.calendar_today_rounded),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Info Sections
                  _buildInfoSection('О себе', bio, Icons.person_outline_rounded),
                  const SizedBox(height: 24),
                  _buildInfoSection('Навыки и интересы', skills, Icons.psychology_outlined),
                  const SizedBox(height: 24),
                  _buildInfoSection('Город', location, Icons.location_on_outlined),
                  
                  const SizedBox(height: 40),
                  
                  // Contact Button (Simulation)
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF983296), Color(0xFFB856B8)]),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFF983296).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'НАПИСАТЬ СООБЩЕНИЕ',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F1F5)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF983296)),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0D0D26)),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF95969D)),
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
              style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0D0D26)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F1F5)),
          ),
          child: Text(
            content,
            style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF6B6B7B), height: 1.6),
          ),
        ),
      ],
    );
  }
}
