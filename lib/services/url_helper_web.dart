// url_helper_web.dart
import 'dart:html' as html;

String? getWebUrlCode() {
  String currentUrl = html.window.location.href;
  if (currentUrl.contains('code=')) {
    return currentUrl.split('code=')[1].split('&')[0];
  }
  return null;
}

void clearWebUrl() {
  html.window.history.pushState({}, '', '/');
}