plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.screen_translator"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.screen_translator"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
// -----------------------------------------------------------------------
// Paste the dependencies below into the `dependencies { ... }` block of
// the android/app/build.gradle that `flutter create` generates for you.
// Also make sure (in the same file):
//   android.compileSdk = 34         (Termux aapt2 is happiest at 34)
//   defaultConfig.minSdk = 24       (MediaProjection foreground service
//                                     type requires API 29+ at runtime,
//                                     the app just needs to check at runtime)
//   defaultConfig.targetSdk = 34
//   kotlinOptions.jvmTarget = '17'
// -----------------------------------------------------------------------

dependencies {
    // On-device text recognition (Latin script is bundled; add the others
    // only for the languages you actually need — each is a separate model).
    implementation("com.google.mlkit:text-recognition:16.0.1")
    implementation("com.google.mlkit:text-recognition-chinese:16.0.1")
    implementation("com.google.mlkit:text-recognition-japanese:16.0.1")
    implementation("com.google.mlkit:text-recognition-korean:16.0.1")
    implementation("com.google.mlkit:text-recognition-devanagari:16.0.1")

    // On-device translation — free, no API key, ~30MB per language pair
    // downloaded once.
    implementation("com.google.mlkit:translate:17.0.3")

    implementation("androidx.core:core-ktx:1.13.1")
}
