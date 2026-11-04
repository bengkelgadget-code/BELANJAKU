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
        isCoreLibraryDesugaringEnabled = true
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
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val alias = keystoreProperties.getProperty("keyAlias")?.trim()
            val pass = keystoreProperties.getProperty("storePassword")?.trim()
            val keyPass = keystoreProperties.getProperty("keyPassword")?.trim() ?: pass
            val type = keystoreProperties.getProperty("storeType")?.trim()

            keyAlias = alias
            storePassword = pass
            keyPassword = keyPass
            if (!type.isNullOrBlank()) {
                storeType = type
            }

            val storeProp = keystoreProperties.getProperty("storeFile")?.trim() ?: "upload-keystore.jks"
            val candidates = listOf(
                file(storeProp),
                file("upload-keystore.jks"),
                rootProject.file(storeProp),
                rootProject.file("app/$storeProp"),
                rootProject.file("app/upload-keystore.jks")
            )
            storeFile = candidates.firstOrNull { it.exists() } ?: file(storeProp)
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
