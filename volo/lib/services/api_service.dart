import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static String _baseUrl = 'http://127.0.0.1:8080';

  static String get baseUrl => _baseUrl;

  static set baseUrl(String value) {
    _baseUrl = value;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('api_base_url', value);
    });
  }

  static Future<void> initBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('api_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
    } else {
      _baseUrl = dotenv.env['BASE_URL'] ?? 'http://127.0.0.1:8080';
    }
  }

  // Регистрация
  Future<Map<String, dynamic>> register(String email, String password, {String role = 'volunteer', String? orgName, String? bin}) async {
    try {
      print('📡 POST REQUEST TO: $baseUrl/auth/register');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'role': role,
          'org_name': orgName,
          'bin': bin,
        }),
      );

      return _handleResponse(response);
    } catch (e, stackTrace) {
      print('❌ REGISTER ERROR: $e');
      print('Stack trace: $stackTrace');
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Вход
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('📡 POST REQUEST TO: $baseUrl/auth/login');
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final result = _handleResponse(response);
      if (result['success']) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', result['data']['access_token']);
        await prefs.setString('role', result['data']['role']);
        await prefs.setBool('is_approved', result['data']['is_approved']);
      }
      return result;
    } catch (e) {
      print('❌ LOGIN ERROR: $e');
        print('💡 СОВЕТ: Проверьте, что VPN ВЫКЛЮЧЕН на Mac и на iPhone. Mac IP: 10.202.8.194');
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получение профиля текущего пользователя
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) return {'success': false, 'message': 'Токен не найден'};

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Обновление профиля
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profileData),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Обновление профиля организации
  Future<Map<String, dynamic>> updateOrgProfile(Map<String, dynamic> profileData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/users/org-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profileData),
      );

      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получение списка событий
  Future<Map<String, dynamic>> getEvents() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/events/'));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Отправка заявки на событие
  Future<Map<String, dynamic>> applyToEvent(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/apply'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получение сертификатов пользователя
  Future<Map<String, dynamic>> getMyCertificates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/events/my-certificates'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получение заявок пользователя
  Future<Map<String, dynamic>> getMyApplications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/events/my-applications'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Верификация почты
  Future<Map<String, dynamic>> verifyEmail(String email, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Восстановление пароля - запрос кода
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Восстановление пароля - сброс
  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'new_password': newPassword
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  static String mediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }

  // Шаблон сертификата организации (без текста, с печатями)
  Future<Map<String, dynamic>> uploadCertificateTemplate(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/users/upload-certificate-template'),
      );
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Загрузка аватара
  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/users/upload-avatar'));
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Обработка ответов от сервера
  Map<String, dynamic> _handleResponse(http.Response response) {
    // Check if the body is not empty and is JSON
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      data = {'detail': response.body};
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return {'success': true, 'data': data};
    } else {
      print('❌ API ERROR [${response.statusCode}]: ${response.body}');
      String message = data['detail'] ?? 'Произошла ошибка';
      if (response.statusCode == 401) {
        message = 'Сессия истекла. Пожалуйста, войдите в аккаунт снова.';
      }
      return {
        'success': false,
        'message': message,
        'statusCode': response.statusCode,
      };
    }
  }

  // Методы администратора
  Future<Map<String, dynamic>> getPendingOrganizations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/admin/pending-organizations'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  Future<Map<String, dynamic>> approveOrganization(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/admin/approve-organization/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // --- Методы для Организатора ---

  // Создание ивента
  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData, {File? imageFile}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      
      if (token == null || token.isEmpty) {
        return {'success': false, 'message': 'Вы не авторизованы. Пожалуйста, войдите снова.'};
      }

      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/events/'));
      request.headers['Authorization'] = 'Bearer $token';
      
      // Add all text fields
      eventData.forEach((key, value) {
        request.fields[key] = value.toString();
      });
      
      // Add image if provided
      if (imageFile != null) {
        var stream = http.ByteStream(imageFile.openRead());
        var length = await imageFile.length();
        var multipartFile = http.MultipartFile(
          'image',
          stream,
          length,
          filename: imageFile.path.split('/').last,
        );
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }
  
  // Завершение ивента (начисление часов и уведомления)
  Future<Map<String, dynamic>> finishEvent(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/finish'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Переключение статуса ивента (активен/неактивен)
  Future<Map<String, dynamic>> toggleEventStatus(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/events/$eventId/toggle-status'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получение ивентов организации
  Future<Map<String, dynamic>> getMyEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/events/my-events'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получение заявок на конкретный ивент
  Future<Map<String, dynamic>> getEventApplications(int eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId/applications'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Обновление статуса заявки
  Future<Map<String, dynamic>> updateApplicationStatus(int applicationId, String status) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/events/applications/$applicationId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получить уведомления
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получить количество непрочитанных уведомлений
  Future<Map<String, dynamic>> getUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/notifications/unread-count'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Отметить уведомление как прочитанное
  Future<Map<String, dynamic>> markNotificationAsRead(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/$notificationId/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Отметить все уведомления как прочитанные
  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.put(
        Uri.parse('$baseUrl/notifications/mark-all-read'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Удалить уведомление
  Future<Map<String, dynamic>> deleteNotification(int notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.delete(
        Uri.parse('$baseUrl/notifications/$notificationId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // ─── Чаты ────────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getMyChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/chats/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  Future<Map<String, dynamic>> getChatMessages(int chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/chats/$chatId/messages'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  Future<Map<String, dynamic>> sendChatMessage(int chatId, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/api/chats/$chatId/messages'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  Future<Map<String, dynamic>> getChatParticipants(int chatId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/api/chats/$chatId/participants'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Отправить запрос в техподдержку
  Future<Map<String, dynamic>> submitSupportRequest(String message) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/support/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'message': message,
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получить мои запросы в техподдержку
  Future<Map<String, dynamic>> getMySupportRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/support/my'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получить все запросы в техподдержку (для админа)
  Future<Map<String, dynamic>> getAllSupportRequests() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.get(
        Uri.parse('$baseUrl/support/all'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Ответить на запрос в техподдержку (для админа)
  Future<Map<String, dynamic>> replyToSupportRequest(int requestId, String replyText) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/support/$requestId/reply'),
        headers: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'reply': replyText,
        },
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Оставить отзыв о мероприятии
  Future<Map<String, dynamic>> submitReview(int eventId, int rating, String text) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final response = await http.post(
        Uri.parse('$baseUrl/events/$eventId/reviews'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'rating': rating,
          'text': text,
        }),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Получить отзывы мероприятия
  Future<Map<String, dynamic>> getEventReviews(int eventId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/events/$eventId/reviews'),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Ошибка сети: $e'};
    }
  }

  // Выход
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }
}
