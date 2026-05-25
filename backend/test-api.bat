@echo off
chcp 65001 >nul
echo ======================================
echo   糖尿病健康管理系统 - API 快速测试
echo ======================================
echo.

:: 检查后端是否运行
echo [1/4] 检查后端服务...
curl -s http://localhost:8080/api/health >nul 2>&1
if %errorlevel% neq 0 (
    echo ✗ 后端未启动！请先启动后端服务
    echo.
    echo 提示：运行 start.bat 或在 IDEA 中启动 Application
    pause
    exit /b 1
)
echo √ 后端运行正常
echo.

:: 注册测试用户
echo [2/4] 注册测试用户...
set REGISTER_BODY={\"phone\":\"13800138000\",\"password\":\"Abc12345\",\"role\":\"PATIENT\"}
curl -X POST http://localhost:8080/api/auth/register ^
  -H "Content-Type: application/json" ^
  -d "%REGISTER_BODY%" > registration_result.json 2>&1

findstr /c:"accessToken" registration_result.json >nul 2>&1
if %errorlevel% equ 0 (
    echo √ 注册成功
    type registration_result.json | findstr "accessToken"
) else (
    echo ! 注册失败或用户已存在
)
echo.

:: 登录获取 token
echo [3/4] 登录获取 token...
set LOGIN_BODY={\"phone\":\"13800138000\",\"password\":\"Abc12345\"}
curl -X POST http://localhost:8080/api/auth/login ^
  -H "Content-Type: application/json" ^
  -d "%LOGIN_BODY%" > login_result.json 2>&1

findstr /c:"accessToken" login_result.json >nul 2>&1
if %errorlevel% equ 0 (
    echo √ 登录成功
    for /f "delims=" %%a in ('findstr "accessToken" login_result.json') do set TOKEN_LINE=%%a
    echo %TOKEN_LINE%
) else (
    echo ✗ 登录失败
    type login_result.json
    pause
    exit /b 1
)
echo.

:: 测试需要登录的接口
echo [4/4] 测试需要登录的接口...
echo.

echo a) 获取用户信息:
curl -X GET http://localhost:8080/api/users/me ^
  -H "Authorization: Bearer YOUR_TOKEN_HERE" ^
  -H "Content-Type: application/json"
echo.
echo.

echo b) 获取今日概览:
curl -X GET http://localhost:8080/api/dashboard/today ^
  -H "Authorization: Bearer YOUR_TOKEN_HERE" ^
  -H "Content-Type: application/json"
echo.
echo.

echo c) 查询食物列表:
curl -X GET "http://localhost:8080/api/diet/foods?keyword=%E7%B1%B3%E9%A5%AD" ^
  -H "Authorization: Bearer YOUR_TOKEN_HERE" ^
  -H "Content-Type: application/json"
echo.
echo.

echo ======================================
echo 测试完成!
echo.
echo 说明：由于 Windows batch 限制，token 需要手动替换
echo 请将 "YOUR_TOKEN_HERE" 替换为实际 token 值
echo ======================================
echo.

:: 清理临时文件
del registration_result.json >nul 2>&1
del login_result.json >nul 2>&1

pause

