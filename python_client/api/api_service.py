"""API 服务层 - 处理与后端的所有通信"""
import requests
from typing import Optional, Dict, Any


class ApiService:
    """后端 API 服务"""

    def __init__(self, base_url: str = "http://127.0.0.1:8080"):
        self.base_url = base_url
        self.api_prefix = "/api"
        self.token: Optional[str] = None
        self._session = requests.Session()
        self._session.headers.update({
            "Content-Type": "application/json; charset=utf-8",
            "Accept": "application/json"
        })

    @property
    def api_base(self) -> str:
        return f"{self.base_url}{self.api_prefix}"

    def set_token(self, token: Optional[str]):
        """设置认证令牌"""
        self.token = token
        if token:
            self._session.headers["Authorization"] = f"Bearer {token}"
        elif "Authorization" in self._session.headers:
            del self._session.headers["Authorization"]

    def check_health(self) -> bool:
        """检查后端服务健康状态"""
        try:
            resp = self._session.get(
                f"{self.api_base}/health",
                timeout=5
            )
            return resp.status_code == 200
        except requests.RequestException:
            return False

    # ==================== 认证相关 ====================

    def login(self, phone: str, password: str, captcha_code: str = "", captcha_id: str = "") -> Dict[str, Any]:
        """密码登录"""
        data = {
            "phone": phone,
            "password": password,
        }
        if captcha_code:
            data["captchaCode"] = captcha_code
        if captcha_id:
            data["captchaChallengeId"] = captcha_id
        return self._post("/auth/login", data, auth_required=False)

    def register(self, phone: str, password: str, sms_code: str) -> Dict[str, Any]:
        """用户注册"""
        return self._post("/auth/register", {
            "phone": phone,
            "password": password,
            "smsCode": sms_code,
        }, auth_required=False)

    def send_sms_code(self, phone: str, captcha_code: str = "", captcha_id: str = "") -> Dict[str, Any]:
        """发送短信验证码"""
        data = {
            "phone": phone,
            "scene": "REGISTER"
        }
        if captcha_code:
            data["captchaCode"] = captcha_code
        if captcha_id:
            data["captchaChallengeId"] = captcha_id
        return self._post("/auth/sms/send", data, auth_required=False)

    def get_captcha(self) -> Dict[str, Any]:
        """获取图形验证码"""
        return self._get("/auth/captcha", auth_required=False)

    def logout(self):
        """退出登录"""
        try:
            self._post("/auth/logout", None)
        except Exception:
            pass
        self.set_token(None)

    # ==================== 仪表盘 ====================

    def get_dashboard_today(self) -> Dict[str, Any]:
        """获取今日概览"""
        return self._get("/dashboard/today")

    # ==================== 血糖相关 ====================

    def get_glucose_records(
        self,
        start_date: Optional[str] = None,
        end_date: Optional[str] = None,
        measure_type: Optional[str] = None,
        page: int = 0,
        size: int = 20
    ) -> Dict[str, Any]:
        """获取血糖记录列表"""
        params = {"page": page, "size": size}
        if start_date:
            params["startDate"] = start_date
        if end_date:
            params["endDate"] = end_date
        if measure_type:
            params["measureType"] = measure_type
        return self._get("/blood-glucose/records", params)

    def create_glucose_record(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """创建血糖记录"""
        return self._post("/blood-glucose/records", data)

    def delete_glucose_record(self, record_id: int):
        """删除血糖记录"""
        self._delete(f"/blood-glucose/records/{record_id}")

    def get_glucose_trend_daily(self, date: str) -> Dict[str, Any]:
        """获取日血糖趋势"""
        return self._get("/blood-glucose/trend/daily", {"date": date})

    def get_glucose_trend_weekly(self, week_start: str) -> Dict[str, Any]:
        """获取周血糖趋势"""
        return self._get("/blood-glucose/trend/weekly", {"weekStart": week_start})

    def get_glucose_trend_monthly(self, year: int, month: int) -> Dict[str, Any]:
        """获取月血糖趋势"""
        return self._get("/blood-glucose/trend/monthly", {"year": year, "month": month})

    def get_abnormal_events(self, page: int = 0, size: int = 50) -> Dict[str, Any]:
        """获取血糖异常事件"""
        return self._get("/blood-glucose/abnormal-events", {"page": page, "size": size})

    # ==================== 饮食相关 ====================

    def get_diet_records(self, date: Optional[str] = None, page: int = 0, size: int = 20) -> Dict[str, Any]:
        """获取饮食记录"""
        params = {"page": page, "size": size}
        if date:
            params["date"] = date
        return self._get("/diet/records", params)

    def create_diet_record(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """创建饮食记录"""
        return self._post("/diet/records", data)

    def delete_diet_record(self, record_id: int):
        """删除饮食记录"""
        self._delete(f"/diet/records/{record_id}")

    def search_food(self, keyword: str) -> Dict[str, Any]:
        """搜索食物"""
        return self._get("/diet/foods/search", {"keyword": keyword})

    def get_meal_plans(self, date: Optional[str] = None) -> Dict[str, Any]:
        """获取膳食计划"""
        params = {}
        if date:
            params["date"] = date
        return self._get("/diet/meal-plans", params)

    # ==================== 运动相关 ====================

    def get_exercise_records(self, date: Optional[str] = None, page: int = 0, size: int = 20) -> Dict[str, Any]:
        """获取运动记录"""
        params = {"page": page, "size": size}
        if date:
            params["date"] = date
        return self._get("/exercise/records", params)

    def create_exercise_record(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """创建运动记录"""
        return self._post("/exercise/records", data)

    def delete_exercise_record(self, record_id: int):
        """删除运动记录"""
        self._delete(f"/exercise/records/{record_id}")

    def get_exercise_types(self) -> Dict[str, Any]:
        """获取运动类型列表"""
        return self._get("/exercise/types")

    # ==================== 用户相关 ====================

    def get_user_profile(self) -> Dict[str, Any]:
        """获取用户资料"""
        return self._get("/user/profile")

    def update_user_profile(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """更新用户资料"""
        return self._put("/user/profile", data)

    def get_health_profile(self) -> Dict[str, Any]:
        """获取健康档案"""
        return self._get("/user/health-profile")

    def update_health_profile(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """更新健康档案"""
        return self._put("/user/health-profile", data)

    # ==================== 社区相关 ====================

    def get_community_posts(self, page: int = 0, size: int = 20) -> Dict[str, Any]:
        """获取社区帖子"""
        return self._get("/community/posts", {"page": page, "size": size})

    def create_community_post(self, data: Dict[str, Any]) -> Dict[str, Any]:
        """发布帖子"""
        return self._post("/community/posts", data)

    def get_post_detail(self, post_id: int) -> Dict[str, Any]:
        """获取帖子详情"""
        return self._get(f"/community/posts/{post_id}")

    def get_post_comments(self, post_id: int, page: int = 0, size: int = 20) -> Dict[str, Any]:
        """获取帖子评论"""
        return self._get(f"/community/posts/{post_id}/comments", {"page": page, "size": size})

    def create_comment(self, post_id: int, content: str) -> Dict[str, Any]:
        """发布评论"""
        return self._post(f"/community/posts/{post_id}/comments", {"content": content})

    # ==================== 提醒相关 ====================

    def get_reminders(self) -> Dict[str, Any]:
        """获取提醒列表"""
        return self._get("/reminders")

    def update_reminder(self, reminder_id: int, data: Dict[str, Any]) -> Dict[str, Any]:
        """更新提醒"""
        return self._put(f"/reminders/{reminder_id}", data)

    # ==================== 内部方法 ====================

    def _get(self, path: str, params: Optional[Dict] = None, auth_required: bool = True) -> Dict[str, Any]:
        """GET 请求"""
        url = f"{self.api_base}{path}"
        try:
            resp = self._session.get(url, params=params, timeout=10)
            return self._handle_response(resp, auth_required)
        except requests.RequestException as e:
            raise ApiException(0, f"网络异常: {str(e)}")

    def _post(self, path: str, data: Optional[Dict], auth_required: bool = True) -> Dict[str, Any]:
        """POST 请求"""
        url = f"{self.api_base}{path}"
        try:
            resp = self._session.post(url, json=data, timeout=10)
            return self._handle_response(resp, auth_required)
        except requests.RequestException as e:
            raise ApiException(0, f"网络异常: {str(e)}")

    def _put(self, path: str, data: Optional[Dict], auth_required: bool = True) -> Dict[str, Any]:
        """PUT 请求"""
        url = f"{self.api_base}{path}"
        try:
            resp = self._session.put(url, json=data, timeout=10)
            return self._handle_response(resp, auth_required)
        except requests.RequestException as e:
            raise ApiException(0, f"网络异常: {str(e)}")

    def _delete(self, path: str, auth_required: bool = True):
        """DELETE 请求"""
        url = f"{self.api_base}{path}"
        try:
            resp = self._session.delete(url, timeout=10)
            self._handle_response(resp, auth_required)
        except requests.RequestException as e:
            raise ApiException(0, f"网络异常: {str(e)}")

    def _handle_response(self, resp: requests.Response, auth_required: bool = True) -> Dict[str, Any]:
        """处理响应"""
        if resp.status_code == 401 and auth_required:
            self.set_token(None)
            raise ApiException(401, "登录已过期，请重新登录")

        if resp.status_code >= 400:
            try:
                body = resp.json()
                message = body.get("message", "请求失败")
            except Exception:
                message = "请求失败"
            raise ApiException(resp.status_code, message)

        if not resp.content:
            return {}

        try:
            return resp.json()
        except Exception:
            return {}


class ApiException(Exception):
    """API 异常"""

    def __init__(self, status_code: int, message: str):
        self.status_code = status_code
        self.message = message
        super().__init__(message)
