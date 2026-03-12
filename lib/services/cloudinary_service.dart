import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CloudinaryService {
  // Cloudinary ayarları
  static const String cloudName = 'djr2ijflc';
  static const String uploadPreset = 'fridgechef'; // Unsigned upload preset

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Fotoğraf yükle ve URL döndür
  static Future<String?> uploadImage(File imageFile) async {
    try {
      debugPrint('Cloudinary: Starting upload...');
      debugPrint('Cloudinary: File exists: ${await imageFile.exists()}, size: ${await imageFile.length()} bytes');

      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'fridgechef';

      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout after 30 seconds');
        },
      );

      final responseData = await streamedResponse.stream.bytesToString();
      debugPrint('Cloudinary: Status ${streamedResponse.statusCode}');

      if (streamedResponse.statusCode == 200) {
        final jsonData = json.decode(responseData);
        final secureUrl = jsonData['secure_url'] as String;
        debugPrint('Cloudinary: Success! URL: $secureUrl');
        return secureUrl;
      } else {
        debugPrint('Cloudinary: FAILED - ${streamedResponse.statusCode}');
        debugPrint('Cloudinary: Response: $responseData');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary: EXCEPTION: $e');
      return null;
    }
  }

  /// Thumbnail URL oluştur
  static String getThumbnailUrl(String originalUrl, {int width = 200, int height = 200}) {
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/w_$width,h_$height,c_fill,q_auto,f_auto/',
    );
  }

  /// Orta boy URL oluştur
  static String getMediumUrl(String originalUrl) {
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/w_400,h_300,c_fill,q_auto,f_auto/',
    );
  }
}
