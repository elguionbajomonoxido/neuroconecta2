import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Leer key.properties
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    println("WARNING: key.properties no encontrado, se usará firma debug.")
}

android {
    namespace = "com.example.neuroconecta2"
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
        // ⚠️ Cambia esto si en Play Console usaste otro ID
        applicationId = "cl.imah.neuroconecta"
        minSdkVersion(24)
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"

        multiDexEnabled = true
    }

    // 🔐 Configuración de firma para RELEASE
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
        }
        getByName("release") {
            // ❗ Antes firmaba con "debug", ahora con "release"
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// Tarea opcional para renombrar el APK (no afecta al .aab)
tasks.register("renameFlutterApk") {
    dependsOn("assembleRelease")
    doLast {
        val flutterApk = file("${buildDir}/outputs/flutter-apk/app-release.apk")
        if (flutterApk.exists()) {
            val versionName = android.defaultConfig.versionName ?: "vUnknown"
            val buildType = "release"
            val destName = "NeuroConecta-${versionName}-${buildType}.apk"
            val dest = file("${buildDir}/outputs/flutter-apk/$destName")
            flutterApk.copyTo(dest, overwrite = true)
            println("APK copiado/renombrado a: ${dest.absolutePath}")
        } else {
            println("No se encontró APK en: ${buildDir}/outputs/flutter-apk/app-release.apk")
        }
    }
}
// Asegúrate de ejecutar esta tarea después de "assembleRelease" si deseas renombrar el APK
// Puedes ejecutar: ./gradlew renameFlutterApk
// END: Firma de la aplicación Android
