# DiabetesApp 使用教程与说明

## 1. 项目简介

这是一个糖尿病健康管理项目，分为前后端两部分：

- `backend/`：Spring Boot 后端服务
- `frontend/`：Flutter 移动端前端

项目目标是为用户提供血糖、饮食、运动、提醒和健康报告的一体化管理能力。

## 2. 运行环境要求

### 后端

- JDK 17 或以上
- Maven 3.9 或以上
- MySQL 8.x

### 前端

- Flutter SDK
- Dart SDK
- Android Studio / VS Code
- Android 模拟器或 Android 真机

## 3. 后端说明

### 目录结构

后端主要代码在：

```text
backend/src/main/java/com/diabetes/health/
```

核心模块包括：

- `controller/`：接口层
- `service/`：业务逻辑层
- `repository/`：数据库访问层
- `entity/`：实体类
- `dto/`：数据传输对象
- `config/`：配置类

### 配置文件

后端配置文件位于：

```text
backend/src/main/resources/
```

默认主配置中使用的是本地 MySQL：

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/diabetes_health?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Shanghai&characterEncoding=utf-8
    username: root
    password: 1234

server:
  port: 8080
```

正式使用前，建议你把数据库账号密码改成自己的。

### 创建数据库

先在 MySQL 中创建数据库：

```sql
CREATE DATABASE diabetes_health CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```

### 启动后端

```bash
cd backend
mvn spring-boot:run
```

或者在 Windows 下：

```bash
start.bat
```

启动成功后可访问：

```text
http://127.0.0.1:8080/api/health
```

## 4. 前端说明

### 目录结构

前端主要代码在：

```text
frontend/lib/
```

重点目录：

- `screens/`：页面
- `services/`：接口调用、鉴权、通知、识别等服务
- `widgets/`：通用 UI 组件
- `theme/`：主题和视觉配置
- `config/`：接口地址等配置

### 关键页面

- `home_screen.dart`：首页
- `glucose_screen.dart`：血糖模块
- `diet_screen.dart`：饮食模块
- `exercise_screen.dart`：运动模块
- `report_screen.dart`：健康报告
- `profile_screen.dart`：我的 / 个人中心

### 启动前端

```bash
cd frontend
flutter pub get
flutter run
```

如果是 Android 真机调试，建议先执行：

```bash
adb reverse tcp:8080 tcp:8080
```

这样手机就能通过 `127.0.0.1:8080` 访问电脑上的后端。

## 5. 前后端联调说明

前端使用自动探测和本地缓存方式寻找后端地址，核心逻辑在：

```text
frontend/lib/services/api_service.dart
frontend/lib/config/api_config.dart
frontend/lib/config/server_url_prefs.dart
```

联调建议：

1. 先启动后端
2. 再启动前端
3. Android 真机优先使用 `adb reverse`
4. 如果不用 USB，就保证手机和电脑在同一局域网

## 6. 打包说明

### Android Debug APK

```bash
cd frontend
flutter build apk --debug
```

生成文件默认在：

```text
frontend/build/app/outputs/flutter-apk/app-debug.apk
```

### 安装到 Android 设备

```bash
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

## 7. 主要业务能力说明

### 血糖模块

- 记录每日血糖
- 支持空腹、餐后、睡前、随机时段
- 支持具体测量时间选择
- 提供趋势图和异常建议

### 饮食模块

- 记录饮食
- 新增食物
- 维护每日食谱
- 食物库包含热量、碳水、蛋白质、脂肪、GI 等信息
- 支持拍照识别食物并估算热量

### 运动模块

- 记录运动时长和消耗
- 根据当天饮食情况估算建议消耗量
- 推荐适合的运动方式

### 健康报告

- 展示血糖趋势
- 饮食推荐
- 支持导出

### 我的

- 编辑个人信息
- 编辑健康档案
- 设置血糖提醒
- 查看提醒列表
- 修改密码

## 8. 已整理掉的不必要内容

为了让仓库更干净，这个 GitHub 交付版没有包含下面这些本地临时文件：

- 构建产物
- 缓存目录
- IDE 本地配置
- Flutter 临时目录
- Gradle 临时目录
- 日志文件
- 调试截图 / XML 转储

## 9. 常见问题

### 9.1 前端提示网络异常

排查顺序：

1. 后端是否成功启动
2. `http://127.0.0.1:8080/api/health` 是否可访问
3. Android 真机是否执行了 `adb reverse tcp:8080 tcp:8080`
4. 是否和后端处于同一局域网

### 9.2 数据库连接失败

检查：

- MySQL 是否启动
- 数据库 `diabetes_health` 是否已创建
- `application.yml` 中账号密码是否正确

### 9.3 Flutter 依赖异常

执行：

```bash
flutter clean
flutter pub get
```

### 9.4 Maven 启动失败

执行：

```bash
mvn -v
java -version
```

确认本地 JDK 和 Maven 已安装并正确配置。

## 10. 推荐开发流程

```bash
# 启动后端
cd backend
mvn spring-boot:run

# 启动前端
cd ../frontend
flutter pub get
flutter run
```

真机调试时额外执行：

```bash
adb reverse tcp:8080 tcp:8080
```

## 11. 补充说明

这个仓库是整理后的 GitHub 交付版，目标是：

- 结构清晰
- 前后端分离明确
- 尽量减少无用文件
- 方便其他人直接 clone 后运行
