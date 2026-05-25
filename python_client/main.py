"""糖尿病健康管家 - 桌面客户端"""
import sys
from PySide6.QtWidgets import QApplication
from PySide6.QtCore import Qt
from screens.login_window import LoginWindow
from screens.main_window import MainWindow
from api.api_service import ApiService


class DiabetesApp:
    """应用程序主类"""

    def __init__(self):
        self.api = ApiService()
        self.main_window = None
        self.login_window = None

    def run(self):
        """运行应用程序"""
        # 设置高DPI支持
        QApplication.setHighDpiScaleFactorRoundingPolicy(
            Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
        )

        app = QApplication(sys.argv)
        app.setApplicationName("糖尿病健康管家")
        app.setApplicationVersion("1.0.0")

        # 设置应用样式
        app.setStyleSheet(self._get_stylesheet())

        # 显示登录窗口
        self.login_window = LoginWindow(self.api, self._on_login_success)
        self.login_window.show()

        return app.exec()

    def _on_login_success(self):
        """登录成功回调"""
        self.login_window.close()
        self.main_window = MainWindow(self.api)
        self.main_window.show()

    def _get_stylesheet(self):
        """全局样式表"""
        return """
            QMainWindow {
                background-color: #f5f5f5;
            }
            QPushButton {
                background-color: #0B8A7D;
                color: white;
                border: none;
                padding: 10px 20px;
                border-radius: 8px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #097268;
            }
            QPushButton:pressed {
                background-color: #075a52;
            }
            QLineEdit {
                padding: 10px;
                border: 2px solid #e0e0e0;
                border-radius: 8px;
                font-size: 14px;
            }
            QLineEdit:focus {
                border-color: #0B8A7D;
            }
            QLabel {
                color: #333333;
            }
        """


if __name__ == "__main__":
    app = DiabetesApp()
    sys.exit(app.run())
