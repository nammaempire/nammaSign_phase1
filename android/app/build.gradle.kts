import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing — credentials are loaded from android/key.properties (which
// is git-ignored). A *release* build MUST be signed with the real upload key:
// a debug-signed AAB is rejected by the Play Store and is insecure. So we only
// wire up release signing when the keystore is present AND complete, and we
// fail the build loudly (see gradle.taskGraph.whenReady below) if a release is
// requested without it — rather than silently falling back to debug signing.
// Debug builds (`flutter run`) are unaffected and need no keystore.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

val hasReleaseSigning = keystorePropertiesFile.exists() &&
    keystoreProperties["keyAlias"] != null &&
    keystoreProperties["keyPassword"] != null &&
    keystoreProperties["storeFile"] != null &&
    keystoreProperties["storePassword"] != null

// Abort loudly if a release assembly task is requested without a real keystore,
// instead of producing a debug-signed (un-shippable) artifact. Scoped to the
// task graph so debug builds and `flutter run` continue to work with no keystore.
gradle.taskGraph.whenReady {
    val buildingRelease = gradle.taskGraph.allTasks.any { task ->
        val n = task.name
        (n.startsWith("assemble") || n.startsWith("bundle") || n.startsWith("package")) &&
            n.endsWith("Release")
    }
    if (buildingRelease && !hasReleaseSigning) {
        throw GradleException(
            "Release build requested but android/key.properties is missing or " +
                "incomplete. A debug-signed release cannot be shipped to the " +
                "Play Store. Create android/key.properties with keyAlias, " +
                "keyPassword, storeFile and storePassword pointing at your " +
                "upload keystore, then rebuild.",
        )
    }
}

android {
    namespace = "com.nammaempire.nammasign"
    // Override Flutter's default (currently 34) — file_picker's
    // flutter_plugin_android_lifecycle dep now requires compileSdk 36.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Production application id. Must match the package registered in
        // Firebase (google-services.json). Permanent once shipped.
        applicationId = "com.nammaempire.nammasign"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile =
                    (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Only ever sign release with the real upload key. If the keystore
            // is absent the build is aborted above (gradle.taskGraph.whenReady)
            // rather than falling back to debug signing.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                null
            }
            // R8 code shrinking + obfuscation, with keep rules in
            // proguard-rules.pro (Firebase, Crashlytics line numbers, Flutter
            // embedding). The app serializes via generated json_serializable /
            // freezed code (no reflection), so shrinking is safe here.
            // NOTE: always smoke-test the release build after changing deps —
            // a missing keep rule only surfaces at runtime in release.
            isMinifyEnabled = true
            isShrinkResources = true
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
