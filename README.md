# 糖尿病健康管家 (Diabetes Health Manager)

一个面向糖尿病患者的全栈健康管理应用，支持血糖追踪、饮食记录、运动管理、健康报告、社区互动和用药提醒。

## 技术栈

| 层级 | 技术 | 说明 |
|------|------|------|
| 前端 | Flutter (Dart) | Material 3，支持 Android/iOS/Web/Desktop |
| 后端 | Spring Boot 3.3 (Java 17) | RESTful API，Spring Security + JWT |
| 数据库 | MySQL | JPA/Hibernate ORM |
| 缓存 | Redis + Caffeine | JWT 黑名单 + 应用缓存 |

## 功能模块

- **血糖管理** — 记录、趋势图表、异常提醒
- **饮食管理** — 膳食记录、食物营养库、AI 拍照识别
- **运动管理** — 运动记录、卡路里计算
- **健康报告** — 数据汇总、PDF 导出
- **病友社区** — 发帖、评论、点赞、收藏
- **用药提醒** — 定时提醒、推送通知

## 快速开始

### 环境要求

- Java 17+
- Flutter SDK 3.11+
- MySQL 8.0+
- Redis 6.0+

### 后端启动

```bash
cd backend
cp .env.example .env  # 编辑配置
mvn spring-boot:run
```

### 前端启动

```bash
cd new_app/new_app
flutter pub get
flutter run
```

### 构建发布

```bash
# 后端
cd backend && mvn clean package

# 前端 APK
cd new_app/new_app && flutter build apk --release
```

## 项目结构

```
├── backend/          # Spring Boot 后端
│   ├── src/main/java/com/diabetes/health/
│   │   ├── controller/   # REST 控制器
│   │   ├── service/      # 业务逻辑
│   │   ├── entity/       # JPA 实体
│   │   ├── dto/          # 数据传输对象
│   │   ├── security/     # JWT + Spring Security
│   │   └── config/       # 配置类
│   └── src/test/         # 单元测试
├── new_app/new_app/  # Flutter 前端
│   ├── lib/
│   │   ├── screens/      # 页面
│   │   ├── services/     # API 服务
│   │   ├── providers/    # 状态管理 (Provider)
│   │   ├── widgets/      # 可复用组件
│   │   ├── utils/        # 工具函数
│   │   ├── theme/        # 主题配置
│   │   └── config/       # 配置
│   └── test/             # 测试
└── .github/workflows/  # CI/CD
```

## CI/CD

GitHub Actions 自动化流程：
1. 后端单元测试 (`mvn test`)
2. Flutter 静态分析 + 测试 (`flutter analyze && flutter test`)
3. 构建 APK + AAB

## 许可证

私有项目，未经授权禁止使用。
