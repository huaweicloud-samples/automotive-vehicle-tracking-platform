"""
Marketplace Subscription Management Service（华为云适配版）
管理客户关系、服务消费方配置、供应商集成与订阅授权。

仅依赖标准库；生产化时在 TODO 处接入 DDS（pymongo）持久化订阅数据。
"""

import json
import logging
import os
from http.server import HTTPServer, BaseHTTPRequestHandler

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

POLICY_COLLECTION = os.environ.get('POLICY_COLLECTION', 'policy_rules')
SECURITY_COLLECTION = os.environ.get('SECURITY_COLLECTION', 'security_rules')


class MarketplaceHandler(BaseHTTPRequestHandler):
    """Marketplace 订阅管理 HTTP 服务"""

    def do_GET(self):
        if self.path == '/health':
            self._send_response(200, {'status': 'healthy'})
        elif self.path.startswith('/subscriptions'):
            self._handle_list_subscriptions()
        elif self.path.startswith('/marketplace/providers'):
            self._handle_list_providers()
        else:
            self._send_response(404, {'error': 'Not found'})

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        body = json.loads(self.rfile.read(content_length)) if content_length > 0 else {}

        if self.path == '/marketplace/subscribe':
            self._handle_subscribe(body)
        elif self.path == '/marketplace/providers/register':
            self._handle_register_provider(body)
        else:
            self._send_response(404, {'error': 'Not found'})

    def _handle_list_subscriptions(self):
        """列出当前消费方的有效订阅。"""
        logger.info("Listing subscriptions")
        response = {
            'subscriptions': [],
            'count': 0
        }
        self._send_response(200, response)

    def _handle_list_providers(self):
        """列出市场内可用的追踪供应商。"""
        logger.info("Listing providers")
        response = {
            'providers': [
                {
                    'id': 'gps-provider-1',
                    'name': 'GPS Tracking Provider',
                    'modes': ['GPS'],
                    'regions': ['IN']
                }
            ]
        }
        self._send_response(200, response)

    def _handle_subscribe(self, body):
        """订阅一个追踪供应商。"""
        consumer_id = body.get('consumerId', '')
        provider_id = body.get('providerId', '')
        logger.info("Subscribe: consumer=%s, provider=%s", consumer_id, provider_id)

        response = {
            'subscriptionId': f"sub-{consumer_id}-{provider_id}",
            'status': 'active',
            'consumerId': consumer_id,
            'providerId': provider_id
        }
        self._send_response(201, response)

    def _handle_register_provider(self, body):
        """注册新的追踪供应商。"""
        provider_name = body.get('name', '')
        logger.info("Register provider: %s", provider_name)

        response = {
            'providerId': f"prov-{provider_name.lower().replace(' ', '-')}",
            'status': 'registered',
            'name': provider_name
        }
        self._send_response(201, response)

    def _send_response(self, status_code, body):
        self.send_response(status_code)
        self.send_header('Content-Type', 'application/json')
        self.end_headers()
        self.wfile.write(json.dumps(body).encode())


if __name__ == '__main__':
    port = int(os.environ.get('PORT', 8080))
    host = os.environ.get('HOST', '0.0.0.0')
    server = HTTPServer((host, port), MarketplaceHandler)  # nosec B104
    logger.info("Marketplace Service starting on %s:%s", host, port)
    server.serve_forever()
