"""血糖管理页面"""
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QFrame, QPushButton, QTableWidget, QTableWidgetItem,
    QHeaderView, QDateEdit, QComboBox, QMessageBox,
    QDialog, QFormLayout, QLineEdit, QDoubleSpinBox
)
from PySide6.QtCore import Qt, QDate
from PySide6.QtGui import QFont
from datetime import datetime, timedelta


class GlucosePage(QWidget):
    """血糖管理页面"""

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

        # 日期选择
        date_label = QLabel("日期：")
        toolbar_layout.addWidget(date_label)

        self.date_edit = QDateEdit()
        self.date_edit.setCalendarPopup(True)
        self.date_edit.setDate(QDate.currentDate())
        self.date_edit.dateChanged.connect(self._load_records)
        toolbar_layout.addWidget(self.date_edit)

        # 测量类型筛选
        type_label = QLabel("类型：")
        toolbar_layout.addWidget(type_label)

        self.type_combo = QComboBox()
        self.type_combo.addItems(["全部", "空腹", "餐后", "睡前", "随机"])
        self.type_combo.currentIndexChanged.connect(self._load_records)
        toolbar_layout.addWidget(self.type_combo)

        toolbar_layout.addStretch()

        # 添加记录按钮
        add_btn = QPushButton("+ 添加记录")
        add_btn.setFixedSize(120, 40)
        add_btn.clicked.connect(self._add_record)
        toolbar_layout.addWidget(add_btn)

        layout.addWidget(toolbar)

        # 统计卡片
        stats = self._create_stats_cards()
        layout.addWidget(stats)

        # 记录表格
        self.table = QTableWidget()
        self.table.setColumnCount(5)
        self.table.setHorizontalHeaderLabels(["时间", "血糖值", "测量类型", "备注", "操作"])
        self.table.horizontalHeader().setSectionResizeMode(QHeaderView.ResizeMode.Stretch)
        self.table.horizontalHeader().setSectionResizeMode(4, QHeaderView.ResizeMode.Fixed)
        self.table.setColumnWidth(4, 100)
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

    def _create_stats_cards(self):
        """创建统计卡片"""
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
            ("平均血糖", "--", "mmol/L"),
            ("最高值", "--", "mmol/L"),
            ("最低值", "--", "mmol/L"),
            ("记录次数", "--", "次"),
        ]

        self.stat_labels = {}
        for title, value, unit in stats:
            stat_widget = QVBoxLayout()
            title_label = QLabel(title)
            title_label.setStyleSheet("color: #666; font-size: 12px;")
            stat_widget.addWidget(title_label)

            value_layout = QHBoxLayout()
            value_label = QLabel(value)
            value_label.setFont(QFont("Microsoft YaHei", 20, QFont.Weight.Bold))
            value_label.setStyleSheet("color: #0B8A7D;")
            value_layout.addWidget(value_label)

            unit_label = QLabel(unit)
            unit_label.setStyleSheet("color: #999; font-size: 12px;")
            value_layout.addWidget(unit_label)
            value_layout.addStretch()

            stat_widget.addLayout(value_layout)
            layout.addLayout(stat_widget)

            self.stat_labels[title] = value_label

        return frame

    def _load_records(self):
        """加载血糖记录"""
        date = self.date_edit.date().toString("yyyy-MM-dd")
        type_map = {0: None, 1: "FASTING", 2: "POST_MEAL", 3: "BEFORE_SLEEP", 4: "RANDOM"}
        measure_type = type_map.get(self.type_combo.currentIndex())

        try:
            result = self.api.get_glucose_records(
                start_date=date,
                end_date=date,
                measure_type=measure_type
            )
            records = result.get("content", [])
            self._populate_table(records)
            self._update_stats(records)
        except Exception as e:
            QMessageBox.warning(self, "错误", f"加载记录失败: {str(e)}")

    def _populate_table(self, records):
        """填充表格"""
        self.table.setRowCount(len(records))

        type_names = {
            "FASTING": "空腹",
            "POST_MEAL": "餐后",
            "BEFORE_SLEEP": "睡前",
            "RANDOM": "随机"
        }

        for row, record in enumerate(records):
            # 时间
            time_item = QTableWidgetItem(record.get("measureTime", ""))
            self.table.setItem(row, 0, time_item)

            # 血糖值
            value = record.get("value", 0)
            value_item = QTableWidgetItem(f"{value} mmol/L")
            # 根据值设置颜色
            if value < 3.9:
                value_item.setForeground(Qt.GlobalColor.red)
            elif value > 7.8:
                value_item.setForeground(QColor("#FF9800"))
            else:
                value_item.setForeground(Qt.GlobalColor.darkGreen)
            self.table.setItem(row, 1, value_item)

            # 测量类型
            type_item = QTableWidgetItem(type_names.get(record.get("measureType", ""), ""))
            self.table.setItem(row, 2, type_item)

            # 备注
            note_item = QTableWidgetItem(record.get("note", ""))
            self.table.setItem(row, 3, note_item)

            # 操作
            delete_btn = QPushButton("删除")
            delete_btn.setStyleSheet("""
                QPushButton {
                    background: #f44336;
                    color: white;
                    border: none;
                    padding: 5px 10px;
                    border-radius: 5px;
                }
                QPushButton:hover {
                    background: #d32f2f;
                }
            """)
            delete_btn.clicked.connect(lambda checked, rid=record.get("id"): self._delete_record(rid))
            self.table.setCellWidget(row, 4, delete_btn)

    def _update_stats(self, records):
        """更新统计信息"""
        if not records:
            return

        values = [r.get("value", 0) for r in records]
        self.stat_labels["平均血糖"].setText(f"{sum(values)/len(values):.1f}")
        self.stat_labels["最高值"].setText(f"{max(values):.1f}")
        self.stat_labels["最低值"].setText(f"{min(values):.1f}")
        self.stat_labels["记录次数"].setText(str(len(records)))

    def _add_record(self):
        """添加血糖记录"""
        dialog = AddGlucoseDialog(self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            try:
                data = dialog.get_data()
                self.api.create_glucose_record(data)
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
                self.api.delete_glucose_record(record_id)
                self._load_records()
            except Exception as e:
                QMessageBox.warning(self, "错误", f"删除失败: {str(e)}")


class AddGlucoseDialog(QDialog):
    """添加血糖记录对话框"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("添加血糖记录")
        self.setFixedSize(350, 300)
        self._setup_ui()

    def _setup_ui(self):
        layout = QFormLayout(self)

        self.value_spin = QDoubleSpinBox()
        self.value_spin.setRange(1.0, 35.0)
        self.value_spin.setSuffix(" mmol/L")
        self.value_spin.setValue(5.5)
        layout.addRow("血糖值：", self.value_spin)

        self.type_combo = QComboBox()
        self.type_combo.addItems(["空腹", "餐后", "睡前", "随机"])
        layout.addRow("测量类型：", self.type_combo)

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
        type_map = {0: "FASTING", 1: "POST_MEAL", 2: "BEFORE_SLEEP", 3: "RANDOM"}
        return {
            "value": self.value_spin.value(),
            "measureType": type_map.get(self.type_combo.currentIndex(), "FASTING"),
            "note": self.note_edit.text() or None,
            "measureTime": datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
        }
