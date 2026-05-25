# 如何调用本项目的 API

## 一、接口在哪里

- **基础地址**：本机后端跑起来后为  
  `http://localhost:8080`
- **接口路径**：都在 `/api/...` 下，例如：
  - 健康检查：`http://localhost:8080/api/health`
  - 登录：`http://localhost:8080/api/auth/login`
  - 血糖记录：`http://localhost:8080/api/blood-glucose/records`
  - 饮食：`http://localhost:8080/api/diet/records`、`/api/diet/foods`
  - 运动：`http://localhost:8080/api/exercise/records`、`/api/exercise/types`
  - 提醒：`http://localhost:8080/api/reminders`
- **完整说明**：每个接口的 URL、方法、参数、Body 见同目录下的 **`API.md`**。

---

## 二、推荐用来“接”API 的工具（任选其一）

### 1. Postman（最常用）

- **下载**：https://www.postman.com/downloads/
- **用途**：图形化发 HTTP 请求、保存请求、管理环境变量（如 baseUrl、token）。
- **适合**：本地调试、给前端/同事演示接口、导出接口集合。

### 2. Apifox（国产、中文）

- **下载**：https://apifox.com/
- **用途**：类似 Postman，支持接口文档、Mock、团队协作。
- **适合**：喜欢中文界面、需要接口文档和 Mock 时。

### 3. IDEA 自带 HTTP Client

- **位置**：IDEA 里新建文件，类型选 **HTTP Request**（.http 文件）。
- **用途**：在项目里直接写请求、点运行发请求，无需再开一个软件。
- **适合**：后端用 IDEA 开发、想少装软件时。

### 4. curl（命令行）

- **用途**：终端里直接发请求，适合快速试一个接口。
- **适合**：习惯命令行、写脚本或 CI 时。

---

## 三、推荐先试的几条 API（按顺序）

下面这几条能帮你快速确认：服务是否正常、登录是否成功、带 token 的接口是否能接到。

### 1. 健康检查（不用登录）

- **工具**：浏览器或任意上述工具。
- **请求**：`GET http://localhost:8080/api/health`
- **预期**：返回 JSON，例如 `{"status":"UP","message":"糖尿病健康管理后端已运行"}`。

---

### 2. 注册（拿到账号）

- **工具**：Postman / Apifox / IDEA HTTP 均可。
- **请求**：`POST http://localhost:8080/api/auth/register`
- **Body**：选 **raw → JSON**，内容：
```json
{
  "phone": "13800138000",
  "password": "Abc12345",
  "role": "PATIENT"
}
```
- **预期**：返回里有 `accessToken` 和 `userInfo`。**把 `accessToken` 复制下来**，后面所有需要登录的接口都要用。

---

### 3. 登录（拿到 token）

- **请求**：`POST http://localhost:8080/api/auth/login`
- **Body**：raw → JSON
```json
{
  "phone": "13800138000",
  "password": "Abc12345"
}
```
- **预期**：同样返回 `accessToken`。**用这个 token 接下面所有需要登录的接口**。

---

### 4. 需要登录的接口怎么“接”（带 token）

在 **请求头（Header）** 里加一行：

- **名称**：`Authorization`
- **值**：`Bearer 你复制的accessToken`  
  例如：`Bearer eyJhbGciOiJIUzI1NiJ9...`

在 **Postman / Apifox** 里：
- 打开请求 → **Headers** → 新增一行：`Authorization` / `Bearer 你的token`。

然后就可以接例如：

- **查当前用户**：`GET http://localhost:8080/api/users/me`（Header 带 Authorization）
- **查今日概览**：`GET http://localhost:8080/api/dashboard/today`（Header 带 Authorization）
- **查运动类型**：`GET http://localhost:8080/api/exercise/types`（Header 带 Authorization）
- **查食物**：`GET http://localhost:8080/api/diet/foods?keyword=米饭`（Header 带 Authorization）
- **新增一条血糖**：`POST http://localhost:8080/api/blood-glucose/records`，Body 见 `API.md`，Header 带 Authorization

---

## 四、推荐“先接到”的几条 API 小结

| 顺序 | 接口 | 方法 | 说明 |
|------|------|------|------|
| 1 | `/api/health` | GET | 确认服务是否起来，浏览器即可 |
| 2 | `/api/auth/register` | POST | 注册，拿到 token |
| 3 | `/api/auth/login` | POST | 登录，拿到 token |
| 4 | `/api/users/me` | GET | 带 token 查当前用户，确认登录有效 |
| 5 | `/api/diet/foods?keyword=米饭` | GET | 带 token 查食物，饮食模块 |
| 6 | `/api/exercise/types` | GET | 带 token 查运动类型，运动模块 |
| 7 | `/api/reminders` | GET | 带 token 查提醒列表，提醒模块 |

你先在 **Postman 或 Apifox** 里按 1→2 或 3→4 接一遍，能通的话，其它接口按 `API.md` 里的路径和 Body 照搬即可。  
如果你说下你更想用哪一个（Postman / Apifox / IDEA / curl），我可以按那个工具给你写一版一步步的截图式说明（用文字描述每一步点哪里）。

