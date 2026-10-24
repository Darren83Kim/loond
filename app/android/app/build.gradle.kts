import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.loond.loond"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.loond.loond"
        // Flutter SDK floor (3.47: 24). Hard-coded 21 was already raised to 24
        // by plugin manifest merger, so the Play device set does not shrink.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Production AdMob app id. The debug build type overrides this with
        // the Google sample id. Profile keeps this production id.
        manifestPlaceholders["admobAppId"] = "ca-app-pub-8022343674155817~5561639742"
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        getByName("debug") {
            manifestPlaceholders["admobAppId"] = "ca-app-pub-3940256099942544~3347511713"
        }
        release {
            // R8 writes app/build/app/outputs/mapping/release/mapping.txt.
            // Upload that file to Play (DEX obfuscation warning).
            // Keep rules: proguard-rules.pro. A past release crashed at launch
            // because R8 removed WorkDatabase_Impl; that class is kept explicitly.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                // Local/dev fallback only — Play upload needs key.properties + upload jks.
                signingConfigs.getByName("debug")
            }
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

// Flutter creates the profile build type in its own afterEvaluate. Set the
// production app id after that so profile does not inherit the debug sample id.
afterEvaluate {
    android.buildTypes.findByName("profile")?.manifestPlaceholders?.put(
        "admobAppId",
        "ca-app-pub-8022343674155817~5561639742",
    )
}
