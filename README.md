# DiabetesApp

糖尿病健康管理项目，已整理为一个干净的 GitHub 交付仓库，包含：

- `backend/`
  Spring Boot 后端，负责用户、血糖、饮食、运动、提醒、健康报告等接口
- `frontend/`
  Flutter 前端，负责移动端 UI、记录流程、提醒设置、饮食拍照识别和报告展示

## 项目结构

```text
DiabetesApp/
├─ backend/        # Java Spring Boot 后端
├─ frontend/       # Flutter 前端
├─ README.md
└─ USAGE_GUIDE.md  # 详细使用教程
```

## 主要功能

- 血糖记录与趋势分析
- 饮食记录、每日食谱、食物库
- 运动记录与消耗建议
- 健康报告与导出
- 血糖提醒推送
- 个人信息与健康档案管理
- 饮食拍照识别热量估算

## 快速启动

### 1. 启动后端

进入后端目录：

```bash
cd backend
```

使用 Maven 启动：

```bash
mvn spring-boot:run
```

默认端口：

```text
http://127.0.0.1:8080
```

健康检查接口：

```text
http://127.0.0.1:8080/api/health
```

### 2. 启动前端

进入前端目录：

```bash
cd frontend
flutter pub get
flutter run
```

如果运行在 Android 真机并通过 USB 连电脑，建议执行：

```bash
adb reverse tcp:8080 tcp:8080
```

这样前端可以直接访问本机后端。

## 文档

详细环境准备、数据库配置、前后端联调、打包和常见问题，请看：

[USAGE_GUIDE.md](./USAGE_GUIDE.md)
