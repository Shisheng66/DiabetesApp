"""首页 - 今日概览"""
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QFrame, QGridLayout, QScrollArea
)
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont
from datetime import datetime


class HomePage(QWidget):
    """首页"""

    def __init__(self, api):
        super().__init__()
        self.api = api
        self._setup_ui()
        self._load_data()

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

        # 欢迎区域
        welcome = self._create_welcome_card()
        layout.addWidget(welcome)

        # 数据卡片网格
        grid = QGridLayout()
        grid.setSpacing(15)

        self.glucose_card = self._create_data_card(
            "今日血糖", "--", "mmol/L", "#0B8A7D"
        )
        self.calorie_in_card = self._create_data_card(
            "今日摄入", "--", "千卡", "#FF9800"
        )
        self.calorie_out_card = self._create_data_card(
            "今日消耗", "--", "千卡", "#4CAF50"
        )
        self.reminder_card = self._create_data_card(
            "待办提醒", "--", "条", "#2196F3"
        )

        grid.addWidget(self.glucose_card, 0, 0)
        grid.addWidget(self.calorie_in_card, 0, 1)
        grid.addWidget(self.calorie_out_card, 1, 0)
        grid.addWidget(self.reminder_card, 1, 1)

        layout.addLayout(grid)

        # 快捷操作
        quick_actions = self._create_quick_actions()
        layout.addWidget(quick_actions)

        layout.addStretch()
        scroll.setWidget(content)

        main_layout = QVBoxLayout(self)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.addWidget(scroll)

    def _create_welcome_card(self):
        """创建欢迎卡片"""
        card = QFrame()
        card.setFixedHeight(120)
        card.setStyleSheet("""
            QFrame {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:0,
                    stop:0 #0B8A7D, stop:1 #097268);
                border-radius: 20px;
            }
        """)

        layout = QHBoxLayout(card)
        layout.setContentsMargins(30, 0, 30, 0)

        left = QVBoxLayout()
        greeting = QLabel(f"早上好！")
        greeting.setFont(QFont("Microsoft YaHei", 20, QFont.Weight.Bold))
        greeting.setStyleSheet("color: white;")
        left.addWidget(greeting)

        today = QLabel(datetime.now().strftime("今天是 %Y年%m月%d日"))
        today.setStyleSheet("color: rgba(255,255,255,0.8); font-size: 14px;")
        left.addWidget(today)

        layout.addLayout(left)
        layout.addStretch()

        return card

    def _create_data_card(self, title, value, unit, color):
        """创建数据卡片"""
        card = QFrame()
        card.setFixedHeight(150)
        card.setStyleSheet(f"""
            QFrame {{
                background: white;
                border-radius: 20px;
                border: 1px solid #e8e8e8;
            }}
        """)

        layout = QVBoxLayout(card)
        layout.setContentsMargins(25, 20, 25, 20)

        title_label = QLabel(title)
        title_label.setStyleSheet(f"color: {color}; font-weight: bold; font-size: 14px;")
        layout.addWidget(title_label)

        value_layout = QHBoxLayout()
        self.value_label = QLabel(value)
        self.value_label.setFont(QFont("Microsoft YaHei", 32, QFont.Weight.Bold))
        self.value_label.setStyleSheet(f"color: {color};")
        value_layout.addWidget(self.value_label)

        unit_label = QLabel(unit)
        unit_label.setStyleSheet("color: #999; font-size: 14px;")
        value_layout.addWidget(unit_label)
        value_layout.addStretch()

        layout.addLayout(value_layout)
        layout.addStretch()

        return card

    def _create_quick_actions(self):
        """创建快捷操作区域"""
        frame = QFrame()
        frame.setStyleSheet("""
            QFrame {
                background: white;
                border-radius: 20px;
                border: 1px solid #e8e8e8;
            }
        """)

        layout = QVBoxLayout(frame)
        layout.setContentsMargins(25, 20, 25, 20)

        title = QLabel("快捷操作")
        title.setFont(QFont("Microsoft YaHei", 14, QFont.Weight.Bold))
        title.setStyleSheet("color: #333;")
        layout.addWidget(title)

        actions_layout = QHBoxLayout()
        actions_layout.setSpacing(15)

        actions = [
            ("记录血糖", "#0B8A7D"),
            ("记录饮食", "#FF9800"),
            ("记录运动", "#4CAF50"),
            ("查看报告", "#2196F3"),
        ]

        for text, color in actions:
            btn = QLabel(f"<div style='text-align:center;'>{text}</div>")
            btn.setFixedSize(120, 80)
            btn.setAlignment(Qt.AlignmentFlag.AlignCenter)
            btn.setStyleSheet(f"""
                QLabel {{
                    background: {color}15;
                    color: {color};
                    border-radius: 15px;
                    font-weight: bold;
                    font-size: 14px;
                }}
            """)
            actions_layout.addWidget(btn)

        layout.addLayout(actions_layout)

        return frame

    def _load_data(self):
        """加载数据"""
        try:
            data = self.api.get_dashboard_today()
            # 更新卡片数据
            if "latestGlucose" in data:
                glucose = data["latestGlucose"]
                self.glucose_card.findChild(QLabel).setText(str(glucose.get("value", "--")))
            if "todayCaloriesIn" in data:
                self.calorie_in_card.findChild(QLabel).setText(str(data["todayCaloriesIn"]))
            if "todayCaloriesOut" in data:
                self.calorie_out_card.findChild(QLabel).setText(str(data["todayCaloriesOut"]))
            if "pendingReminders" in data:
                self.reminder_card.findChild(QLabel).setText(str(data["pendingReminders"]))
        except Exception:
            pass
