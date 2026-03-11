plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    // Sincronizado con tu MainActivity.kt
    namespace = "com.ramirez.spidersense.spidersense" 
    compileSdk = 36 

    defaultConfig {
        // Este ID debe ser idéntico al namespace para evitar el error de ClassNotFound
        applicationId = "com.ramirez.spidersense.spidersense"
        
        // Usamos el número directo para asegurar compatibilidad con la cámara
        minSdk = flutter.minSdkVersion 
        targetSdk = 36
        
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

flutter {
    source = "../.."
}
