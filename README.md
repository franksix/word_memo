### 🇨🇳 国内开发环境配置

在中国大陆开发 Flutter 项目时，Gradle 和 Flutter 依赖的默认下载源速度极慢，首次构建可能卡住数十分钟甚至失败。**开始开发前，请先完成下面 3 步配置。**

#### 1. 替换 Gradle 下载镜像

打开 `android/gradle/wrapper/gradle-wrapper.properties`，找到 `distributionUrl` 这一行，将 `services.gradle.org` 替换为腾讯云镜像：

```properties
# 修改前
distributionUrl=https\://services.gradle.org/distributions/gradle-9.3.1-all.zip

# 修改后（推荐）
distributionUrl=https\://mirrors.cloud.tencent.com/gradle/gradle-9.3.1-all.zip
```

> 腾讯云镜像覆盖绝大多数 Gradle 版本，地址规律为 `https://mirrors.cloud.tencent.com/gradle/gradle-<版本>-all.zip`。如果某个版本在腾讯云缺失，可改用阿里云：`https://mirrors.aliyun.com/gradle/gradle-<版本>-all.zip`。

#### 2. 设置 Flutter 环境变量镜像

Flutter 官方的 Pub 包和引擎产物也走境外源，需要设置两个环境变量。**永久生效的方式**：在系统环境变量中添加：

| 变量名 | 值 |
|---|---|
| `PUB_HOSTED_URL` | `https://pub.flutter-io.cn` |
| `FLUTTER_STORAGE_BASE_URL` | `https://storage.flutter-io.cn` |

这两个值是 Flutter 官方文档推荐的中国镜像配置。设置完成后**重新打开终端/Android Studio**，再执行 `flutter pub get` 或构建。

#### 3.  Gradle 优先走阿里云 Maven 镜像

打开 `android/settings.gradle.kts`（或 `android/build.gradle`），在 `repositories` 块中**阿里云镜像放在最前面**，官方源保留在后面作为回退：

```kotlin
repositories {
    maven { url = uri("https://maven.aliyun.com/repository/google") }
    maven { url = uri("https://maven.aliyun.com/repository/public") }
    maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
    google()          // 保留，作为镜像缺失时的回退
    mavenCentral()    // 同上
}
```

阿里云的 `google`、`public`、`gradle-plugin` 仓库分别对应 Google Maven、Maven Central 和 Gradle 插件门户，是国内 Flutter 项目最常用的镜像组合。

---

完成以上 3 步后，在 Android Studio 中 **Sync Project with Gradle Files**，首次构建的下载速度会有明显提升。

> **进阶提示**：如果希望进一步加快日常构建，可以在 `android/gradle.properties` 中确认以下两项已开启（Flutter 模板通常已默认配置，如无则手动加上）：
> ```properties
> org.gradle.parallel=true
> org.gradle.caching=true
> ```
> `parallel` 启用并行构建，`caching` 复用构建缓存，两者配合可显著缩短重复构建时间。