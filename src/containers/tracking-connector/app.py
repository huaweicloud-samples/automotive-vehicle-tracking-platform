"""
Tracking Connector Service（华为云适配版）
核心编排服务：供应商协议标准化、请求路由、响应聚合、会话管理。

华为云部署环境变量（k8s.yaml ConfigMap 注入）：
  KAFKA_BOOTSTRAP_SERVERS  DMS Kafka 连接地址（VPC 内网）
  CACHE_ENDPOINT           DCS Redis 连接域名
  CACHE_PORT               DCS Redis 端口（默认 6379）
  POLICY_COLLECTION        策略规则集合名
  SECURITY_COLLECTION      安全规则集合名
  MONGO_CONNECTION         DDS MongoDB 连接串（可选）

仅依赖标准库，纯内存演示逻辑；生产化时在 TODO 处接入
DMS/Redis/DDS 客户端（kafka-python / redis-py / pymongo）。
"""

import json
import logging
import os
import uuid
from http.server import HTTPServer, BaseHTTPRequestHandler

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

KAFKA_BOOTSTRAP = os.environ.get('KAFKA_BOOTSTRAP_SERVERS', '')
KAFKA_BOOTSTRAP_SSL = os.environ.get('KAFKA_BOOTSTRAP_SERVERS_SSL', '')
KAFKA_TOPIC = os.environ.get('KAFKA_TOPIC', 'vehicle-tracking-events')
KAFKA_USERNAME = os.environ.get('KAFKA_USERNAME', 'vehicle-tracking')
KAFKA_PASSWORD = os.environ.get('KAFKA_PASSWORD', '')
CACHE_ENDPOINT = os.environ.get('CACHE_ENDPOINT', '')
MONGO_CONNECTION = os.environ.get('MONGO_CONNECTION', '')
POLICY_COLLECTION = os.environ.get('POLICY_COLLECTION', 'policy_rules')
SECURITY_COLLECTION = os.environ.get('SECURITY_COLLECTION', 'security_rules')


class TrackingConnectorHandler(BaseHTTPRequestHandler):
    """Tracking Connector HTTP 服务"""

    def do_GET(self):
        if self.path == '/health':
            self._send_response(200, {'status': 'healthy'})
        elif self.path.startswith('/tracking/') and self.path.endswith('/location'):
            tracking_id = self.path.split('/')[2]
            self._handle_get_location(tracking_id)
        else:
            self._send_response(404, {'error': 'Not found'})

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = json.loads(self.rfile.read(content_length)) if content_length > 0 else {}

        if self.path == '/discovery':
            self._handle_discovery(body)
        elif self.path == '/tracking':
            self._handle_tracking(body)
        else:
            self._send_response(404, {'error': 'Not found'})

    def do_DELETE(self):
        if self.path.startswith('/tracking/'):
            tracking_id = self.path.split('/')[2]
            self._handle_termination(tracking_id)
        else:
            self._send_response(404, {'error': 'Not found'})

    def _handle_discovery(self, body):
        """车辆发现：广播到各供应商并聚合响应。"""
        vehicle_id = body.get('vehicleId', '')
        logger.info("Discovery request for vehicle: %s", vehicle_id)

        response = {
            'vehicleId': vehicle_id,
            'providers': [
                {
                    'provider': 'gps-provider',
                    'trackingMode': 'GPS',
                    'frequency': '30s',
                    'reliability': 'high'
                }
            ]
        }
        self._send_response(200, response)

    def _handle_tracking(self, body):
        """发起追踪：路由到所选供应商，返回 trackingId，并发布 LOCATION_UPDATE 事件到 Kafka、写 DDS 会话。"""
        vehicle_id = body.get('vehicleId', '')
        provider_id = body.get('providerId', 'gps')
        logger.info("Tracking request for vehicle: %s, provider: %s", vehicle_id, provider_id)

        tracking_id = f"trk-{vehicle_id}-{uuid.uuid4().hex[:8]}"

        # 发布位置更新事件到 DMS Kafka（SASL_SSL）
        try:
            self._publish_location_event(tracking_id, vehicle_id, provider_id)
        except Exception as exc:  # noqa: BLE001
            logger.error("Kafka publish failed: %s", exc)

        # 写 DDS session_state 集合（MongoDB 兼容）
        try:
            self._write_session_state(tracking_id, vehicle_id, provider_id)
        except Exception as exc:  # noqa: BLE001
            logger.error("DDS write failed: %s", exc)

        response = {
            'trackingId': tracking_id,
            'status': 'STARTED',
            'provider': provider_id,
            'frequency': '30s',
            'kafkaTopic': KAFKA_TOPIC,
        }
        self._send_response(200, response)

    def _write_session_state(self, tracking_id, vehicle_id, provider_id):
        """在 DDS 中记录会话状态（collection: session_state）。"""
        import datetime as _dt
        from pymongo import MongoClient

        client = MongoClient(
            MONGO_CONNECTION,
            serverSelectionTimeoutMS=8000,
            tls=True,
            tlsAllowInvalidCertificates=True,
        )
        db = client['vehicle_tracking']
        session = {
            'trackingId': tracking_id,
            'vehicleId': vehicle_id,
            'provider': provider_id,
            'status': 'STARTED',
            'createdAt': _dt.datetime.now(_dt.timezone.utc).isoformat(),
        }
        result = db['session_state'].insert_one(session)
        logger.info("DDS session_state inserted id=%s trackingId=%s", result.inserted_id, tracking_id)
        client.close()

    def _publish_location_event(self, tracking_id, vehicle_id, provider_id):
        """构造并发布 LOCATION_UPDATE 事件。"""
        import json as _json
        import ssl as _ssl
        from kafka import KafkaProducer

        event = {
            'eventId': str(uuid.uuid4()),
            'eventType': 'LOCATION_UPDATE',
            'trackingId': tracking_id,
            'vehicleId': vehicle_id,
            'provider': provider_id,
            'location': {
                'latitude': 19.076,
                'longitude': 72.877,
                'timestamp': '2026-08-19T00:00:00Z',
            },
            'metadata': {'source': 'tracking-connector', 'schemaVersion': '1.0'},
        }
        # DMS 默认证书为自签名/私有 CA，关闭证书校验以完成演示链路（生产建议配置 DMS CA 证书）
        ssl_context = _ssl.create_default_context()
        ssl_context.check_hostname = False
        ssl_context.verify_mode = _ssl.CERT_NONE
        producer = KafkaProducer(
            bootstrap_servers=KAFKA_BOOTSTRAP_SSL or KAFKA_BOOTSTRAP,
            security_protocol='SASL_SSL',
            sasl_mechanism='PLAIN',
            sasl_plain_username=KAFKA_USERNAME,
            sasl_plain_password=KAFKA_PASSWORD,
            ssl_context=ssl_context,
            value_serializer=lambda v: _json.dumps(v).encode('utf-8'),
            request_timeout_ms=15000,
        )
        future = producer.send(KAFKA_TOPIC, value=event)
        future.get(timeout=10)
        producer.flush()
        producer.close()
        logger.info("Published LOCATION_UPDATE to topic=%s trackingId=%s", KAFKA_TOPIC, tracking_id)

    def _handle_get_location(self, tracking_id):
        """查询追踪会话最新位置。"""
        logger.info("Location request for tracking: %s", tracking_id)

        # TODO: 接入 Redis 会话缓存与供应商查询
        response = {
            'trackingId': tracking_id,
            'latitude': 0.0,
            'longitude': 0.0,
            'timestamp': '1970-01-01T00:00:00Z',
            'speed': 0.0,
            'heading': 0
        }
        self._send_response(200, response)

    def _handle_termination(self, tracking_id):
        """终止追踪会话。"""
        logger.info("Termination request for tracking: %s", tracking_id)

        # TODO: 通知供应商并清理会话
        response = {
            'trackingId': tracking_id,
            'status': 'TERMINATED'
        }
        self._send_response(200, response)

    def _send_response(self, status_code, body):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(body).encode())


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    host = os.environ.get('HOST', '0.0.0.0')
    server = HTTPServer((host, port), TrackingConnectorHandler)  # nosec B104
    logger.info("Tracking Connector starting on %s:%s", host, port)
    server.serve_forever()
