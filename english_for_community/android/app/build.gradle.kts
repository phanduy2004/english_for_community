plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")      // đúng cho Kotlin DSL
    id("dev.flutter.flutter-gradle-plugin") // sau Android & Kotlin
}

android {

    namespace = "com.example.english_for_community"
    compileSdk =36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.english_for_community"
        ndk {
            // Cú pháp đúng: Dùng += listOf() để thêm vào danh sách
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
        // Nếu có plugin đòi minSdk cao (vd. flutter_timezone), đảm bảo >= 26.
        // Nếu không, có thể giữ nguyên flutter.minSdkVersion.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Desugaring (ổn)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // ❌ KHÔNG cần thêm kotlin-stdlib — plugin Kotlin đã kéo sẵn.
    // Nếu vẫn muốn chỉ rõ, dùng: implementation(kotlin("stdlib"))  (không cần version)
}
