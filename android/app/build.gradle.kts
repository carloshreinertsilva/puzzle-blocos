import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The upload key for Google Play lives outside the repository: either
// android/key.properties (on your computer) or environment variables (in
// CI, from GitHub secrets). Without it, release builds fall back to the
// debug key, which is fine for testing but rejected by the Play Store.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
fun signingValue(name: String, env: String): String? =
    keyProperties.getProperty(name) ?: System.getenv(env)
val uploadStoreFile = signingValue("storeFile", "CAPI_KEYSTORE_PATH")

android {
    namespace = "com.capiblocks.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Never change this after the first upload to Google Play.
        applicationId = "com.capiblocks.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (uploadStoreFile != null) {
            create("upload") {
                storeFile = rootProject.file(uploadStoreFile)
                storePassword = signingValue("storePassword", "CAPI_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "CAPI_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "CAPI_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (uploadStoreFile != null) {
                signingConfigs.getByName("upload")
            } else {
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
