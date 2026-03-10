plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Debe coincidir con el nombre de paquete que configuramos
    namespace = "com.ramirez.spidersense" 
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
        // Tu Application ID único
        applicationId = "com.ramirez.spidersense"
        
        // CAMBIO CRÍTICO: La IA y la Cámara requieren mínimo versión 23 (Android 6.0)
        // para procesar imágenes en tiempo real y manejar permisos modernos.
        minSdk = 23 
        
        targetSdk = flutter.targetSdk
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}