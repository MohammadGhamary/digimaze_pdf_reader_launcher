import org.gradle.api.JavaVersion
import org.gradle.kotlin.dsl.configure
import com.android.build.api.dsl.LibraryExtension
import java.net.URL

group = "com.vnegar.digimaze_pdf_reader_launcher"
version = "1.0.0"

plugins {
    id("com.android.library")
}

val pluginLibsDir = file("$projectDir/libs")

rootProject.allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://pkgs.dev.azure.com/MicrosoftDeviceSDK/DuoSDK-Public/_packaging/Duo-SDK-Feed/maven/v1")
        }

        flatDir {
            dirs(pluginLibsDir)
        }
    }
}

val libsDir = file("$projectDir/libs")

val aarFilesToDownload = mapOf(
    "FoxitRDK.aar" to "https://files.digimaze.org/FoxitRDK.aar",
    "FoxitRDKUIExtensions.aar" to "https://files.digimaze.org/FoxitRDKUIExtensions.aar"
)

val downloadAarFiles by tasks.registering {
    doLast {
        libsDir.mkdirs()
        aarFilesToDownload.forEach { (fileName, url) ->
            val target = File(libsDir, fileName)

            if (!target.exists()) {
                println("Downloading $fileName ...")
                val tmp = File(libsDir, "$fileName.tmp")
                URL(url).openStream().use { input ->
                    tmp.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }

                val header = tmp.inputStream().use { it.readNBytes(2) }
                if (tmp.length() < 1024 || header.size < 2 || header[0] != 'P'.code.toByte() || header[1] != 'K'.code.toByte()) {
                    tmp.delete()
                    throw GradleException(
                        "Downloaded '$fileName' does not look like a valid .aar file " +
                                "(too small or not a zip archive). Check the URL is correct and publicly reachable: $url"
                    )
                }

                tmp.renameTo(target)
                println("Downloaded $fileName (${target.length() / 1024 / 1024} MB)")
            } else {
                println("$fileName already exists, skipping download.")
            }
        }
    }
}

tasks.named("preBuild") {
    dependsOn(downloadAarFiles)
}

extensions.configure<LibraryExtension> {
    namespace = "com.vnegar.digimaze_pdf_reader_launcher"

    compileSdk = 37

    defaultConfig {
        minSdk = 26
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"

        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }

        consumerProguardFiles("proguard-rules.pro")
    }

    externalNativeBuild {
        cmake {
            path = file("src/main/cpp/CMakeLists.txt")
            version = "3.22.1"
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    lint {
        disable += "InvalidPackage"
        disable += "GradleDependency"
        checkReleaseBuilds = false
        abortOnError = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("androidx.appcompat:appcompat:1.8.0")
    implementation("com.google.android.material:material:1.14.0")
    implementation("androidx.multidex:multidex:2.0.1")
    implementation(files("$pluginLibsDir/FoxitRDK.aar"))
    implementation(files("$pluginLibsDir/FoxitRDKUIExtensions.aar"))
    implementation("com.edmodo:cropper:2.0.0")
    implementation("com.microsoft.identity.client:msal:8.4.2")
    implementation("com.nostra13.universalimageloader:universal-image-loader:1.9.5")
    implementation("io.reactivex.rxjava2:rxjava:2.2.21")
    implementation("io.reactivex.rxjava2:rxandroid:2.1.1")
    implementation("org.bouncycastle:bcpkix-jdk15on:1.70")
    implementation("org.bouncycastle:bcprov-jdk15on:1.70")
    implementation("com.google.mlkit:digital-ink-recognition:19.0.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.mockito:mockito-core:5.23.0")
}