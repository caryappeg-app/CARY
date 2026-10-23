# مشاركة العربية + فتحها من الرابط

## 1) الباكدجات
    flutter pub add share_plus:^10.1.4 app_links:^6.3.2

## 2) أندرويد
انسخ `android_files/AndroidManifest.xml` فوق `android/app/src/main/AndroidManifest.xml`.
(لو الدومين مش cary.pages.dev غيّره في سطر android:host.)

## 3) آيفون: اتبع `ios_files/IOS_SETUP.txt`.

## 4) Cloudflare Pages (مجاني)
1. dash.cloudflare.com → Workers & Pages → Create → Pages → Upload assets.
2. سمّي المشروع `cary` (الدومين يبقى cary.pages.dev) وارفع محتوى مجلد `cloudflare_site`
   بالكامل (بما فيه مجلد `.well-known` والملفين `_headers` و `_redirects`).
3. افتح `.well-known/assetlinks.json` وغيّر:
   - `package_name` = applicationId الحقيقي (في android/app/build.gradle.kts)
   - `sha256_cert_fingerprints` = بصمة مفتاح التوقيع:
     `keytool -list -v -keystore %USERPROFILE%\.android\debug.keystore -alias androiddebugkey -storepass android`
     (للنسخة المنشورة على Google Play: Play Console → App integrity → App signing).
   ثم أعد الرفع.
4. اتأكد: افتح https://cary.pages.dev/.well-known/assetlinks.json لازم يظهر الـ JSON.

## 5) لو اسم المشروع مختلف
    flutter run --dart-define=SHARE_LINK_BASE=https://اسمك.pages.dev
وغيّر android:host في الـ Manifest و applinks في iOS.

## ملاحظات
- لو التطبيق متسطّب بـ debug keystore، البصمة بتاعت debug هي اللي تتحط.
- Android 12+ بيتحقق من assetlinks وقت التثبيت؛ لو غيّرت الملف أعد تثبيت التطبيق.
- في وضع الـ Mock الداتا في الذاكرة: العربية لازم تكون موجودة في نفس الجهاز اللي فتح الرابط.
  للمشاركة بين أجهزة مختلفة محتاج Backend حقيقي (/cars/{id}).
