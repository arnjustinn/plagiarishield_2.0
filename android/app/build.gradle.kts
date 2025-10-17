plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.plagiarishield"
    compileSdk = 35

    defaultConfig {
        applicationId = "com.example.plagiarishield"
        minSdk = 21        // replace with your desired minSdk
        targetSdk = 35
        versionCode = 1    // replace with your versionCode
        versionName = "1.0.0"  // replace with your versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false 
            
        }
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.google.android.material:material:1.9.0")
}

flutter {
    source = "../.."
}
