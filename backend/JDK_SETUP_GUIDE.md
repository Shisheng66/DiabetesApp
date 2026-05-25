# JDK 配置指南

## 🔍 问题诊断

错误信息："模块没有 JDK" 表示项目需要配置 Java Development Kit (JDK)。

## ✅ 解决方案

### 方案一：安装 JDK 17（推荐）

#### 1. 下载 JDK 17

选择以下任一来源下载：

- **Oracle JDK**: https://www.oracle.com/java/technologies/downloads/#java17
- **OpenJDK**: https://jdk.java.net/17/
- **Microsoft Build of OpenJDK**: https://learn.microsoft.com/en-us/java/openjdk/download
- **Adoptium (Eclipse Temurin)**: https://adoptium.net/temurin/releases/?version=17

#### 2. 安装 JDK

**Windows 系统：**
1. 下载 `.msi` 安装包
2. 双击运行，按提示安装
3. 默认安装路径：`C:\Program Files\Java\jdk-17`

#### 3. 配置环境变量

1. 右键"此电脑" → "属性" → "高级系统设置"
2. 点击"环境变量"
3. 新建系统变量：
   - 变量名：`JAVA_HOME`
   - 变量值：`C:\Program Files\Java\jdk-17`（根据实际安装路径）

4. 编辑 `Path` 变量，添加：
   - `%JAVA_HOME%\bin`

#### 4. 验证安装

打开命令提示符，输入：
```bash
java -version
javac -version
```

应该显示类似：
```
java version "17.0.x"
javac 17.0.x
```

---

### 方案二：在 IDEA 中配置 JDK

#### 1. 打开 IDEA 设置

- **File** → **Project Structure** (或按 `Ctrl+Alt+Shift+S`)

#### 2. 添加 JDK

1. 选择 **SDKs** 标签
2. 点击 **+** 号
3. 选择 **Add JDK...**
4. 浏览到 JDK 安装目录
   - Windows: `C:\Program Files\Java\jdk-17`
5. 点击 **OK**

#### 3. 设置项目 JDK

1. 选择 **Project** 标签
2. 在 **Project SDK** 下拉框中选择刚添加的 JDK 17
3. 确保 **Project language level** 设置为 17

---

### 方案三：使用 IDEA 自动下载 JDK

#### IntelliJ IDEA 2021.1+ 支持自动下载 JDK

1. 打开 **File** → **Project Structure** → **SDKs**
2. 点击 **+** → **Download JDK...**
3. 选择：
   - Version: **17**
   - Vendor: 选择任意（如 JetBrains Runtime、Oracle、OpenJDK）
4. 点击 **Download**
5. 下载完成后自动配置

---

## 🛠️ 针对本项目的配置步骤

### 步骤 1: 确认已安装 JDK

打开命令提示符：
```bash
java -version
```

如果没有安装，请先安装 JDK 17。

### 步骤 2: 在 IDEA 中配置

1. 打开项目：`F:\Cursor需求文件\糖尿病健康管理系统app\backend`
2. 按 `Ctrl+Alt+Shift+S` 打开 Project Structure
3. 确保 Project SDK 设置为 JDK 17
4. 点击 Apply → OK

### 步骤 3: 重新加载 Maven

1. 右侧 Maven 工具窗口
2. 点击刷新按钮 🔄
3. 等待依赖下载完成

### 步骤 4: 验证配置

尝试运行启动类：
- 找到 `DiabetesHealthApplication.java`
- 右键 → Run 'DiabetesHealthApplication.main()'

---

## 💡 常见问题

### Q1: 我已经有 JDK 8/11，可以用吗？

**A:** 本项目基于 Spring Boot 3.3.2，**必须使用 JDK 17+**。

原因：
- Spring Boot 3.x 最低要求 Java 17
- pom.xml 中配置了 `<java.version>17</java.version>`

### Q2: 多个 JDK 版本如何切换？

**A:** 在 IDEA 中：
1. File → Project Structure → SDKs
2. 可以添加多个 JDK
3. 在 Project 标签中切换不同的 SDK

### Q3: 配置后仍然报错怎么办？

**A:** 尝试以下步骤：
1. 关闭 IDEA
2. 删除 `.idea` 目录（可选）
3. 重新打开项目
4. File → Invalidate Caches → Invalidate and Restart

---

## 📋 检查清单

配置完成后请确认：

- [ ] JDK 17 已安装
- [ ] `java -version` 显示 17.x.x
- [ ] IDEA Project SDK 设置为 17
- [ ] Maven 使用 JDK 17
- [ ] 能够运行 DiabetesHealthApplication

---

## 🔗 相关资源

- [Oracle JDK 17 下载](https://www.oracle.com/java/technologies/downloads/#java17)
- [OpenJDK 17 下载](https://jdk.java.net/17/)
- [IntelliJ IDEA JDK 配置教程](https://www.jetbrains.com/help/idea/sdk.html)
- [Spring Boot 3.3.2 官方文档](https://docs.spring.io/spring-boot/docs/3.3.2/reference/html/)

---

**最低要求**: 
- ✅ Java 17 或更高版本
- ✅ Maven 3.6+
- ✅ IDEA 2021.1+（推荐）
