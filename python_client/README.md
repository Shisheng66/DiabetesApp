# 糖尿病健康管家 - 桌面客户端

基于 Python + PySide6 开发的桌面客户端，连接后端 Spring Boot API。

## 功能特性

- 用户登录/注册
- 首页今日概览
- 血糖管理（记录、查询、统计）
- 饮食记录（记录、查询、营养统计）
- 运动管理（记录、查询、消耗统计）
- 社区交流（发帖、评论）
- 个人中心（资料编辑、设置）

## 环境要求

- Python 3.8+
- Windows 10/11

## 安装依赖

```bash
pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
```

## 运行

```bash
python main.py
```

或双击 `run.bat`

## 打包成 exe

```bash
build.bat
```

打包后的可执行文件在 `dist` 目录中。

## 配置

默认连接后端地址：`http://127.0.0.1:8080`

如需修改，请编辑 `api/api_service.py` 中的 `base_url` 参数。

## 目录结构

```
python_client/
├── main.py              # 程序入口
├── api/
│   └── api_service.py   # API 服务层
├── screens/
│   ├── login_window.py  # 登录窗口
│   ├── main_window.py   # 主窗口
│   ├── home_page.py     # 首页
│   ├── glucose_page.py  # 血糖管理
│   ├── diet_page.py     # 饮食记录
│   ├── exercise_page.py # 运动管理
│   ├── community_page.py # 社区交流
│   └── profile_page.py  # 个人中心
├── utils/               # 工具类
├── widgets/             # 自定义组件
├── resources/           # 资源文件
├── requirements.txt     # 依赖列表
├── run.bat              # 启动脚本
└── build.bat            # 打包脚本
```
