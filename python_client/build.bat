@echo off
echo 正在打包糖尿病健康管家...
cd /d "%~dp0"

:: 安装 PyInstaller
pip install pyinstaller -i https://pypi.tuna.tsinghua.edu.cn/simple

:: 打包
pyinstaller --onefile --windowed --name "糖尿病健康管家" ^
    --icon=resources/icon.ico ^
    --add-data "screens;screens" ^
    --add-data "api;api" ^
    --add-data "utils;utils" ^
    --add-data "widgets;widgets" ^
    main.py

echo 打包完成！
echo 可执行文件在 dist 目录中。
pause
