plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "app.waylight.waylight_mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Store identifier; never change it after the first release (docs/releasing.md).
        applicationId = "app.waylight.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Signed with the debug keys until store signing is set up (#25).
            signingConfig = signingConfigs.getByName("debug")
            // Keep rules for classes created by reflection (#174).
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
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

dependencies {
    // Refresh of the home screen widgets while the app is closed (ADR 0009):
    // the platform's scheduler, which respects Doze and battery limits.
    implementation("androidx.work:work-runtime:2.10.0")
    // X25519 for decrypting push messages below Android 13 (ADR 0008); an
    // offline crypto library without network access.
    implementation("com.google.crypto.tink:tink-android:1.24.0")
    // JVM unit tests of the native push code; org.json is only a stub in
    // the Android SDK outside a device.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20260814")
}
