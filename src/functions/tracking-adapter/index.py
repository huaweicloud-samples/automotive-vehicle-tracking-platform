"""
供应商适配器统一入口（FunctionGraph handler）。

通过环境变量 PROVIDER_TYPE 区分 GPS / SIM / AIS140 三种供应商；
收到发现 / 追踪 / 终止请求后，模拟生成位置数据并发布到 DMS Kafka。

环境变量（在 FunctionGraph 控制台或 API 配置，见部署指导书）：
  PROVIDER_TYPE          供应商类型：GPS | SIM | AIS140
  KAFKA_BOOTSTRAP_SERVERS Kafka 客户端连接地址（DMS 实例 connect_address，SASL_SSL）
  KAFKA_TOPIC            事件主题，默认 vehicle-tracking-events
  KAFKA_USERNAME         SASL 用户名（默认 vehicle-tracking）
  KAFKA_PASSWORD         SASL 密码（敏感）
  CACHE_ENDPOINT         Redis 缓存地址（可选，用于会话状态读写）
"""

import json
import logging
import os
import time

from kafka import KafkaProducer

from base_adapter import (
    build_tracking_event,
    create_response,
    generate_dummy_location,
    generate_tracking_id,
    get_vehicle_info,
    validate_event,
)

logger = logging.getLogger()
logger.setLevel(logging.INFO)

PROVIDER_TYPE = os.environ.get("PROVIDER_TYPE", "GPS")
KAFKA_BOOTSTRAP = os.environ.get("KAFKA_BOOTSTRAP_SERVERS", "")
KAFKA_TOPIC = os.environ.get("KAFKA_TOPIC", "vehicle-tracking-events")
KAFKA_USERNAME = os.environ.get("KAFKA_USERNAME", "vehicle-tracking")
KAFKA_PASSWORD = os.environ.get("KAFKA_PASSWORD", "")

_producer = None


def get_producer():
    """懒加载 Kafka 生产者（SASL_SSL + PLAIN），避免冷启动拖慢首次请求。"""
    global _producer
    if _producer is None:
        _producer = KafkaProducer(
            bootstrap_servers=KAFKA_BOOTSTRAP,
            security_protocol="SASL_SSL",
            sasl_mechanism="PLAIN",
            sasl_plain_username=KAFKA_USERNAME,
            sasl_plain_password=KAFKA_PASSWORD,
            api_version=(3, 3, 1),
            value_serializer=lambda v: json.dumps(v, ensure_ascii=False).encode("utf-8"),
            request_timeout_ms=15000,
            retries=3,
        )
    return _producer


def _publish(event_payload: dict):
    """发布事件到 Kafka，记录发送结果。"""
    if not KAFKA_BOOTSTRAP:
        logger.warning("KAFKA_BOOTSTRAP_SERVERS 未配置，跳过发布")
        return None
    producer = get_producer()
    future = producer.send(KAFKA_TOPIC, value=event_payload)
    try:
        metadata = future.get(timeout=10)
        logger.info("事件已发布 topic=%s partition=%s offset=%s",
                    metadata.topic, metadata.partition, metadata.offset)
        return metadata
    except Exception as exc:  # noqa: BLE001
        logger.error("发布事件失败: %s", exc)
        raise


def handler(event, context):
    """FunctionGraph 入口。event 为 APIG 触发的请求事件。"""
    try:
        path = event.get("path", "/")
        raw_body = event.get("body", "")
        body = json.loads(raw_body) if raw_body else (event.get("queryStringParameters") or {})
        logger.info("适配器=%s 请求=%s", PROVIDER_TYPE, path)

        if path in ("/discovery", "/api/discovery"):
            ok, err = validate_event(body, ["vehicleId"])
            if not ok:
                return create_response(400, {"error": err})
            vehicle_id = body["vehicleId"]
            vehicle = get_vehicle_info(vehicle_id)
            return create_response(200, {
                "vehicleId": vehicle_id,
                "providers": [{
                    "provider": f"{PROVIDER_TYPE.lower()}-provider",
                    "trackingMode": PROVIDER_TYPE,
                    "frequency": "30s",
                    "reliability": "high",
                    "region": vehicle["region"],
                }],
            })

        if path in ("/tracking", "/api/tracking"):
            ok, err = validate_event(body, ["vehicleId"])
            if not ok:
                return create_response(400, {"error": err})
            vehicle_id = body["vehicleId"]
            vehicle = get_vehicle_info(vehicle_id)
            tracking_id = generate_tracking_id(PROVIDER_TYPE.lower(), vehicle_id)
            location = generate_dummy_location(vehicle["base_lat"], vehicle["base_lon"])
            event_payload = build_tracking_event(
                tracking_id, vehicle_id, PROVIDER_TYPE, location)
            _publish(event_payload)
            return create_response(202, {
                "trackingId": tracking_id,
                "status": "STARTED",
                "provider": PROVIDER_TYPE,
                "firstLocation": location,
            })

        if path.startswith("/tracking/") and path.endswith("/terminate"):
            tracking_id = path.split("/")[2]
            return create_response(200, {"trackingId": tracking_id, "status": "TERMINATED"})

        return create_response(404, {"error": "Not found"})
    except Exception as exc:  # noqa: BLE001
        logger.exception("适配器处理失败")
        return create_response(500, {"error": str(exc)})
