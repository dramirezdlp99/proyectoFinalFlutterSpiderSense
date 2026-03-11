plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.spidersense"
    compileSdk = flutter.compileSdkVersion

    defaultConfig {
        applicationId = "com.example.spidersense"
        // Cambiamos esto a 23 manualmente para evitar el error y cumplir con la cámara
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        // Corregimos el error del jvmTarget usando el formato moderno
        freeCompilerArgs += "-Xjvm-default=all"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}