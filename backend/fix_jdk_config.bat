@echo off
chcp 65001 >nul
echo ========================================
echo   修复 IDEA JDK 配置
echo ========================================
echo.

echo [1/4] 检查 JDK 安装...
if defined JAVA_HOME (
    echo ✓ JAVA_HOME 已设置：%JAVA_HOME%
) else (
    echo ✗ JAVA_HOME 未设置
    pause
    exit /b 1
)

echo.
echo [2/4] 验证 Java 版本...
java -version
if errorlevel 1 (
    echo ✗ Java 未正确安装
    pause
    exit /b 1
)

echo.
echo [3/4] 清理 IDEA 缓存...
if exist ".idea" (
    echo 删除 .idea 目录...
    rmdir /s /q .idea
    echo ✓ 已删除
) else (
    echo .idea 目录不存在
)

echo.
echo [4/4] 重新导入 Maven 项目...
if exist "pom.xml" (
    echo 找到 pom.xml
    echo.
    echo 请在 IDEA 中执行以下操作:
    echo 1. File → Open → 选择 backend 目录
    echo 2. 等待 Maven 依赖下载完成
    echo 3. File → Project Structure → 确认 SDK 为 17
) else (
    echo ✗ 未找到 pom.xml
)

echo.
echo ========================================
echo   修复完成！
echo ========================================
echo.
echo 下一步操作:
echo 1. 重新在 IDEA 中打开此项目（backend 文件夹）
echo 2. 按 Ctrl+Alt+Shift+S 打开 Project Structure
echo 3. 确保 Project SDK 设置为 17
echo 4. 重新加载 Maven 项目
echo.
pause
