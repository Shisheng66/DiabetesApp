# 本地启动指南

## 首次准备

1. 安装并启动 MySQL，创建数据库 `diabetes_health`。
2. 启动 Redis，默认地址为 `localhost:6379`。
3. 从 `backend/.env.example` 复制一份为 `backend/.env`，填写本机数据库密码和至少 32 位的 `JWT_SECRET`。
4. 本地开发使用 `dev` Profile。它会在首次启动时更新开发数据库表结构；生产环境必须使用 `prod` Profile 和受控迁移脚本。

## 在 IntelliJ IDEA 中启动

1. 使用项目根目录打开工程。
2. 在右上角运行配置列表中选择 `Backend Dev`。
3. 点击运行。该配置已固定 `Active profiles: dev`。
4. 浏览器访问 `http://127.0.0.1:8080/api/health`，返回 `status: UP` 即表示后端启动成功。

如果 IDEA 未自动显示配置，可在 `Run -> Edit Configurations -> Spring Boot` 中新建配置：

- Main class：`com.diabetes.health.DiabetesHealthApplication`
- Active profiles：`dev`
- Working directory：`backend`

## 命令行启动

```powershell
cd F:\Shisheng_Project\DiabetesApp\backend
mvn spring-boot:run "-Dspring-boot.run.profiles=dev"
```

## Android 真机联调

```powershell
adb reverse tcp:8080 tcp:8080
```

保持后端运行后，再启动或重新打开手机上的 Debug APK。手机会通过 `127.0.0.1:8080` 访问电脑后端。

## 本次表结构报错

若错误包含 `missing table [doctor_patient_access]`，说明没有用 `dev` Profile 启动，或生产数据库尚未执行迁移。开发环境使用 `dev` 重启一次即可创建该表；生产环境执行 `backend/db/migrations/V20260710__doctor_patient_access.sql` 后再使用 `prod` 启动。
