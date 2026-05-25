# 糖尿病健康管家 Flutter 前端

糖尿病健康管家前端用于记录血糖、饮食、运动、健康报告和病友社区互动。

## Getting Started

常用命令：

```bash
flutter pub get
flutter analyze
flutter build apk --debug
```

开发真机调试后端连接时，可执行：

```bash
adb reverse tcp:8080 tcp:8080
```

Release 包请通过 `--dart-define=API_BASE_URL=https://你的后端域名` 指定正式 HTTPS 后端地址。
