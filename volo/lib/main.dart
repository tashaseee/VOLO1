// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'login_page.dart';
import 'onboarding_page.dart';
import 'register_page.dart';
import 'sign_in_page.dart';
import 'main_screen.dart';
import 'event_detail_page.dart';
import 'filter_page.dart';
import 'profile_page.dart';
import 'my_applications_page.dart';
import 'search_page.dart';
import 'notifications_page.dart';
import 'organizer_navigator.dart';
import 'add_event_page.dart';
import 'volunteers_page.dart';
import 'organizer_profile_page.dart';
import 'volo_history_page.dart';
import 'admin_panel_page.dart';
import 'help_support_page.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await ApiService.initBaseUrl();
  runApp(const VoloApp());
}

class VoloApp extends StatelessWidget {
  const VoloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru', 'RU'),
        Locale('en', 'US'),
      ],
      locale: const Locale('ru', 'RU'),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginPage(),
        '/onboarding': (context) => OnboardingPage(),
        '/register': (context) => RegisterPage(),
        '/sign_in': (context) => SignInPage(),
        '/home': (context) => const MainScreen(initialIndex: 2),
        '/event_detail': (context) => EventDetailPage(
          eventTitle: 'Default Title',
          organizer: 'Default Organizer',
          date: 'Default Date',
          location: 'Default Location',
          chatLink: 'https://t.me/default_chat',
          description: 'Default description',
          responsibilities: ['Default responsibility'],
          benefits: ['Default benefit'],
          eventId: 0,
        ),
        '/filter': (context) => FilterPage(),
        '/profile': (context) => ProfilePage(),
        '/applications': (context) => MyApplicationsPage(),
        '/search': (context) => SearchPage(),
        '/notifications': (context) => NotificationsPage(),
        '/organizer_home': (context) => OrganizerNavigator(),
        '/add_event': (context) => AddEventPage(),
        '/volunteers': (context) => VolunteersPage(),
        '/organizer_profile': (context) => OrganizerProfilePage(),
        '/volo_history': (context) => VoloHistoryPage(),
        '/admin_panel': (context) => const AdminPanelPage(),
        '/help_support': (context) => const HelpSupportPage(),
      },
      theme: ThemeData(
        textTheme: GoogleFonts.poppinsTextTheme().apply(
          bodyColor: const Color(0xFF0D0D26),
          displayColor: const Color(0xFF0D0D26),
        ),
        primaryColor: const Color(0xFF983296),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0D0D26),
          ),
          iconTheme: IconThemeData(color: Color(0xFF983296), size: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: const Color(0xFF983296),
            foregroundColor: Colors.white,
            textStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF983296), width: 1),
            textStyle: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF983296), width: 1.5),
          ),
          labelStyle: GoogleFonts.poppins(
            fontSize: 13,
            color: const Color(0xFF95969D),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}