# Spring Boot 启动配置总结

## ✅ 已完成的配置

### 1. 主启动类增强
**文件**: `DiabetesHealthApplication.java`

**新增功能**:
- ✅ 添加日志记录（使用 Lombok @Slf4j）
- ✅ 应用就绪事件监听器
- ✅ CommandLineRunner Bean（启动后初始化任务）
- ✅ 启用定时任务（@EnableScheduling）
- ✅ 详细的启动成功提示

### 2. 配置属性类
**目录**: `src/main/java/com/diabetes/health/config/`

#### a) AppProperties.java
- 应用名称和版本配置
- CORS 跨域配置
- 类型安全的配置绑定

#### b) JwtProperties.java
- JWT 密钥配置
- Token 过期时间
- Token 前缀和 Header 名称

#### c) StartupValidator.java
- 启动时自动验证关键配置
- JWT 配置验证
- 应用配置验证

### 3. 多环境配置文件
**目录**: `src/main/resources/`

#### application.yml (主配置)
```yaml
- 应用名称：diabetes-health-management
- 默认环境：dev
- Jackson 日期格式化
- 文件上传限制：10MB
- Server 端口：8080
- API 上下文路径：/api
- Tomcat 线程池配置
- GZIP 压缩启用
- SpringDoc OpenAPI 配置
- Actuator 监控端点
```

#### application-dev.yml (开发环境)
```yaml
- 数据库：diabetes_health_dev
- HikariCP 连接池配置
- JPA DDL: update
- 日志级别：DEBUG
- JWT 过期：7 天
```

#### application-prod.yml (生产环境)
```yaml
- 环境变量支持
- 数据库：diabetes_health
- 连接池优化（最大 20 连接）
- JPA DDL: validate
- 日志级别：WARN
- JWT 过期：3 天
```

#### application-test.yml (测试环境)
```yaml
- H2 内存数据库
- JPA DDL: create-drop
- H2 Console 启用
- JWT 过期：1 小时
```

### 4. 依赖增强 (pom.xml)
新增依赖:
- ✅ H2 Database (测试用)
- ✅ Spring Boot Actuator (监控)
- ✅ SpringDoc OpenAPI (Swagger UI)

### 5. 启动脚本

#### start.bat (Windows)
- 交互式菜单
- 支持 dev/prod/test/profiles
- 打包功能
- 一键运行

#### start.sh (Linux/Mac)
- 彩色输出
- 交互式菜单
- 支持所有 profiles
- 打包和运行

### 6. IDEA 运行配置
**文件**: `.idea/runConfigurations.xml`

预配置:
- DiabetesHealthApplication [dev] - JVM: -Xms512m -Xmx1024m
- DiabetesHealthApplication [prod] - JVM: -Xms1024m -Xmx2048m
- DiabetesHealthApplication [test] - JVM: -Xms256m -Xmx512m

### 7. 文档

#### README.md
- 快速启动指南
- 配置说明
- 故障排查
- 访问地址

#### SPRING_BOOT_STARTUP_GUIDE.md
- 详细启动说明
- 环境配置详解
- 核心配置项说明
- 最佳实践

## 📊 项目结构

```
backend/
├── src/main/java/com/diabetes/health/
│   ├── DiabetesHealthApplication.java    # ✨ 增强版主启动类
│   └── config/
│       ├── AppProperties.java            # ✨ 新增
│       ├── JwtProperties.java            # ✨ 新增
│       └── StartupValidator.java         # ✨ 新增
├── src/main/resources/
│   ├── application.yml                   # ✨ 增强版主配置
│   ├── application-dev.yml               # ✨ 新增
│   ├── application-prod.yml              # ✨ 新增
│   └── application-test.yml              # ✨ 新增
├── .idea/
│   └── runConfigurations.xml             # ✨ 新增 IDEA 运行配置
├── pom.xml                               # ✨ 增强版（新增依赖）
├── start.bat                             # ✨ Windows 启动脚本
├── start.sh                              # ✨ Linux/Mac 启动脚本
├── README.md                             # ✨ 快速启动文档
├── SPRING_BOOT_STARTUP_GUIDE.md          # ✨ 详细配置文档
└── .gitignore                            # ✨ 增强版
```

## 🎯 核心特性

### 1. 多环境支持
- **开发环境 (dev)**: 自动更新表结构，详细日志
- **生产环境 (prod)**: 严格验证，环境变量支持
- **测试环境 (test)**: H2 内存数据库，快速测试

### 2. 配置验证
启动时自动验证:
- JWT 密钥长度（≥32 字符）
- JWT 过期时间（>0）
- 应用名称（非空）
- CORS 配置（非空）

### 3. 监控和管理
- Actuator 健康检查端点
- Metrics 指标收集
- Swagger UI API 文档
- H2 Console（测试环境）

### 4. 性能优化
- HikariCP 连接池
- Tomcat 线程池配置
- GZIP 压缩
- JSON 序列化优化

## 🚀 快速开始

### 方式 1: 使用启动脚本（推荐）
```bash
# Windows
start.bat

# Linux/Mac
./start.sh
```

### 方式 2: Maven 命令
```bash
# 开发环境
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 生产环境
mvn spring-boot:run -Dspring-boot.run.profiles=prod
```

### 方式 3: IDEA
直接运行 `DiabetesHealthApplication` 类中的 main 方法

## 🌐 访问地址

启动成功后:

| 服务 | 地址 |
|------|------|
| API 基础地址 | http://localhost:8080/api |
| Swagger UI | http://localhost:8080/api/swagger-ui.html |
| API 文档 | http://localhost:8080/api/v3/api-docs |
| 健康检查 | http://localhost:8080/api/actuator/health |

## 📋 启动检查清单

启动前请确保:
- [ ] JDK 17+ 已安装
- [ ] MySQL 服务已启动
- [ ] 数据库已创建
- [ ] 数据库用户名密码已配置
- [ ] 端口 8080 未被占用

## 🔍 常见问题

### 1. 端口被占用
修改 `application.yml`:
```yaml
server:
  port: 8081
```

### 2. 数据库连接失败
检查 `application-dev.yml`:
```yaml
spring:
  datasource:
    username: your_username
    password: your_password
```

### 3. JWT 密钥错误
确保密钥至少 32 字符:
```yaml
app:
  jwt:
    secret: this-is-a-very-long-secret-key-at-least-32-characters
```

## 📈 后续优化建议

1. **日志管理**: 集成 Logback 或 Log4j2
2. **链路追踪**: 集成 Sleuth + Zipkin
3. **安全加固**: 配置 HTTPS
4. **性能监控**: 集成 Prometheus + Grafana
5. **容器化**: 创建 Docker 镜像

## 💡 提示

- 开发时使用 `dev` profile，享受热部署和详细日志
- 测试使用 `test` profile，H2 数据库无需安装 MySQL
- 生产部署使用 `prod` profile，配合环境变量管理敏感信息

---

**配置完成时间**: 2026-03-14  
**Spring Boot 版本**: 3.3.2  
**Java 版本**: 17+
