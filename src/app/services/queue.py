import json
from functools import lru_cache

import anyio
import boto3

from src.app.core.settings import get_queue_settings


@lru_cache(maxsize=1)
def get_sqs_client():
    qs = get_queue_settings()
    return boto3.client(
        "sqs",
        endpoint_url="https://message-queue.api.cloud.yandex.net",
        region_name="ru-central1",
        aws_access_key_id=qs.ACCESS_KEY,
        aws_secret_access_key=qs.SECRET_KEY,
    )


async def send_task_notification(task_id: str, action: str, user_id: str) -> None:
    qs = get_queue_settings()
    message = {"task_id": task_id, "action": action, "user_id": user_id}

    client = get_sqs_client()

    def _send():
        client.send_message(
            QueueUrl=qs.QUEUE_URL,
            MessageBody=json.dumps(message),
        )

    await anyio.to_thread.run_sync(_send)
