// The Wear OS app is its own Gradle build, independent of the Flutter app
// in android/: it needs neither the Flutter SDK nor the phone's plugins
// (ADR 0015).
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "waylight-wear"
