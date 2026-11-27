"""
供应商适配器公共模块。

提供标准化的响应格式、模拟位置数据生成、事件载荷构建与通用校验。
仅依赖标准库，供三个供应商适配器（GPS / SIM / AIS140）复用。

运行环境：FunctionGraph（Python 3.10），部署时需将本模块与 index.py 一并打包。
"""

import json
import logging
import random
import uuid
from datetime import datetime, timezone

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def create_response(status_code: int, body: dict) -> dict:
    """构造标准化响应。"""
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
            "X-Request-Id": str(uuid.uuid4()),
        },
        "body": json.dumps(body, ensure_ascii=False),
    }


def generate_tracking_id(provider_prefix: str, vehicle_id: str) -> str:
    """为一次追踪会话生成唯一 ID。"""
    return f"trk-{provider_prefix}-{vehicle_id}-{uuid.uuid4().hex[:8]}"


def generate_dummy_location(base_lat: float = 19.076, base_lon: float = 72.877) -> dict:
    """在基准坐标附近生成模拟位置数据。"""
    return {
        "latitude": round(base_lat + random.uniform(-0.05, 0.05), 6),
        "longitude": round(base_lon + random.uniform(-0.05, 0.05), 6),
        "altitude": round(random.uniform(10.0, 50.0), 1),
        "speed": round(random.uniform(0, 80), 1),
        "heading": random.randint(0, 359),
        "accuracy": round(random.uniform(3.0, 15.0), 1),
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


def build_tracking_event(tracking_id: str, vehicle_id: str, provider: str, location: dict) -> dict:
    """构造发布到 Kafka 事件总线的位置更新事件载荷。"""
    return {
        "eventId": str(uuid.uuid4()),
        "eventType": "LOCATION_UPDATE",
        "trackingId": tracking_id,
        "vehicleId": vehicle_id,
        "provider": provider,
        "location": location,
        "metadata": {
            "producedAt": datetime.now(timezone.utc).isoformat(),
            "schemaVersion": "1.0",
        },
    }


def validate_event(event: dict, required_fields: list) -> tuple:
    """校验事件必填字段，返回 (是否合法, 错误信息)。"""
    missing = [f for f in required_fields if not event.get(f)]
    if missing:
        return False, f"Missing required fields: {', '.join(missing)}"
    return True, None


# 模拟车辆注册表（用于演示；生产环境应改为查询车辆档案）
DUMMY_VEHICLES = {
    "MH01AB1234": {"owner": "Fleet Corp India", "type": "truck", "region": "IN",
                   "base_lat": 19.076, "base_lon": 72.877},
    "DL02CD5678": {"owner": "Logistics Express", "type": "van", "region": "IN",
                   "base_lat": 28.613, "base_lon": 77.209},
    "KA03EF9012": {"owner": "South Transport Ltd", "type": "truck", "region": "IN",
                   "base_lat": 12.971, "base_lon": 77.594},
    "TN04GH3456": {"owner": "Tamil Freight Services", "type": "lorry", "region": "IN",
                   "base_lat": 13.082, "base_lon": 80.270},
    "GJ05IJ7890": {"owner": "Gujarat Movers", "type": "container", "region": "IN",
                   "base_lat": 23.022, "base_lon": 72.571},
}


def get_vehicle_info(vehicle_id: str) -> dict:
    """按车辆 ID 取模拟档案；未命中时返回默认值。"""
    return DUMMY_VEHICLES.get(
        vehicle_id,
        {"owner": "Unknown Fleet", "type": "unknown", "region": "IN",
         "base_lat": 20.593, "base_lon": 78.962},
    )
