#!/usr/bin/env python3
"""
糖尿病健康管家 — 后端压力测试脚本
用法: python stress_test.py [--base-url http://localhost:8080]
"""

import argparse
import json
import statistics
import sys
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from dataclasses import dataclass, field
from typing import Optional

import requests

# ── 配置 ──────────────────────────────────────────────────────

DEFAULT_BASE_URL = "http://localhost:8080"
API_PREFIX = "/api"

# ── 数据结构 ──────────────────────────────────────────────────

@dataclass
class RequestResult:
    status_code: int
    latency_ms: float
    error: Optional[str] = None

@dataclass
class ScenarioResult:
    name: str
    total_requests: int = 0
    success_count: int = 0
    fail_count: int = 0
    latencies: list = field(default_factory=list)
    errors: dict = field(default_factory=dict)
    duration_s: float = 0.0

    def add(self, result: RequestResult):
        self.total_requests += 1
        self.latencies.append(result.latency_ms)
        if 200 <= result.status_code < 400:
            self.success_count += 1
        else:
            self.fail_count += 1
            key = f"{result.status_code}"
            if result.error:
                key = f"{result.status_code}: {result.error[:50]}"
            self.errors[key] = self.errors.get(key, 0) + 1

    def report(self) -> str:
        if not self.latencies:
            return f"[{self.name}] 无请求"
        latencies = sorted(self.latencies)
        p50 = latencies[int(len(latencies) * 0.5)]
        p95 = latencies[int(len(latencies) * 0.95)]
        p99 = latencies[min(int(len(latencies) * 0.99), len(latencies) - 1)]
        rps = self.total_requests / max(self.duration_s, 0.001)
        lines = [
            f"\n{'='*60}",
            f"  {self.name}",
            f"{'='*60}",
            f"  总请求数:   {self.total_requests}",
            f"  成功:       {self.success_count}",
            f"  失败:       {self.fail_count}",
            f"  持续时间:   {self.duration_s:.1f}s",
            f"  吞吐量:     {rps:.1f} req/s",
            f"  响应时间:",
            f"    p50:      {p50:.0f}ms",
            f"    p95:      {p95:.0f}ms",
            f"    p99:      {p99:.0f}ms",
            f"    min:      {latencies[0]:.0f}ms",
            f"    max:      {latencies[-1]:.0f}ms",
        ]
        if self.errors:
            lines.append(f"  错误分布:")
            for err, count in sorted(self.errors.items(), key=lambda x: -x[1]):
                lines.append(f"    {err}: {count}次")
        lines.append(f"{'='*60}")
        return "\n".join(lines)


# ── 辅助函数 ──────────────────────────────────────────────────

def api_url(base: str, path: str) -> str:
    return f"{base}{API_PREFIX}{path}"


def timed_request(method: str, url: str, session: requests.Session = None, **kwargs) -> RequestResult:
    start = time.monotonic()
    try:
        client = session or requests
        resp = client.request(method, url, timeout=10, **kwargs)
        latency = (time.monotonic() - start) * 1000
        return RequestResult(resp.status_code, latency)
    except requests.RequestException as e:
        latency = (time.monotonic() - start) * 1000
        return RequestResult(0, latency, str(e)[:100])


def register_user(base: str, phone: str, password: str) -> Optional[str]:
    """注册用户并返回 token。"""
    session = requests.Session()
    try:
        # 1. 获取验证码
        resp = session.get(api_url(base, "/auth/captcha"), timeout=10)
        if resp.status_code != 200:
            return None
        captcha = resp.json()

        # 2. 发送短信
        resp = session.post(api_url(base, "/auth/sms/send"), json={
            "phone": phone,
            "scene": "REGISTER",
            "captchaChallengeId": captcha["challengeId"],
            "captchaCode": captcha.get("displayCode", "ABCD"),
        }, timeout=10)
        if resp.status_code != 200:
            return None
        sms = resp.json()

        # 3. 注册
        resp = session.post(api_url(base, "/auth/register"), json={
            "phone": phone,
            "password": password,
            "smsCode": sms.get("debugCode", "000000"),
        }, timeout=10)
        if resp.status_code != 200:
            return None
        return resp.json().get("accessToken")
    finally:
        session.close()


def login_user(base: str, phone: str, password: str) -> Optional[str]:
    """密码登录并返回 token。"""
    session = requests.Session()
    try:
        resp = session.get(api_url(base, "/auth/captcha"), timeout=10)
        if resp.status_code != 200:
            return None
        captcha = resp.json()

        resp = session.post(api_url(base, "/auth/login"), json={
            "phone": phone,
            "password": password,
            "loginType": "PASSWORD",
            "captchaChallengeId": captcha["challengeId"],
            "captchaCode": captcha.get("displayCode", "ABCD"),
        }, timeout=10)
        if resp.status_code != 200:
            return None
        return resp.json().get("accessToken")
    finally:
        session.close()


# ── 测试场景 ──────────────────────────────────────────────────

def scenario_health_check(base: str, concurrency: int, duration_s: int) -> ScenarioResult:
    """健康检查基准测试"""
    result = ScenarioResult("健康检查基准 (GET /api/health)")
    url = api_url(base, "/health")
    end_time = time.monotonic() + duration_s

    def worker():
        session = requests.Session()
        results = []
        while time.monotonic() < end_time:
            results.append(timed_request("GET", url, session=session))
        session.close()
        return results

    start = time.monotonic()
    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = [pool.submit(worker) for _ in range(concurrency)]
        for f in as_completed(futures):
            for r in f.result():
                result.add(r)
    result.duration_s = time.monotonic() - start
    return result


def scenario_login(base: str, concurrency: int, duration_s: int) -> ScenarioResult:
    """登录压测"""
    result = ScenarioResult("登录压测 (POST /api/auth/login)")
    # 预注册用户
    phone = "13800009001"
    token = register_user(base, phone, "Test1234")
    if not token:
        result.errors["注册失败"] = 1
        return result

    url = api_url(base, "/auth/login")
    end_time = time.monotonic() + duration_s

    def worker():
        session = requests.Session()
        results = []
        while time.monotonic() < end_time:
            # 获取验证码
            cap = session.get(api_url(base, "/auth/captcha"), timeout=10)
            if cap.status_code != 200:
                results.append(RequestResult(cap.status_code, 0))
                continue
            cap_data = cap.json()
            results.append(timed_request("POST", url, session=session, json={
                "phone": phone,
                "password": "Test1234",
                "loginType": "PASSWORD",
                "captchaChallengeId": cap_data["challengeId"],
                "captchaCode": cap_data.get("displayCode", "ABCD"),
            }))
        session.close()
        return results

    start = time.monotonic()
    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = [pool.submit(worker) for _ in range(concurrency)]
        for f in as_completed(futures):
            for r in f.result():
                result.add(r)
    result.duration_s = time.monotonic() - start
    return result


def scenario_read_apis(base: str, concurrency: int, duration_s: int, token: str) -> ScenarioResult:
    """读接口压测"""
    result = ScenarioResult("读接口压测 (GET blood-glucose/dashboard/diet)")
    headers = {"Authorization": f"Bearer {token}"}
    urls = [
        api_url(base, "/blood-glucose/records?page=0&size=20"),
        api_url(base, "/dashboard/today"),
        api_url(base, f"/diet/records?date={time.strftime('%Y-%m-%d')}"),
    ]
    end_time = time.monotonic() + duration_s

    def worker():
        session = requests.Session()
        session.headers.update(headers)
        results = []
        i = 0
        while time.monotonic() < end_time:
            url = urls[i % len(urls)]
            results.append(timed_request("GET", url, session=session))
            i += 1
        session.close()
        return results

    start = time.monotonic()
    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = [pool.submit(worker) for _ in range(concurrency)]
        for f in as_completed(futures):
            for r in f.result():
                result.add(r)
    result.duration_s = time.monotonic() - start
    return result


def scenario_write_apis(base: str, concurrency: int, duration_s: int, token: str) -> ScenarioResult:
    """写接口压测"""
    result = ScenarioResult("写接口压测 (POST blood-glucose/diet records)")
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    url_glucose = api_url(base, "/blood-glucose/records")
    end_time = time.monotonic() + duration_s

    def worker():
        session = requests.Session()
        session.headers.update(headers)
        results = []
        i = 0
        while time.monotonic() < end_time:
            body = {
                "measureTime": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                "measureType": "FASTING",
                "valueMmolL": round(4.0 + (i % 10) * 0.3, 1),
            }
            results.append(timed_request("POST", url_glucose, session=session, json=body))
            i += 1
        session.close()
        return results

    start = time.monotonic()
    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = [pool.submit(worker) for _ in range(concurrency)]
        for f in as_completed(futures):
            for r in f.result():
                result.add(r)
    result.duration_s = time.monotonic() - start
    return result


def scenario_mixed(base: str, concurrency: int, duration_s: int, token: str) -> ScenarioResult:
    """综合场景：模拟真实用户行为"""
    result = ScenarioResult("综合场景 (混合读写)")
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
    end_time = time.monotonic() + duration_s

    def worker():
        session = requests.Session()
        session.headers.update(headers)
        results = []
        i = 0
        while time.monotonic() < end_time:
            action = i % 5
            if action == 0:
                results.append(timed_request("GET", api_url(base, "/dashboard/today"), session=session))
            elif action == 1:
                results.append(timed_request("GET", api_url(base, "/blood-glucose/records?page=0&size=10"), session=session))
            elif action == 2:
                body = {
                    "measureTime": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
                    "measureType": "FASTING",
                    "valueMmolL": round(5.0 + (i % 8) * 0.2, 1),
                }
                results.append(timed_request("POST", api_url(base, "/blood-glucose/records"), session=session, json=body))
            elif action == 3:
                results.append(timed_request("GET", api_url(base, f"/diet/records?date={time.strftime('%Y-%m-%d')}"), session=session))
            else:
                results.append(timed_request("GET", api_url(base, "/users/me"), session=session))
            i += 1
        session.close()
        return results

    start = time.monotonic()
    with ThreadPoolExecutor(max_workers=concurrency) as pool:
        futures = [pool.submit(worker) for _ in range(concurrency)]
        for f in as_completed(futures):
            for r in f.result():
                result.add(r)
    result.duration_s = time.monotonic() - start
    return result


# ── 主流程 ──────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="糖尿病健康管家后端压力测试")
    parser.add_argument("--base-url", default=DEFAULT_BASE_URL, help="后端地址")
    parser.add_argument("--scenario", default="all",
                        choices=["health", "login", "read", "write", "mixed", "all"],
                        help="测试场景")
    parser.add_argument("--concurrency", type=int, default=10, help="并发数")
    parser.add_argument("--duration", type=int, default=30, help="持续时间(秒)")
    args = parser.parse_args()

    base = args.base_url.rstrip("/")
    conc = args.concurrency
    dur = args.duration

    print(f"后端地址: {base}")
    print(f"并发数:   {conc}")
    print(f"持续时间: {dur}s")

    # 检查后端是否可达
    try:
        resp = requests.get(api_url(base, "/health"), timeout=5)
        print(f"健康检查: {resp.status_code} {resp.json().get('status', '')}")
    except Exception as e:
        print(f"错误: 无法连接后端 {base} — {e}")
        sys.exit(1)

    # 注册测试用户
    print("\n准备测试数据...")
    stress_phone = "13800009000"
    stress_token = register_user(base, stress_phone, "Stress1234")
    if not stress_token:
        print("警告: 测试用户注册失败，写入测试将跳过")
    else:
        print(f"测试用户已注册: {stress_phone}")

    results = []

    if args.scenario in ("health", "all"):
        results.append(scenario_health_check(base, conc, dur))

    if args.scenario in ("login", "all"):
        results.append(scenario_login(base, min(conc, 5), dur))

    if args.scenario in ("read", "all") and stress_token:
        results.append(scenario_read_apis(base, conc, dur, stress_token))

    if args.scenario in ("write", "all") and stress_token:
        results.append(scenario_write_apis(base, min(conc, 10), dur, stress_token))

    if args.scenario in ("mixed", "all") and stress_token:
        results.append(scenario_mixed(base, conc, dur, stress_token))

    # 输出报告
    print("\n" + "=" * 60)
    print("  压力测试报告")
    print("=" * 60)

    for r in results:
        print(r.report())

    # 总结
    total = sum(r.total_requests for r in results)
    total_fail = sum(r.fail_count for r in results)
    print(f"\n总计: {total} 请求, {total_fail} 失败, 失败率 {total_fail/max(total,1)*100:.1f}%")

    if total_fail > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
