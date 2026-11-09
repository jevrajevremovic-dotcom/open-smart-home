import java.util.Properties

// The Wear OS companion: the car buttons on the watch. It talks only to the
// phone app (Wear Data Layer); same application id and the same key, which
// is what lets the two find each other.
plugins {
    id("com.android.application")
}

val keyProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKey = keyProperties.getProperty("storeFile") != null

// Version from pubspec.yaml, like the phone app.
val pubspecVersion = rootProject.file("../pubspec.yaml").readLines()
    .first { it.startsWith("version:") }
    .substringAfter(":").trim()

android {
    namespace = "org.opensmarthome.open_smart_home.wear"
    compileSdk = 36

    defaultConfig {
        applicationId = "org.opensmarthome.open_smart_home"
        minSdk = 30
        targetSdk = 36
        versionName = pubspecVersion.substringBefore("+")
        versionCode = pubspecVersion.substringAfter("+").toInt()
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (hasReleaseKey) {
            create("release") {
                // Resolved like the phone app's (android/app/...).
                storeFile = rootProject.file("app").resolve(keyProperties.getProperty("storeFile"))
                storePassword = keyProperties.getProperty("storePassword")
                keyAlias = keyProperties.getProperty("keyAlias")
                keyPassword = keyProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKey) {
                signingConfigs.getByName("release")
            } else {
                logger.warn("key.properties not found: wear release signed with the DEBUG key")
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}
