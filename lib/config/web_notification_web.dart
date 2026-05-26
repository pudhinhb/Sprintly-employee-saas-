/// Web: show browser Notification when app is in foreground.
import 'package:web/web.dart' as web;

void showWebNotification(String title, String body, {String? tag}) {
  try {
    if (web.Notification.permission == 'granted') {
      web.Notification(
        title,
        web.NotificationOptions(body: body, tag: tag ?? 'webnox-sprintly-employee'),
      );
    }
  } catch (_) {}
}
