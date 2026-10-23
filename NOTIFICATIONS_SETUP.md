# إعداد الإشعارات (مرة واحدة)

## 1) الحزمة
```bash
flutter pub add flutter_local_notifications:^19.0.0
flutter pub get
```

## 2) أندرويد
`android/app/src/main/AndroidManifest.xml` — جوه `<manifest>` (قبل `<application>`):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

`android/app/build.gradle` (أو `build.gradle.kts`) — الحزمة بتحتاج Core Library Desugaring:
```gradle
android {
    compileOptions {
        coreLibraryDesugaringEnabled true      // build.gradle.kts: isCoreLibraryDesugaringEnabled = true
        sourceCompatibility JavaVersion.VERSION_11
        targetCompatibility JavaVersion.VERSION_11
    }
}
dependencies {
    coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4'
    // build.gradle.kts: coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
```

## 3) iOS
`ios/Runner/AppDelegate.swift` — جوه `application(_:didFinishLaunchingWithOptions:)` قبل `return`:
```swift
if #available(iOS 10.0, *) {
  UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
}
```
