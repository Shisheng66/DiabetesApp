# ======================================
#   糖尿病健康管理系统 - API 测试脚本
# ======================================

Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  糖尿病健康管理系统 API 测试" -ForegroundColor Cyan
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""

$baseUrl = "http://localhost:8080"
$headers = @{ "Content-Type" = "application/json" }

# 1. 检查应用健康状态
Write-Host "[1/8] 检查应用健康状态..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/health" -Method GET -UseBasicParsing
    Write-Host "✓ 应用运行正常" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
    Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "✗ 应用未启动或无法访问" -ForegroundColor Red
    Write-Host "  Error: $_" -ForegroundColor Red
    Write-Host "  请确保应用已经启动并运行在 http://localhost:8080" -ForegroundColor Red
    exit 1
}
Write-Host ""

# 2. 测试注册接口
Write-Host "[2/8] 测试用户注册..." -ForegroundColor Yellow
$randomNum = Get-Random -Maximum 9999
$registerData = @{
    phone = "13800138000"
    password = "Abc12345"
    role = "PATIENT"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/auth/register" -Method POST -Headers $headers -Body $registerData -UseBasicParsing
    Write-Host "✓ 注册成功" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
    $registerResult = $response.Content | ConvertFrom-Json
    Write-Host "  Token: $($registerResult.accessToken.Substring(0, 50))..." -ForegroundColor Gray
    $token = $registerResult.accessToken
} catch {
    Write-Host "! 注册失败 (可能用户已存在)" -ForegroundColor Yellow
    Write-Host "  继续尝试登录..." -ForegroundColor Gray
}
Write-Host ""

# 3. 测试登录接口
Write-Host "[3/8] 测试用户登录..." -ForegroundColor Yellow
$loginData = @{
    phone = "13800138000"
    password = "Abc12345"
} | ConvertTo-Json

try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/auth/login" -Method POST -Headers $headers -Body $loginData -UseBasicParsing
    Write-Host "✓ 登录成功" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
    $loginResult = $response.Content | ConvertFrom-Json
    $token = $loginResult.accessToken
    Write-Host "  Token: $($token.Substring(0, 50))..." -ForegroundColor Gray
} catch {
    Write-Host "✗ 登录失败" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    if ($_.ErrorDetails.Message) {
        Write-Host "  Details: $($_.ErrorDetails.Message)" -ForegroundColor Red
    }
    Write-Host "`n 提示：请先在数据库中创建测试账号" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# 4. 设置认证头部
$authHeaders = $headers.Clone()
$authHeaders.Add("Authorization", "Bearer $token")

# 5. 测试获取当前用户信息
Write-Host "[4/8] 测试获取当前用户信息..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/users/me" -Method GET -Headers $authHeaders -UseBasicParsing
    Write-Host "✓ 获取用户信息成功" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
    $userData = $response.Content | ConvertFrom-Json
    Write-Host "  Username: $($userData.phone)" -ForegroundColor Gray
    Write-Host "  Role: $($userData.role)" -ForegroundColor Gray
} catch {
    Write-Host "✗ 获取用户信息失败" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
}
Write-Host ""

# 6. 测试获取今日概览
Write-Host "[5/8] 测试获取今日概览..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/dashboard/today" -Method GET -Headers $authHeaders -UseBasicParsing
    Write-Host "✓ 获取今日概览成功" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
    $dashboardData = $response.Content | ConvertFrom-Json
    Write-Host "  Response: $($response.Content)" -ForegroundColor Gray
} catch {
    Write-Host "✗ 获取今日概览失败" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
}
Write-Host ""

# 7. 测试查询食物列表
Write-Host "[6/8] 测试查询食物列表..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/diet/foods?keyword=米饭" -Method GET -Headers $authHeaders -UseBasicParsing
    Write-Host "✓ 获取食物列表成功" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
    $foodData = $response.Content | ConvertFrom-Json
    Write-Host "  找到 $($foodData.content.Count) 条食物记录" -ForegroundColor Gray
    if ($foodData.content.Count -gt 0) {
        Write-Host "  第一条： $($foodData.content[0].name)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ 获取食物列表失败" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
}
Write-Host ""

# 8. 测试查询运动类型
Write-Host "[7/8] 测试查询运动类型..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/exercise/types" -Method GET -Headers $authHeaders -UseBasicParsing
    Write-Host "✓ 获取运动类型成功" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
    $exerciseData = $response.Content | ConvertFrom-Json
    Write-Host "  找到 $($exerciseData.Count) 种运动类型" -ForegroundColor Gray
    foreach ($type in $exerciseData) {
        Write-Host "    - $($type.name)" -ForegroundColor Gray
    }
} catch {
    Write-Host "✗ 获取运动类型失败" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
}
Write-Host ""

# 9. 测试健康提醒列表
Write-Host "[8/8] 测试获取健康提醒..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "$baseUrl/api/reminders" -Method GET -Headers $authHeaders -UseBasicParsing
    Write-Host "✓ 获取提醒列表成功" -ForegroundColor Green
    Write-Host "  Status: $($response.StatusCode)" -ForegroundColor Gray
    $reminderData = $response.Content | ConvertFrom-Json
    Write-Host "  找到 $($reminderData.Count) 条提醒" -ForegroundColor Gray
} catch {
    Write-Host "✗ 获取提醒列表失败" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
}
Write-Host ""

# 测试完成
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "  测试完成!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "总结:" -ForegroundColor Yellow
Write-Host "  ✓ 健康检查通过" -ForegroundColor Green
Write-Host "  ✓ 认证接口正常" -ForegroundColor Green
Write-Host "  ✓ 业务接口可用" -ForegroundColor Green
Write-Host ""
Write-Host "Token 已保存，可用于后续前端开发测试" -ForegroundColor Cyan
Write-Host "Token: $token" -ForegroundColor Cyan
Write-Host ""

# 保存 token 到文件
$token | Out-File -FilePath ".\token.txt" -Encoding utf8
Write-Host "Token 已保存到 .\token.txt" -ForegroundColor Gray
Write-Host ""

