# Spring Boot 启动配置说明

## 📋 目录结构

```
backend/
├── src/main/java/com/diabetes/health/
│   ├── DiabetesHealthApplication.java    # 主启动类
│   └── config/
│       ├── AppProperties.java            # 应用配置属性类
│       └── JwtProperties.java            # JWT 配置属性类
└── src/main/resources/
    ├── application.yml                   # 主配置文件
    ├── application-dev.yml               # 开发环境配置
    ├── application-prod.yml              # 生产环境配置
    └── application-test.yml              # 测试环境配置
```

## 🚀 启动方式

### 方式一：使用 IDEA 启动（推荐）

1. **导入项目**
   - 打开 IDEA → File → Open
   - 选择 `backend` 目录
   - 等待 Maven 依赖下载完成

2. **配置运行配置**
   - 点击右上角 "Edit Configurations"
   - 点击 "+" → Application
   - Main class: `com.diabetes.health.DiabetesHealthApplication`
   - JRE: 选择 JDK 17+
   - VM options (可选): `-Xms512m -Xmx1024m`

3. **选择运行环境**
   - 在 VM options 中添加：`-Dspring.profiles.active=dev`
   - 或在 `application.yml` 中修改 `spring.profiles.active`

4. **启动**
   - 点击绿色运行按钮

### 方式二：使用 Maven 命令启动

```bash
# 开发环境
cd backend
mvn spring-boot:run -Dspring-boot.run.profiles=dev

# 生产环境
mvn spring-boot:run -Dspring-boot.run.profiles=prod

# 测试环境
mvn spring-boot:run -Dspring-boot.run.profiles=test
```

### 方式三：打包后运行

```bash
# 1. 打包
cd backend
mvn clean package -DskipTests

# 2. 运行
java -jar target/health-management-backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev
```

## 🔧 环境配置说明

### 开发环境 (dev)

- **数据库**: MySQL - `diabetes_health_dev`
- **端口**: 8080
- **日志级别**: DEBUG
- **JPA DDL**: update (自动更新表结构)
- **JWT 过期时间**: 7 天

### 生产环境 (prod)

- **数据库**: MySQL - `diabetes_health`
- **支持环境变量**:
  - `DB_HOST`: 数据库主机 (默认 localhost)
  - `DB_PORT`: 数据库端口 (默认 3306)
  - `DB_USERNAME`: 数据库用户名
  - `DB_PASSWORD`: 数据库密码
  - `JWT_SECRET`: JWT 密钥
- **JPA DDL**: validate (验证表结构)
- **JWT 过期时间**: 3 天

### 测试环境 (test)

- **数据库**: H2 (内存数据库)
- **JPA DDL**: create-drop (每次测试重建表)
- **JWT 过期时间**: 1 小时
- **H2 Console**: http://localhost:8080/api/h2-console

## ⚙️ 核心配置项

### 服务器配置

```yaml
server:
  port: 8080                    # 服务端口
  servlet:
    context-path: /api          # 上下文路径
  tomcat:
    connection-timeout: 20000   # 连接超时 (毫秒)
    threads:
      max: 200                  # 最大线程数
      min-spare: 10             # 最小空闲线程
```

### 数据库配置

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/diabetes_health
    username: root
    password: ${DB_PASSWORD}
    hikari:
      maximum-pool-size: 10     # 最大连接数
      minimum-idle: 5           # 最小空闲连接
      connection-timeout: 30000 # 连接超时
```

### JWT 配置

```yaml
app:
  jwt:
    secret: your-secret-key-at-least-32-chars
    expiration-seconds: 604800  # 7 天
    header: Authorization
    token-prefix: "Bearer "
```

## 📊 访问地址

启动成功后，可以访问以下地址：

- **API 基础地址**: http://localhost:8080/api
- **Swagger UI**: http://localhost:8080/api/swagger-ui.html
- **API 文档**: http://localhost:8080/api/v3/api-docs
- **健康检查**: http://localhost:8080/api/actuator/health

## 🔍 常见问题

### 1. 端口被占用

**解决方案**: 修改端口号
```yaml
server:
  port: 8081  # 改为其他端口
```

或在启动时指定：
```bash
java -jar app.jar --server.port=8081
```

### 2. 数据库连接失败

**检查项**:
- MySQL 服务是否启动
- 数据库名、用户名、密码是否正确
- 防火墙设置

### 3. JWT 密钥长度不足

**错误信息**: `IllegalArgumentException: key length must be at least 256 bits`

**解决方案**: 确保密钥至少 32 个字符

### 4. Lombok 未生效

**解决方案**: 
- IDEA 安装 Lombok 插件
- Enable annotation processing: Settings → Build → Compiler → Annotation Processors

## 🎯 最佳实践

1. **敏感信息管理**
   - 生产环境使用环境变量
   - 不要将密码等敏感信息提交到版本控制

2. **性能优化**
   - 调整连接池大小
   - 启用 GZIP 压缩
   - 配置合适的 JVM 参数

3. **监控与日志**
   - 启用 Actuator 监控端点
   - 配置日志级别
   - 使用日志框架异步输出

## 📝 启动日志示例

```
========================================
糖尿病健康管理系统启动成功!
API 访问地址：http://localhost:8080
========================================
系统初始化完成，准备就绪...
当前时间：2026-03-14 10:30:45
```
