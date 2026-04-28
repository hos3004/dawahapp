pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader")
    // ✅ حدّثنا Android Gradle Plugin حسب طلب التحذير (على الأقل 8.6.0)
    id("com.android.application") version "8.6.0" apply false
    // ✅ حدّثنا Kotlin لنسخة 2.1.0 كما يطلب Flutter
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

include(":app")
