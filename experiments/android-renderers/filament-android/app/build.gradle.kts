plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}
android {
    namespace = "com.adeldice.filamentlab"
    compileSdk = 35
    defaultConfig {
        applicationId = "com.adeldice.filamentlab"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}
dependencies {
    implementation("com.google.android.filament:filament-android:1.77.3")
    implementation("com.google.android.filament:gltfio-android:1.77.3")
    implementation("com.google.android.filament:filament-utils-android:1.77.3")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
}
