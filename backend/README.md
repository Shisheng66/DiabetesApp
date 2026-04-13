# 🚀 Spring Boot 启动说明

## ⚡ 快速启动（推荐）

### Windows 用户

双击运行 `start.bat` 或在命令行执行：
```bash
start.bat
```

然后按照菜单提示选择环境即可。

### Linux/Mac 用户

```bash
chmod +x start.sh
./start.sh
```

## 📝 配置说明

### 1. 数据库准备

确保 MySQL 服务已启动，并创建数据库：

```sql
CREATE DATABASE IF NOT EXISTS diabetes_health_dev 
DEFAULT CHARACTER SET utf8mb4 
DEFAULT COLLATE utf8mb4_unicode_ci;
```

### 2. 修改数据库配置

编辑 `src/main/resources/application-dev.yml`:

```yaml
spring:
  datasource:
    username: your_mysql_username  # 改为你的 MySQL 用户名
    password: your_mysql_password  # 改为你的 MySQL 密码
```

### 3. 首次启动检查清单

- [ ] MySQL 服务已启动
- [ ] 数据库已创建
- [ ] 数据库用户名密码已配置
- [ ] JDK 17+ 已安装
- [ ] Maven 已安装（如果使用命令行）

## 🎯 启动成功标志

看到以下日志表示启动成功：

```
========================================
糖尿病健康管理系统启动成功!
API 访问地址：http://localhost:8080
========================================
系统初始化完成，准备就绪...
当前时间：2026-03-14 10:30:45
```

## 🌐 访问应用

启动成功后，可以访问：

- **API 地址**: http://localhost:8080/api
- **Swagger UI**: http://localhost:8080/api/swagger-ui.html
- **健康检查**: http://localhost:8080/api/actuator/health

## 🔧 故障排查

### 问题 1: 端口被占用

**错误信息**: `Port 8080 was already in use`

**解决方案**:
```bash
# 方法 1: 杀死占用端口的进程
netstat -ano | findstr :8080
taskkill /PID <PID> /F

# 方法 2: 修改端口号
# 编辑 application-dev.yml，将 server.port 改为其他值
```

### 问题 2: 数据库连接失败

**错误信息**: `Access denied for user 'root'@'localhost'`

**解决方案**:
1. 检查 MySQL 服务是否启动
2. 确认用户名密码正确
3. 检查数据库是否存在

### 问题 3: JWT 密钥长度不足

**错误信息**: `key length must be at least 256 bits`

**解决方案**:
确保 `application-dev.yml` 中的 `app.jwt.secret` 至少 32 个字符。

## 📖 详细文档

更多配置和高级用法请查看：[SPRING_BOOT_STARTUP_GUIDE.md](SPRING_BOOT_STARTUP_GUIDE.md)

## 💡 提示

- **开发环境**: 使用 `dev` profile，自动更新数据库表结构
- **测试环境**: 使用 `test` profile，使用 H2 内存数据库
- **生产环境**: 使用 `prod` profile，严格验证配置
