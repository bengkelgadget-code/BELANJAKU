import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystorePropertiesFile = if (rootProject.file("key.properties").exists()) {
    rootProject.file("key.properties")
} else {
    file("key.properties")
}

val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.bengkel.belanjaku"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bengkel.belanjaku"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias") ?: "belanjaku"
            keyPassword = keystoreProperties.getProperty("keyPassword") ?: "belanjaku2026"
            val storeProp = keystoreProperties.getProperty("storeFile") ?: "belanjaku-release.jks"
            val candidates = listOf(
                file(storeProp),
                file("belanjaku-release.jks"),
                rootProject.file(storeProp),
                rootProject.file("app/$storeProp"),
                rootProject.file("app/belanjaku-release.jks")
            )
            storeFile = candidates.firstOrNull { it.exists() } ?: file("belanjaku-release.jks")
            storePassword = keystoreProperties.getProperty("storePassword") ?: "belanjaku2026"
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
