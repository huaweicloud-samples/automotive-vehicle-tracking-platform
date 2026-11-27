FROM swr.cn-north-4.myhuaweicloud.com/vehicle-tracking/tracking-connector:previous

WORKDIR /app

# kafka-python 用于向 DMS Kafka 发布事件（SASL_SSL）
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 8080

ENV HOST=0.0.0.0
ENV PORT=8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health')" || exit 1

CMD ["python", "app.py"]
