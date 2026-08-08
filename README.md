# 视频转 MP3 工具集（video_2_mp3）

面向中老年用户的视频转 MP3 工具集，覆盖 **Windows 7+（HTA）** 与 **Android（Flutter）** 双平台，包含本地视频转 MP3 与糖豆链接转 MP3 两大功能。

## 目录结构

```
video_2_mp3/
├── mp4-to-mp3/          Windows：本地视频转 MP3（HTA 单工具版）
├── tangdou-to-mp3/      Windows：糖豆链接转 MP3（HTA 单工具版）
├── video-to-mp3/        Windows：双 Tab 合集版（本地 + 糖豆，一个应用）
├── mp4_to_mp3_flutter/  Android：手机版（Flutter，本地 + 糖豆两个 Tab）
└── README.md            本说明
```

## 各子文件夹功能

### mp4-to-mp3/ — Windows 本地视频转 MP3（单工具版）

- 批量把 MP4 视频提取音频转成 MP3，选择文件夹或文件均可，支持包含子文件夹
- 音质可选 128 / 192 / 320 kbps，默认 192；支持输出到指定目录（重名自动加序号）
- 高级选项：跳过前面/后面 N 秒、剪切后重复拼接 2 遍（X2）、转换成功后源文件移入回收站
- 零安装零依赖：使用 Windows 自带的 mshta.exe 运行界面，需自行放入 32 位 ffmpeg.exe（见 `bin/把ffmpeg.exe放这里.txt`）
- 使用说明见文件夹内 `README.txt`

### tangdou-to-mp3/ — Windows 糖豆链接转 MP3（单工具版）

- 粘贴糖豆/糖豆达人分享链接（h5/play 页面），自动解析视频地址并下载
- 下载后调用 ffmpeg 转成 MP3，默认输出到程序目录 `Download\`，可自定义输出目录并持久化
- 下载请求携带 Referer 头（糖豆 CDN 校验），ffmpeg 使用 `-referer` 与超时选项保证取流稳定
- 高级选项：跳过前面/后面 N 秒、剪切后重复拼接 2 遍（X2），带「清零」按钮一键恢复默认
- 转换成功后自动清理输入框中的成功链接，失败行保留便于重试
- 同样需要 32 位 ffmpeg.exe（见 `bin/把ffmpeg.exe放这里.txt`）

### video-to-mp3/ — Windows 双 Tab 合集版（推荐）

- 把上述两个工具合并为一个 HTA 应用，顶部 Tab 栏在「本地视频转MP3 / 糖豆链接转MP3」间切换
- 两个面板切换时各自保活（转换中的任务不中断），公共函数（日志、设置、ffmpeg 检测等）仅保留一份
- `settings.ini` 单文件双段存储：`[Output]` 本地输出设置、`[Tangdou]` 糖豆输出目录，互不串扰
- 默认值：本地跳过前 5 秒后 3 秒、糖豆跳过前 5 秒后 3 秒，X2 均默认不勾选
- 需要 32 位 ffmpeg.exe（见 `bin/把ffmpeg.exe放这里.txt`）

### mp4_to_mp3_flutter/ — Android 手机版

- Flutter 3.x 编写，仅支持 Android（minSdk 24 / targetSdk 34）
- 界面与 Windows 版一致的「本地视频转MP3 / 糖豆链接转MP3」双 Tab
- 本地 Tab：通过 SAF 选择 MP4 文件/文件夹，支持跳过前后秒数、X2 重复拼接、自定义输出目录
- 糖豆 Tab：粘贴分享链接解析下载并转 MP3，输出目录可选（默认系统 Music 目录）
- 无需任何存储权限：文件访问全部走系统 SAF 授权；糖豆接口为 http，已允许明文流量
- FFmpeg 通过 `ffmpeg_kit_flutter_new` 原生库集成（随 APK 内置，无需额外安装）
- 安卓打包步骤见下文「安卓打包」

## 安卓打包（mp4_to_mp3_flutter）

### 1. 环境要求

| 组件 | 版本要求 |
|---|---|
| Flutter | 3.x（Dart SDK `^3.12.2`，见 `pubspec.yaml`） |
| Android compileSdk | 36 |
| Android minSdk / targetSdk | 24 / 34 |
| JDK | 17（`build.gradle.kts` 已配置 Java 17 编译） |
| NDK | `30.0.14904198`（ffmpeg_kit 原生库需要，错误时按提示安装对应版本） |

首次构建前先确认环境：

```bash
flutter doctor
```

必须项全部通过（Android toolchain、Android Studio 或命令行 SDK 均可）。若报 NDK 缺失，在 Android Studio 的 SDK Manager 中安装 `NDK 30.0.14904198`，或执行：

```bash
flutter config --android-sdk <你的SDK路径>   # 必要时
```

### 2. 获取依赖

```bash
cd mp4_to_mp3_flutter
flutter pub get
```

主要依赖：`ffmpeg_kit_flutter_new ^4.5.3`（FFmpeg 原生封装）、`provider ^6.1.2`（状态管理）、`shared_preferences ^2.3.0`（设置持久化）、`androidx.documentfile`（SAF 文件访问）。

### 3. 构建 APK

```bash
flutter build apk --release --split-per-abi
```

- `--split-per-abi`：按 CPU 架构拆分 APK，每个 ABI 一个安装包，体积远小于全合一包
- 构建产物输出到：

```
mp4_to_mp3_flutter/build/app/outputs/flutter-apk/
├── app-arm64-v8a-release.apk    现代手机（2017 年后主流，推荐）
├── app-armeabi-v7a-release.apk  老款 32 位手机
└── app-x86_64-release.apk       x86 架构平板/模拟器
```

如需单一全量包（不分 ABI），去掉参数即可：

```bash
flutter build apk --release
```

### 4. 安装与分发

- 手机开启「允许安装未知来源应用」，把对应 ABI 的 APK 拷贝到手机点击安装即可
- 绝大多数现代手机选 `app-arm64-v8a-release.apk`；无法判断时优先尝试该包，安装报错再换 `armeabi-v7a`
- 应用名为「MP4转MP3」，安装后无任何权限申请弹窗（文件访问走系统文件选择器授权）

### 5. 签名说明

当前 `android/app/build.gradle.kts` 中 release 构建**使用 debug 签名**（开发期默认，`signingConfig = signingConfigs.getByName("debug")`），可直接安装使用，但**不适合应用商店发布**。

正式发布需配置正式签名：

1. 生成 keystore：

```bash
keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

2. 在项目根目录新建 `key.properties`（勿提交到 Git）：

```properties
storePassword=你的密码
keyPassword=你的密码
keyAlias=release
storeFile=release.jks 的绝对路径
```

3. 修改 `android/app/build.gradle.kts`，在 `android {}` 前加载签名配置：

```kotlin
import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

android {
    // ... 现有配置 ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

4. 重新执行第 3 节构建命令，产物即为正式签名 APK。

### 6. 权限与文件访问说明

| 项目 | 说明 |
|---|---|
| 存储权限 | **不申请**。文件选择全部通过 SAF（`ACTION_OPEN_DOCUMENT` / `ACTION_OPEN_DOCUMENT_TREE`），用户主动选择即授权，符合新版 Android 规范 |
| `INTERNET` | 糖豆链接解析与下载需要（糖豆 API 为 http，已开启 `usesCleartextTraffic`） |
| `WRITE_EXTERNAL_STORAGE` | 仅声明 `maxSdkVersion="28"`，即只在 Android 9 及以下生效（写入系统 Music 目录场景），高版本系统不申请 |
| FFmpeg 文件访问 | 通过 `FFmpegKitConfig.getSafParameterForRead/Write` 将 `content://` URI 转为 ffmpeg 可读路径，不做强制绝对路径转换 |

### 7. 常见问题

- **构建报 NDK 版本错误**：在 `android/app/build.gradle.kts` 将 `ndkVersion` 改为本机已装版本，或按提示安装 `30.0.14904198`
- **构建卡在 Gradle 下载**：国内网络建议配置 Gradle 镜像（阿里云 maven 仓库），或先手动下载 Gradle 发行版
- **`flutter pub get` 失败**：检查网络；必要时执行 `flutter clean` 后重试
- **APK 安装后点击无反应/闪退**：确认选择了与手机 CPU 匹配的 ABI 包；可在 `adb install` 时查看报错
- **真机 Android 9 及以下写入公共目录失败**：属于运行时权限场景，应用内已做权限申请与拒绝处理，拒绝后请到系统设置允许存储权限

## 通用说明

- **Windows 版依赖 ffmpeg.exe**：三个 HTA 工具都需要把 32 位（win32/i686）ffmpeg.exe 放入各自的 `bin\` 文件夹，下载方式见各文件夹内 `bin/把ffmpeg.exe放这里.txt`；Android 版已内置 ffmpeg 原生库，无需额外操作
- **Git 忽略规则**：`bin/ffmpeg.exe`、`settings.ini`、`Download/`、`debug.log` 均不纳入版本库（运行期产物/用户文件）
- **开发约定**：功能改动在 main 派生 worktree 分支开发，真机验证通过后合并推送 origin/main