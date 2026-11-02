/// عنوان السيرفر اللي فيه ملفات التحديث عن بعد (config.json + update.json + APK).
/// افتراضياً: GitHub Pages الخاص بالمستودع.
/// تقدر تغيّره وقت البناء:
///   flutter build apk --dart-define=REMOTE_BASE_URL=https://example.com/app
const String kRemoteBaseUrl = String.fromEnvironment(
  'REMOTE_BASE_URL',
  defaultValue: 'https://qbrahym02-cmyk.github.io/flutter-todo-ota-app',
);

const String kConfigUrl = '$kRemoteBaseUrl/config.json';
const String kUpdateUrl = '$kRemoteBaseUrl/update.json';
