plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.yourcompany.easystudy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.yourcompany.easystudy"

        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Безопасное чтение всех свойств:
            val storeFileProperty = keystoreProperties["storeFile"] as? String
            val storePasswordProperty = keystoreProperties["storePassword"] as? String
            val keyPasswordProperty = keystoreProperties["keyPassword"] as? String
            val keyAliasProperty = keystoreProperties["keyAlias"] as? String
            
            // Проверка и установка значений
            if (storeFileProperty != null) {
                storeFile = file(storeFileProperty)
            }
            storePassword = storePasswordProperty ?: ""
            keyPassword = keyPasswordProperty ?: ""
            keyAlias = keyAliasProperty ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
