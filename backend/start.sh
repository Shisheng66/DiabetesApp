#!/bin/bash

# ===================================================================
# 糖尿病健康管理系统 - Spring Boot 启动脚本 (Linux/Mac)
# ===================================================================

APP_NAME="DiabetesHealthApplication"
JAR_FILE="target/health-management-backend-0.0.1-SNAPSHOT.jar"
MAIN_CLASS="com.diabetes.health.DiabetesHealthApplication"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================"
echo "  $APP_NAME - Spring Boot 启动脚本"
echo "========================================"
echo ""

# 显示菜单
show_menu() {
    echo "请选择启动环境:"
    echo "1. 开发环境 (dev)"
    echo "2. 生产环境 (prod)"
    echo "3. 测试环境 (test)"
    echo "4. 清理并重新打包"
    echo "0. 退出"
    echo ""
}

# 开发环境启动
start_dev() {
    echo -e "${GREEN}[开发环境启动]${NC}"
    echo "正在启动 Spring Boot 应用..."
    mvn spring-boot:run -Dspring-boot.run.profiles=dev
}

# 生产环境启动
start_prod() {
    echo -e "${GREEN}[生产环境启动]${NC}"
    echo "正在启动 Spring Boot 应用..."
    mvn spring-boot:run -Dspring-boot.run.profiles=prod
}

# 测试环境启动
start_test() {
    echo -e "${GREEN}[测试环境启动]${NC}"
    echo "正在启动 Spring Boot 应用..."
    mvn spring-boot:run -Dspring-boot.run.profiles=test
}

# 打包
do_package() {
    echo -e "${YELLOW}[清理并打包]${NC}"
    echo "正在执行 Maven clean package..."
    mvn clean package -DskipTests
    
    if [ -f "$JAR_FILE" ]; then
        echo ""
        echo -e "${GREEN}打包成功！${NC}"
        read -p "是否运行？(Y/N): " run_choice
        if [[ "$run_choice" =~ ^[Yy]$ ]]; then
            echo "正在运行 JAR 文件..."
            java -jar "$JAR_FILE" --spring.profiles.active=dev
        fi
    else
        echo -e "${RED}打包失败，请检查错误信息!${NC}"
    fi
}

# 主循环
while true; do
    show_menu
    read -p "请输入选项 (0-4): " choice
    
    case $choice in
        1)
            start_dev
            break
            ;;
        2)
            start_prod
            break
            ;;
        3)
            start_test
            break
            ;;
        4)
            do_package
            break
            ;;
        0)
            echo "退出..."
            exit 0
            ;;
        *)
            echo "无效选项，请重新选择!"
            echo ""
            ;;
    esac
done
