// //app level build.gradle.kts
// import java.util.Properties

// plugins {
//     id("com.android.application")
//     id("kotlin-android")
//     id("dev.flutter.flutter-gradle-plugin")
// }

// fun localProperties(): Properties {
//     val properties = Properties()
//     val localPropertiesFile = project.rootProject.file("local.properties")
//     if (localPropertiesFile.exists()) {
//         localPropertiesFile.inputStream().use { properties.load(it) }
//     }
//     return properties
// }

// val flutterVersionCode: String = localProperties().getProperty("flutter.versionCode") ?: "1"
// val flutterVersionName: String = localProperties().getProperty("flutter.versionName") ?: "1.0"

// android {
//     // It's good practice to update the namespace to your unique package name
//     namespace = "com.example.al_faruk_app" 
//     compileSdk = flutter.compileSdkVersion

//     compileOptions {
//         // --- FIX 1: ENABLE CORE LIBRARY DESUGARING ---
//         isCoreLibraryDesugaringEnabled = true
        
//         sourceCompatibility = JavaVersion.VERSION_1_8
//         targetCompatibility = JavaVersion.VERSION_1_8
//     }

//     kotlinOptions {
//         jvmTarget = "1.8"
//     }

//     defaultConfig {
//         applicationId = "com.example.al_faruk_app"
//         minSdk = flutter.minSdkVersion
//         targetSdk = flutter.targetSdkVersion
//         versionCode = flutterVersionCode.toInt()
//         versionName = flutterVersionName
//     }

//     buildTypes {
//         release {
//             signingConfig = signingConfigs.getByName("debug")
//         }
//     }
// }

// flutter {
//     source = "../.."
// }

// // --- FIX 2: ADD THE DESUGARING LIBRARY DEPENDENCY ---
// dependencies {
//     coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
// }
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    // --- ADD THIS LINE ---
    id("com.google.gms.google-services") 
}

fun localProperties(): Properties {
    val properties = Properties()
    val localPropertiesFile = project.rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { properties.load(it) }
    }
    return properties
}

val flutterVersionCode: String = localProperties().getProperty("flutter.versionCode") ?: "1"
val flutterVersionName: String = localProperties().getProperty("flutter.versionName") ?: "1.0"

android {
    // It's good practice to update the namespace to your unique package name
    namespace = "com.example.al_faruk_app" 
    compileSdk = flutter.compileSdkVersion

    compileOptions {
        // --- FIX 1: ENABLE CORE LIBRARY DESUGARING ---
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    defaultConfig {
        applicationId = "com.example.al_faruk_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutterVersionCode.toInt()
        versionName = flutterVersionName
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

// --- FIX 2: ADD THE DESUGARING LIBRARY DEPENDENCY ---
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}