"""社区交流页面"""
from PySide6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel,
    QFrame, QPushButton, QScrollArea, QTextEdit,
    QMessageBox, QDialog, QFormLayout, QLineEdit
)
from PySide6.QtCore import Qt
from PySide6.QtGui import QFont


class CommunityPage(QWidget):
    """社区交流页面"""

    def __init__(self, api):
        super().__init__()
        self.api = api
        self._setup_ui()
        self._load_posts()

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

        title = QLabel("社区交流")
        title.setFont(QFont("Microsoft YaHei", 16, QFont.Weight.Bold))
        toolbar_layout.addWidget(title)

        toolbar_layout.addStretch()

        new_post_btn = QPushButton("+ 发布帖子")
        new_post_btn.setFixedSize(120, 40)
        new_post_btn.clicked.connect(self._new_post)
        toolbar_layout.addWidget(new_post_btn)

        layout.addWidget(toolbar)

        # 帖子列表
        self.posts_scroll = QScrollArea()
        self.posts_scroll.setWidgetResizable(True)
        self.posts_scroll.setFrameShape(QFrame.Shape.NoFrame)
        self.posts_scroll.setStyleSheet("background: transparent;")

        self.posts_container = QWidget()
        self.posts_container.setStyleSheet("background: transparent;")
        self.posts_layout = QVBoxLayout(self.posts_container)
        self.posts_layout.setSpacing(15)
        self.posts_layout.setContentsMargins(0, 0, 0, 0)

        self.posts_scroll.setWidget(self.posts_container)
        layout.addWidget(self.posts_scroll)

    def _load_posts(self):
        """加载帖子"""
        try:
            result = self.api.get_community_posts()
            posts = result.get("content", [])
            self._populate_posts(posts)
        except Exception as e:
            QMessageBox.warning(self, "错误", f"加载帖子失败: {str(e)}")

    def _populate_posts(self, posts):
        """填充帖子列表"""
        # 清除现有帖子
        while self.posts_layout.count():
            child = self.posts_layout.takeAt(0)
            if child.widget():
                child.widget().deleteLater()

        for post in posts:
            post_card = self._create_post_card(post)
            self.posts_layout.addWidget(post_card)

        self.posts_layout.addStretch()

    def _create_post_card(self, post):
        """创建帖子卡片"""
        card = QFrame()
        card.setStyleSheet("""
            QFrame {
                background: white;
                border-radius: 15px;
                border: 1px solid #e8e8e8;
            }
            QFrame:hover {
                border-color: #0B8A7D;
            }
        """)

        layout = QVBoxLayout(card)
        layout.setContentsMargins(20, 15, 20, 15)

        # 标题
        title = QLabel(post.get("title", ""))
        title.setFont(QFont("Microsoft YaHei", 14, QFont.Weight.Bold))
        title.setStyleSheet("color: #333;")
        title.setWordWrap(True)
        layout.addWidget(title)

        # 内容预览
        content = post.get("content", "")
        if len(content) > 100:
            content = content[:100] + "..."
        content_label = QLabel(content)
        content_label.setStyleSheet("color: #666; font-size: 13px;")
        content_label.setWordWrap(True)
        layout.addWidget(content_label)

        # 底部信息
        footer = QHBoxLayout()

        author = QLabel(f"作者: {post.get('authorName', '匿名')}")
        author.setStyleSheet("color: #999; font-size: 12px;")
        footer.addWidget(author)

        time_label = QLabel(post.get("createdAt", ""))
        time_label.setStyleSheet("color: #999; font-size: 12px;")
        footer.addWidget(time_label)

        footer.addStretch()

        comments_btn = QPushButton(f"评论 ({post.get('commentCount', 0)})")
        comments_btn.setStyleSheet("""
            QPushButton {
                background: transparent;
                color: #0B8A7D;
                border: none;
                font-size: 12px;
            }
            QPushButton:hover {
                color: #097268;
            }
        """)
        comments_btn.clicked.connect(lambda checked, pid=post.get("id"): self._view_post(pid))
        footer.addWidget(comments_btn)

        layout.addLayout(footer)

        # 点击查看详情
        card.mousePressEvent = lambda e, pid=post.get("id"): self._view_post(pid)
        card.setCursor(Qt.CursorShape.PointingHandCursor)

        return card

    def _new_post(self):
        """发布新帖子"""
        dialog = NewPostDialog(self)
        if dialog.exec() == QDialog.DialogCode.Accepted:
            try:
                data = dialog.get_data()
                self.api.create_community_post(data)
                self._load_posts()
                QMessageBox.information(self, "成功", "帖子已发布")
            except Exception as e:
                QMessageBox.warning(self, "错误", f"发布失败: {str(e)}")

    def _view_post(self, post_id):
        """查看帖子详情"""
        try:
            post = self.api.get_post_detail(post_id)
            comments = self.api.get_post_comments(post_id)
            dialog = PostDetailDialog(post, comments.get("content", []), self)
            dialog.exec()
        except Exception as e:
            QMessageBox.warning(self, "错误", f"加载帖子失败: {str(e)}")


class NewPostDialog(QDialog):
    """发布帖子对话框"""

    def __init__(self, parent=None):
        super().__init__(parent)
        self.setWindowTitle("发布帖子")
        self.setFixedSize(500, 400)
        self._setup_ui()

    def _setup_ui(self):
        layout = QVBoxLayout(self)

        form = QFormLayout()

        self.title_edit = QLineEdit()
        self.title_edit.setPlaceholderText("帖子标题")
        form.addRow("标题：", self.title_edit)

        layout.addLayout(form)

        self.content_edit = QTextEdit()
        self.content_edit.setPlaceholderText("帖子内容...")
        layout.addWidget(self.content_edit)

        btn_layout = QHBoxLayout()
        cancel_btn = QPushButton("取消")
        cancel_btn.clicked.connect(self.reject)
        btn_layout.addWidget(cancel_btn)

        ok_btn = QPushButton("发布")
        ok_btn.clicked.connect(self.accept)
        btn_layout.addWidget(ok_btn)
        layout.addLayout(btn_layout)

    def get_data(self):
        return {
            "title": self.title_edit.text(),
            "content": self.content_edit.toPlainText()
        }


class PostDetailDialog(QDialog):
    """帖子详情对话框"""

    def __init__(self, post, comments, parent=None):
        super().__init__(parent)
        self.post = post
        self.comments = comments
        self.setWindowTitle("帖子详情")
        self.setMinimumSize(600, 500)
        self._setup_ui()

    def _setup_ui(self):
        layout = QVBoxLayout(self)

        # 标题
        title = QLabel(self.post.get("title", ""))
        title.setFont(QFont("Microsoft YaHei", 18, QFont.Weight.Bold))
        title.setStyleSheet("color: #333;")
        title.setWordWrap(True)
        layout.addWidget(title)

        # 作者信息
        info = QHBoxLayout()
        author = QLabel(f"作者: {self.post.get('authorName', '匿名')}")
        author.setStyleSheet("color: #666;")
        info.addWidget(author)

        time_label = QLabel(self.post.get("createdAt", ""))
        time_label.setStyleSheet("color: #999;")
        info.addWidget(time_label)
        info.addStretch()
        layout.addLayout(info)

        # 内容
        content = QLabel(self.post.get("content", ""))
        content.setStyleSheet("color: #333; font-size: 14px;")
        content.setWordWrap(True)
        layout.addWidget(content)

        # 评论区
        comments_title = QLabel(f"评论 ({len(self.comments)})")
        comments_title.setFont(QFont("Microsoft YaHei", 14, QFont.Weight.Bold))
        layout.addWidget(comments_title)

        for comment in self.comments:
            comment_frame = QFrame()
            comment_frame.setStyleSheet("""
                QFrame {
                    background: #f5f5f5;
                    border-radius: 10px;
                    padding: 10px;
                }
            """)
            comment_layout = QVBoxLayout(comment_frame)

            comment_author = QLabel(comment.get("authorName", "匿名"))
            comment_author.setStyleSheet("font-weight: bold; color: #0B8A7D;")
            comment_layout.addWidget(comment_author)

            comment_content = QLabel(comment.get("content", ""))
            comment_content.setWordWrap(True)
            comment_layout.addWidget(comment_content)

            layout.addWidget(comment_frame)

        # 关闭按钮
        close_btn = QPushButton("关闭")
        close_btn.clicked.connect(self.accept)
        layout.addWidget(close_btn)
