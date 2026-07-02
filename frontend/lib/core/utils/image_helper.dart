import '../network/dio_client.dart';

String getImageUrl(String imagePath) {
  if (imagePath.isEmpty) return '';
  if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
    return imagePath;
  }
  
  try {
    final uri = Uri.parse(DioClient.baseUrl);
    final host = '${uri.scheme}://${uri.host}:${uri.port}';
    if (imagePath.startsWith('/')) {
      return '$host$imagePath';
    }
    return '$host/$imagePath';
  } catch (_) {
    if (imagePath.startsWith('/')) {
      return 'http://127.0.0.1:8000$imagePath';
    }
    return 'http://127.0.0.1:8000/$imagePath';
  }
}
