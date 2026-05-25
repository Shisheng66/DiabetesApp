"""饮食记录页面"""
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QFrame, QPushButton, QTableWidget, QTableWidgetItem,
    QHeaderView, QDateEdit, QMessageBox, QDialog,
    QFormLayout, QLineEdit, QDoubleSpinBox, QComboBox
)
from PySide6.QtCore import Qt, QDate
from PySide6.QtGui import QFont
from datetime import datetime


class DietPage(QWidget):
    """饮食记录页面"""

    def __init__(self, api):
        super().__init__()
        self.api = api
        self._setup_ui()
        self._load_records()

    def _setup_ui(self):
        """设置界面"""
        layout = QVBoxLayout(self)
        layout.setSpacing(20)
        layout.setContentsMargins(0, 0, 0, 0)

        # 顶部工具栏
        toolbar = QFrame()
        toolbar.setStyleSheet("""
            QFrame {
                background: white;
                border-radius: 15px;
                border: 1px solid #e8e8e8;
            }
        """)
        toolbar_layout = QHBoxLayout(toolbar)
        toolbar_layout.setContentsMargins(20, 15, 20, 15)

        date_label = QLabel("日期：")
        toolbar_layout.addWidget(date_label)

        self.date_edit = QDateEdit()
        self.date_edit.setCalendarPopup(True)
        self.date_edit.setDate(QDate.currentDate())
        self.date_edit.dateChanged.connect(self._load_records)
        toolbar_layout.addWidget(self.date_edit)

        toolbar_layout.addStretch()

        add_btn = QPushButton("+ 添加记录")
        add_btn.setFixedSize(120, 40)
        add_btn.clicked.connect(self._add_record)
        toolbar_layout.addWidget(add_btn)

        layout.addWidget(toolbar)

        # 营养统计
        stats = self._create_nutrition_stats()
        layout.addWidget(stats)

        # 记录表格
        self.table = QTableWidget()
        self.table.setColumnCount(6)
        self.table.setHorizontalHeaderLabels(["时间", "餐次", "食物", "热量", "备注", "操作"])
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.table.horizontalHeader().setSectionResizeMode(5, QHeaderView.ResizeMode.Fixed)
        self.table.setColumnWidth(5, 100)
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.table.setStyleSheet("""
            QTableWidget {
                background: white;
                border: 1px solid #e8e8e8;
                border-radius: 15px;
            }
            QTableWidget::item {
                padding: 10px;
            }
            QHeaderView::section {
                background: #f5f5f5;
                padding: 10px;
                border: none;
                font-weight: bold;
            }
        """)
        layout.addWidget(self.table)

    def _create_nutrition_stats(self):
        """创建营养统计卡片"""
        frame = QFrame()
        frame.setStyleSheet("""
            QFrame {
                background: white;
                border-radius: 15px;
                border: 1px solid #e8e8e8;
            }
        """)
        layout = QHBoxLayout(frame)
        layout.setContentsMargins(20, 15, 20, 15)
        layout.setSpacing(30)

        stats = [
            ("总热量", "--", "千卡", "#FF9800"),
            ("蛋白质", "--", "克", "#4CAF50"),
            ("碳水", "--", "克", "#2196F3"),
            ("脂肪", "--", "克", "#9C27B0"),
        ]

        self.nutrition_labels = {}
        for title, value, unit, color in stats:
            stat_widget = QVBoxLayout()
            title_label = QLabel(title)
            title_label.setStyleSheet(f"color: {color}; font-weight: bold; font-size: 12px;")
            stat_widget.addWidget(title_label)

            value_layout = QHBoxLayout()
            value_label = QLabel(value)
            value_label.setFont(QFont("Microsoft YaHei", 20, QFont.Weight.Bold))
            value_label.setStyleSheet(f"color: {color};")
            value_layout.addWidget(value_label)

            unit_label = QLabel(unit)
            unit_label.setStyleSheet("color: #999; font-size: 12px;")
            value_layout.addWidget(unit_label)
            value_layout.addStretch()

            stat_widget.addLayout(value_layout)
            layout.addLayout(stat_widget)

            self.nutrition_labels[title] = value_label

        return frame

    def _load_records(self):
        """加载饮食记录"""
        date = self.date_edit.date().toString("yyyy-MM-dd")
        try:
            result = self.api.get_diet_records(date=date)
            records = result.get("content", [])
            self._populate_table(records)
        except Exception as e:
            QMessageBox.warning(self, "错误", f"加载记录失败: {str(e)}")

    def _populate_table(self, records):
        """填充表格"""
        self.table.setRowCount(len(records))

        meal_names = {
            "BREAKFAST": "早餐",
            "LUNCH": "午餐",
            "DINNER": "晚餐",
            "SNACK": "加餐"
        }

        total_calories = 0
        for row, record in enumerate(records):
            self.table.setItem(row, 0, QTableWidgetItem(record.get("recordTime", "")))
            self.table.setItem(row, 1, QTableWidgetItem(meal_names.get(record.get("mealType", ""), "")))
            self.table.setItem(row, 2, QTableWidgetItem(record.get("foodName", "")))

            calories = record.get("calories", 0)
            total_calories += calories
            self.table.setItem(row, 3, QTableWidgetItem(f"{calories} 千卡"))
            self.table.setItem(row, 4, QTableWidgetItem(record.get("note", "")))

            delete_btn = QPushButton("删除")
            delete_btn.setStyleSheet("""
                QPushButton {
                    background: #f44336;
                    color: white;
                    border: none;
                    padding: 5px 10px;
                    border-radius: 5px;
                }
                QPushButton:hover { background: #d32f2f; }
            """)
            delete_btn.clicked.connect(lambda checked, rid=record.get("id"): self._delete_record(rid))
            self.table.setCellWidget(row, 5, delete_btn)

        self.nutrition_labels["总热量"].setText(str(int(total_calories)))

    def _add_record(self):
        """添加饮食记录"""
        dialog = AddDietDialog(self.api, self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            try:
                data = dialog.get_data()
                self.api.create_diet_record(data)
                self._load_records()
                QMessageBox.information(self, "成功", "记录已添加")
            except Exception as e:
                QMessageBox.warning(self, "错误", f"添加失败: {str(e)}")

    def _delete_record(self, record_id):
        """删除记录"""
        reply = QMessageBox.question(
            self, "确认", "确定要删除这条记录吗？",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        if reply == QMessageBox.StandardButton.Yes:
            try:
                self.api.delete_diet_record(record_id)
                self._load_records()
            except Exception as e:
                QMessageBox.warning(self, "错误", f"删除失败: {str(e)}")


class AddDietDialog(QDialog):
    """添加饮食记录对话框"""

    def __init__(self, api, parent=None):
        super().__init__(parent)
        self.api = api
        self.setWindowTitle("添加饮食记录")
        self.setFixedSize(400, 350)
        self._setup_ui()

    def _setup_ui(self):
        layout = QFormLayout(self)

        self.meal_combo = QComboBox()
        self.meal_combo.addItems(["早餐", "午餐", "晚餐", "加餐"])
        layout.addRow("餐次：", self.meal_combo)

        self.food_edit = QLineEdit()
        self.food_edit.setPlaceholderText("食物名称")
        layout.addRow("食物：", self.food_edit)

        self.calories_spin = QDoubleSpinBox()
        self.calories_spin.setRange(0, 5000)
        self.calories_spin.setSuffix(" 千卡")
        layout.addRow("热量：", self.calories_spin)

        self.note_edit = QLineEdit()
        self.note_edit.setPlaceholderText("可选备注")
        layout.addRow("备注：", self.note_edit)

        btn_layout = QHBoxLayout()
        cancel_btn = QPushButton("取消")
        cancel_btn.clicked.connect(self.reject)
        btn_layout.addWidget(cancel_btn)

        ok_btn = QPushButton("确定")
        ok_btn.clicked.connect(self.accept)
        btn_layout.addWidget(ok_btn)
        layout.addRow(btn_layout)

    def get_data(self):
        meal_map = {0: "BREAKFAST", 1: "LUNCH", 2: "DINNER", 3: "SNACK"}
        return {
            "mealType": meal_map.get(self.meal_combo.currentIndex(), "BREAKFAST"),
            "foodName": self.food_edit.text(),
            "calories": self.calories_spin.value(),
            "note": self.note_edit.text() or None,
            "recordTime": datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        }
