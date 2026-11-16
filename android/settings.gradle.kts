pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}
dependencyResolutionManagement {
    // 将模式设置为 PREFER_PROJECT，这是 Gradle 的默认行为，
    // 它允许项目或插件添加仓库，优先使用项目级仓库，同时保留 settings 中的作为后备。
    // 这能从根本上消除因插件动态添加仓库而导致的构建失败。[reference:1]
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)

    repositories {
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/public") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        google()
        mavenCentral()
        // 【关键步骤】提前声明 Flutter 引擎所需的 Maven 仓库。
        // 这样 Flutter 插件启动时会发现仓库已存在，便不会再次尝试动态添加，从源头避免冲突。[reference:2]
        maven {
            url = uri("https://storage.flutter-io.cn/download.flutter.io")
        }
    }
}
include(":app")
