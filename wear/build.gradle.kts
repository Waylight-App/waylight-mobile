plugins {
    id("com.android.application") version "9.3.1"
    id("org.jetbrains.kotlin.android") version "2.4.20"
    id("org.jetbrains.kotlin.plugin.compose") version "2.4.20"
}

// The watch app carries the version of the phone app, which release-please
// bumps in pubspec.yaml ("1.2.3+45": name 1.2.3, code 45).
val pubspecVersion: List<String> =
    Regex("""(?m)^version:\s*([0-9.]+)\+([0-9]+)""")
        .find(rootDir.resolve("../pubspec.yaml").readText())
        ?.destructured
        ?.toList()
        ?: error("pubspec.yaml has no version of the form 1.2.3+4")

android {
    namespace = "app.waylight.wear"
    compileSdk = 36

    defaultConfig {
        // The same identifier as the phone app, so a store listing can carry
        // both later (docs/releasing.md); never change it after a release.
        applicationId = "app.waylight.mobile"
        // Wear OS 3, the first version with Tiles from AndroidX and the
        // oldest still sold.
        minSdk = 30
        targetSdk = 36
        versionName = pubspecVersion[0]
        versionCode = pubspecVersion[1].toInt()
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
            // Signed with the debug key until release signing is set up (#25),
            // like the phone app.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// Only AndroidX and JetBrains libraries: nothing from Google Play services
// or Firebase (ADR 0015); CI checks the APK for it.
dependencies {
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.wear.compose:compose-foundation:1.5.0")
    implementation("androidx.wear.compose:compose-material:1.5.0")
}
