# Android standalone RNG-first WebGL2 D20 experimental APK source

- No Godot, Jolt, Three.js or external cloud service.
- Uses system Android WebView (Chromium WebGL2 hardware acceleration) and **only local app HTTPS-emulated assets**.
- Zero third-party Android library runtime dependencies.
- Original licensed 500k GLB is NOT in the public APK. Choose it once from the document picker; Java code verifies its exact SHA256 before persisting to app private storage.
- On subsequent launches, WebView obtains it from app's private storage through the local `appassets.androidplatform.net` request interceptor. All other hosts and URLs are denied.
- This is an engineering prototype, not an approved production design or device-performance claim.

Open the folder in Android Studio with Android SDK 35, Java 17 and Gradle 8.10.2. Run `gradle assembleDebug` from this folder. Install `app/build/outputs/apk/debug/app-debug.apk` to an Android device. Select the original private GLB once.