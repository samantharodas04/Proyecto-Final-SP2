plugins {
    id("com.android.application")
    // FlutterFire / Google services
    id("com.google.gms.google-services")
    // Kotlin
    id("kotlin-android")
    // Flutter plugin (debe ir después de Android/Kotlin)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.creditos"
    compileSdk = flutter.compileSdkVersion

    // NDK requerido por firebase_* (tú lo necesitabas en 27.x)
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.creditos"

        // ⚠️ En .kts se usa ASIGNACIÓN, no minSdkVersion(...)
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // firma de ejemplo para que --release funcione
            signingConfig = signingConfigs.getByName("debug")
            // Si más adelante firmas release real, reemplaza lo anterior
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }
}

flutter {
    source = "../.."
}

// No necesitas declarar dependencias de Firebase aquí:
// los plugins Flutter (firebase_core, firebase_auth, cloud_firestore) las traen.

