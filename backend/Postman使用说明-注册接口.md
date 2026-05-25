# Postman 调用注册接口步骤（解决 400）

## 一、确认后端已启动

在 IDEA 里运行 `DiabetesHealthApplication`，控制台出现 `Started DiabetesHealthApplication` 且无报错。  
然后继续下面步骤。

---

## 二、在 Postman 里发注册请求（一步步来）

### 第 1 步：新建请求

1. 打开 Postman。
2. 点击 **New** → **HTTP Request**（或左侧 **+** 新建一个请求）。
3. 请求会显示为 “Untitled Request”，可改名为“注册”。

### 第 2 步：选方法和填地址

1. 方法选 **POST**（下拉框里选，不要用 GET）。
2. 地址栏填：
   ```
   http://localhost:8080/api/auth/register
   ```
   - 不要多空格、不要漏 `http://`
   - 若后端改了端口（例如 8081），这里也要改成对应端口。

### 第 3 步：设置 Body（最容易导致 400 的一步）

1. 点下面 **Body** 这一栏。
2. 选中 **raw**（单选）。
3. 右侧类型下拉选 **JSON**（不要选 Text、form-data 等）。
4. 在下面大文本框里**只**贴下面这一段（不要多引号、不要用中文引号）：

```json
{
  "phone": "13800138000",
  "password": "Abc12345",
  "role": "PATIENT"
}
```

注意：
- 键名必须叫 `phone`、`password`、`role`（全小写）。
- 手机号、密码、role 都要用**英文双引号**包起来。
- 逗号只在两段之间有一个，最后一项后面不要逗号。
- 若复制到别处再贴回来，检查是否多了/少了引号或逗号。

### 第 4 步：发请求

1. 点右上角蓝色 **Send**。
2. 看下面 **Body** 里的返回内容。

---

## 三、正常时返回什么（200）

会返回类似（具体 token 会变）：

```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiJ9...",
  "tokenType": "Bearer",
  "userInfo": {
    "id": 1,
    "phone": "13800138000",
    "role": "PATIENT",
    "nickname": "用户138000",
    "avatarUrl": null,
    "healthProfile": { ... }
  }
}
```

说明注册成功，可以把 `accessToken` 复制下来，后面带登录的接口要用。

---

## 四、返回 400 时怎么查（按这个顺序看）

### 1. 先看返回 Body 里的内容

400 时后端会返回 JSON，常见两种：

**情况 A：参数校验失败（带 `errors`）**

```json
{
  "message": "参数校验失败",
  "errors": {
    "phone": "手机号格式不正确"
  },
  "status": 400
}
```

或：

```json
{
  "message": "参数校验失败",
  "errors": {
    "password": "密码长度8-64位"
  },
  "status": 400
}
```

- **`errors.phone`**：说明手机号不符合规则，按下面「手机号要求」改。
- **`errors.password`**：说明密码长度不对，按下面「密码要求」改。

**情况 B：业务错误（例如该手机号已注册）**

```json
{
  "message": "该手机号已注册",
  "status": 400
}
```

- 换一个没注册过的手机号再试，或直接调**登录**接口：`POST http://localhost:8080/api/auth/login`，Body 同样用 JSON，同上。

---

### 2. 注册接口的“硬性要求”（必须满足才不会 400）

| 字段     | 要求 |
|----------|------|
| **phone** | 必须是**中国大陆 11 位手机号**：第 1 位是 `1`，第 2 位是 `3`～`9`，后面 9 位数字。例如：`13800138000`、`159Abc1234578`。不能带空格、不能少位、不能写 10 位或 12 位。 |
| **password** | 长度 **8～64 位**。例如 `Abc12345`、`abc123` 都可以。 |
| **role** | 可选。不填默认 `PATIENT`。若填，只能填：`PATIENT`、`DOCTOR`、`FAMILY`、`ADMIN`（大写）。 |

建议先用这一份 Body 试一次（复制过去不要改）：

```json
{
  "phone": "13800138000",
  "password": "Abc12345",
  "role": "PATIENT"
}
```

---

### 3. 再检查这几项（避免 400）

1. **Body 类型**：Body 选的是 **raw**，类型选的是 **JSON**。  
   选成 Text 或 form-data 会解析不到 JSON，容易 400。
2. **Content-Type**：选 raw + JSON 后，Postman 一般会自动加 `Content-Type: application/json`。  
   若你手动改了 Headers，不要删掉或改掉这一项。
3. **URL**：确认是 `http://localhost:8080/api/auth/register`，没有多一个斜杠、没有拼错 `auth` 或 `register`。
4. **后端未启动或端口错**：会报连接错误（如 Connection refused），不是 400。若你确定是 400，多半是上面 1～3 或参数不符合要求。

---

## 五、用同一手机号再注册会 400

若该手机号已经注册过，会返回：

```json
{
  "message": "该手机号已注册",
  "status": 400
}
```

这时不需要再注册，直接调**登录**接口即可：

- **URL**：`POST http://localhost:8080/api/auth/login`
- **Body**：raw → JSON  
```json
{
  "phone": "13800138000",
  "password": "Abc12345"
}
```

登录成功也会返回 `accessToken`，用法和注册返回的一样。

---

## 六、小结：Postman 注册接口检查清单

- [ ] 方法：**POST**
- [ ] URL：`http://localhost:8080/api/auth/register`
- [ ] Body：**raw** + **JSON**
- [ ] Body 内容：`phone` 11 位且 1 开头、第二位数 3～9，`password` 6～32 位
- [ ] 若仍 400：看返回里 **message** 和 **errors**，按提示改字段

如果你把 Postman 里返回的**完整 400 的 Body**（或截图文字）发给我，我可以根据里面的 `message` 和 `errors` 帮你精确指出要改哪一项。

