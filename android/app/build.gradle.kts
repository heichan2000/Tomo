import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// The Play upload key (spec §14): android/key.properties, git-ignored, names a
// keystore kept outside the repo. Only release builds need it.
val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val keyProblem: String? = run {
    val missing = listOf("storeFile", "keyAlias", "password")
        .filter { keyProperties.getProperty(it).isNullOrBlank() }
    when {
        missing.isNotEmpty() ->
            "android/key.properties is missing or lacks ${missing.joinToString()}"
        !file(keyProperties.getProperty("storeFile")).exists() ->
            "the keystore ${keyProperties.getProperty("storeFile")} is not there"
        else -> null
    }
}

android {
    namespace = "io.github.heichan2000.tomo"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications will not build without this (spec §15.5).
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // Final, and fixed for good at the first Play upload (spec §17, C14).
        applicationId = "io.github.heichan2000.tomo"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Android 8: notification channels and adaptive icons both start here
        // (spec §15.1).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (keyProblem == null) {
            create("upload") {
                storeFile = file(keyProperties.getProperty("storeFile"))
                keyAlias = keyProperties.getProperty("keyAlias")
                storePassword = keyProperties.getProperty("password")
                keyPassword = keyProperties.getProperty("password")
            }
        }
    }

    buildTypes {
        debug {
            // Installs beside the real app as "Tomo Dev" (spec §15.5); the name
            // is in src/debug/res/values/strings.xml.
            applicationIdSuffix = ".dev"
        }
        release {
            // Never the debug key: Play rejects it. Without the upload key a
            // release build stops (below) rather than signing with anything else.
            signingConfig = signingConfigs.findByName("upload")
        }
    }
}

gradle.taskGraph.whenReady {
    if (keyProblem != null && allTasks.any { it.name.contains("Release") }) {
        throw GradleException(
            "Release builds are signed with Tomo's upload key, but $keyProblem. " +
                "See spec §14 for where the key lives.",
        )
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
