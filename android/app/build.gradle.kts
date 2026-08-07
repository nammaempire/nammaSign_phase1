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

// Local-testing escape hatch: set the env var ALLOW_DEBUG_SIGNED_RELEASE=true to
// build a DEBUG-SIGNED release without a keystore. This is for local testing
// ONLY — such an artifact can NOT be uploaded to the Play Store. The default
// (env var unset) still fails loudly, so a debug-signed build can never ship by
// accident.
val allowDebugSignedRelease =
    (System.getenv("ALLOW_DEBUG_SIGNED_RELEASE") ?: "").equals("true", ignoreCase = true)

// Abort loudly if a release assembly task is requested without a real keystore,
// instead of producing a debug-signed (un-shippable) artifact. Scoped to the
// task graph so debug builds and `flutter run` continue to work with no keystore.
gradle.taskGraph.whenReady {
    val buildingRelease = gradle.taskGraph.allTasks.any { task ->
        val n = task.name
        (n.startsWith("assemble") || n.startsWith("bundle") || n.startsWith("package")) &&
            n.endsWith("Release")
    }
    if (buildingRelease && !hasReleaseSigning && !allowDebugSignedRelease) {
        throw GradleException(
            "Release build requested but android/key.properties is missing or " +
                "incomplete. A debug-signed release cannot be shipped to the " +
                "Play Store. Either:\n" +
                "  • create android/key.properties with keyAlias, keyPassword, " +
                "storeFile and storePassword pointing at your upload keystore " +
                "(required for a Play Store build), or\n" +
                "  • for LOCAL TESTING ONLY, set ALLOW_DEBUG_SIGNED_RELEASE=true " +
                "to build a debug-signed release that cannot be published.",
        )
    }
    if (buildingRelease && !hasReleaseSigning && allowDebugSignedRelease) {
        logger.warn(
            "⚠️  Building a DEBUG-SIGNED release (ALLOW_DEBUG_SIGNED_RELEASE=true). " +
                "For LOCAL TESTING ONLY — this artifact cannot be uploaded to the " +
                "Play Store.",
        )
    }
}

android {
    namespace = "com.nammaempire.nammasign"
    // Override Flutter's default (currently 34) — file_picker's
    // flutter_plugin_android_lifecycle dep now requires compileSdk 36.
    compileSdk = 36
    // Pin the NDK to the version the Firebase/plugins require (they all ask
    // for 28.2.13676358). Using an explicit, installed version ensures the
    // release-bundle debug-symbol strip step finds the NDK toolchain reliably.
    ndkVersion = "28.2.13676358"

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
            // Sign release with the real upload key. If the keystore is absent
            // the build is aborted above (gradle.taskGraph.whenReady), unless the
            // ALLOW_DEBUG_SIGNED_RELEASE opt-in is set for local testing — then we
            // fall back to debug signing (which can never be shipped to Play).
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else if (allowDebugSignedRelease) {
                signingConfigs.getByName("debug")
            } else {
                null
            }
            // R8 code shrinking + obfuscation is temporarily DISABLED: with it
            // on, the release build crashed on launch ("keeps stopping"), which
            // means a keep rule is missing for some dependency. Ship working
            // first; re-enable below once the missing rule is identified from a
            // release logcat and added to proguard-rules.pro, then smoke-tested.
            //   isMinifyEnabled = true
            //   isShrinkResources = true
            //   proguardFiles(
            //       getDefaultProguardFile("proguard-android-optimize.txt"),
            //       "proguard-rules.pro",
            //   )
            isMinifyEnabled = false
            isShrinkResources = false
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
