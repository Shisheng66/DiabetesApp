"""登录窗口"""
import base64
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QLineEdit, QPushButton, QMessageBox, QStackedWidget
)
from PySide6.QtCore import Qt, Signal, QByteArray, QBuffer, QIODevice
from PySide6.QtGui import QFont, QIcon, QPixmap
from api.api_service import ApiException


class LoginWindow(QWidget):
    """登录/注册窗口"""

    def __init__(self, api, on_success):
        super().__init__()
        self.api = api
        self.on_success = on_success
        self.is_login_mode = True
        self.login_captcha_id = None
        self.reg_captcha_id = None

        self.setWindowTitle("糖尿病健康管家 - 登录")
        self.setFixedSize(400, 580)
        self._setup_ui()

    def _setup_ui(self):
        """设置界面"""
        layout = QVBoxLayout(self)
        layout.setSpacing(15)
        layout.setContentsMargins(40, 30, 40, 30)

        # Logo/标题
        title = QLabel("糖尿病健康管家")
        title.setAlignment(Qt.AlignmentFlag.AlignCenter)
        title.setFont(QFont("Microsoft YaHei", 24, QFont.Weight.Bold))
        title.setStyleSheet("color: #0B8A7D;")
        layout.addWidget(title)

        subtitle = QLabel("桌面客户端")
        subtitle.setAlignment(Qt.AlignmentFlag.AlignCenter)
        subtitle.setStyleSheet("color: #666; font-size: 14px;")
        layout.addWidget(subtitle)

        layout.addSpacing(20)

        # 堆叠窗口用于切换登录/注册
        self.stack = QStackedWidget()

        # 登录页面
        login_page = QWidget()
        login_layout = QVBoxLayout(login_page)
        login_layout.setSpacing(12)

        self.login_phone = QLineEdit()
        self.login_phone.setPlaceholderText("手机号")
        login_layout.addWidget(self.login_phone)

        self.login_password = QLineEdit()
        self.login_password.setPlaceholderText("密码")
        self.login_password.setEchoMode(QLineEdit.EchoMode.Password)
        login_layout.addWidget(self.login_password)

        # 登录图形验证码
        captcha_row = QHBoxLayout()
        self.login_captcha_input = QLineEdit()
        self.login_captcha_input.setPlaceholderText("图形验证码")
        captcha_row.addWidget(self.login_captcha_input)

        self.login_captcha_label = QLabel()
        self.login_captcha_label.setFixedSize(100, 36)
        self.login_captcha_label.setStyleSheet("border: 1px solid #ccc; background: white;")
        self.login_captcha_label.setCursor(Qt.CursorShape.PointingHandCursor)
        self.login_captcha_label.mousePressEvent = lambda e: self._refresh_login_captcha()
        captcha_row.addWidget(self.login_captcha_label)
        login_layout.addLayout(captcha_row)

        self.login_captcha_hint = QLabel()
        self.login_captcha_hint.setStyleSheet("color: #999; font-size: 11px;")
        login_layout.addWidget(self.login_captcha_hint)

        self.login_btn = QPushButton("登录")
        self.login_btn.clicked.connect(self._do_login)
        login_layout.addWidget(self.login_btn)

        self.stack.addWidget(login_page)

        # 注册页面
        register_page = QWidget()
        register_layout = QVBoxLayout(register_page)
        register_layout.setSpacing(12)

        self.reg_phone = QLineEdit()
        self.reg_phone.setPlaceholderText("手机号")
        register_layout.addWidget(self.reg_phone)

        # 注册图形验证码
        captcha_row2 = QHBoxLayout()
        self.reg_captcha_input = QLineEdit()
        self.reg_captcha_input.setPlaceholderText("图形验证码")
        captcha_row2.addWidget(self.reg_captcha_input)

        self.reg_captcha_label = QLabel()
        self.reg_captcha_label.setFixedSize(100, 36)
        self.reg_captcha_label.setStyleSheet("border: 1px solid #ccc; background: white;")
        self.reg_captcha_label.setCursor(Qt.CursorShape.PointingHandCursor)
        self.reg_captcha_label.mousePressEvent = lambda e: self._refresh_reg_captcha()
        captcha_row2.addWidget(self.reg_captcha_label)
        register_layout.addLayout(captcha_row2)

        self.reg_captcha_hint = QLabel()
        self.reg_captcha_hint.setStyleSheet("color: #999; font-size: 11px;")
        register_layout.addWidget(self.reg_captcha_hint)

        # 短信验证码
        sms_row = QHBoxLayout()
        self.reg_sms_code = QLineEdit()
        self.reg_sms_code.setPlaceholderText("短信验证码")
        sms_row.addWidget(self.reg_sms_code)

        self.sms_btn = QPushButton("发送验证码")
        self.sms_btn.setFixedWidth(100)
        self.sms_btn.clicked.connect(self._send_sms)
        sms_row.addWidget(self.sms_btn)
        register_layout.addLayout(sms_row)

        self.reg_password = QLineEdit()
        self.reg_password.setPlaceholderText("密码（8位以上，含字母和数字）")
        self.reg_password.setEchoMode(QLineEdit.EchoMode.Password)
        register_layout.addWidget(self.reg_password)

        self.reg_confirm = QLineEdit()
        self.reg_confirm.setPlaceholderText("确认密码")
        self.reg_confirm.setEchoMode(QLineEdit.EchoMode.Password)
        register_layout.addWidget(self.reg_confirm)

        self.register_btn = QPushButton("注册")
        self.register_btn.clicked.connect(self._do_register)
        register_layout.addWidget(self.register_btn)

        self.stack.addWidget(register_page)

        layout.addWidget(self.stack)

        # 切换登录/注册
        switch_layout = QHBoxLayout()
        self.switch_label = QLabel("没有账号？")
        self.switch_label.setStyleSheet("color: #666;")
        switch_layout.addWidget(self.switch_label)

        self.switch_btn = QPushButton("立即注册")
        self.switch_btn.setStyleSheet("""
            QPushButton {
                background: transparent;
                color: #0B8A7D;
                font-weight: bold;
                padding: 0;
            }
            QPushButton:hover {
                color: #097268;
            }
        """)
        self.switch_btn.clicked.connect(self._toggle_mode)
        switch_layout.addWidget(self.switch_btn)
        layout.addLayout(switch_layout)

        # 服务状态
        self.status_label = QLabel("检查服务连接中...")
        self.status_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.status_label.setStyleSheet("color: #999; font-size: 12px;")
        layout.addWidget(self.status_label)

        # 回车键登录
        self.login_password.returnPressed.connect(self._do_login)
        self.reg_confirm.returnPressed.connect(self._do_register)

    def showEvent(self, event):
        """窗口显示时检查服务状态"""
        super().showEvent(event)
        self._check_health()
        self._refresh_login_captcha()
        self._refresh_reg_captcha()

    def _check_health(self):
        """检查后端服务状态"""
        if self.api.check_health():
            self.status_label.setText("服务连接正常")
            self.status_label.setStyleSheet("color: #4CAF50; font-size: 12px;")
        else:
            self.status_label.setText("无法连接到服务，请确认服务已启动")
            self.status_label.setStyleSheet("color: #f44336; font-size: 12px;")

    def _refresh_login_captcha(self):
        """刷新登录图形验证码"""
        try:
            result = self.api.get_captcha()
            self.login_captcha_id = result.get("challengeId")
            self._display_captcha(result, self.login_captcha_label)
            # 显示调试验证码（开发环境）
            display_code = result.get("displayCode")
            if display_code:
                self.login_captcha_hint.setText(f"调试验证码: {display_code}")
            else:
                self.login_captcha_hint.setText("")
        except Exception as e:
            self.login_captcha_hint.setText(f"获取验证码失败: {str(e)}")

    def _refresh_reg_captcha(self):
        """刷新注册图形验证码"""
        try:
            result = self.api.get_captcha()
            self.reg_captcha_id = result.get("challengeId")
            self._display_captcha(result, self.reg_captcha_label)
            # 显示调试验证码（开发环境）
            display_code = result.get("displayCode")
            if display_code:
                self.reg_captcha_hint.setText(f"调试验证码: {display_code}")
            else:
                self.reg_captcha_hint.setText("")
        except Exception as e:
            self.reg_captcha_hint.setText(f"获取验证码失败: {str(e)}")

    def _display_captcha(self, captcha_data, label):
        """显示图形验证码图片"""
        image_data_uri = captcha_data.get("imageDataUri", "")
        if image_data_uri.startswith("data:image/png;base64,"):
            base64_data = image_data_uri.split(",", 1)[1]
            image_bytes = base64.b64decode(base64_data)
            pixmap = QPixmap()
            pixmap.loadFromData(image_bytes)
            label.setPixmap(pixmap.scaled(
                label.size(),
                Qt.AspectRatioMode.KeepAspectRatio,
                Qt.TransformationMode.SmoothTransformation
            ))

    def _toggle_mode(self):
        """切换登录/注册模式"""
        self.is_login_mode = not self.is_login_mode
        if self.is_login_mode:
            self.stack.setCurrentIndex(0)
            self.switch_label.setText("没有账号？")
            self.switch_btn.setText("立即注册")
            self.setWindowTitle("糖尿病健康管家 - 登录")
        else:
            self.stack.setCurrentIndex(1)
            self.switch_label.setText("已有账号？")
            self.switch_btn.setText("返回登录")
            self.setWindowTitle("糖尿病健康管家 - 注册")

    def _do_login(self):
        """执行登录"""
        phone = self.login_phone.text().strip()
        password = self.login_password.text().strip()
        captcha_code = self.login_captcha_input.text().strip()

        if not phone or not password:
            QMessageBox.warning(self, "提示", "请输入手机号和密码")
            return

        if not captcha_code:
            QMessageBox.warning(self, "提示", "请输入图形验证码")
            return

        try:
            result = self.api.login(
                phone, password,
                captcha_code=captcha_code,
                captcha_id=self.login_captcha_id
            )
            token = result.get("accessToken") or result.get("token")
            if token:
                self.api.set_token(token)
                self.on_success()
            else:
                QMessageBox.warning(self, "登录失败", "未获取到令牌")
        except ApiException as e:
            QMessageBox.warning(self, "登录失败", e.message)
            self._refresh_login_captcha()

    def _do_register(self):
        """执行注册"""
        phone = self.reg_phone.text().strip()
        sms_code = self.reg_sms_code.text().strip()
        password = self.reg_password.text().strip()
        confirm = self.reg_confirm.text().strip()

        if not all([phone, sms_code, password, confirm]):
            QMessageBox.warning(self, "提示", "请填写所有字段")
            return

        if password != confirm:
            QMessageBox.warning(self, "提示", "两次密码输入不一致")
            return

        if len(password) < 6:
            QMessageBox.warning(self, "提示", "密码长度不能少于6位")
            return

        try:
            result = self.api.register(phone, password, sms_code)
            token = result.get("accessToken") or result.get("token")
            if token:
                self.api.set_token(token)
                self.on_success()
            else:
                QMessageBox.information(self, "注册成功", "请登录")
                self._toggle_mode()
        except ApiException as e:
            QMessageBox.warning(self, "注册失败", e.message)

    def _send_sms(self):
        """发送短信验证码"""
        phone = self.reg_phone.text().strip()
        captcha_code = self.reg_captcha_input.text().strip()

        if not phone:
            QMessageBox.warning(self, "提示", "请输入手机号")
            return

        if not captcha_code:
            QMessageBox.warning(self, "提示", "请输入图形验证码")
            return

        try:
            result = self.api.send_sms_code(
                phone,
                captcha_code=captcha_code,
                captcha_id=self.reg_captcha_id
            )
            # 显示调试验证码（开发环境）
            debug_code = result.get("debugCode")
            if debug_code:
                QMessageBox.information(self, "验证码", f"短信验证码: {debug_code}")
            else:
                QMessageBox.information(self, "提示", "验证码已发送")

            self.sms_btn.setEnabled(False)
            self.sms_btn.setText("已发送")
        except ApiException as e:
            QMessageBox.warning(self, "发送失败", e.message)
            self._refresh_reg_captcha()
