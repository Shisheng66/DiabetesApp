"""个人中心页面"""
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QFrame, QPushButton, QScrollArea, QMessageBox,
    QDialog, QFormLayout, QLineEdit, QComboBox
)
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont


class ProfilePage(QWidget):
    """个人中心页面"""

    def __init__(self, api):
        super().__init__()
        self.api = api
        self._setup_ui()
        self._load_profile()

    def _setup_ui(self):
        """设置界面"""
        scroll = QScrollArea()
        scroll.setWidgetResizable(True)
        scroll.setFrameShape(QFrame.Shape.NoFrame)
        scroll.setStyleSheet("background: transparent;")

        content = QWidget()
        content.setStyleSheet("background: transparent;")
        layout = QVBoxLayout(content)
        layout.setSpacing(20)
        layout.setContentsMargins(0, 0, 0, 0)

        # 用户信息卡片
        user_card = self._create_user_card()
        layout.addWidget(user_card)

        # 功能菜单
        menu = self._create_menu()
        layout.addWidget(menu)

        layout.addStretch()
        scroll.setWidget(content)

        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.addWidget(scroll)

    def _create_user_card(self):
        """创建用户信息卡片"""
        card = QFrame()
        card.setFixedHeight(150)
        card.setStyleSheet("""
            QFrame {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #0B8A7D, stop:1 #097268);
                border-radius: 20px;
            }
        """)

        layout = QHBoxLayout(card)
        layout.setContentsMargins(30, 0, 30, 0)

        # 头像
        avatar = QLabel("用")
        avatar.setFixedSize(70, 70)
        avatar.setAlignment(Qt.AlignmentFlag.AlignCenter)
        avatar.setStyleSheet("""
            QLabel {
                background: rgba(255, 255, 255, 0.2);
                border-radius: 35px;
                color: white;
                font-size: 28px;
                font-weight: bold;
            }
        """)
        layout.addWidget(avatar)

        layout.addSpacing(20)

        # 用户信息
        info = QVBoxLayout()
        self.name_label = QLabel("用户")
        self.name_label.setFont(QFont("Microsoft YaHei", 20, QFont.Weight.Bold))
        self.name_label.setStyleSheet("color: white;")
        info.addWidget(self.name_label)

        self.phone_label = QLabel("手机号：--")
        self.phone_label.setStyleSheet("color: rgba(255,255,255,0.8); font-size: 14px;")
        info.addWidget(self.phone_label)

        layout.addLayout(info)
        layout.addStretch()

        # 编辑按钮
        edit_btn = QPushButton("编辑资料")
        edit_btn.setStyleSheet("""
            QPushButton {
                background: rgba(255, 255, 255, 0.2);
                color: white;
                border: 1px solid rgba(255, 255, 255, 0.3);
                padding: 10px 20px;
                border-radius: 10px;
                font-weight: bold;
            }
            QPushButton:hover {
                background: rgba(255, 255, 255, 0.3);
            }
        """)
        edit_btn.clicked.connect(self._edit_profile)
        layout.addWidget(edit_btn)

        return card

    def _create_menu(self):
        """创建功能菜单"""
        frame = QFrame()
        frame.setStyleSheet("""
            QFrame {
                background: white;
                border-radius: 20px;
                border: 1px solid #e8e8e8;
            }
        """)

        layout = QVBoxLayout(frame)
        layout.setContentsMargins(20, 10, 20, 10)
        layout.setSpacing(0)

        menu_items = [
            ("健康档案", "查看和编辑您的健康信息"),
            ("血糖提醒", "设置血糖测量提醒"),
            ("会员中心", "查看会员权益"),
            ("关于", "版本信息"),
        ]

        for title, subtitle in menu_items:
            item = self._create_menu_item(title, subtitle)
            layout.addWidget(item)

        layout.addSpacing(10)

        # 退出登录按钮
        logout_btn = QPushButton("退出登录")
        logout_btn.setFixedHeight(50)
        logout_btn.setStyleSheet("""
            QPushButton {
                background: #f44336;
                color: white;
                border: none;
                border-radius: 12px;
                font-weight: bold;
                font-size: 15px;
            }
            QPushButton:hover {
                background: #d32f2f;
            }
        """)
        logout_btn.clicked.connect(self._logout)
        layout.addWidget(logout_btn)

        return frame

    def _create_menu_item(self, title, subtitle):
        """创建菜单项"""
        item = QFrame()
        item.setCursor(Qt.CursorShape.PointingHandCursor)
        item.setStyleSheet("""
            QFrame {
                border: none;
                border-radius: 10px;
                padding: 15px;
            }
            QFrame:hover {
                background: #f5f5f5;
            }
        """)

        layout = QHBoxLayout(item)
        layout.setContentsMargins(10, 10, 10, 10)

        info = QVBoxLayout()
        title_label = QLabel(title)
        title_label.setFont(QFont("Microsoft YaHei", 14, QFont.Weight.Bold))
        title_label.setStyleSheet("color: #333;")
        info.addWidget(title_label)

        subtitle_label = QLabel(subtitle)
        subtitle_label.setStyleSheet("color: #999; font-size: 12px;")
        info.addWidget(subtitle_label)

        layout.addLayout(info)
        layout.addStretch()

        arrow = QLabel(">")
        arrow.setStyleSheet("color: #999; font-size: 18px;")
        layout.addWidget(arrow)

        return item

    def _load_profile(self):
        """加载用户资料"""
        try:
            profile = self.api.get_user_profile()
            self.name_label.setText(profile.get("nickname", "用户"))
            self.phone_label.setText(f"手机号：{profile.get('phone', '--')}")
        except Exception:
            pass

    def _edit_profile(self):
        """编辑资料"""
        dialog = EditProfileDialog(self.api, self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            try:
                data = dialog.get_data()
                self.api.update_user_profile(data)
                self._load_profile()
                QMessageBox.information(self, "成功", "资料已更新")
            except Exception as e:
                QMessageBox.warning(self, "错误", f"更新失败: {str(e)}")

    def _logout(self):
        """退出登录"""
        reply = QMessageBox.question(
            self, "确认", "确定要退出登录吗？",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        if reply == QMessageBox.StandardButton.Yes:
            self.api.logout()
            # 关闭主窗口，显示登录窗口
            self.window().close()


class EditProfileDialog(QDialog):
    """编辑资料对话框"""

    def __init__(self, api, parent=None):
        super().__init__(parent)
        self.api = api
        self.setWindowTitle("编辑资料")
        self.setFixedSize(400, 300)
        self._setup_ui()

    def _setup_ui(self):
        layout = QFormLayout(self)

        self.nickname_edit = QLineEdit()
        self.nickname_edit.setPlaceholderText("昵称")
        layout.addRow("昵称：", self.nickname_edit)

        self.gender_combo = QComboBox()
        self.gender_combo.addItems(["男", "女", "保密"])
        layout.addRow("性别：", self.gender_combo)

        self.age_edit = QLineEdit()
        self.age_edit.setPlaceholderText("年龄")
        layout.addRow("年龄：", self.age_edit)

        btn_layout = QHBoxLayout()
        cancel_btn = QPushButton("取消")
        cancel_btn.clicked.connect(self.reject)
        btn_layout.addWidget(cancel_btn)

        ok_btn = QPushButton("保存")
        ok_btn.clicked.connect(self.accept)
        btn_layout.addWidget(ok_btn)
        layout.addRow(btn_layout)

        # 加载现有数据
        self._load_current()

    def _load_current(self):
        """加载当前资料"""
        try:
            profile = self.api.get_user_profile()
            self.nickname_edit.setText(profile.get("nickname", ""))
            gender = profile.get("gender", "")
            if gender == "MALE":
                self.gender_combo.setCurrentIndex(0)
            elif gender == "FEMALE":
                self.gender_combo.setCurrentIndex(1)
            self.age_edit.setText(str(profile.get("age", "")))
        except Exception:
            pass

    def get_data(self):
        gender_map = {0: "MALE", 1: "FEMALE", 2: "OTHER"}
        return {
            "nickname": self.nickname_edit.text(),
            "gender": gender_map.get(self.gender_combo.currentIndex(), "OTHER"),
            "age": int(self.age_edit.text()) if self.age_edit.text().isdigit() else None
        }
