"""主窗口 - 包含侧边栏导航和内容区域"""
from PySide6.QtWidgets import (
    QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QLabel, QPushButton, QStackedWidget, QFrame,
    QScrollArea, QSizePolicy
)
from PySide6.QtCore import Qt, QSize
from PySide6.QtGui import QFont, QIcon, QColor

from screens.home_page import HomePage
from screens.glucose_page import GlucosePage
from screens.diet_page import DietPage
from screens.exercise_page import ExercisePage
from screens.community_page import CommunityPage
from screens.profile_page import ProfilePage


class MainWindow(QMainWindow):
    """主窗口"""

    def __init__(self, api):
        super().__init__()
        self.api = api
        self.setWindowTitle("糖尿病健康管家")
        self.setMinimumSize(1200, 800)
        self._setup_ui()

    def _setup_ui(self):
        """设置界面"""
        central = QWidget()
        self.setCentralWidget(central)

        main_layout = QHBoxLayout(central)
        main_layout.setContentsMargins(0, 0, 0, 0)
        main_layout.setSpacing(0)

        # 侧边栏
        sidebar = self._create_sidebar()
        main_layout.addWidget(sidebar)

        # 内容区域
        content = QWidget()
        content.setStyleSheet("background-color: #f5f7fa;")
        content_layout = QVBoxLayout(content)
        content_layout.setContentsMargins(20, 20, 20, 20)

        # 顶部栏
        top_bar = self._create_top_bar()
        content_layout.addWidget(top_bar)

        # 页面堆栈
        self.page_stack = QStackedWidget()

        # 创建各个页面
        self.home_page = HomePage(self.api)
        self.glucose_page = GlucosePage(self.api)
        self.diet_page = DietPage(self.api)
        self.exercise_page = ExercisePage(self.api)
        self.community_page = CommunityPage(self.api)
        self.profile_page = ProfilePage(self.api)

        self.page_stack.addWidget(self.home_page)
        self.page_stack.addWidget(self.glucose_page)
        self.page_stack.addWidget(self.diet_page)
        self.page_stack.addWidget(self.exercise_page)
        self.page_stack.addWidget(self.community_page)
        self.page_stack.addWidget(self.profile_page)

        content_layout.addWidget(self.page_stack)

        main_layout.addWidget(content)

    def _create_sidebar(self):
        """创建侧边栏"""
        sidebar = QFrame()
        sidebar.setFixedWidth(220)
        sidebar.setStyleSheet("""
            QFrame {
                background: qlineargradient(x1:0, y1:0, x2:1, y2:1,
                    stop:0 #0B8A7D, stop:1 #097268);
            }
        """)

        layout = QVBoxLayout(sidebar)
        layout.setContentsMargins(15, 20, 15, 20)
        layout.setSpacing(5)

        # Logo
        logo_label = QLabel("糖尿病\n健康管家")
        logo_label.setFont(QFont("Microsoft YaHei", 18, QFont.Weight.Bold))
        logo_label.setStyleSheet("color: white;")
        logo_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(logo_label)

        layout.addSpacing(30)

        # 导航按钮
        nav_items = [
            ("首页", 0),
            ("血糖管理", 1),
            ("饮食记录", 2),
            ("运动管理", 3),
            ("社区交流", 4),
            ("个人中心", 5),
        ]

        self.nav_buttons = []
        for text, index in nav_items:
            btn = QPushButton(text)
            btn.setFixedHeight(45)
            btn.setCursor(Qt.CursorShape.PointingHandCursor)
            btn.setStyleSheet("""
                QPushButton {
                    background: transparent;
                    color: rgba(255, 255, 255, 0.8);
                    border: none;
                    border-radius: 10px;
                    font-size: 15px;
                    font-weight: bold;
                    text-align: left;
                    padding-left: 20px;
                }
                QPushButton:hover {
                    background: rgba(255, 255, 255, 0.15);
                    color: white;
                }
                QPushButton[active="true"] {
                    background: rgba(255, 255, 255, 0.25);
                    color: white;
                }
            """)
            btn.clicked.connect(lambda checked, i=index: self._switch_page(i))
            layout.addWidget(btn)
            self.nav_buttons.append(btn)

        layout.addStretch()

        # 底部提示
        tip = QLabel("桌面端 v1.0")
        tip.setStyleSheet("color: rgba(255,255,255,0.5); font-size: 12px;")
        tip.setAlignment(Qt.AlignmentFlag.AlignCenter)
        layout.addWidget(tip)

        # 默认选中首页
        self._switch_page(0)

        return sidebar

    def _create_top_bar(self):
        """创建顶部栏"""
        top_bar = QFrame()
        top_bar.setFixedHeight(60)
        top_bar.setStyleSheet("""
            QFrame {
                background: white;
                border-radius: 15px;
                border: 1px solid #e8e8e8;
            }
        """)

        layout = QHBoxLayout(top_bar)
        layout.setContentsMargins(20, 0, 20, 0)

        self.title_label = QLabel("首页")
        self.title_label.setFont(QFont("Microsoft YaHei", 16, QFont.Weight.Bold))
        self.title_label.setStyleSheet("color: #333;")
        layout.addWidget(self.title_label)

        layout.addStretch()

        # 日期
        from datetime import datetime
        date_label = QLabel(datetime.now().strftime("%Y年%m月%d日"))
        date_label.setStyleSheet("color: #666; font-size: 14px;")
        layout.addWidget(date_label)

        return top_bar

    def _switch_page(self, index):
        """切换页面"""
        self.page_stack.setCurrentIndex(index)

        # 更新按钮状态
        for i, btn in enumerate(self.nav_buttons):
            btn.setProperty("active", i == index)
            btn.style().unpolish(btn)
            btn.style().polish(btn)

        # 更新标题
        titles = ["首页", "血糖管理", "饮食记录", "运动管理", "社区交流", "个人中心"]
        self.title_label.setText(titles[index])
