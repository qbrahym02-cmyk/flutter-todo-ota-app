# 📝 مهامي — تطبيق To-Do بـ Flutter مع تحديث عن بعد

تطبيق مهام كامل (عربي، RTL، Material 3، وضع ليلي) **تقدر تحدّثه عن بعد** بدون ما يحتاج المستخدم يروح لمتجر أو يحمّل التطبيق من جديد.

## ✨ المميزات
- إضافة / تعديل / حذف المهام (اسحب للحذف + زر تراجع)
- إنجاز المهام، أولويات، تاريخ استحقاق، تنبيه للمهام المتأخرة
- فلترة: الكل / المتبقية / المنجزة + شريط تقدّم
- حفظ محلي على الجهاز (يبقى بعد التحديثات)
- **تحديث عن بعد بمستويين** 👇

---

## 🚀 طريقتين للتحديث عن بعد

### 1) تحديث فوري (بدون أي تحميل) — `remote/config.json`
عدّل الملف وادفعه (push) — يتغيّر عند كل المستخدمين خلال دقائق، **بدون تنزيل أي شيء**:

| المفتاح | وش يسوي |
|---|---|
| `app_title` | اسم التطبيق في الأعلى |
| `theme_color` | لون التطبيق بالكامل (مثل `#E91E63`) |
| `announcement` | شريط إعلان أعلى الشاشة (اتركه `""` لإخفائه) |
| `maintenance` | `true` = يقفل التطبيق ويعرض رسالة صيانة |
| `maintenance_message` | نص رسالة الصيانة |
| `empty_message` | النص لما تكون القائمة فاضية |
| `quick_tasks` | اقتراحات سريعة تظهر عند إضافة مهمة |
| `features.show_stats` | إظهار/إخفاء شريط التقدّم |
| `features.priorities` | تفعيل/إيقاف الأولويات |
| `features.due_dates` | تفعيل/إيقاف تواريخ الاستحقاق |

> تقدر تعدّله حتى من موقع GitHub نفسه (افتح الملف ← ✏️ ← Commit) أو من جوالك.

### 2) تحديث الكود نفسه (ميزات جديدة) — تلقائي بالكامل
1. عدّل أي شيء في `lib/` (أو `pubspec.yaml`)
2. اكتب ملاحظات التحديث في `remote/update_settings.json`
3. `git push`

GitHub Actions يبني APK جديد، يوقّعه بنفس المفتاح، وينشر `update.json`.
التطبيق يفحص التحديث عند كل فتح ← تطلع نافذة **"تحديث جديد"** ← المستخدم يضغط **"حدّث الآن"** ← ينزل داخل التطبيق ← **"تثبيت"**. خلاص. المهام تبقى محفوظة.

`update_settings.json`:
```json
{
  "changelog": "• ميزة جديدة\n• إصلاح مشكلة",
  "force": false,
  "min_supported_build": 0
}
```
- `force: true` ← التحديث إجباري (ما يقدر يقفل النافذة)
- `min_supported_build: 5` ← أي نسخة أقدم من build 5 لازم تتحدّث

### 🌐 نسخة الويب (PWA)
نفس التطبيق منشور كموقع ويب — يتحدّث تلقائياً مع كل push، ويقدر المستخدم يضيفه للشاشة الرئيسية.

---

## 🔗 الروابط (بعد أول build)
| | |
|---|---|
| تحميل التطبيق (أول مرة فقط) | `https://<user>.github.io/<repo>/apk/latest.apk` |
| نسخة الويب | `https://<user>.github.io/<repo>/` |
| الإعدادات الحيّة | `https://<user>.github.io/<repo>/config.json` |
| معلومات آخر تحديث | `https://<user>.github.io/<repo>/update.json` |

## 🔐 Secrets المطلوبة في GitHub (Settings ← Secrets ← Actions)
| الاسم | القيمة |
|---|---|
| `KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `KEYSTORE_PASSWORD` | كلمة مرور الـ keystore |
| `KEY_ALIAS` | `upload` |
| `KEY_PASSWORD` | كلمة مرور المفتاح |

> ⚠️ **لا تضيّع ملف المفتاح** — لو تغيّر، أندرويد يرفض تثبيت التحديث فوق النسخة القديمة.

## 🛠️ تشغيل محلي
```bash
flutter pub get
flutter run
flutter test
```

## ℹ️ ملاحظات تقنية
- أول تثبيت: أندرويد يطلب مرة واحدة السماح بـ "التثبيت من مصادر غير معروفة" لهذا التطبيق.
- iOS لا يسمح بتثبيت تحديثات خارج App Store؛ استخدم نسخة الويب، أو [Shorebird](https://shorebird.dev) لتحديث كود Dart مباشرة.
- لتغيير السيرفر: `--dart-define=REMOTE_BASE_URL=https://your-server.com/app`

## 📁 هيكل المشروع
```
lib/
├── main.dart                  # نقطة البداية + الثيم من السيرفر
├── app_constants.dart         # رابط السيرفر
├── models/task.dart
├── services/
│   ├── task_store.dart        # التخزين المحلي
│   ├── remote_config.dart     # الإعدادات عن بعد (مع كاش للعمل بدون نت)
│   └── updater.dart           # فحص وتنزيل وتثبيت التحديثات
├── screens/home_screen.dart
└── widgets/{task_editor,update_dialog}.dart
remote/
├── config.json                # ← عدّل هذا للتحديث الفوري
└── update_settings.json       # ← ملاحظات التحديث القادم
.github/workflows/
├── release.yml                # بناء + نشر التحديثات
└── config.yml                 # نشر config.json فوراً
```
