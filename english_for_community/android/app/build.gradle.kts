plugins {
    id("com.android.application")
    // Khuyến nghị dùng id mới cho Kotlin Android
    id("org.jetbrains.kotlin.android")
    // Flutter plugin phải đặt sau Android & Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.english_for_community"

    // Có thể để theo Flutter, nhưng nên đảm bảo >= 34
    compileSdk = maxOf(flutter.compileSdkVersion, 34)

    // 🔧 Ép dùng NDK đúng như log yêu cầu
    ndkVersion = "27.0.12077973"

    // AGP 8.x yêu cầu Java 17
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.english_for_community"

        // 🔧 Fix lỗi Manifest merger: Firebase Auth yêu cầu >= 23
        minSdk = flutter.minSdkVersion

        // targetSdk theo Flutter, đảm bảo >= 34
        targetSdk = maxOf(flutter.targetSdkVersion, 34)

        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Dùng debug keystore cho build nhanh; đổi sang keystore thật khi phát hành
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
