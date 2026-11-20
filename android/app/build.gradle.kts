// Firebase options of the store flavour (ADR 0008), from the Gradle property
// waylight.fcm.<name> or the environment variable WAYLIGHT_FCM_<NAME>.
val firebaseFields = mapOf(
    "FCM_PROJECT_ID" to "projectId",
    "FCM_APP_ID" to "appId",
    "FCM_API_KEY" to "apiKey",
    "FCM_SENDER_ID" to "senderId",
)

fun firebaseValue(name: String): String =
    (project.findProperty("waylight.fcm.$name") as String?)
        ?: System.getenv("WAYLIGHT_FCM_" + name.replace(Regex("([A-Z])"), "_$1").uppercase())
        ?: ""

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

    // Two distributions (ADR 0008): "store" receives push notifications
    // through Firebase, "fdroid" contains no Firebase code at all.
    flavorDimensions += "distribution"
    productFlavors {
        create("store") {
            dimension = "distribution"
            // Firebase is initialised in code from these build-time values
            // instead of a google-services.json in the repository; empty
            // values leave push notifications off.
            for ((field, property) in firebaseFields) {
                buildConfigField("String", field, "\"${firebaseValue(property)}\"")
            }
        }
        create("fdroid") {
            dimension = "distribution"
        }
    }

    buildFeatures {
        buildConfig = true
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
    // Store flavour only (ADR 0008): Firebase Messaging receives the push
    // messages, Tink provides X25519 below Android 13. Neither is part of the
    // F-Droid build.
    "storeImplementation"("com.google.firebase:firebase-messaging:26.0.2")
    "storeImplementation"("com.google.crypto.tink:tink-android:1.24.0")
    // JVM unit tests of the native push code; org.json is only a stub in
    // the Android SDK outside a device.
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20260814")
}
