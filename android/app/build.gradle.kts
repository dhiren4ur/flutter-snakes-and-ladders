plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.devdhiren.snacks_ladders"
    compileSdk = 35
    ndkVersion = "27.0.12077973"


    compileOptions {1
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // ADD THIS: Release signing configuration
    signingConfigs {
        create("release") {
            storeFile = file("C:\\snacks_ladders -offline\\FINAL REQ\\N ew folder\\snk.jks")  // CHANGE THIS PATH
            storePassword = "snk100873"               // CHANGE THIS
            keyAlias = "snkalias"                           // CHANGE THIS
            keyPassword = "snk100873"                     // CHANGE THIS
        }
    }

    defaultConfig {
        applicationId = "com.devdhiren.snacks_ladders"
        minSdk = 23
        targetSdk = 35
        versionCode = 10
        versionName = "1.0.10"

    }

    buildTypes {
        release {
            // FIXED: Use release signing instead of debug
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}


