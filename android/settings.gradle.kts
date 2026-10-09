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
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    // 9.3.0/9.3.1 ship a lint that crashes on JDK 17 (NoSuchMethodError in the
    // bundled intellij-core JavaDocParser); 9.3.2 fixed it, so stay on the latest
    // 9.3 patch. The 9.3 line needs Gradle >= 9.5.0 and build-tools 36.0.0.
    id("com.android.application") version "9.3.3" apply false
    id("org.jetbrains.kotlin.android") version "2.4.20" apply false
}

include(":app")
