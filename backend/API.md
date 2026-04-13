# 糖尿病健康管理后端 API 说明

基础地址：`http://localhost:8080`  
除注明「无需登录」的接口外，其余均需在请求头携带：`Authorization: Bearer <accessToken>`

---

## 一、健康检查（无需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/health | 检查服务是否运行 |

---

## 二、认证（无需登录）

### 注册

- **POST** `/api/auth/register`
- Body (JSON)：
```json
{
  "phone": "13800138000",
  "password": "123456",
  "role": "PATIENT"
}
```
- 返回：`accessToken`、`userInfo`（同登录）

### 登录

- **POST** `/api/auth/login`
- Body (JSON)：
```json
{
  "phone": "13800138000",
  "password": "123456"
}
```
- 返回示例：
```json
{
  "accessToken": "eyJhbGc...",
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

---

## 三、用户与健康档案（需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/users/me | 获取当前用户信息（含健康档案摘要） |
| PUT | /api/users/me | 修改昵称、头像，Body: `{ "nickname": "", "avatarUrl": "" }` |
| GET | /api/users/me/health-profile | 获取健康档案 |
| PUT | /api/users/me/health-profile | 更新健康档案（年龄/性别/身高/体重/糖尿病类型/诊断时间/服药情况/目标血糖范围等） |
| PUT | /api/users/me/password | 修改密码，Body: `{ "oldPassword": "", "newPassword": "" }` |

健康档案 Body 示例（PUT 时按需传字段）：
```json
{
  "nickname": "张三",
  "gender": "MALE",
  "birthDate": "1990-01-01",
  "heightCm": 170,
  "weightKg": 70,
  "diabetesType": "TYPE2",
  "diagnosisDate": "2020-05-01",
  "medicationStatus": "口服药",
  "targetFbgMin": 3.9,
  "targetFbgMax": 6.1,
  "targetPbgMin": 4.4,
  "targetPbgMax": 7.8,
  "remark": ""
}
```

---

## 四、血糖记录与趋势（需登录）

### 新增血糖

- **POST** `/api/blood-glucose/records`
- Body (JSON)：
```json
{
  "measureTime": "2026-03-06T08:00:00Z",
  "measureType": "FASTING",
  "valueMmolL": 5.6,
  "source": "MANUAL",
  "deviceId": null,
  "remark": "晨起空腹"
}
```
- `measureType`：FASTING（空腹）、POST_MEAL（餐后）、BEFORE_SLEEP（睡前）、RANDOM（随机）
- `source`：MANUAL（手动）、BLE（蓝牙血糖仪）

### 血糖记录列表

- **GET** `/api/blood-glucose/records`
- 查询参数：`startDate`、`endDate`（ISO 日期）、`measureType`、`page`（默认 0）、`size`（默认 20）
- 返回：分页列表，每项同「单条记录」结构

### 单条记录

- **GET** `/api/blood-glucose/records/{id}`

### 删除记录

- **DELETE** `/api/blood-glucose/records/{id}`

### 趋势图数据

- **GET** `/api/blood-glucose/trend/daily?date=2026-03-06` 日趋势
- **GET** `/api/blood-glucose/trend/weekly?weekStart=2026-03-02` 周趋势（weekStart 为该周某天）
- **GET** `/api/blood-glucose/trend/monthly?year=2026&month=3` 月趋势  
- 返回：`{ "periodType": "daily|weekly|monthly", "points": [ { "time": "...", "value": 5.6 } ] }`

---

## 五、首页今日概览（需登录）

- **GET** `/api/dashboard/today`
- 返回：今日最近一次血糖、今日运动/饮食热量（当前为 0 占位）、今日提醒（当前为空列表）

---

## 六、饮食管理（需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/diet/records | 新增饮食记录 |
| GET | /api/diet/records | 按日期查询记录，参数：`date`（必填）、`mealType`（可选：BREAKFAST/LUNCH/DINNER/SNACK） |
| GET | /api/diet/summary/daily | 某日营养汇总，参数：`date` |
| DELETE | /api/diet/records/{id} | 删除记录 |
| GET | /api/diet/foods | 食物搜索，参数：`keyword`、`page`、`size` |

新增饮食记录 Body 示例：
```json
{
  "recordDate": "2026-03-06",
  "recordTime": "2026-03-06T08:30:00Z",
  "mealType": "BREAKFAST",
  "foodId": 1,
  "amountG": 150,
  "remark": ""
}
```

---

## 七、运动管理（需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/exercise/records | 新增运动记录 |
| GET | /api/exercise/records | 列表，参数：`startDate`、`endDate`、`page`、`size` |
| GET | /api/exercise/summary/daily | 某日运动汇总，参数：`date` |
| DELETE | /api/exercise/records/{id} | 删除记录 |
| GET | /api/exercise/types | 运动类型列表（步行/跑步/骑行/游泳等） |

新增运动记录 Body 示例：
```json
{
  "exerciseTypeId": 1,
  "startTime": "2026-03-06T07:00:00Z",
  "endTime": "2026-03-06T07:30:00Z",
  "durationMin": 30,
  "distanceKm": 3.0,
  "calorieKcal": 150,
  "remark": ""
}
```

---

## 八、健康提醒（需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/reminders | 新增提醒 |
| GET | /api/reminders | 提醒列表 |
| PUT | /api/reminders/{id} | 更新提醒 |
| DELETE | /api/reminders/{id} | 删除提醒 |
| POST | /api/push/register-token | 注册推送 token（APP 启动时上报，用于后续推送通知） |

新增提醒 Body 示例：
```json
{
  "type": "GLUCOSE_TEST",
  "timeOfDay": "08:00",
  "repeatType": "DAILY",
  "enabled": true,
  "remark": "晨起测血糖"
}
```
- `type`：GLUCOSE_TEST（测血糖）、MEDICINE（吃药）、EXERCISE（运动）、DIET（饮食）
- `repeatType`：DAILY（每天）、WORKDAY（工作日）、CUSTOM（自定义）

注册推送 token Body：
```json
{
  "deviceType": "ANDROID",
  "pushToken": "设备获取的推送 token"
}
```

---

## 错误响应

- 400：参数错误或业务校验失败，body 中 `message`、可选 `errors`
- 401：未登录或 token 无效
- 403：无权限
- 404：资源不存在
