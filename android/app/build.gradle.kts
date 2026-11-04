import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")

    // FlutterFire Configuration
    id("com.google.gms.google-services")

    // Flutter Gradle Plugin
    id("dev.flutter.flutter-gradle-plugin")
}

// ============================================================
// RHEAAI RELEASE KEYSTORE CONFIGURATION
// ============================================================

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(
        FileInputStream(keystorePropertiesFile)
    )
}

android {

    // Updated RheaAI package identity
    namespace = "com.rheaai.healthcoach"

    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    // ========================================================
    // JAVA CONFIGURATION
    // ========================================================

    compileOptions {
        isCoreLibraryDesugaringEnabled = true

        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }


   // ========================================================
// APPLICATION CONFIGURATION
// ========================================================

defaultConfig {
    // RheaAI Android package name
    applicationId = "com.rheaai.healthcoach"

    minSdk = flutter.minSdkVersion
    targetSdk = 36

    versionCode = flutter.versionCode
    versionName = flutter.versionName
}

    // ========================================================
    // PRODUCTION RELEASE SIGNING
    // ========================================================

    signingConfigs {
        create("release") {

            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?

            storeFile = keystoreProperties["storeFile"]?.let {
                file(it)
            }

            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    // ========================================================
    // BUILD TYPES
    // ========================================================

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    // Preserve your existing lint configuration
    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }
}

// ============================================================
// KOTLIN CONFIGURATION
// ============================================================

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

// ============================================================
// DEPENDENCIES
// ============================================================

dependencies {

    // Required by flutter_local_notifications
    coreLibraryDesugaring(
        "com.android.tools:desugar_jdk_libs:2.1.5"
    )
}

// ============================================================
// FLUTTER CONFIGURATION
// ============================================================

flutter {
    source = "../.."
}