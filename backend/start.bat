@echo off
chcp 65001 >nul
echo ========================================
echo   糖尿病健康管理系统 - Spring Boot 启动脚本
echo ========================================
echo.

:menu
echo 请选择启动环境:
echo 1. 开发环境 (dev)
echo 2. 生产环境 (prod)
echo 3. 测试环境 (test)
echo 4. 清理并重新打包
echo 0. 退出
echo.

set /p choice=请输入选项 (0-4): 

if "%choice%"=="1" goto dev
if "%choice%"=="2" goto prod
if "%choice%"=="3" goto test
if "%choice%"=="4" goto package
if "%choice%"=="0" goto end

echo 无效选项，请重新选择!
echo.
goto menu

:dev
echo.
echo [开发环境启动]
echo 正在启动 Spring Boot 应用...
cd /d %~dp0
call mvn spring-boot:run -Dspring-boot.run.profiles=dev
goto end

:prod
echo.
echo [生产环境启动]
echo 正在启动 Spring Boot 应用...
cd /d %~dp0
call mvn spring-boot:run -Dspring-boot.run.profiles=prod
goto end

:test
echo.
echo [测试环境启动]
echo 正在启动 Spring Boot 应用...
cd /d %~dp0
call mvn spring-boot:run -Dspring-boot.run.profiles=test
goto end

:package
echo.
echo [清理并打包]
echo 正在执行 Maven clean package...
cd /d %~dp0
call mvn clean package -DskipTests
if exist target\health-management-backend-0.0.1-SNAPSHOT.jar (
    echo.
    echo 打包成功！是否运行？(Y/N)
    set /p run_choice=
    if /i "%run_choice%"=="Y" (
        echo 正在运行 JAR 文件...
        java -jar target\health-management-backend-0.0.1-SNAPSHOT.jar --spring.profiles.active=dev
    )
) else (
    echo 打包失败，请检查错误信息!
)
goto end

:end
echo.
echo 按任意键退出...
pause >nul
exit /b 0
